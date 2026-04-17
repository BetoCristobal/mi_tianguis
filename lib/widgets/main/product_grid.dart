import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class ProductGrid extends StatelessWidget {
  const ProductGrid({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('categorias')
          .where('activo', isEqualTo: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return const _GridStatusView(
            icon: Icons.cloud_off_rounded,
            title: 'No se pudieron cargar las categorias',
            message: 'Revisa tu conexion e intenta nuevamente.',
          );
        }

        final docs = snapshot.data?.docs ?? [];
        final categories = docs.map(_CategoryItem.fromDocument).toList();

        if (categories.isEmpty) {
          return const _GridStatusView(
            icon: Icons.category_outlined,
            title: 'Aun no hay categorias',
            message:
                'Agrega documentos en Firestore para mostrar el directorio.',
          );
        }

        final random = Random();
        final featuredIndex = random.nextInt(categories.length);
        final featured = categories[featuredIndex];
        final categoriesWithoutFeatured = [
          ...categories.take(featuredIndex),
          ...categories.skip(featuredIndex + 1),
        ];
        final remaining = categoriesWithoutFeatured;

        return CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(22),
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
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
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
                        const Text(
                          'Encuentra negocios locales por categoria',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            height: 1.15,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          '${categories.length} categorias disponibles en Firestore.',
                          style: const TextStyle(
                            color: Color(0xFFE7F5EE),
                            fontSize: 15,
                            height: 1.45,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  _FeaturedCategoryCard(category: featured),
                  const SizedBox(height: 22),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 4),
                    child: Text(
                      'Explora mas categorias',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF1F1F1F),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 4),
                    child: Text(
                      'Cada categoria te lleva a negocios reales registrados en Firestore.',
                      style: TextStyle(
                        color: Color(0xFF5D6470),
                        height: 1.45,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                ],
              ),
            ),
            if (remaining.isNotEmpty)
              SliverToBoxAdapter(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final bool useTwoColumns = constraints.maxWidth >= 560;
                    final double spacing = 12;
                    final double cardWidth = useTwoColumns
                        ? (constraints.maxWidth - spacing) / 2
                        : constraints.maxWidth;

                    return Wrap(
                      spacing: spacing,
                      runSpacing: spacing,
                      children: remaining
                          .map(
                            (category) => SizedBox(
                              width: cardWidth,
                              child: _CategoryCatalogCard(category: category),
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
        );
      },
    );
  }
}

class _FeaturedCategoryCard extends StatelessWidget {
  const _FeaturedCategoryCard({required this.category});

  final _CategoryItem category;

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
                color: Color.fromRGBO(53, 54, 66, 0.09),
                blurRadius: 24,
                offset: Offset(0, 12),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 190,
                decoration: BoxDecoration(
                  color: category.color,
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(30)),
                ),
                child: Stack(
                  children: [
                    Positioned(
                      right: -20,
                      top: -12,
                      child: Container(
                        width: 140,
                        height: 140,
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
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 7),
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
                      right: 20,
                      bottom: 14,
                      child: _CategoryImage(
                        imagePath: category.image,
                        width: 120,
                        height: 120,
                      ),
                    ),
                    Positioned(
                      left: 20,
                      right: 132,
                      bottom: 22,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            category.displayTitle,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 28,
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
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
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
                    Icon(
                      Icons.arrow_forward_rounded,
                      color: category.color,
                      size: 28,
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
  const _CategoryCatalogCard({required this.category});

  final _CategoryItem category;

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
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 68,
                  height: 68,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.72),
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
                    padding: const EdgeInsets.all(12),
                    child: _CategoryImage(
                      imagePath: category.image,
                      width: 40,
                      height: 40,
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
                        style: const TextStyle(
                          fontSize: 17.5,
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
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.72),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Explorar',
                              style: TextStyle(
                                color: category.color,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(width: 8),
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
      return Image.network(
        imagePath,
        width: width,
        height: height,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) => fallback,
      );
    }

    return Image.asset(
      imagePath,
      width: width,
      height: height,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) => fallback,
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

  factory _CategoryItem.fromDocument(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data();

    return _CategoryItem(
      titulo: (data['titulo'] ?? doc.id) as String,
      reference: doc.reference,
      image: ((data['image'] ?? data['imagen']) ?? '') as String,
      color: _parseColor(data['color']),
      description: (data['descripcion'] ??
          'Explora negocios en esta categoria.') as String,
    );
  }

  static Color _parseColor(dynamic value) {
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
}

void _openCategory(BuildContext context, _CategoryItem category) {
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
