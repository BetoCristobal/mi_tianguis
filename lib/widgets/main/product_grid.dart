import 'package:flutter/material.dart';

class ProductGrid extends StatelessWidget {
  const ProductGrid({super.key});

  @override
  Widget build(BuildContext context) {
    final List<_CategoryItem> products = const [
      _CategoryItem(
        titulo: 'Alimentos',
        image: 'assets/iconos_categorias/ic_comida.png',
        coleccion: 'alimentos',
        color: Color(0xFFD96C3F),
        description: 'Comida casera, antojitos y sabores locales.',
      ),
      _CategoryItem(
        titulo: 'Autos',
        image: 'assets/iconos_categorias/ic_autos.png',
        coleccion: 'autos',
        color: Color(0xFF4D6CFA),
        description: 'Servicios, refacciones y movilidad.',
      ),
      _CategoryItem(
        titulo: 'Belleza',
        image: 'assets/iconos_categorias/ic_belleza.png',
        coleccion: 'belleza',
        color: Color(0xFFD45D8C),
        description: 'Estetica, cuidado personal y estilo.',
      ),
      _CategoryItem(
        titulo: 'Construccion',
        image: 'assets/iconos_categorias/ic_construccion.png',
        coleccion: 'construccion',
        color: Color(0xFF9A6B39),
        description: 'Materiales, herramientas y oficios.',
      ),
      _CategoryItem(
        titulo: 'Educacion',
        image: 'assets/iconos_categorias/ic_educacion.png',
        coleccion: 'educacion',
        color: Color(0xFF2E8B74),
        description: 'Clases, capacitacion y apoyo escolar.',
      ),
      _CategoryItem(
        titulo: 'Tecnologia',
        image: 'assets/iconos_categorias/ic_tecnologia.png',
        coleccion: 'electronica_y_tecnologia',
        color: Color(0xFF4052B5),
        description: 'Electronica, reparaciones y accesorios.',
      ),
      _CategoryItem(
        titulo: 'Eventos',
        image: 'assets/iconos_categorias/ic_eventos.png',
        coleccion: 'eventos',
        color: Color(0xFF8E44AD),
        description: 'Decoracion, musica y celebraciones.',
      ),
      _CategoryItem(
        titulo: 'Hogar',
        image: 'assets/iconos_categorias/ic_hogar.png',
        coleccion: 'hogar',
        color: Color(0xFF3E7C5D),
        description: 'Articulos utiles para tu casa.',
      ),
      _CategoryItem(
        titulo: 'Salud',
        image: 'assets/iconos_categorias/ic_salud.png',
        coleccion: 'salud',
        color: Color(0xFF0F9D8A),
        description: 'Bienestar, consultas y cuidado.',
      ),
      _CategoryItem(
        titulo: 'Servicios',
        image: 'assets/iconos_categorias/ic_servicios.png',
        coleccion: 'servicios',
        color: Color(0xFFCC7A00),
        description: 'Oficios, tramites y ayuda profesional.',
      ),
      _CategoryItem(
        titulo: 'Tiendas',
        image: 'assets/iconos_categorias/ic_tiendas.png',
        coleccion: 'tiendas',
        color: Color(0xFFB84A5A),
        description: 'Productos, regalos y compras del barrio.',
      ),
    ];

    final featured = products.first;
    final spotlight = products.skip(1).take(2).toList();
    final remaining = products.skip(3).toList();

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
                    const Text(
                      'Explora comercios, servicios y opciones cercanas con una vista mas clara y atractiva.',
                      style: TextStyle(
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
              const SizedBox(height: 18),
              Row(
                children: spotlight
                    .map(
                      (category) => Expanded(
                        child: Padding(
                          padding: EdgeInsets.only(
                            right: category == spotlight.first ? 7 : 0,
                            left: category == spotlight.last ? 7 : 0,
                          ),
                          child: SizedBox(
                            height: 190,
                            child: _SpotlightCategoryCard(category: category),
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
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
                  'Cada categoria te lleva a negocios reales registrados en tu directorio.',
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
        SliverGrid(
          delegate: SliverChildBuilderDelegate(
            (context, index) => _CategoryGridCard(category: remaining[index]),
            childCount: remaining.length,
          ),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 14,
            mainAxisSpacing: 14,
            mainAxisExtent: 220,
          ),
        ),
        const SliverToBoxAdapter(
          child: SizedBox(height: 18),
        ),
      ],
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
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(30),
                  ),
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
                          horizontal: 12,
                          vertical: 7,
                        ),
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
                      child: Image.asset(
                        category.image,
                        width: 120,
                        height: 120,
                        fit: BoxFit.contain,
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
                            category.titulo,
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
                        horizontal: 14,
                        vertical: 10,
                      ),
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

class _SpotlightCategoryCard extends StatelessWidget {
  const _SpotlightCategoryCard({required this.category});

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
            color: category.color,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Align(
                  alignment: Alignment.topRight,
                  child: Image.asset(
                    category.image,
                    width: 56,
                    height: 56,
                    fit: BoxFit.contain,
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  category.titulo,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  category.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFFF5F5F5),
                    height: 1.35,
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

class _CategoryGridCard extends StatelessWidget {
  const _CategoryGridCard({required this.category});

  final _CategoryItem category;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _openCategory(context, category),
        borderRadius: BorderRadius.circular(26),
        child: Ink(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(26),
            boxShadow: const [
              BoxShadow(
                color: Color.fromRGBO(53, 54, 66, 0.07),
                blurRadius: 20,
                offset: Offset(0, 10),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    color: category.color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: Image.asset(
                      category.image,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  category.titulo,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1F1F1F),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  category.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF5D6470),
                    height: 1.35,
                  ),
                ),
                const Spacer(),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Text(
                      'Entrar',
                      style: TextStyle(
                        color: category.color,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const Spacer(),
                    Icon(
                      Icons.arrow_forward_ios_rounded,
                      color: category.color,
                      size: 16,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CategoryItem {
  const _CategoryItem({
    required this.titulo,
    required this.image,
    required this.coleccion,
    required this.color,
    required this.description,
  });

  final String titulo;
  final String image;
  final String coleccion;
  final Color color;
  final String description;
}

void _openCategory(BuildContext context, _CategoryItem category) {
  Navigator.pushNamed(
    context,
    'listaNegocios',
    arguments: {
      'productColeccion': category.coleccion,
      'productTitulo': category.titulo,
    },
  );
}
