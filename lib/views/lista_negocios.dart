import 'dart:math';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class ListaNegocios extends StatelessWidget {
  const ListaNegocios({super.key});

  @override
  Widget build(BuildContext context) {
    final Map<String, dynamic> args =
        ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
    final String titulo = args['productTitulo'] as String? ?? 'Categoria';
    final DocumentReference<Map<String, dynamic>>? categoriaRef =
        args['categoriaRef'] as DocumentReference<Map<String, dynamic>>?;

    if (categoriaRef == null) {
      return const _ListaStatusView(
        titulo: 'Categoria',
        icon: Icons.category_outlined,
        title: 'Falta informacion de la categoria',
        message: 'No se pudo identificar la categoria seleccionada.',
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF4F0E8),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('negocios')
            .where('activo', isEqualTo: true)
            .where('categoria', isEqualTo: categoriaRef)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return _ListaStatusView(
              titulo: titulo,
              icon: Icons.cloud_off_rounded,
              title: 'No se pudo cargar la categoria',
              message: 'Intenta nuevamente en unos momentos.',
            );
          }

          final docs = snapshot.data?.docs ?? [];

          if (docs.isEmpty) {
            return _ListaStatusView(
              titulo: titulo,
              icon: Icons.storefront_outlined,
              title: 'Sin negocios por ahora',
              message: 'Aun no hay negocios disponibles en $titulo.',
            );
          }

          final random = Random();
          final featuredDoc = docs[random.nextInt(docs.length)];
          final otherDocs = docs.where((doc) => doc.id != featuredDoc.id).toList();

          return CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 170,
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
                    child: SafeArea(
                      bottom: false,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 22, 20, 24),
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
                                color: const Color.fromRGBO(255, 244, 214, 0.95),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: const Text(
                                'Seleccion local',
                                style: TextStyle(
                                  color: Color(0xFF6A3A16),
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            const SizedBox(height: 14),
                            Text(
                              titulo,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 30,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '${docs.length} opciones para explorar',
                              style: const TextStyle(
                                color: Color(0xFFF9EAD9),
                                fontSize: 15,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 18, 16, 10),
                  child: _FeaturedBusinessCard(
                    doc: featuredDoc,
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
              if (otherDocs.isNotEmpty)
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(18, 8, 18, 10),
                    child: Text(
                      'Mas negocios en esta categoria',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF2F241F),
                      ),
                    ),
                  ),
                ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final doc = otherDocs[index];
                      final data = doc.data();

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _BusinessListTile(
                          nombre: (data['nombre'] ?? 'Sin nombre') as String,
                          descripcion: (data['descripcion'] ?? '') as String,
                          direccion: (data['direccion'] ?? '') as String,
                          imageUrl: _readImage(data),
                          onTap: () {
                            Navigator.pushNamed(
                              context,
                              'detallesNegocio',
                              arguments: {'negocioId': doc.id},
                            );
                          },
                        ),
                      );
                    },
                    childCount: otherDocs.length,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

String _readImage(Map<String, dynamic> data) {
  return ((data['image'] ?? data['imagen']) ?? '') as String;
}

class _FeaturedBusinessCard extends StatelessWidget {
  const _FeaturedBusinessCard({
    required this.doc,
    required this.onTap,
  });

  final QueryDocumentSnapshot<Map<String, dynamic>> doc;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final data = doc.data();
    final String nombre = (data['nombre'] ?? 'Sin nombre') as String;
    final String descripcion = (data['descripcion'] ?? '') as String;
    final String direccion = (data['direccion'] ?? '') as String;
    final String imageUrl = _readImage(data);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(30),
        child: Ink(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(30),
            boxShadow: const [
              BoxShadow(
                color: Color.fromRGBO(67, 47, 37, 0.12),
                blurRadius: 26,
                offset: Offset(0, 14),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
                child: AspectRatio(
                  aspectRatio: 16 / 10,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      if (imageUrl.trim().isNotEmpty)
                        CachedNetworkImage(
                          imageUrl: imageUrl,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(
                            color: const Color(0xFFE8D9C8),
                            child: const Center(child: CircularProgressIndicator()),
                          ),
                          errorWidget: (context, url, error) =>
                              const _ImageFallback(iconSize: 58),
                        )
                      else
                        const _ImageFallback(iconSize: 58),
                      const DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Color.fromRGBO(0, 0, 0, 0.08),
                              Color.fromRGBO(0, 0, 0, 0.62),
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
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 26,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            if (direccion.trim().isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Text(
                                direccion,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Color(0xFFF7EEE6),
                                  fontSize: 14,
                                ),
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
                        height: 1.45,
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
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: const Color(0xFF7A3E2B),
                            borderRadius: BorderRadius.circular(14),
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
    required this.onTap,
  });

  final String nombre;
  final String descripcion;
  final String direccion;
  final String imageUrl;
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
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: SizedBox(
                    width: 92,
                    height: 92,
                    child: imageUrl.trim().isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: imageUrl,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => Container(
                              color: const Color(0xFFE8D9C8),
                              child: const Center(child: CircularProgressIndicator()),
                            ),
                            errorWidget: (context, url, error) =>
                                const _ImageFallback(iconSize: 34),
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
                        style: const TextStyle(
                          fontSize: 18,
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
                          height: 1.35,
                          color: Color(0xFF6B5F57),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
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
                                  ? 'Direccion no disponible'
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
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Container(
                  width: 40,
                  height: 40,
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
