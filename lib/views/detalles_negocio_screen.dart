import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class DetallesNegocioScreen extends StatelessWidget {
  const DetallesNegocioScreen({super.key});

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
          final entries = data.entries.toList();

          // Claves a mostrar y en orden
          final orderedKeys = ['descripcion', 'direccion', 'whatsapp'];
          final labels = {
            'descripcion': 'Descripción',
            'direccion': 'Dirección',
            'whatsapp': 'WhatsApp',
          };

          return ListView(
            padding: const EdgeInsets.all(16),
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
              ...orderedKeys
                  .where((k) => data[k] != null && data[k].toString().trim().isNotEmpty)
                  .map((k) => ListTile(
                        dense: true,
                        title: Text(labels[k]!),
                        subtitle: Text('${data[k]}'),
                      )),
            ],
          );
        },
      ),
    );
  }
}