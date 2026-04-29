import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:mi_tianguis/services/firestore_service.dart';
import 'package:mi_tianguis/widgets/shared/app_image_view.dart';

class ListaNegocios extends StatelessWidget {
  const ListaNegocios({super.key});

  @override
  Widget build(BuildContext context) {
    final service = FirestoreService.instance;
    final double screenWidth = MediaQuery.sizeOf(context).width;
    final bool isTablet = screenWidth >= 720;
    final double maxContentWidth = screenWidth >= 1200 ? 1120 : 960;
    final Map<String, dynamic> args =
        ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
    final String titulo = args['productTitulo'] as String? ?? 'Categoría';
    final DocumentReference<Map<String, dynamic>>? categoriaRef =
        args['categoriaRef'] as DocumentReference<Map<String, dynamic>>?;

    if (categoriaRef == null) {
      return const _ListaStatusView(
        titulo: 'Categoría',
        icon: Icons.category_outlined,
        title: 'Falta información de la categoría',
        message: 'No se pudo identificar la categoría seleccionada.',
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF4F0E8),
      body: FutureBuilder<void>(
        future: service.ensureSynchronized(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting &&
              service.businesses.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return _ListaStatusView(
              titulo: titulo,
              icon: Icons.cloud_off_rounded,
              title: 'No se pudo cargar la categoría',
              message: 'Intenta nuevamente en unos momentos.',
            );
          }

          final docs = service.businessesForCategory(categoriaRef);

          if (docs.isEmpty) {
            return _ListaStatusView(
              titulo: titulo,
              icon: Icons.storefront_outlined,
              title: 'Sin negocios por ahora',
              message: 'Aún no hay negocios disponibles en $titulo.',
            );
          }

          final random = Random();
          final featuredDoc = docs[random.nextInt(docs.length)];
          final otherDocs = docs
              .where((doc) => doc.id != featuredDoc.id)
              .toList(growable: false);

          return Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxContentWidth),
              child: CustomScrollView(
                slivers: [
                  SliverAppBar(
                    expandedHeight: isTablet ? 220 : 186,
                    pinned: true,
                    backgroundColor: const Color(0xFF7A3E2B),
                    foregroundColor: Colors.white,
                    flexibleSpace: FlexibleSpaceBar(
                      background: Container(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Color(0xFFB5651D),
                              Color(0xFF7A3E2B),
                            ],
                          ),
                        ),
                        child: Stack(
                          children: [
                            Positioned(
                              top: -28,
                              right: -18,
                              child: Container(
                                width: 126,
                                height: 126,
                                decoration: BoxDecoration(
                                  color: const Color.fromRGBO(255, 255, 255, 0.10),
                                  borderRadius: BorderRadius.circular(999),
                                ),
                              ),
                            ),
                            Positioned(
                              bottom: -30,
                              right: 38,
                              child: Container(
                                width: 82,
                                height: 82,
                                decoration: BoxDecoration(
                                  color: const Color.fromRGBO(255, 244, 214, 0.12),
                                  borderRadius: BorderRadius.circular(999),
                                ),
                              ),
                            ),
                            SafeArea(
                              bottom: false,
                              child: Padding(
                                padding: EdgeInsets.fromLTRB(
                                  isTablet ? 28 : 20,
                                  24,
                                  isTablet ? 28 : 20,
                                  isTablet ? 28 : 24,
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color: const Color.fromRGBO(
                                          255,
                                          244,
                                          214,
                                          0.95,
                                        ),
                                        borderRadius: BorderRadius.circular(999),
                                      ),
                                      child: const Text(
                                        'Selección local',
                                        style: TextStyle(
                                          color: Color(0xFF6A3A16),
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 14),
                                    Text(
                                      titulo,
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: isTablet ? 38 : 31,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      '${docs.length} opciones para explorar en esta categoría.',
                                      style: const TextStyle(
                                        color: Color(0xFFF9EAD9),
                                        fontSize: 14.5,
                                        height: 1.4,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(
                        isTablet ? 24 : 16,
                        18,
                        isTablet ? 24 : 16,
                        12,
                      ),
                      child: _FeaturedBusinessCard(
                        business: featuredDoc,
                        isTablet: isTablet,
                        onTap: () {
                          Navigator.pushNamed(
                            context,
                            'detallesNegocio',
                            arguments: {'negocioId': featuredDoc.id},
                          );
                        },
                      ),
                    ),
                  ),
                  if (otherDocs.isNotEmpty) ...[
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(
                          isTablet ? 24 : 18,
                          6,
                          isTablet ? 24 : 18,
                          6,
                        ),
                        child: const Text(
                          'Más negocios en esta categoría',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF2F241F),
                          ),
                        ),
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(
                          isTablet ? 24 : 18,
                          0,
                          isTablet ? 24 : 18,
                          10,
                        ),
                        child: const Text(
                          'Revisa otras opciones disponibles y abre su ficha completa.',
                          style: TextStyle(
                            fontSize: 14,
                            color: Color(0xFF6E625C),
                            height: 1.4,
                          ),
                        ),
                      ),
                    ),
                  ],
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(
                        isTablet ? 24 : 16,
                        0,
                        isTablet ? 24 : 16,
                        24,
                      ),
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          final int columns = constraints.maxWidth >= 900 ? 2 : 1;
                          final double spacing = 12;
                          final double itemWidth =
                              (constraints.maxWidth - (spacing * (columns - 1))) /
                                  columns;

                          return Wrap(
                            spacing: spacing,
                            runSpacing: spacing,
                            children: otherDocs
                                .map(
                                  (item) => SizedBox(
                                    width: itemWidth,
                                    child: _BusinessListTile(
                                      nombre: item.nombre,
                                      descripcion: item.descripcion,
                                      direccion: item.direccion,
                                      imageUrl: item.preferredImagePath,
                                      isTablet: isTablet,
                                      onTap: () {
                                        Navigator.pushNamed(
                                          context,
                                          'detallesNegocio',
                                          arguments: {'negocioId': item.id},
                                        );
                                      },
                                    ),
                                  ),
                                )
                                .toList(),
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _FeaturedBusinessCard extends StatelessWidget {
  const _FeaturedBusinessCard({
    required this.business,
    required this.isTablet,
    required this.onTap,
  });

  final BusinessItem business;
  final bool isTablet;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final String nombre = business.nombre.isEmpty ? 'Sin nombre' : business.nombre;
    final String descripcion = business.descripcion;
    final String direccion = business.direccion;
    final String imageUrl = business.preferredImagePath;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(32),
        child: Ink(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(32),
            boxShadow: const [
              BoxShadow(
                color: Color.fromRGBO(67, 47, 37, 0.12),
                blurRadius: 28,
                offset: Offset(0, 14),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
                child: AspectRatio(
                  aspectRatio: isTablet ? 16 / 8.5 : 16 / 10,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      if (imageUrl.trim().isNotEmpty)
                        AppImageView(
                          imagePath: imageUrl,
                          fit: BoxFit.cover,
                          fallback: const _ImageFallback(iconSize: 58),
                        )
                      else
                        const _ImageFallback(iconSize: 58),
                      const DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Color.fromRGBO(0, 0, 0, 0.10),
                              Color.fromRGBO(0, 0, 0, 0.64),
                            ],
                          ),
                        ),
                      ),
                      Positioned(
                        left: 18,
                        top: 18,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                          decoration: BoxDecoration(
                            color: const Color.fromRGBO(255, 243, 212, 0.96),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: const Text(
                            'Destacado',
                            style: TextStyle(
                              color: Color(0xFF6A3A16),
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        left: 18,
                        right: 18,
                        bottom: 18,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              nombre,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: isTablet ? 31 : 27,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            if (direccion.trim().isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  const Icon(
                                    Icons.location_on_outlined,
                                    size: 16,
                                    color: Color(0xFFF7EEE6),
                                  ),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      direccion,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        color: Color(0xFFF7EEE6),
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      descripcion.trim().isEmpty
                          ? 'Abre la ficha completa para ver los datos de este negocio.'
                          : descripcion,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 15,
                        height: 1.5,
                        color: Color(0xFF594B43),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF6E8DA),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.visibility_outlined,
                                size: 18,
                                color: Color(0xFF7A3E2B),
                              ),
                              SizedBox(width: 8),
                              Text(
                                'Ver detalles',
                                style: TextStyle(
                                  color: Color(0xFF7A3E2B),
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Spacer(),
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: const Color(0xFF7A3E2B),
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: const Icon(
                            Icons.arrow_forward_rounded,
                            color: Colors.white,
                          ),
                        ),
                      ],
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

class _BusinessListTile extends StatelessWidget {
  const _BusinessListTile({
    required this.nombre,
    required this.descripcion,
    required this.direccion,
    required this.imageUrl,
    required this.isTablet,
    required this.onTap,
  });

  final String nombre;
  final String descripcion;
  final String direccion;
  final String imageUrl;
  final bool isTablet;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Ink(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: const [
              BoxShadow(
                color: Color.fromRGBO(67, 47, 37, 0.09),
                blurRadius: 20,
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
                    width: isTablet ? 116 : 96,
                    height: isTablet ? 116 : 96,
                    child: imageUrl.trim().isNotEmpty
                        ? AppImageView(
                            imagePath: imageUrl,
                            fit: BoxFit.cover,
                            fallback: const _ImageFallback(iconSize: 34),
                          )
                        : const _ImageFallback(iconSize: 34),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        nombre,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: isTablet ? 20 : 18,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF2F241F),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        descripcion.trim().isEmpty
                            ? 'Toca para conocer este negocio.'
                            : descripcion,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 14,
                          height: 1.4,
                          color: Color(0xFF6B5F57),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8F4EC),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.location_on_outlined,
                              size: 16,
                              color: Color(0xFFB5651D),
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                direccion.trim().isEmpty
                                    ? 'Dirección no disponible'
                                    : direccion,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: Color(0xFF8A6F5A),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF6E8DA),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 18,
                    color: Color(0xFF7A3E2B),
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

class _ListaStatusView extends StatelessWidget {
  const _ListaStatusView({
    required this.titulo,
    required this.icon,
    required this.title,
    required this.message,
  });

  final String titulo;
  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F0E8),
      appBar: AppBar(
        title: Text(titulo),
        backgroundColor: const Color(0xFF7A3E2B),
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 56,
                color: const Color(0xFF8A817C),
              ),
              const SizedBox(height: 16),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF2F241F),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 15,
                  color: Color(0xFF6E625C),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
