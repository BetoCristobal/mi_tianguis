import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FirestoreService {
  FirestoreService._();

  static final FirestoreService instance = FirestoreService._();

  static const String _syncCollection = 'app_meta';
  static const String _syncDocId = 'sync';
  static const String _categoriasSyncMillisKey = 'categorias_sync_millis';
  static const String _negociosSyncMillisKey = 'negocios_sync_millis';

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<CategoryItem> _categories = const [];
  List<BusinessItem> _businesses = const [];
  Future<void>? _ongoingSync;

  List<CategoryItem> get categories => List.unmodifiable(_categories);
  List<BusinessItem> get businesses => List.unmodifiable(_businesses);

  Future<void> ensureSynchronized({bool forceRefresh = false}) {
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
    final prefs = await SharedPreferences.getInstance();
    var localCategoriasSyncMillis = prefs.getInt(_categoriasSyncMillisKey) ?? 0;
    var localNegociosSyncMillis = prefs.getInt(_negociosSyncMillisKey) ?? 0;

    await _loadCacheIntoMemory();

    final hasLocalSnapshot = _categories.isNotEmpty || _businesses.isNotEmpty;
    var shouldDoFullServerSync = forceRefresh || !hasLocalSnapshot;

    Timestamp? remoteCategoriasUpdatedAt;
    Timestamp? remoteNegociosUpdatedAt;

    try {
      final syncDoc = await _firestore
          .collection(_syncCollection)
          .doc(_syncDocId)
          .get(const GetOptions(source: Source.server));

      final syncData = syncDoc.data() ?? const <String, dynamic>{};
      remoteCategoriasUpdatedAt = syncData['categoriasUpdatedAt'] as Timestamp?;
      remoteNegociosUpdatedAt = syncData['negociosUpdatedAt'] as Timestamp?;

      if (remoteCategoriasUpdatedAt == null || remoteNegociosUpdatedAt == null) {
        shouldDoFullServerSync = true;
      }
    } catch (_) {
      if (hasLocalSnapshot) {
        return;
      }

      await _fullServerSync(
        prefs: prefs,
        localCategoriasSyncMillis: localCategoriasSyncMillis,
        localNegociosSyncMillis: localNegociosSyncMillis,
      );
      return;
    }

    if (shouldDoFullServerSync) {
      await _fullServerSync(
        prefs: prefs,
        localCategoriasSyncMillis: localCategoriasSyncMillis,
        localNegociosSyncMillis: localNegociosSyncMillis,
      );
      return;
    }

    final remoteCategoriasMillis = remoteCategoriasUpdatedAt!.millisecondsSinceEpoch;
    final remoteNegociosMillis = remoteNegociosUpdatedAt!.millisecondsSinceEpoch;

    if (remoteCategoriasMillis > localCategoriasSyncMillis) {
      final changedCategories = await _firestore
          .collection('categorias')
          .where(
            'actualizado',
            isGreaterThan: Timestamp.fromMillisecondsSinceEpoch(
              localCategoriasSyncMillis,
            ),
          )
          .get(const GetOptions(source: Source.server));

      _mergeCategories(
        changedCategories.docs.map(CategoryItem.fromDocument).toList(growable: false),
      );

      localCategoriasSyncMillis = remoteCategoriasMillis;
      await prefs.setInt(_categoriasSyncMillisKey, localCategoriasSyncMillis);
    }

    if (remoteNegociosMillis > localNegociosSyncMillis) {
      final changedBusinesses = await _firestore
          .collection('negocios')
          .where(
            'actualizado',
            isGreaterThan: Timestamp.fromMillisecondsSinceEpoch(
              localNegociosSyncMillis,
            ),
          )
          .get(const GetOptions(source: Source.server));

      _mergeBusinesses(
        changedBusinesses.docs.map(BusinessItem.fromDocument).toList(growable: false),
      );

      localNegociosSyncMillis = remoteNegociosMillis;
      await prefs.setInt(_negociosSyncMillisKey, localNegociosSyncMillis);
    }

  }

  Future<void> _loadCacheIntoMemory() async {
    try {
      final categoriesSnapshot = await _firestore
          .collection('categorias')
          .where('activo', isEqualTo: true)
          .get(const GetOptions(source: Source.cache));
      _categories = categoriesSnapshot.docs
          .map(CategoryItem.fromDocument)
          .toList(growable: false);

      final businessesSnapshot = await _firestore
          .collection('negocios')
          .where('activo', isEqualTo: true)
          .get(const GetOptions(source: Source.cache));
      _businesses = businessesSnapshot.docs
          .map(BusinessItem.fromDocument)
          .toList(growable: false);
    } catch (_) {
      _categories = const [];
      _businesses = const [];
    }
  }

  Future<void> _fullServerSync({
    required SharedPreferences prefs,
    required int localCategoriasSyncMillis,
    required int localNegociosSyncMillis,
  }) async {
    final categoriesSnapshot = await _firestore
        .collection('categorias')
        .where('activo', isEqualTo: true)
        .get(const GetOptions(source: Source.server));
    final businessesSnapshot = await _firestore
        .collection('negocios')
        .where('activo', isEqualTo: true)
        .get(const GetOptions(source: Source.server));

    _categories = categoriesSnapshot.docs
        .map(CategoryItem.fromDocument)
        .toList(growable: false);
    _businesses = businessesSnapshot.docs
        .map(BusinessItem.fromDocument)
        .toList(growable: false);

    final maxCategoriaMillis = _categories.fold<int>(
      localCategoriasSyncMillis,
      (current, item) => item.actualizadoMillis > current
          ? item.actualizadoMillis
          : current,
    );
    final maxNegocioMillis = _businesses.fold<int>(
      localNegociosSyncMillis,
      (current, item) => item.actualizadoMillis > current
          ? item.actualizadoMillis
          : current,
    );

    await prefs.setInt(_categoriasSyncMillisKey, maxCategoriaMillis);
    await prefs.setInt(_negociosSyncMillisKey, maxNegocioMillis);
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

    _categories = merged.values.toList(growable: false);
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

    _businesses = merged.values.toList(growable: false);
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
    required this.reference,
    required this.image,
    required this.color,
    required this.description,
    required this.activo,
    required this.actualizado,
  });

  final String id;
  final String titulo;
  final DocumentReference<Map<String, dynamic>> reference;
  final String image;
  final Color color;
  final String description;
  final bool activo;
  final Timestamp? actualizado;

  String get displayTitle => _capitalizeWords(titulo);
  int get actualizadoMillis => actualizado?.millisecondsSinceEpoch ?? 0;

  factory CategoryItem.fromDocument(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data();
    return CategoryItem(
      id: doc.id,
      titulo: (data['titulo'] ?? doc.id) as String,
      reference: doc.reference,
      image: ((data['image'] ?? data['imagen']) ?? '') as String,
      color: _parseColor(data['color']),
      description:
          (data['descripcion'] ?? 'Explora negocios en esta categoria.') as String,
      activo: (data['activo'] ?? true) as bool,
      actualizado: data['actualizado'] as Timestamp?,
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
    required this.productosServicios,
    required this.coordenadas,
    required this.categoryRef,
    required this.activo,
    required this.actualizado,
  });

  final String id;
  final String nombre;
  final String descripcion;
  final String direccion;
  final String whatsapp;
  final String facebook;
  final String instagram;
  final String imageUrl;
  final List<String> productosServicios;
  final GeoPoint? coordenadas;
  final DocumentReference<Map<String, dynamic>>? categoryRef;
  final bool activo;
  final Timestamp? actualizado;

  String? get categoryPath => categoryRef?.path;
  int get actualizadoMillis => actualizado?.millisecondsSinceEpoch ?? 0;

  factory BusinessItem.fromDocument(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data();
    return BusinessItem(
      id: doc.id,
      nombre: (data['nombre'] ?? '') as String,
      descripcion: (data['descripcion'] ?? '') as String,
      direccion: (data['direccion'] ?? '') as String,
      whatsapp: (data['whatsapp'] ?? '') as String,
      facebook: (data['facebook'] ?? '') as String,
      instagram: (data['instagram'] ?? '') as String,
      imageUrl: ((data['image'] ?? data['imagen']) ?? '') as String,
      productosServicios: ((data['productos_servicios'] as List<dynamic>?) ?? [])
          .map((item) => item.toString().trim())
          .where((item) => item.isNotEmpty)
          .toList(growable: false),
      coordenadas: data['coordenadas'] as GeoPoint?,
      categoryRef:
          data['categoria'] as DocumentReference<Map<String, dynamic>>?,
      activo: (data['activo'] ?? true) as bool,
      actualizado: data['actualizado'] as Timestamp?,
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
    ].join(' ').toLowerCase();

    return haystack.contains(query);
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
