import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class DetallesNegocioScreen extends StatelessWidget {
  const DetallesNegocioScreen({super.key});

  Future<void> _openInMaps(double lat, double lng, {String? label}) async {
    final title = Uri.encodeComponent(label ?? 'Ubicacion');

    final geoUri = Uri.parse('geo:$lat,$lng?q=$lat,$lng($title)');
    if (await canLaunchUrl(geoUri)) {
      await launchUrl(geoUri, mode: LaunchMode.externalApplication);
      return;
    }

    final gmapsUri = Uri.parse(
      'comgooglemaps://?q=$lat,$lng($title)&center=$lat,$lng&zoom=16',
    );
    if (await canLaunchUrl(gmapsUri)) {
      await launchUrl(gmapsUri, mode: LaunchMode.externalApplication);
      return;
    }

    final webUri = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=$lat,$lng',
    );
    await launchUrl(webUri, mode: LaunchMode.externalApplication);
  }

  Future<void> _openWhatsApp(String phone) async {
    final sanitized = phone.replaceAll(RegExp(r'[^0-9+]'), '');
    final whatsappUri = Uri.parse('https://wa.me/${sanitized.replaceAll('+', '')}');

    if (await canLaunchUrl(whatsappUri)) {
      await launchUrl(whatsappUri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>?;
    final String? negocioId = args?['negocioId'] as String?;
    final String? coleccion = args?['coleccion'] as String?;

    if (negocioId == null || negocioId.isEmpty || coleccion == null || coleccion.isEmpty) {
      return const Scaffold(
        body: Center(
          child: Text('Faltan argumentos para cargar el negocio'),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF6F3EE),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance.collection(coleccion).doc(negocioId).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return _StatusView(
              icon: Icons.wifi_off_rounded,
              title: 'No se pudo cargar el negocio',
              message: 'Revisa tu conexion e intenta nuevamente.',
            );
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return _StatusView(
              icon: Icons.storefront_outlined,
              title: 'Negocio no disponible',
              message: 'No se encontro informacion para este negocio.',
            );
          }

          final data = snapshot.data!.data()!;
          final String nombre = (data['nombre'] ?? '') as String;
          final String descripcion = (data['descripcion'] ?? '') as String;
          final String direccion = (data['direccion'] ?? '') as String;
          final String whatsapp = (data['whatsapp'] ?? '') as String;
          final String? imageUrl = data['image'] as String?;

          final GeoPoint? gp = data['coordenadas'] as GeoPoint?;
          final double? lat = gp?.latitude;
          final double? lng = gp?.longitude;
          final bool hasMapLocation = lat != null && lng != null;
          final bool hasWhatsApp = whatsapp.trim().isNotEmpty;

          return CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 280,
                pinned: true,
                backgroundColor: const Color(0xFF1B4332),
                foregroundColor: Colors.white,
                flexibleSpace: FlexibleSpaceBar(
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      if (imageUrl != null && imageUrl.isNotEmpty)
                        CachedNetworkImage(
                          imageUrl: imageUrl,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(
                            color: const Color(0xFFE9E1D5),
                            child: const Center(child: CircularProgressIndicator()),
                          ),
                          errorWidget: (context, url, error) => _HeaderFallback(
                            title: nombre,
                          ),
                        )
                      else
                        _HeaderFallback(title: nombre),
                      const DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Color.fromRGBO(0, 0, 0, 0.10),
                              Color.fromRGBO(0, 0, 0, 0.68),
                            ],
                          ),
                        ),
                      ),
                      Positioned(
                        left: 20,
                        right: 20,
                        bottom: 24,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF4D35E),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: const Text(
                                'Negocio local',
                                style: TextStyle(
                                  color: Color(0xFF3A2D00),
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              nombre.isEmpty ? 'Sin nombre' : nombre,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 28,
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
                                  color: Color(0xFFF5F5F5),
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
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 18, 16, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: [
                          if (hasWhatsApp)
                            _ActionChip(
                              icon: Icons.chat_bubble_rounded,
                              label: 'WhatsApp',
                              color: const Color(0xFF1FA855),
                              onTap: () => _openWhatsApp(whatsapp),
                            ),
                          if (hasMapLocation)
                            _ActionChip(
                              icon: Icons.map_rounded,
                              label: 'Como llegar',
                              color: const Color(0xFFB5651D),
                              onTap: () => _openInMaps(
                                lat,
                                lng,
                                label: nombre.isEmpty ? 'Negocio' : nombre,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 22),
                      _InfoSection(
                        title: 'Descripcion',
                        icon: Icons.description_outlined,
                        child: Text(
                          descripcion.trim().isEmpty
                              ? 'Este negocio aun no tiene descripcion.'
                              : descripcion,
                          style: const TextStyle(
                            height: 1.55,
                            color: Color(0xFF3D3D3D),
                            fontSize: 15,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      _InfoSection(
                        title: 'Contacto y ubicacion',
                        icon: Icons.store_mall_directory_outlined,
                        child: Column(
                          children: [
                            _DetailRow(
                              icon: Icons.location_on_outlined,
                              label: 'Direccion',
                              value: direccion.trim().isEmpty
                                  ? 'No disponible'
                                  : direccion,
                            ),
                            const SizedBox(height: 14),
                            _DetailRow(
                              icon: Icons.phone_rounded,
                              label: 'WhatsApp',
                              value: hasWhatsApp ? whatsapp : 'No disponible',
                              accent: hasWhatsApp,
                              onTap: hasWhatsApp ? () => _openWhatsApp(whatsapp) : null,
                            ),
                          ],
                        ),
                      ),
                      if (hasMapLocation) ...[
                        const SizedBox(height: 16),
                        _InfoSection(
                          title: 'Ubicacion',
                          icon: Icons.map_outlined,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFEDE3D2),
                                  borderRadius: BorderRadius.circular(18),
                                ),
                                child: const Row(
                                  children: [
                                    Icon(
                                      Icons.place_rounded,
                                      color: Color(0xFF7A4E1D),
                                    ),
                                    SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        'La ubicacion del negocio esta lista para abrirse en tu app de mapas.',
                                        style: TextStyle(
                                          color: Color(0xFF5D4631),
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 14),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  onPressed: () => _openInMaps(
                                    lat,
                                    lng,
                                    label: nombre.isEmpty ? 'Negocio' : nombre,
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF1B4332),
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(vertical: 16),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                  ),
                                  icon: const Icon(Icons.navigation_rounded),
                                  label: const Text('Abrir en Maps'),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
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

class _HeaderFallback extends StatelessWidget {
  const _HeaderFallback({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF355C4A),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.storefront_rounded,
              size: 64,
              color: Colors.white70,
            ),
            const SizedBox(height: 12),
            Text(
              title.isEmpty ? 'Mi Tianguis' : title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoSection extends StatelessWidget {
  const _InfoSection({
    required this.title,
    required this.icon,
    required this.child,
  });

  final String title;
  final IconData icon;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(53, 54, 66, 0.08),
            blurRadius: 24,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: const Color(0xFFE9F1EC),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  icon,
                  color: const Color(0xFF1B4332),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1E1E1E),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          child,
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
    this.accent = false,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final String value;
  final bool accent;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final row = Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F5EF),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: accent ? const Color(0xFFDDF5E5) : const Color(0xFFE8ECEF),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: accent ? const Color(0xFF1FA855) : const Color(0xFF44515C),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF6B7280),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: accent ? FontWeight.w700 : FontWeight.w500,
                    color: accent ? const Color(0xFF167A3E) : const Color(0xFF222222),
                  ),
                ),
              ],
            ),
          ),
          if (onTap != null)
            const Padding(
              padding: EdgeInsets.only(left: 8, top: 8),
              child: Icon(
                Icons.open_in_new_rounded,
                size: 18,
                color: Color(0xFF7A7A7A),
              ),
            ),
        ],
      ),
    );

    if (onTap == null) {
      return row;
    }

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: row,
    );
  }
}

class _ActionChip extends StatelessWidget {
  const _ActionChip({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: Colors.white, size: 20),
              const SizedBox(width: 10),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusView extends StatelessWidget {
  const _StatusView({
    required this.icon,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F3EE),
      body: Center(
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
      ),
    );
  }
}
