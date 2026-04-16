import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart'; // Para abrir Maps

class DetallesNegocioScreen extends StatelessWidget {
  const DetallesNegocioScreen({super.key});

  // Abre en app de mapas si está disponible; si no, en navegador.
  Future<void> _openInMaps(double lat, double lng, {String? label}) async {
    final title = Uri.encodeComponent(label ?? 'Ubicación');

    // Android (geo: scheme) -> abre la app de mapas por defecto
    final geoUri = Uri.parse('geo:$lat,$lng?q=$lat,$lng($title)');
    if (await canLaunchUrl(geoUri)) {
      await launchUrl(geoUri, mode: LaunchMode.externalApplication);
      return;
    }

    // Google Maps app (iOS/Android)
    final gmapsUri = Uri.parse('comgooglemaps://?q=$lat,$lng($title)&center=$lat,$lng&zoom=16');
    if (await canLaunchUrl(gmapsUri)) {
      await launchUrl(gmapsUri, mode: LaunchMode.externalApplication);
      return;
    }

    // Fallback web
    final webUri = Uri.parse('https://www.google.com/maps/search/?api=1&query=$lat,$lng');
    await launchUrl(webUri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>?;
    final String? negocioId = args?['negocioId'] as String?;
    final String? coleccion = args?['coleccion'] as String?;

    if (negocioId == null || negocioId.isEmpty || coleccion == null || coleccion.isEmpty) {
      return const Scaffold(
        body: Center(child: Text('Faltan argumentos para cargar el negocio')),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Detalles del negocio')),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection(coleccion)
            .doc(negocioId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text('No se encontró información del negocio'));
          }

          final data = snapshot.data!.data()!;
          final String nombre = (data['nombre'] ?? '') as String;
          final String? imageUrl = data['image'] as String?;
          final entries = data.entries.toList(); // ...existing code...

          // Claves a mostrar y en orden
          final orderedKeys = ['descripcion', 'direccion', 'whatsapp'];
          final labels = {
            'descripcion': 'Descripción',
            'direccion': 'Dirección',
            'whatsapp': 'WhatsApp',
          };

          // Lee coordenadas desde GeoPoint (Firestore)
          final GeoPoint? gp = data['coordenadas'] as GeoPoint?;
          final double? lat = gp?.latitude;
          final double? lng = gp?.longitude;

          return ListView(
            padding: const EdgeInsets.all(16), // ...existing code...
            children: [
              if (imageUrl != null && imageUrl.isNotEmpty)
                CachedNetworkImage(
                  imageUrl: imageUrl,
                  height: 200,
                  fit: BoxFit.cover,
                  placeholder: (context, url) =>
                      const SizedBox(height: 200, child: Center(child: CircularProgressIndicator())),
                  errorWidget: (context, url, error) => const Icon(Icons.image_not_supported, size: 120),
                ),
              const SizedBox(height: 16),
              Text(
                nombre.isEmpty ? 'Sin nombre' : nombre,
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),

              // Muestra solo descripción, dirección y WhatsApp
              ...orderedKeys
                  .where((k) => data[k] != null && data[k].toString().trim().isNotEmpty)
                  .map((k) => ListTile(
                        dense: true,
                        title: Text(labels[k]!),
                        subtitle: Text('${data[k]}'),
                      )),

              if (lat != null && lng != null) ...[
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerRight,
                  child: OutlinedButton.icon(
                    onPressed: () => _openInMaps(lat!, lng!, label: nombre.isEmpty ? 'Negocio' : nombre),
                    icon: const Icon(Icons.map),
                    label: const Text('Abrir en Maps'),
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}