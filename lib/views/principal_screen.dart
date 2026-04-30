import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:mi_tianguis/services/firestore_service.dart';
import 'package:mi_tianguis/widgets/main/product_grid.dart';
import 'package:mi_tianguis/widgets/shared/app_image_view.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

class PrincipalScreen extends StatefulWidget {
  const PrincipalScreen({super.key});

  @override
  State<PrincipalScreen> createState() => _PrincipalScreenState();
}

class _PrincipalScreenState extends State<PrincipalScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  final FirestoreService _firestoreService = FirestoreService.instance;
  Future<void> _syncFuture = Future.value();
  String _query = '';
  bool _hasCheckedAppVersion = false;

  void _showSyncInfo() {
    final categoriesSync = _firestoreService.categoriesLastSync;
    final businessesSync = _firestoreService.businessesLastSync;

    showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Última sincronización'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Categorías: ${_formatSyncDate(categoriesSync)}',
              ),
              const SizedBox(height: 10),
              Text(
                'Negocios: ${_formatSyncDate(businessesSync)}',
              ),
              const SizedBox(height: 14),
              const Text(
                'Usa esta referencia para saber qué hora ya detectó la app.',
                style: TextStyle(
                  fontSize: 13,
                  color: Color(0xFF6C6F76),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cerrar'),
            ),
          ],
        );
      },
    );
  }

  @override
  void initState() {
    super.initState();
    _syncFuture = _firestoreService.ensureSynchronized();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAppVersionIfNeeded();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isSearching = _query.trim().isNotEmpty;
    final double screenWidth = MediaQuery.sizeOf(context).width;
    final bool isTablet = screenWidth >= 720;
    final double horizontalPadding = isTablet ? 24 : 12;
    final double maxContentWidth = screenWidth >= 1200 ? 1120 : 960;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F0E8),
      appBar: AppBar(
        toolbarHeight: 76,
        elevation: 0,
        backgroundColor: const Color(0xFFF4F0E8),
        surfaceTintColor: Colors.transparent,
        centerTitle: false,
        titleSpacing: 18,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: IconButton(
              tooltip: 'Información',
              onPressed: _showSyncInfo,
              icon: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: const [
                    BoxShadow(
                      color: Color.fromRGBO(53, 54, 66, 0.08),
                      blurRadius: 14,
                      offset: Offset(0, 6),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.info_outline_rounded,
                  color: Color(0xFF1B4332),
                ),
              ),
            ),
          ),
        ],
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Mi Tianguis',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: Color(0xFF1F1F1F),
              ),
            ),
            SizedBox(height: 2),
            Text(
              'Negocios y servicios cerca de ti',
              style: TextStyle(
                fontSize: 13,
                color: Color(0xFF6C6F76),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
      body: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () => FocusScope.of(context).unfocus(),
        child: DecoratedBox(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFFF4F0E8),
                Color(0xFFF8F5EF),
              ],
            ),
          ),
          child: Column(
            children: [
              Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: maxContentWidth),
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(
                      horizontalPadding,
                      4,
                      horizontalPadding,
                      10,
                    ),
                    child: _SearchShell(
                      child: _SearchBar(
                        controller: _searchController,
                        focusNode: _searchFocusNode,
                        onChanged: (value) {
                          setState(() {
                            _query = value;
                          });
                        },
                        onClear: () {
                          _searchController.clear();
                          setState(() {
                            _query = '';
                          });
                          FocusScope.of(context).unfocus();
                        },
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: maxContentWidth),
                    child: FutureBuilder<void>(
                      future: _syncFuture,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState != ConnectionState.waiting) {
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            _checkAppVersionIfNeeded();
                          });
                        }

                        return Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: isTablet ? horizontalPadding : 10,
                          ),
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 220),
                            child: isSearching
                                ? _SearchResultsList(
                                    key: const ValueKey('search-results'),
                                    query: _query,
                                    items: _firestoreService.businesses
                                        .map(_BusinessSearchItem.fromBusiness)
                                        .toList(growable: false),
                                    isLoading:
                                        snapshot.connectionState ==
                                        ConnectionState.waiting,
                                    hasError: snapshot.hasError,
                                  )
                                : const ProductGrid(
                                    key: ValueKey('product-grid'),
                                  ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _checkAppVersionIfNeeded() async {
    if (!mounted || _hasCheckedAppVersion) {
      return;
    }

    _hasCheckedAppVersion = true;

    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final installedVersion = packageInfo.version.trim();
      final snapshot = await FirebaseFirestore.instance
          .collection('app_meta')
          .doc('app_version')
          .get(const GetOptions(source: Source.server));

      final data = snapshot.data();
      if (data == null) {
        return;
      }

      final latestVersion = (data['latestVersion'] ?? '').toString().trim();
      final minRequiredVersion =
          (data['minRequiredVersion'] ?? '').toString().trim();
      final updateMessage = (data['updateMessage'] ?? '').toString().trim();
      final playStoreUrl = (data['playStoreUrl'] ?? '').toString().trim();

      if (latestVersion.isEmpty || playStoreUrl.isEmpty) {
        return;
      }

      final isBelowMinimum =
          minRequiredVersion.isNotEmpty &&
          _compareVersions(installedVersion, minRequiredVersion) < 0;
      final hasUpdateAvailable =
          _compareVersions(installedVersion, latestVersion) < 0;

      if (!hasUpdateAvailable && !isBelowMinimum) {
        return;
      }

      if (!mounted) {
        return;
      }

      await showDialog<void>(
        context: context,
        barrierDismissible: !isBelowMinimum,
        builder: (context) {
          return PopScope(
            canPop: !isBelowMinimum,
            child: AlertDialog(
              title: Text(
                isBelowMinimum
                    ? 'Actualización requerida'
                    : 'Actualización disponible',
              ),
              content: Text(
                updateMessage.isEmpty
                    ? (isBelowMinimum
                          ? 'Necesitas actualizar la app para seguir usándola.'
                          : 'Hay una nueva versión disponible.')
                    : updateMessage,
              ),
              actions: [
                if (!isBelowMinimum)
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Después'),
                  ),
                FilledButton(
                  onPressed: () async {
                    final uri = Uri.parse(playStoreUrl);
                    if (await canLaunchUrl(uri)) {
                      await launchUrl(
                        uri,
                        mode: LaunchMode.externalApplication,
                      );
                    }
                    if (!isBelowMinimum && context.mounted) {
                      Navigator.of(context).pop();
                    }
                  },
                  child: const Text('Actualizar'),
                ),
              ],
            ),
          );
        },
      );
    } catch (_) {
      _hasCheckedAppVersion = false;
    }
  }
}

String _formatSyncDate(DateTime? value) {
  if (value == null) {
    return 'Sin sincronización';
  }

  String twoDigits(int number) => number.toString().padLeft(2, '0');

  return '${twoDigits(value.day)}/${twoDigits(value.month)}/${value.year} ${twoDigits(value.hour)}:${twoDigits(value.minute)}';
}

int _compareVersions(String a, String b) {
  final aParts = a.split('.').map((item) => int.tryParse(item) ?? 0).toList();
  final bParts = b.split('.').map((item) => int.tryParse(item) ?? 0).toList();
  final maxLength = aParts.length > bParts.length ? aParts.length : bParts.length;

  for (var index = 0; index < maxLength; index++) {
    final aValue = index < aParts.length ? aParts[index] : 0;
    final bValue = index < bParts.length ? bParts[index] : 0;

    if (aValue != bValue) {
      return aValue.compareTo(bValue);
    }
  }

  return 0;
}

class _SearchShell extends StatelessWidget {
  const _SearchShell({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: const Color.fromRGBO(255, 255, 255, 0.72),
        borderRadius: BorderRadius.circular(28),
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(53, 54, 66, 0.08),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _SearchBar extends StatelessWidget {
  const _SearchBar({
    required this.controller,
    required this.focusNode,
    required this.onChanged,
    required this.onClear,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
      ),
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        onChanged: onChanged,
        textInputAction: TextInputAction.search,
        style: const TextStyle(
          color: Color(0xFF1F1F1F),
          fontSize: 15,
          fontWeight: FontWeight.w600,
        ),
        decoration: InputDecoration(
          border: InputBorder.none,
          hintText: 'Buscar negocios, descripción o productos/servicios',
          hintStyle: const TextStyle(
            color: Color(0xFF7C8793),
            fontSize: 14,
          ),
          prefixIcon: Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFE9F1EC),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.search_rounded,
              color: Color(0xFF1B4332),
            ),
          ),
          suffixIcon: controller.text.isEmpty
              ? null
              : IconButton(
                  onPressed: onClear,
                  icon: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF3EEE6),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.close_rounded,
                      size: 18,
                      color: Color(0xFF7C8793),
                    ),
                  ),
                ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 18,
            vertical: 18,
          ),
        ),
      ),
    );
  }
}

class _SearchResultsList extends StatelessWidget {
  const _SearchResultsList({
    required this.query,
    required this.items,
    required this.isLoading,
    required this.hasError,
    super.key,
  });

  final String query;
  final List<_BusinessSearchItem> items;
  final bool isLoading;
  final bool hasError;

  @override
  Widget build(BuildContext context) {
    final normalizedQuery = _normalizeSearchText(query.trim());

    if (isLoading && items.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (hasError) {
      return const _SearchStateView(
        icon: Icons.wifi_off_rounded,
        title: 'No se pudieron cargar los resultados',
        message: 'Intenta nuevamente en unos momentos.',
      );
    }

    final results = items
        .where((item) => item.matches(normalizedQuery))
        .toList(growable: false);

    if (results.isEmpty) {
      return _SearchStateView(
        icon: Icons.search_off_rounded,
        title: 'Sin coincidencias',
        message: 'No encontramos negocios para "$query".',
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 4, 4, 10),
          child: Text(
            '${results.length} resultado${results.length == 1 ? '' : 's'}',
            style: const TextStyle(
              color: Color(0xFF6C6F76),
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.only(bottom: 18),
            keyboardDismissBehavior:
                ScrollViewKeyboardDismissBehavior.manual,
            itemCount: results.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final item = results[index];
              return _SearchBusinessCard(item: item);
            },
          ),
        ),
      ],
    );
  }
}

class _SearchBusinessCard extends StatelessWidget {
  const _SearchBusinessCard({required this.item});

  final _BusinessSearchItem item;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          FocusManager.instance.primaryFocus?.unfocus();
          Navigator.pushNamed(
            context,
            'detallesNegocio',
            arguments: {'negocioId': item.id},
          );
        },
        borderRadius: BorderRadius.circular(24),
        child: Ink(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: const [
              BoxShadow(
                color: Color.fromRGBO(53, 54, 66, 0.08),
                blurRadius: 18,
                offset: Offset(0, 10),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: SizedBox(
                    width: 94,
                    height: 94,
                    child: AppImageView(
                      imagePath: item.imageUrl,
                      fit: BoxFit.cover,
                      fallback: const _ImageFallback(iconSize: 34),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.nombre,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF1F1F1F),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        item.descripcion.isEmpty
                            ? 'Abre la ficha para ver más detalles.'
                            : item.descripcion,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13.5,
                          color: Color(0xFF5D6470),
                          height: 1.4,
                        ),
                      ),
                      if (item.productosServicios.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: item.productosServicios
                              .take(3)
                              .map(
                                (servicio) => Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 7,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF8F4EC),
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                  child: Text(
                                    servicio,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF7A3E2B),
                                    ),
                                  ),
                                ),
                              )
                              .toList(),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SearchStateView extends StatelessWidget {
  const _SearchStateView({
    required this.icon,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(26),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(26),
            boxShadow: const [
              BoxShadow(
                color: Color.fromRGBO(53, 54, 66, 0.08),
                blurRadius: 20,
                offset: Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 48,
                color: const Color(0xFF7A7A7A),
              ),
              const SizedBox(height: 14),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1E1E1E),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF666666),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ImageFallback extends StatelessWidget {
  const _ImageFallback({required this.iconSize});

  final double iconSize;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF6E7F5B),
      child: Center(
        child: Icon(
          Icons.storefront_rounded,
          size: iconSize,
          color: Colors.white70,
        ),
      ),
    );
  }
}

class _BusinessSearchItem {
  const _BusinessSearchItem({
    required this.id,
    required this.nombre,
    required this.descripcion,
    required this.productosServicios,
    required this.imageUrl,
  });

  final String id;
  final String nombre;
  final String descripcion;
  final List<String> productosServicios;
  final String imageUrl;

  factory _BusinessSearchItem.fromBusiness(BusinessItem item) {
    return _BusinessSearchItem(
      id: item.id,
      nombre: item.nombre,
      descripcion: item.descripcion,
      productosServicios: item.productosServicios,
      imageUrl: item.preferredImagePath,
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
