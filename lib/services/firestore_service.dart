import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';

class FirestoreService {
  FirestoreService._();

  static final FirestoreService instance = FirestoreService._();

  static const String _syncCollection = 'app_meta';
  static const String _syncDocId = 'sync';
  static const String _categoriesBoxName = 'categorias_box';
  static const String _businessesBoxName = 'negocios_box';
  static const String _syncBoxName = 'sync_box';
  static const String _categoriesSyncMillisKey = 'categorias_sync_millis';
  static const String _businessesSyncMillisKey = 'negocios_sync_millis';

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  late final Directory _imagesRootDirectory;
  late final Directory _categoriesImagesDirectory;
  late final Directory _businessesImagesDirectory;

  List<CategoryItem> _categories = const [];
  List<BusinessItem> _businesses = const [];
  bool _initialized = false;
  bool _hasCompletedLaunchSync = false;
  Future<void>? _ongoingSync;

  List<CategoryItem> get categories => List.unmodifiable(_categories);
  List<BusinessItem> get businesses => List.unmodifiable(_businesses);

  Future<void> initialize() async {
    if (_initialized) {
      return;
    }

    await Hive.initFlutter();
    await Hive.openBox<Map<dynamic, dynamic>>(_categoriesBoxName);
    await Hive.openBox<Map<dynamic, dynamic>>(_businessesBoxName);
    await Hive.openBox<dynamic>(_syncBoxName);

    final supportDirectory = await getApplicationSupportDirectory();
    _imagesRootDirectory = Directory('${supportDirectory.path}/offline_images');
    _categoriesImagesDirectory = Directory(
      '${_imagesRootDirectory.path}/categorias',
    );
    _businessesImagesDirectory = Directory(
      '${_imagesRootDirectory.path}/negocios',
    );
    await _categoriesImagesDirectory.create(recursive: true);
    await _businessesImagesDirectory.create(recursive: true);

    _initialized = true;
    _loadLocalSnapshot();
    await _cleanupOrphanedImages();
  }

  Future<void> ensureSynchronized({bool forceRefresh = false}) async {
    await initialize();

    if (!forceRefresh && _hasCompletedLaunchSync) {
      return;
    }

    final ongoing = _ongoingSync;
    if (ongoing != null) {
      return ongoing;
    }

    final future = _synchronize(forceRefresh: forceRefresh);
    _ongoingSync = future;
    return future.whenComplete(() {
      if (identical(_ongoingSync, future)) {
        _ongoingSync = null;
      }
    });
  }

  Future<void> _synchronize({required bool forceRefresh}) async {
    final syncBox = Hive.box<dynamic>(_syncBoxName);
    var localCategoriesSyncMillis =
        (syncBox.get(_categoriesSyncMillisKey) as int?) ?? 0;
    var localBusinessesSyncMillis =
        (syncBox.get(_businessesSyncMillisKey) as int?) ?? 0;

    _loadLocalSnapshot();

    final hasLocalSnapshot = _categories.isNotEmpty || _businesses.isNotEmpty;
    final shouldDoFullServerSync = !hasLocalSnapshot;

    Timestamp? remoteCategoriesUpdatedAt;
    Timestamp? remoteBusinessesUpdatedAt;

    try {
      final syncDoc = await _firestore
          .collection(_syncCollection)
          .doc(_syncDocId)
          .get(const GetOptions(source: Source.server));

      final syncData = syncDoc.data() ?? const <String, dynamic>{};
      remoteCategoriesUpdatedAt = syncData['categoriasUpdatedAt'] as Timestamp?;
      remoteBusinessesUpdatedAt = syncData['negociosUpdatedAt'] as Timestamp?;
    } catch (_) {
      if (hasLocalSnapshot) {
        _hasCompletedLaunchSync = true;
        return;
      }

      await _fullServerSync(
        syncBox: syncBox,
        localCategoriesSyncMillis: localCategoriesSyncMillis,
        localBusinessesSyncMillis: localBusinessesSyncMillis,
      );
      _hasCompletedLaunchSync = true;
      return;
    }

    if (shouldDoFullServerSync ||
        remoteCategoriesUpdatedAt == null ||
        remoteBusinessesUpdatedAt == null) {
      await _fullServerSync(
        syncBox: syncBox,
        localCategoriesSyncMillis: localCategoriesSyncMillis,
        localBusinessesSyncMillis: localBusinessesSyncMillis,
      );
      _hasCompletedLaunchSync = true;
      return;
    }

    final remoteCategoriesMillis =
        remoteCategoriesUpdatedAt.millisecondsSinceEpoch;
    final remoteBusinessesMillis =
        remoteBusinessesUpdatedAt.millisecondsSinceEpoch;

    if (remoteCategoriesMillis > localCategoriesSyncMillis) {
      final changedCategories = await _firestore
          .collection('categorias')
          .where(
            'actualizado',
            isGreaterThan: Timestamp.fromMillisecondsSinceEpoch(
              localCategoriesSyncMillis,
            ),
          )
          .get(const GetOptions(source: Source.server));

      final changedItems = changedCategories.docs
          .map(CategoryItem.fromDocument)
          .toList(growable: false);

      final preparedItems = await _prepareCategoryImages(changedItems);
      await _removeCategoryImagesForInactive(preparedItems);
      _mergeCategories(preparedItems);
      await _persistCategories(preparedItems);

      localCategoriesSyncMillis = remoteCategoriesMillis;
      await syncBox.put(_categoriesSyncMillisKey, localCategoriesSyncMillis);
    }

    if (remoteBusinessesMillis > localBusinessesSyncMillis) {
      final changedBusinesses = await _firestore
          .collection('negocios')
          .where(
            'actualizado',
            isGreaterThan: Timestamp.fromMillisecondsSinceEpoch(
              localBusinessesSyncMillis,
            ),
          )
          .get(const GetOptions(source: Source.server));

      final changedItems = changedBusinesses.docs
          .map(BusinessItem.fromDocument)
          .toList(growable: false);

      final preparedItems = await _prepareBusinessImages(changedItems);
      await _removeBusinessImagesForInactive(preparedItems);
      _mergeBusinesses(preparedItems);
      await _persistBusinesses(preparedItems);

      localBusinessesSyncMillis = remoteBusinessesMillis;
      await syncBox.put(_businessesSyncMillisKey, localBusinessesSyncMillis);
    }

    await _repairMissingLocalImages();
    await _cleanupOrphanedImages();

    _hasCompletedLaunchSync = true;
  }

  void _loadLocalSnapshot() {
    final categoriesBox = Hive.box<Map<dynamic, dynamic>>(_categoriesBoxName);
    final businessesBox = Hive.box<Map<dynamic, dynamic>>(_businessesBoxName);

    _categories = categoriesBox.values
        .map((item) => CategoryItem.fromMap(Map<String, dynamic>.from(item)))
        .where((item) => item.activo)
        .toList(growable: false)
      ..sort((a, b) => a.displayTitle.compareTo(b.displayTitle));

    _businesses = businessesBox.values
        .map((item) => BusinessItem.fromMap(Map<String, dynamic>.from(item)))
        .where((item) => item.activo)
        .toList(growable: false)
      ..sort((a, b) => a.nombre.compareTo(b.nombre));
  }

  Future<void> _fullServerSync({
    required Box<dynamic> syncBox,
    required int localCategoriesSyncMillis,
    required int localBusinessesSyncMillis,
  }) async {
    final previousCategories = _categories;
    final previousBusinesses = _businesses;
    final categoriesSnapshot = await _firestore
        .collection('categorias')
        .where('activo', isEqualTo: true)
        .get(const GetOptions(source: Source.server));
    final businessesSnapshot = await _firestore
        .collection('negocios')
        .where('activo', isEqualTo: true)
        .get(const GetOptions(source: Source.server));

    _categories = await _prepareCategoryImages(
      categoriesSnapshot.docs
          .map(CategoryItem.fromDocument)
          .toList(growable: false),
    )
      ..sort((a, b) => a.displayTitle.compareTo(b.displayTitle));
    _businesses = await _prepareBusinessImages(
      businessesSnapshot.docs
          .map(BusinessItem.fromDocument)
          .toList(growable: false),
    )
      ..sort((a, b) => a.nombre.compareTo(b.nombre));

    await _replaceCategories(_categories);
    await _replaceBusinesses(_businesses);
    await _deleteRemovedCategoryImages(previousCategories, _categories);
    await _deleteRemovedBusinessImages(previousBusinesses, _businesses);

    final maxCategoryMillis = _categories.fold<int>(
      localCategoriesSyncMillis,
      (current, item) =>
          item.actualizadoMillis > current ? item.actualizadoMillis : current,
    );
    final maxBusinessMillis = _businesses.fold<int>(
      localBusinessesSyncMillis,
      (current, item) =>
          item.actualizadoMillis > current ? item.actualizadoMillis : current,
    );

    await syncBox.put(_categoriesSyncMillisKey, maxCategoryMillis);
    await syncBox.put(_businessesSyncMillisKey, maxBusinessMillis);
  }

  Future<void> _replaceCategories(List<CategoryItem> items) async {
    final box = Hive.box<Map<dynamic, dynamic>>(_categoriesBoxName);
    await box.clear();
    for (final item in items) {
      await box.put(item.id, item.toMap());
    }
  }

  Future<void> _replaceBusinesses(List<BusinessItem> items) async {
    final box = Hive.box<Map<dynamic, dynamic>>(_businessesBoxName);
    await box.clear();
    for (final item in items) {
      await box.put(item.id, item.toMap());
    }
  }

  Future<void> _persistCategories(List<CategoryItem> changedItems) async {
    if (changedItems.isEmpty) {
      return;
    }

    final box = Hive.box<Map<dynamic, dynamic>>(_categoriesBoxName);
    for (final item in changedItems) {
      if (item.activo) {
        await box.put(item.id, item.toMap());
      } else {
        await _deleteImageFile(item.localImagePath);
        await box.delete(item.id);
      }
    }
  }

  Future<void> _persistBusinesses(List<BusinessItem> changedItems) async {
    if (changedItems.isEmpty) {
      return;
    }

    final box = Hive.box<Map<dynamic, dynamic>>(_businessesBoxName);
    for (final item in changedItems) {
      if (item.activo) {
        await box.put(item.id, item.toMap());
      } else {
        await _deleteImageFile(item.localImagePath);
        await box.delete(item.id);
      }
    }
  }

  Future<List<CategoryItem>> _prepareCategoryImages(
    List<CategoryItem> items,
  ) async {
    final prepared = <CategoryItem>[];
    for (final item in items) {
      prepared.add(await _prepareCategoryImage(item));
    }
    return prepared;
  }

  Future<List<BusinessItem>> _prepareBusinessImages(
    List<BusinessItem> items,
  ) async {
    final prepared = <BusinessItem>[];
    for (final item in items) {
      prepared.add(await _prepareBusinessImage(item));
    }
    return prepared;
  }

  Future<CategoryItem> _prepareCategoryImage(CategoryItem item) async {
    if (!item.activo) {
      return item;
    }

    final imageSource = item.image.trim();
    if (imageSource.isEmpty || !imageSource.startsWith('http')) {
      await _deleteImageFile(_existingCategoryLocalPath(item.id));
      await _deleteImageFile(item.localImagePath);
      return item.copyWith(localImagePath: null);
    }

    final localPath = await _downloadImage(
      imageSource,
      _categoriesImagesDirectory,
      item.id,
    );

    return item.copyWith(localImagePath: localPath);
  }

  Future<BusinessItem> _prepareBusinessImage(BusinessItem item) async {
    if (!item.activo) {
      return item;
    }

    final imageSource = item.imageUrl.trim();
    if (imageSource.isEmpty || !imageSource.startsWith('http')) {
      await _deleteImageFile(_existingBusinessLocalPath(item.id));
      await _deleteImageFile(item.localImagePath);
      return item.copyWith(localImagePath: null);
    }

    final localPath = await _downloadImage(
      imageSource,
      _businessesImagesDirectory,
      item.id,
    );

    return item.copyWith(localImagePath: localPath);
  }

  Future<String?> _downloadImage(
    String url,
    Directory directory,
    String id,
  ) async {
    HttpClient? client;
    try {
      final file = File('${directory.path}/$id.img');
      client = HttpClient()..connectionTimeout = const Duration(seconds: 12);
      final request = await client.getUrl(Uri.parse(url));
      final response = await request.close().timeout(
        const Duration(seconds: 15),
      );

      if (response.statusCode < 200 || response.statusCode >= 300) {
        return file.existsSync() ? file.path : null;
      }

      final bytes = await consolidateHttpClientResponseBytes(
        response,
      ).timeout(const Duration(seconds: 20));
      await file.writeAsBytes(bytes, flush: true);
      return file.path;
    } catch (_) {
      final file = File('${directory.path}/$id.img');
      return file.existsSync() ? file.path : null;
    } finally {
      client?.close(force: true);
    }
  }

  Future<void> _removeCategoryImagesForInactive(
    List<CategoryItem> changedItems,
  ) async {
    final current = {
      for (final item in _categories) item.id: item,
    };

    for (final item in changedItems.where((item) => !item.activo)) {
      final previous = current[item.id];
      await _deleteImageFile(previous?.localImagePath ?? item.localImagePath);
    }
  }

  Future<void> _removeBusinessImagesForInactive(
    List<BusinessItem> changedItems,
  ) async {
    final current = {
      for (final item in _businesses) item.id: item,
    };

    for (final item in changedItems.where((item) => !item.activo)) {
      final previous = current[item.id];
      await _deleteImageFile(previous?.localImagePath ?? item.localImagePath);
    }
  }

  Future<void> _deleteRemovedCategoryImages(
    List<CategoryItem> previousItems,
    List<CategoryItem> currentItems,
  ) async {
    final currentIds = currentItems.map((item) => item.id).toSet();
    for (final item in previousItems) {
      if (!currentIds.contains(item.id)) {
        await _deleteImageFile(item.localImagePath);
      }
    }
  }

  Future<void> _deleteRemovedBusinessImages(
    List<BusinessItem> previousItems,
    List<BusinessItem> currentItems,
  ) async {
    final currentIds = currentItems.map((item) => item.id).toSet();
    for (final item in previousItems) {
      if (!currentIds.contains(item.id)) {
        await _deleteImageFile(item.localImagePath);
      }
    }
  }

  Future<void> _deleteImageFile(String? path) async {
    if (path == null || path.trim().isEmpty) {
      return;
    }

    final file = File(path);
    if (await file.exists()) {
      await file.delete();
    }
  }

  Future<void> _cleanupOrphanedImages() async {
    final categoryPaths = _categories
        .map((item) => item.localImagePath)
        .whereType<String>()
        .where((item) => item.trim().isNotEmpty)
        .toSet();
    final businessPaths = _businesses
        .map((item) => item.localImagePath)
        .whereType<String>()
        .where((item) => item.trim().isNotEmpty)
        .toSet();

    await _cleanupDirectory(_categoriesImagesDirectory, categoryPaths);
    await _cleanupDirectory(_businessesImagesDirectory, businessPaths);
  }

  Future<void> _cleanupDirectory(
    Directory directory,
    Set<String> allowedPaths,
  ) async {
    if (!await directory.exists()) {
      return;
    }

    await for (final entity in directory.list()) {
      if (entity is File && !allowedPaths.contains(entity.path)) {
        await entity.delete();
      }
    }
  }

  String? _existingCategoryLocalPath(String id) {
    for (final item in _categories) {
      if (item.id == id) {
        return item.localImagePath;
      }
    }
    return null;
  }

  String? _existingBusinessLocalPath(String id) {
    for (final item in _businesses) {
      if (item.id == id) {
        return item.localImagePath;
      }
    }
    return null;
  }

  Future<void> _repairMissingLocalImages() async {
    final repairedCategories = <CategoryItem>[];
    var categoriesChanged = false;

    for (final item in _categories) {
      final repaired = await _repairCategoryImage(item);
      repairedCategories.add(repaired);
      if (repaired.localImagePath != item.localImagePath) {
        categoriesChanged = true;
      }
    }

    if (categoriesChanged) {
      _categories = repairedCategories
        ..sort((a, b) => a.displayTitle.compareTo(b.displayTitle));
      await _replaceCategories(_categories);
    }

    final repairedBusinesses = <BusinessItem>[];
    var businessesChanged = false;

    for (final item in _businesses) {
      final repaired = await _repairBusinessImage(item);
      repairedBusinesses.add(repaired);
      if (repaired.localImagePath != item.localImagePath) {
        businessesChanged = true;
      }
    }

    if (businessesChanged) {
      _businesses = repairedBusinesses
        ..sort((a, b) => a.nombre.compareTo(b.nombre));
      await _replaceBusinesses(_businesses);
    }
  }

  Future<CategoryItem> _repairCategoryImage(CategoryItem item) async {
    if (item.image.trim().isEmpty || !item.image.startsWith('http')) {
      return item;
    }

    if (item.localImagePath != null && File(item.localImagePath!).existsSync()) {
      return item;
    }

    return _prepareCategoryImage(item);
  }

  Future<BusinessItem> _repairBusinessImage(BusinessItem item) async {
    if (item.imageUrl.trim().isEmpty || !item.imageUrl.startsWith('http')) {
      return item;
    }

    if (item.localImagePath != null && File(item.localImagePath!).existsSync()) {
      return item;
    }

    return _prepareBusinessImage(item);
  }

  void _mergeCategories(List<CategoryItem> changedItems) {
    if (changedItems.isEmpty) {
      return;
    }

    final merged = <String, CategoryItem>{
      for (final item in _categories) item.id: item,
    };

    for (final item in changedItems) {
      if (item.activo) {
        merged[item.id] = item;
      } else {
        merged.remove(item.id);
      }
    }

    _categories = merged.values.toList(growable: false)
      ..sort((a, b) => a.displayTitle.compareTo(b.displayTitle));
  }

  void _mergeBusinesses(List<BusinessItem> changedItems) {
    if (changedItems.isEmpty) {
      return;
    }

    final merged = <String, BusinessItem>{
      for (final item in _businesses) item.id: item,
    };

    for (final item in changedItems) {
      if (item.activo) {
        merged[item.id] = item;
      } else {
        merged.remove(item.id);
      }
    }

    _businesses = merged.values.toList(growable: false)
      ..sort((a, b) => a.nombre.compareTo(b.nombre));
  }

  List<BusinessItem> businessesForCategory(
    DocumentReference<Map<String, dynamic>> categoriaRef,
  ) {
    return _businesses
        .where((item) => item.categoryPath == categoriaRef.path)
        .toList(growable: false);
  }

  BusinessItem? businessById(String negocioId) {
    for (final item in _businesses) {
      if (item.id == negocioId) {
        return item;
      }
    }
    return null;
  }
}

class CategoryItem {
  const CategoryItem({
    required this.id,
    required this.titulo,
    required this.referencePath,
    required this.image,
    required this.localImagePath,
    required this.color,
    required this.description,
    required this.activo,
    required this.actualizadoMillis,
  });

  final String id;
  final String titulo;
  final String referencePath;
  final String image;
  final String? localImagePath;
  final Color color;
  final String description;
  final bool activo;
  final int actualizadoMillis;

  String get displayTitle => _capitalizeWords(titulo);

  DocumentReference<Map<String, dynamic>> get reference =>
      referencePath.trim().isNotEmpty
      ? FirebaseFirestore.instance.doc(referencePath)
      : FirebaseFirestore.instance.collection('categorias').doc(id);

  String get preferredImagePath =>
      (localImagePath?.trim().isNotEmpty ?? false) ? localImagePath! : image;

  factory CategoryItem.fromDocument(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data();
    final updatedAt = data['actualizado'] as Timestamp?;

    return CategoryItem(
      id: doc.id,
      titulo: (data['titulo'] ?? doc.id) as String,
      referencePath: doc.reference.path,
      image: ((data['image'] ?? data['imagen']) ?? '') as String,
      localImagePath: null,
      color: _parseColor(data['color']),
      description:
          (data['descripcion'] ?? 'Explora negocios en esta categoria.') as String,
      activo: (data['activo'] ?? true) as bool,
      actualizadoMillis: updatedAt?.millisecondsSinceEpoch ?? 0,
    );
  }

  factory CategoryItem.fromMap(Map<String, dynamic> data) {
    return CategoryItem(
      id: (data['id'] ?? '') as String,
      titulo: (data['titulo'] ?? '') as String,
      referencePath: (data['referencePath'] ?? '') as String,
      image: (data['image'] ?? '') as String,
      localImagePath: data['localImagePath'] as String?,
      color: _parseColor(data['color']),
      description: (data['description'] ?? '') as String,
      activo: (data['activo'] ?? true) as bool,
      actualizadoMillis: (data['actualizadoMillis'] ?? 0) as int,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'titulo': titulo,
      'referencePath': referencePath,
      'image': image,
      'localImagePath': localImagePath,
      'color': color.value,
      'description': description,
      'activo': activo,
      'actualizadoMillis': actualizadoMillis,
    };
  }

  CategoryItem copyWith({
    String? localImagePath,
  }) {
    return CategoryItem(
      id: id,
      titulo: titulo,
      referencePath: referencePath,
      image: image,
      localImagePath: localImagePath,
      color: color,
      description: description,
      activo: activo,
      actualizadoMillis: actualizadoMillis,
    );
  }
}

class BusinessItem {
  const BusinessItem({
    required this.id,
    required this.nombre,
    required this.descripcion,
    required this.direccion,
    required this.whatsapp,
    required this.facebook,
    required this.instagram,
    required this.imageUrl,
    required this.localImagePath,
    required this.productosServicios,
    required this.coordenadas,
    required this.categoryPath,
    required this.activo,
    required this.actualizadoMillis,
  });

  final String id;
  final String nombre;
  final String descripcion;
  final String direccion;
  final String whatsapp;
  final String facebook;
  final String instagram;
  final String imageUrl;
  final String? localImagePath;
  final List<String> productosServicios;
  final GeoPoint? coordenadas;
  final String? categoryPath;
  final bool activo;
  final int actualizadoMillis;

  String get preferredImagePath =>
      (localImagePath?.trim().isNotEmpty ?? false) ? localImagePath! : imageUrl;

  factory BusinessItem.fromDocument(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data();
    final updatedAt = data['actualizado'] as Timestamp?;
    final categoryRef =
        data['categoria'] as DocumentReference<Map<String, dynamic>>?;

    return BusinessItem(
      id: doc.id,
      nombre: (data['nombre'] ?? '') as String,
      descripcion: (data['descripcion'] ?? '') as String,
      direccion: (data['direccion'] ?? '') as String,
      whatsapp: (data['whatsapp'] ?? '') as String,
      facebook: (data['facebook'] ?? '') as String,
      instagram: (data['instagram'] ?? '') as String,
      imageUrl: ((data['image'] ?? data['imagen']) ?? '') as String,
      localImagePath: null,
      productosServicios: ((data['productos_servicios'] as List<dynamic>?) ?? [])
          .map((item) => item.toString().trim())
          .where((item) => item.isNotEmpty)
          .toList(growable: false),
      coordenadas: data['coordenadas'] as GeoPoint?,
      categoryPath: categoryRef?.path,
      activo: (data['activo'] ?? true) as bool,
      actualizadoMillis: updatedAt?.millisecondsSinceEpoch ?? 0,
    );
  }

  factory BusinessItem.fromMap(Map<String, dynamic> data) {
    final dynamic rawCoordinates = data['coordenadas'];
    final Map<String, dynamic>? coordinatesMap = rawCoordinates is Map
        ? Map<String, dynamic>.from(rawCoordinates)
        : null;

    return BusinessItem(
      id: (data['id'] ?? '') as String,
      nombre: (data['nombre'] ?? '') as String,
      descripcion: (data['descripcion'] ?? '') as String,
      direccion: (data['direccion'] ?? '') as String,
      whatsapp: (data['whatsapp'] ?? '') as String,
      facebook: (data['facebook'] ?? '') as String,
      instagram: (data['instagram'] ?? '') as String,
      imageUrl: (data['imageUrl'] ?? '') as String,
      localImagePath: data['localImagePath'] as String?,
      productosServicios: ((data['productosServicios'] as List<dynamic>?) ?? [])
          .map((item) => item.toString().trim())
          .where((item) => item.isNotEmpty)
          .toList(growable: false),
      coordenadas: coordinatesMap == null
          ? null
          : GeoPoint(
              (coordinatesMap['latitude'] as num).toDouble(),
              (coordinatesMap['longitude'] as num).toDouble(),
            ),
      categoryPath: data['categoryPath'] as String?,
      activo: (data['activo'] ?? true) as bool,
      actualizadoMillis: (data['actualizadoMillis'] ?? 0) as int,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nombre': nombre,
      'descripcion': descripcion,
      'direccion': direccion,
      'whatsapp': whatsapp,
      'facebook': facebook,
      'instagram': instagram,
      'imageUrl': imageUrl,
      'localImagePath': localImagePath,
      'productosServicios': productosServicios,
      'coordenadas': coordenadas == null
          ? null
          : {
              'latitude': coordenadas!.latitude,
              'longitude': coordenadas!.longitude,
            },
      'categoryPath': categoryPath,
      'activo': activo,
      'actualizadoMillis': actualizadoMillis,
    };
  }

  BusinessItem copyWith({
    String? localImagePath,
  }) {
    return BusinessItem(
      id: id,
      nombre: nombre,
      descripcion: descripcion,
      direccion: direccion,
      whatsapp: whatsapp,
      facebook: facebook,
      instagram: instagram,
      imageUrl: imageUrl,
      localImagePath: localImagePath,
      productosServicios: productosServicios,
      coordenadas: coordenadas,
      categoryPath: categoryPath,
      activo: activo,
      actualizadoMillis: actualizadoMillis,
    );
  }

  bool matches(String query) {
    if (query.isEmpty) {
      return true;
    }

    final haystack = [
      nombre,
      descripcion,
      ...productosServicios,
    ].join(' ');

    return _normalizeSearchText(haystack).contains(_normalizeSearchText(query));
  }
}

Color _parseColor(dynamic value) {
  if (value is int) {
    return Color(value);
  }

  if (value is String) {
    final sanitized = value.replaceAll('#', '').trim();
    if (sanitized.isEmpty) {
      return const Color(0xFF2D6A4F);
    }

    final normalized = sanitized.length == 6 ? 'FF$sanitized' : sanitized;
    final parsed = int.tryParse(normalized, radix: 16);
    if (parsed != null) {
      return Color(parsed);
    }
  }

  return const Color(0xFF2D6A4F);
}

String _capitalizeWords(String value) {
  final normalized = value.trim();
  if (normalized.isEmpty) {
    return value;
  }

  return normalized.split(RegExp(r'\s+')).map((word) {
    if (word.isEmpty) {
      return word;
    }
    return '${word[0].toUpperCase()}${word.substring(1)}';
  }).join(' ');
}

String _normalizeSearchText(String value) {
  return value
      .toLowerCase()
      .replaceAll('á', 'a')
      .replaceAll('à', 'a')
      .replaceAll('ä', 'a')
      .replaceAll('â', 'a')
      .replaceAll('é', 'e')
      .replaceAll('è', 'e')
      .replaceAll('ë', 'e')
      .replaceAll('ê', 'e')
      .replaceAll('í', 'i')
      .replaceAll('ì', 'i')
      .replaceAll('ï', 'i')
      .replaceAll('î', 'i')
      .replaceAll('ó', 'o')
      .replaceAll('ò', 'o')
      .replaceAll('ö', 'o')
      .replaceAll('ô', 'o')
      .replaceAll('ú', 'u')
      .replaceAll('ù', 'u')
      .replaceAll('ü', 'u')
      .replaceAll('û', 'u')
      .replaceAll('ñ', 'n');
}
