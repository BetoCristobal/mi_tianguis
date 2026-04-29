import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:flutter/material.dart';
import 'package:mi_tianguis/services/firestore_service.dart';
import 'package:mi_tianguis/widgets/shared/app_image_view.dart';
import 'package:url_launcher/url_launcher.dart';

class DetallesNegocioScreen extends StatelessWidget {
  const DetallesNegocioScreen({super.key});

  void _openImageViewer(
    BuildContext context, {
    required String imageUrl,
    required String heroTag,
  }) {
    if (imageUrl.trim().isEmpty) {
      return;
    }

    Navigator.of(context).push(
      PageRouteBuilder<void>(
        opaque: false,
        barrierColor: Colors.black.withValues(alpha: 0.92),
        pageBuilder: (context, animation, secondaryAnimation) {
          return _FullscreenImageViewer(
            imageUrl: imageUrl,
            heroTag: heroTag,
          );
        },
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: animation,
            child: child,
          );
        },
      ),
    );
  }

  Future<void> _openInMaps(double lat, double lng, {String? label}) async {
    final title = Uri.encodeComponent(label ?? 'Ubicaci\u00f3n');

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

  void _showOpenWarning(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  Future<void> _openWhatsApp(BuildContext context, String phone) async {
    final digits = _normalizePhone(phone);

    if (digits == null) {
      _showOpenWarning(context, 'El n\u00famero de WhatsApp no es v\u00e1lido.');
      return;
    }

    final appUri = Uri.parse('whatsapp://send?phone=$digits');
    if (await canLaunchUrl(appUri) &&
        await launchUrl(
          appUri,
          mode: LaunchMode.externalNonBrowserApplication,
        )) {
      return;
    }

    final webUri = Uri.parse('https://api.whatsapp.com/send?phone=$digits');
    if (await canLaunchUrl(webUri) &&
        await launchUrl(webUri, mode: LaunchMode.externalApplication)) {
      return;
    }

    _showOpenWarning(
      context,
      'No se pudo abrir WhatsApp. Verifica que est\u00e9 instalado o que tengas sesi\u00f3n activa.',
    );
  }

  Future<void> _openFacebook(BuildContext context, String value) async {
    final normalized = _normalizeFacebookUrl(value);
    if (normalized == null) {
      _showOpenWarning(context, 'El enlace de Facebook no es v\u00e1lido.');
      return;
    }

    final appUri = Uri.parse(
      'fb://facewebmodal/f?href=${Uri.encodeComponent(normalized)}',
    );
    if (await canLaunchUrl(appUri) &&
        await launchUrl(
          appUri,
          mode: LaunchMode.externalNonBrowserApplication,
        )) {
      return;
    }

    final webUri = Uri.parse(normalized);
    if (await canLaunchUrl(webUri) &&
        await launchUrl(webUri, mode: LaunchMode.externalApplication)) {
      return;
    }

    _showOpenWarning(
      context,
      'No se pudo abrir Facebook. Verifica que la app est\u00e9 instalada o inicia sesi\u00f3n en el navegador.',
    );
  }

  Future<void> _openExternalLink(BuildContext context, String url) async {
    final normalized = _normalizeUrl(url);
    if (normalized == null) {
      _showOpenWarning(context, 'El enlace no es v\u00e1lido.');
      return;
    }

    final uri = Uri.parse(normalized);
    if (await canLaunchUrl(uri) &&
        await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      return;
    }

    _showOpenWarning(
      context,
      'No se pudo abrir el enlace. Intenta de nuevo m\u00e1s tarde.',
    );
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
    final service = FirestoreService.instance;
    final double screenWidth = MediaQuery.sizeOf(context).width;
    final bool isTablet = screenWidth >= 820;
    final double maxContentWidth = screenWidth >= 1300 ? 1160 : 980;
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
      body: FutureBuilder<void>(
        future: service.ensureSynchronized(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting &&
              service.businesses.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return const _StatusView(
              icon: Icons.wifi_off_rounded,
              title: 'No se pudo cargar el negocio',
              message: 'Revisa tu conexi\u00f3n e intenta nuevamente.',
            );
          }

          final business = service.businessById(negocioId);

          if (business == null) {
            return const _StatusView(
              icon: Icons.storefront_outlined,
              title: 'Negocio no disponible',
              message: 'No se encontr\u00f3 informaci\u00f3n para este negocio.',
            );
          }

          final String nombre = business.nombre;
          final String descripcion = business.descripcion;
          final String direccion = business.direccion;
          final String whatsapp = business.whatsapp;
          final String facebook = business.facebook;
          final String instagram = business.instagram;
          final String imageUrl = business.preferredImagePath;
          final List<String> servicios = business.productosServicios;

          final GeoPoint? gp = business.coordenadas;
          final double? lat = gp?.latitude;
          final double? lng = gp?.longitude;
          final bool hasMapLocation =
              lat != null && lng != null && !(lat == 0 && lng == 0);
          final String? whatsappPhone = _normalizePhone(whatsapp);
          final String? facebookUrl = _normalizeFacebookUrl(facebook);
          final String? instagramUrl = _normalizeInstagramUrl(instagram);

          return Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxContentWidth),
              child: CustomScrollView(
                slivers: [
                  SliverAppBar(
                    expandedHeight: isTablet ? 340 : 280,
                    pinned: true,
                    backgroundColor: const Color(0xFF1B4332),
                    foregroundColor: Colors.white,
                    flexibleSpace: FlexibleSpaceBar(
                      background: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: imageUrl.isEmpty
                              ? null
                              : () => _openImageViewer(
                                    context,
                                    imageUrl: imageUrl,
                                    heroTag: 'business-image-$negocioId',
                                  ),
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              if (imageUrl.isNotEmpty)
                                Hero(
                                  tag: 'business-image-$negocioId',
                                  child: AppImageView(
                                    imagePath: imageUrl,
                                    fit: BoxFit.cover,
                                    placeholderColor: const Color(0xFFE9E1D5),
                                    fallback: _HeaderFallback(title: nombre),
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
                                top: isTablet ? 26 : 22,
                                right: isTablet ? 26 : 18,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color.fromRGBO(
                                      255,
                                      255,
                                      255,
                                      0.16,
                                    ),
                                    borderRadius: BorderRadius.circular(999),
                                    border: Border.all(
                                      color: const Color.fromRGBO(
                                        255,
                                        255,
                                        255,
                                        0.22,
                                      ),
                                    ),
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.zoom_in_rounded,
                                        size: 16,
                                        color: Colors.white,
                                      ),
                                      SizedBox(width: 6),
                                      Text(
                                        'Toca para ampliar',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w700,
                                          fontSize: 12.5,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              Positioned(
                                left: isTablet ? 28 : 20,
                                right: isTablet ? 28 : 20,
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
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: isTablet ? 34 : 28,
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
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(
                        isTablet ? 24 : 16,
                        18,
                        isTablet ? 24 : 16,
                        24,
                      ),
                      child: isTablet
                          ? Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  flex: 5,
                                  child: _DetailsContent(
                                    hasWhatsApp: whatsappPhone != null,
                                    hasFacebook: facebookUrl != null,
                                    hasInstagram: instagramUrl != null,
                                    hasMapLocation: hasMapLocation,
                                    whatsappPhone: whatsappPhone ?? '',
                                    facebookUrl: facebookUrl ?? '',
                                    instagramUrl: instagramUrl ?? '',
                                    lat: lat ?? 0,
                                    lng: lng ?? 0,
                                    nombre: nombre,
                                    descripcion: descripcion,
                                    servicios: servicios,
                                    openWhatsApp: _openWhatsApp,
                                    openFacebook: _openFacebook,
                                    openExternalLink: _openExternalLink,
                                    openInMaps: _openInMaps,
                                  ),
                                ),
                                const SizedBox(width: 18),
                                Expanded(
                                  flex: 4,
                                  child: _DetailsAside(
                                    nombre: nombre,
                                    direccion: direccion,
                                    imageUrl: imageUrl,
                                    heroTag: 'business-image-$negocioId-aside',
                                    onImageTap: () => _openImageViewer(
                                      context,
                                      imageUrl: imageUrl,
                                      heroTag:
                                          'business-image-$negocioId-aside',
                                    ),
                                  ),
                                ),
                              ],
                            )
                          : _DetailsContent(
                              hasWhatsApp: whatsappPhone != null,
                              hasFacebook: facebookUrl != null,
                              hasInstagram: instagramUrl != null,
                              hasMapLocation: hasMapLocation,
                              whatsappPhone: whatsappPhone ?? '',
                              facebookUrl: facebookUrl ?? '',
                              instagramUrl: instagramUrl ?? '',
                              lat: lat ?? 0,
                              lng: lng ?? 0,
                              nombre: nombre,
                              descripcion: descripcion,
                              servicios: servicios,
                              openWhatsApp: _openWhatsApp,
                              openFacebook: _openFacebook,
                              openExternalLink: _openExternalLink,
                              openInMaps: _openInMaps,
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

class _DetailsContent extends StatelessWidget {
  const _DetailsContent({
    required this.hasWhatsApp,
    required this.hasFacebook,
    required this.hasInstagram,
    required this.hasMapLocation,
    required this.whatsappPhone,
    required this.facebookUrl,
    required this.instagramUrl,
    required this.lat,
    required this.lng,
    required this.nombre,
    required this.descripcion,
    required this.servicios,
    required this.openWhatsApp,
    required this.openFacebook,
    required this.openExternalLink,
    required this.openInMaps,
  });

  final bool hasWhatsApp;
  final bool hasFacebook;
  final bool hasInstagram;
  final bool hasMapLocation;
  final String whatsappPhone;
  final String facebookUrl;
  final String instagramUrl;
  final double lat;
  final double lng;
  final String nombre;
  final String descripcion;
  final List<String> servicios;
  final Future<void> Function(BuildContext, String) openWhatsApp;
  final Future<void> Function(BuildContext, String) openFacebook;
  final Future<void> Function(BuildContext, String) openExternalLink;
  final Future<void> Function(double, double, {String? label}) openInMaps;

  @override
  Widget build(BuildContext context) {
    return Column(
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
                onTap: () => openWhatsApp(context, whatsappPhone),
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
                onTap: () => openFacebook(context, facebookUrl),
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
                onTap: () => openExternalLink(context, instagramUrl),
              ),
            if (hasMapLocation)
              _ActionChip(
                icon: const _MapsPinIcon(),
                label: 'Abrir en Maps',
                color: const Color(0xFFFFAE00),
                onTap: () => openInMaps(
                  lat,
                  lng,
                  label: nombre.isEmpty ? 'Negocio' : nombre,
                ),
              ),
          ],
        ),
        const SizedBox(height: 22),
        _InfoSection(
          title: 'Descripci\u00f3n',
          icon: Icons.description_outlined,
          child: Text(
            descripcion.trim().isEmpty
                ? 'Este negocio a\u00fan no tiene descripci\u00f3n.'
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
    );
  }
}

class _DetailsAside extends StatelessWidget {
  const _DetailsAside({
    required this.nombre,
    required this.direccion,
    required this.imageUrl,
    required this.heroTag,
    required this.onImageTap,
  });

  final String nombre;
  final String direccion;
  final String imageUrl;
  final String heroTag;
  final VoidCallback onImageTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
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
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            child: AspectRatio(
              aspectRatio: 4 / 3,
              child: imageUrl.isNotEmpty
                  ? GestureDetector(
                      onTap: onImageTap,
                      child: Hero(
                        tag: heroTag,
                        child: AppImageView(
                          imagePath: imageUrl,
                          fit: BoxFit.cover,
                          placeholderColor: const Color(0xFFE9E1D5),
                          fallback: _HeaderFallback(title: nombre),
                        ),
                      ),
                    )
                  : _HeaderFallback(title: nombre),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  nombre.isEmpty ? 'Sin nombre' : nombre,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1E1E1E),
                  ),
                ),
                if (direccion.trim().isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Padding(
                        padding: EdgeInsets.only(top: 2),
                        child: Icon(
                          Icons.location_on_outlined,
                          size: 18,
                          color: Color(0xFF7A3E2B),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          direccion,
                          style: const TextStyle(
                            color: Color(0xFF5D6470),
                            height: 1.45,
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
    );
  }
}

class _FullscreenImageViewer extends StatefulWidget {
  const _FullscreenImageViewer({
    required this.imageUrl,
    required this.heroTag,
  });

  final String imageUrl;
  final String heroTag;

  @override
  State<_FullscreenImageViewer> createState() => _FullscreenImageViewerState();
}

class _FullscreenImageViewerState extends State<_FullscreenImageViewer> {
  final TransformationController _transformationController =
      TransformationController();

  @override
  void dispose() {
    _transformationController.dispose();
    super.dispose();
  }

  void _resetZoom() {
    _transformationController.value = Matrix4.identity();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: Container(color: Colors.transparent),
            ),
          ),
          SafeArea(
            child: Stack(
              children: [
                Center(
                  child: GestureDetector(
                    onDoubleTap: _resetZoom,
                    child: InteractiveViewer(
                      minScale: 0.8,
                      maxScale: 4,
                      panEnabled: true,
                      scaleEnabled: true,
                      transformationController: _transformationController,
                      child: Hero(
                        tag: widget.heroTag,
                        child: AppImageView(
                          imagePath: widget.imageUrl,
                          fit: BoxFit.contain,
                          placeholderColor: Colors.transparent,
                          fallback: Container(
                            width: 260,
                            height: 260,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: const Color(0xFF355C4A),
                              borderRadius: BorderRadius.circular(24),
                            ),
                            child: const Icon(
                              Icons.broken_image_outlined,
                              color: Colors.white70,
                              size: 56,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 12,
                  right: 12,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _ViewerButton(
                        icon: Icons.center_focus_strong_rounded,
                        onTap: _resetZoom,
                      ),
                      const SizedBox(width: 10),
                      _ViewerButton(
                        icon: Icons.close_rounded,
                        onTap: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ViewerButton extends StatelessWidget {
  const _ViewerButton({
    required this.icon,
    required this.onTap,
  });

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withValues(alpha: 0.42),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: SizedBox(
          width: 44,
          height: 44,
          child: Icon(
            icon,
            color: Colors.white,
          ),
        ),
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
