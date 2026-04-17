import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
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
    final digits = _normalizePhone(phone);

    if (digits == null) {
      return;
    }

    final appUri = Uri.parse('whatsapp://send?phone=$digits');
    if (await launchUrl(
      appUri,
      mode: LaunchMode.externalNonBrowserApplication,
    )) {
      return;
    }

    final webUri = Uri.parse('https://api.whatsapp.com/send?phone=$digits');
    if (await launchUrl(webUri, mode: LaunchMode.externalApplication)) {
      return;
    }
  }

  Future<void> _openFacebook(String value) async {
    final normalized = _normalizeFacebookUrl(value);
    if (normalized == null) {
      return;
    }

    final appUri = Uri.parse(
      'fb://facewebmodal/f?href=${Uri.encodeComponent(normalized)}',
    );
    if (await launchUrl(
      appUri,
      mode: LaunchMode.externalNonBrowserApplication,
    )) {
      return;
    }

    final webUri = Uri.parse(normalized);
    if (await launchUrl(webUri, mode: LaunchMode.externalApplication)) {
      return;
    }
  }

  Future<void> _openExternalLink(String url) async {
    final normalized = _normalizeUrl(url);
    if (normalized == null) {
      return;
    }

    final uri = Uri.parse(normalized);
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  String? _normalizePhone(String phone) {
    final sanitized = phone.replaceAll(RegExp(r'[^0-9+]'), '');
    final digits = sanitized.replaceAll('+', '');
    if (digits.isEmpty) {
      return null;
    }
    return digits;
  }

  String? _normalizeUrl(String url) {
    final trimmed = url.trim();
    if (trimmed.isEmpty) {
      return null;
    }

    if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
      return trimmed;
    }

    return 'https://$trimmed';
  }

  String? _normalizeFacebookUrl(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      return null;
    }

    if (trimmed.startsWith('fb://')) {
      return null;
    }

    if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
      return trimmed;
    }

    final cleaned = trimmed.replaceFirst('@', '');
    if (cleaned.contains('facebook.com/')) {
      return 'https://$cleaned';
    }

    return 'https://www.facebook.com/$cleaned';
  }

  String? _normalizeInstagramUrl(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      return null;
    }

    if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
      return trimmed;
    }

    final cleaned = trimmed.replaceFirst('@', '');
    if (cleaned.contains('instagram.com/')) {
      return 'https://$cleaned';
    }

    return 'https://www.instagram.com/$cleaned/';
  }

  @override
  Widget build(BuildContext context) {
    final args =
        ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>?;
    final String? negocioId = args?['negocioId'] as String?;

    if (negocioId == null || negocioId.isEmpty) {
      return const Scaffold(
        body: Center(
          child: Text('Faltan argumentos para cargar el negocio'),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF6F3EE),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('negocios')
            .doc(negocioId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return const _StatusView(
              icon: Icons.wifi_off_rounded,
              title: 'No se pudo cargar el negocio',
              message: 'Revisa tu conexion e intenta nuevamente.',
            );
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const _StatusView(
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
          final String facebook = (data['facebook'] ?? '') as String;
          final String instagram = (data['instagram'] ?? '') as String;
          final String imageUrl =
              ((data['image'] ?? data['imagen']) ?? '') as String;
          final List<String> servicios =
              ((data['productos_servicios'] as List<dynamic>?) ?? [])
              .map((item) => item.toString().trim())
              .where((item) => item.isNotEmpty)
              .toList();

          final GeoPoint? gp = data['coordenadas'] as GeoPoint?;
          final double? lat = gp?.latitude;
          final double? lng = gp?.longitude;
          final bool hasMapLocation =
              lat != null && lng != null && !(lat == 0 && lng == 0);
          final String? whatsappPhone = _normalizePhone(whatsapp);
          final String? facebookUrl = _normalizeFacebookUrl(facebook);
          final String? instagramUrl = _normalizeInstagramUrl(instagram);
          final bool hasWhatsApp = whatsappPhone != null;
          final bool hasFacebook = facebookUrl != null;
          final bool hasInstagram = instagramUrl != null;

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
                      if (imageUrl.isNotEmpty)
                        CachedNetworkImage(
                          imageUrl: imageUrl,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(
                            color: const Color(0xFFE9E1D5),
                            child: const Center(
                              child: CircularProgressIndicator(),
                            ),
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
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
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
                              icon: const FaIcon(
                                FontAwesomeIcons.whatsapp,
                                color: Colors.white,
                                size: 16,
                              ),
                              label: 'WhatsApp',
                              color: const Color(0xFF1FA855),
                              onTap: () => _openWhatsApp(whatsappPhone),
                            ),
                          if (hasFacebook)
                            _ActionChip(
                              icon: const FaIcon(
                                FontAwesomeIcons.facebookF,
                                color: Colors.white,
                                size: 16,
                              ),
                              label: 'Facebook',
                              color: const Color(0xFF1877F2),
                              onTap: () => _openFacebook(facebookUrl),
                            ),
                          if (hasInstagram)
                            _ActionChip(
                              icon: const FaIcon(
                                FontAwesomeIcons.instagram,
                                color: Colors.white,
                                size: 16,
                              ),
                              label: 'Instagram',
                              color: const Color(0xFFE1306C),
                              onTap: () => _openExternalLink(instagramUrl),
                            ),
                          if (hasMapLocation)
                            _ActionChip(
                              icon: const _MapsPinIcon(),
                              label: 'Ubicación',
                              color: const Color.fromARGB(255, 255, 174, 0),
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
                      if (servicios.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        _InfoSection(
                          title: 'Productos/Servicios',
                          icon: Icons.inventory_2_outlined,
                          child: Wrap(
                            spacing: 10,
                            runSpacing: 10,
                            children: servicios
                                .map(
                                  (servicio) => Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 10,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF8F4EC),
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(
                                          Icons.check_circle_rounded,
                                          size: 18,
                                          color: Color(0xFF1B4332),
                                        ),
                                        const SizedBox(width: 8),
                                        Flexible(
                                          child: Text(
                                            servicio,
                                            style: const TextStyle(
                                              color: Color(0xFF2B2B2B),
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                )
                                .toList(),
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

class _ActionChip extends StatelessWidget {
  const _ActionChip({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final Widget icon;
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
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              icon,
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MapsPinIcon extends StatelessWidget {
  const _MapsPinIcon();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 16,
      height: 16,
      child: Stack(
        alignment: Alignment.center,
        children: [
          const Positioned(
            top: 0,
            child: Icon(
              Icons.location_pin,
              size: 16,
              color: Color(0xFFEA4335),
            ),
          ),
          const Positioned(
            top: 5,
            child: Icon(
              Icons.circle,
              size: 4,
              color: Color(0xFF4285F4),
            ),
          ),
          const Positioned(
            top: 3,
            left: 3,
            child: Icon(
              Icons.circle,
              size: 3.5,
              color: Color(0xFFFBBC05),
            ),
          ),
          const Positioned(
            top: 3,
            right: 3,
            child: Icon(
              Icons.circle,
              size: 3.5,
              color: Color(0xFF34A853),
            ),
          ),
        ],
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
