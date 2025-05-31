import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Importa Firestore para acceder a la base de datos.



class ListaNegocios extends StatelessWidget {  
  ListaNegocios({super.key});  

  @override
  Widget build(BuildContext context) {
    //Recibe argumentos de PrincipalScreen (Titulo y la coleccion a consultar)
    final Map<String, dynamic> args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
    final String titulo = args['productTitulo'];
    final String coleccion = args['productColeccion'];

    return Scaffold(
      appBar: AppBar(title: Text(titulo),),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection(coleccion).snapshots(), 
        builder: (context, snapshot) {
          if(snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(),);
          }

          if(!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("No hay negocios disponibles"),);
          }

          final docs = snapshot.data!.docs;

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>; //Datos del documento
              final String nombreNegocio = data['nombre'];
              final String urlImage = data['image'];

              return Card(
                elevation: 2,
                child: Column(
                  children: [
                    CachedNetworkImage(
                          imageUrl: urlImage,
                          height: 150,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => const Center(child: CircularProgressIndicator()),
                          errorWidget: (context, url, error) => const Icon(Icons.image_not_supported, size: 100),
                        ),
                      
                    
                    Text(nombreNegocio)
                  ],
                ),
              );
            }
          );
        }
      ),
    );
  }
}