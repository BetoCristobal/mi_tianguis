import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:mi_tianguis/services/firestore_service.dart';
import 'package:mi_tianguis/widgets/shared/app_image_view.dart';

class ProductGrid extends StatelessWidget {
  const ProductGrid({super.key});

  @override
  Widget build(BuildContext context) {
    final service = FirestoreService.instance;

    return FutureBuilder<void>(
      future: service.ensureSynchronized(),
      builder: (context, snapshot) {
        final double screenWidth = MediaQuery.sizeOf(context).width;
        final bool isTablet = screenWidth >= 720;
        final double maxContentWidth = screenWidth >= 1200 ? 1120 : 960;
        final double horizontalPadding = isTablet ? 8 : 0;

        if (snapshot.connectionState == ConnectionState.waiting &&
            service.categories.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return const _GridStatusView(
            icon: Icons.cloud_off_rounded,
            title: 'No se pudieron cargar las categorias',
            message: 'Revisa tu conexion e intenta nuevamente.',
          );
        }

        final categories = service.categories
            .map(_CategoryItem.fromCategory)
            .toList(growable: false);

        if (categories.isEmpty) {
          return const _GridStatusView(
            icon: Icons.category_outlined,
            title: 'Aun no hay categorias',
            message: 'Agrega documentos en Firestore para mostrar el directorio.',
          );
        }

        final random = Random();
        final featuredIndex = random.nextInt(categories.length);
        final featured = categories[featuredIndex];
        final categoriesWithoutFeatured = [
          ...categories.take(featuredIndex),
          ...categories.skip(featuredIndex + 1),
        ];

        return Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxContentWidth),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
              child: CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 6),
                        _HeroBanner(
                          totalCategories: categories.length,
                          isTablet: isTablet,
                        ),
                        const SizedBox(height: 18),
                        _FeaturedCategoryCard(
                          category: featured,
                          isTablet: isTablet,
                        ),
                        const SizedBox(height: 22),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 4),
                          child: Text(
                            'Explora mas categorias',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF1F1F1F),
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 4),
                          child: Text(
                            'Selecciona una categoria para abrir negocios locales registrados.',
                            style: TextStyle(
                              color: Color(0xFF5D6470),
                              height: 1.45,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],
                    ),
                  ),
                  if (categoriesWithoutFeatured.isNotEmpty)
                    SliverToBoxAdapter(
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          final int columns = constraints.maxWidth >= 1024
                              ? 3
                              : constraints.maxWidth >= 620
                              ? 2
                              : 1;
                          final double spacing = 12;
                          final double cardWidth =
                              (constraints.maxWidth - (spacing * (columns - 1))) /
                                  columns;

                          return Wrap(
                            spacing: spacing,
                            runSpacing: spacing,
                            children: categoriesWithoutFeatured
                                .map(
                                  (category) => SizedBox(
                                    width: cardWidth,
                                    child: _CategoryCatalogCard(
                                      category: category,
                                      isTablet: isTablet,
                                    ),
                                  ),
                                )
                                .toList(),
                          );
                        },
                      ),
                    ),
                  const SliverToBoxAdapter(
                    child: SizedBox(height: 18),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _HeroBanner extends StatelessWidget {
  const _HeroBanner({
    required this.totalCategories,
    required this.isTablet,
  });

  final int totalCategories;
  final bool isTablet;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
        isTablet ? 28 : 22,
        isTablet ? 26 : 22,
        isTablet ? 28 : 22,
        isTablet ? 28 : 24,
      ),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF2D6A4F),
            Color(0xFF1B4332),
          ],
        ),
        borderRadius: BorderRadius.circular(30),
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(27, 67, 50, 0.18),
            blurRadius: 28,
            offset: Offset(0, 16),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            top: -34,
            right: -18,
            child: Container(
              width: 136,
              height: 136,
              decoration: BoxDecoration(
                color: const Color.fromRGBO(255, 255, 255, 0.10),
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
          Positioned(
            bottom: -42,
            right: 46,
            child: Container(
              width: 92,
              height: 92,
              decoration: BoxDecoration(
                color: const Color.fromRGBO(244, 211, 94, 0.14),
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color.fromRGBO(244, 211, 94, 0.95),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: const Text(
                  'Directorio del barrio',
                  style: TextStyle(
                    color: Color(0xFF3A2D00),
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Encuentra negocios locales por categoria',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: isTablet ? 36 : 29,
                  height: 1.12,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Descubre opciones cercanas y navega por rubros con una portada mas clara y visual.',
                style: TextStyle(
                  color: Color(0xFFE7F5EE),
                  fontSize: 14.5,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color.fromRGBO(255, 255, 255, 0.10),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: const Color.fromRGBO(255, 255, 255, 0.12),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.storefront_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      '$totalCategories categorias disponibles',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FeaturedCategoryCard extends StatelessWidget {
  const _FeaturedCategoryCard({
    required this.category,
    required this.isTablet,
  });

  final _CategoryItem category;
  final bool isTablet;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _openCategory(context, category),
        borderRadius: BorderRadius.circular(30),
        child: Ink(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(30),
            boxShadow: const [
              BoxShadow(
                color: Color.fromRGBO(53, 54, 66, 0.10),
                blurRadius: 26,
                offset: Offset(0, 14),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: isTablet ? 255 : 205,
                decoration: BoxDecoration(
                  color: category.color,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
                ),
                child: Stack(
                  children: [
                    Positioned(
                      right: -24,
                      top: -16,
                      child: Container(
                        width: 148,
                        height: 148,
                        decoration: BoxDecoration(
                          color: const Color.fromRGBO(255, 255, 255, 0.12),
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                    ),
                    Positioned(
                      left: 18,
                      top: 18,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                        decoration: BoxDecoration(
                          color: const Color.fromRGBO(255, 255, 255, 0.92),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: const Text(
                          'Categoria destacada',
                          style: TextStyle(
                            color: Color(0xFF202020),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      right: isTablet ? 26 : 18,
                      bottom: isTablet ? 16 : 10,
                      child: _CategoryImage(
                        imagePath: category.image,
                        width: isTablet ? 154 : 126,
                        height: isTablet ? 154 : 126,
                      ),
                    ),
                    Positioned(
                      left: 20,
                      right: isTablet ? 186 : 138,
                      bottom: isTablet ? 28 : 22,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            category.displayTitle,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: isTablet ? 34 : 29,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            category.description,
                            style: const TextStyle(
                              color: Color(0xFFF5F5F5),
                              height: 1.35,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: category.color.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        'Ver negocios',
                        style: TextStyle(
                          color: category.color,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const Spacer(),
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: category.color.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(
                        Icons.arrow_forward_rounded,
                        color: category.color,
                        size: 22,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CategoryCatalogCard extends StatelessWidget {
  const _CategoryCatalogCard({
    required this.category,
    required this.isTablet,
  });

  final _CategoryItem category;
  final bool isTablet;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _openCategory(context, category),
        borderRadius: BorderRadius.circular(24),
        child: Ink(
          decoration: BoxDecoration(
            color: category.color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(24),
            boxShadow: const [
              BoxShadow(
                color: Color.fromRGBO(53, 54, 66, 0.08),
                blurRadius: 22,
                offset: Offset(0, 12),
              ),
            ],
            border: Border.all(
              color: const Color.fromRGBO(234, 226, 216, 0.95),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(15),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 72,
                  height: isTablet ? 80 : 72,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.74),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: category.color.withValues(alpha: 0.12),
                        blurRadius: 16,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(isTablet ? 15 : 13),
                    child: _CategoryImage(
                      imagePath: category.image,
                      width: isTablet ? 46 : 42,
                      height: isTablet ? 46 : 42,
                      iconColor: category.color,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        category.displayTitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: isTablet ? 20 : 18,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF182028),
                          height: 1.15,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        category.description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13.5,
                          color: Color(0xFF48515B),
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.76),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: category.color,
                                borderRadius: BorderRadius.circular(999),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Explorar',
                              style: TextStyle(
                                color: category.color,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Icon(
                              Icons.arrow_forward_rounded,
                              color: category.color,
                              size: 18,
                            ),
                          ],
                        ),
                      ),
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

class _CategoryImage extends StatelessWidget {
  const _CategoryImage({
    required this.imagePath,
    required this.width,
    required this.height,
    this.iconColor = Colors.white,
  });

  final String imagePath;
  final double width;
  final double height;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    final fallback = Icon(
      Icons.category_rounded,
      size: width,
      color: iconColor,
    );

    if (imagePath.trim().isEmpty) {
      return fallback;
    }

    if (imagePath.startsWith('http://') || imagePath.startsWith('https://')) {
      return AppImageView(
        imagePath: imagePath,
        width: width,
        height: height,
        fit: BoxFit.contain,
        progressSize: width * 0.32,
        fallback: fallback,
      );
    }

    return AppImageView(
      imagePath: imagePath,
      width: width,
      height: height,
      fit: BoxFit.contain,
      progressSize: width * 0.32,
      fallback: fallback,
    );
  }
}

class _GridStatusView extends StatelessWidget {
  const _GridStatusView({
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
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 56,
              color: const Color(0xFF7A7A7A),
            ),
            const SizedBox(height: 16),
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
                fontSize: 15,
                color: Color(0xFF666666),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryItem {
  const _CategoryItem({
    required this.titulo,
    required this.reference,
    required this.image,
    required this.color,
    required this.description,
  });

  final String titulo;
  final DocumentReference<Map<String, dynamic>> reference;
  final String image;
  final Color color;
  final String description;

  String get displayTitle => _capitalizeWords(titulo);

  factory _CategoryItem.fromCategory(CategoryItem item) {
    return _CategoryItem(
      titulo: item.titulo,
      reference: item.reference,
      image: item.preferredImagePath,
      color: item.color,
      description: item.description,
    );
  }
}

void _openCategory(BuildContext context, _CategoryItem category) {
  FocusManager.instance.primaryFocus?.unfocus();
  Navigator.pushNamed(
    context,
    'listaNegocios',
    arguments: {
      'productTitulo': category.displayTitle,
      'categoriaRef': category.reference,
    },
  );
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
