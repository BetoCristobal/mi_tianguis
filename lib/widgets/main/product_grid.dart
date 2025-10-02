import 'package:flutter/material.dart';

class ProductGrid extends StatelessWidget {
  const ProductGrid({super.key});

  @override
  Widget build(BuildContext context) {

    final List<Map<String, String>> products = const [
      {
        'titulo': 'Alimentos',
        'image': 'assets/iconos_categorias/ic_comida.png',
        'coleccion': 'alimentos'
      },
      {
        'titulo': 'Autos',
        'image': 'assets/iconos_categorias/ic_autos.png',
        'coleccion': 'autos'
      },
      {
        'titulo': 'Belleza',
        'image': 'assets/iconos_categorias/ic_belleza.png',
        'coleccion': 'belleza'
      },
      {
        'titulo': 'Construcción',
        'image': 'assets/iconos_categorias/ic_construccion.png',
        'coleccion': 'construccion'
      },
      {
        'titulo': 'Educación',
        'image': 'assets/iconos_categorias/ic_educacion.png',
        'coleccion': 'educacion'
      },
      {
        'titulo': 'Tecnología',
        'image': 'assets/iconos_categorias/ic_tecnologia.png',
        'coleccion': 'electronica_y_tecnologia'
      },
      {
        'titulo': 'Eventos',
        'image': 'assets/iconos_categorias/ic_eventos.png',
        'coleccion': 'eventos'
      },
      {
        'titulo': 'Hogar',
        'image': 'assets/iconos_categorias/ic_hogar.png',
        'coleccion': 'hogar'
      },
      {
        'titulo': 'Salud',
        'image': 'assets/iconos_categorias/ic_salud.png',
        'coleccion': 'salud'
      },
      {
        'titulo': 'Servicios',
        'image': 'assets/iconos_categorias/ic_servicios.png',
        'coleccion': 'servicios'
      },
      {
        'titulo': 'Tiendas',
        'image': 'assets/iconos_categorias/ic_tiendas.png',
        'coleccion': 'tiendas'
      },
    ];

    return GridView.builder(
      itemCount: products.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 5,
        mainAxisSpacing: 5,
        childAspectRatio: 1
      ), 
      itemBuilder: (context, index) {
        final product = products[index];

        return InkWell(
          onTap: () {
            Navigator.pushNamed(context, 'listaNegocios',
              arguments: { 
                'productColeccion': product['coleccion'], 
                'productTitulo': product['titulo'] 
              }
            );
          },
          child: Card(
            elevation: 4,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: Image(
                      image: AssetImage(product['image']!)
                    ),
                  ),
                ),
                Container(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 10, bottom: 10),
                    child: Text(product['titulo']!),
                  ),
                ),
              ],
            ),
          ),
        );
      }
    );
  }
}