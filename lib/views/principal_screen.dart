import 'package:flutter/material.dart';
import 'package:mi_tianguis/widgets/main/product_grid.dart';

class PrincipalScreen extends StatelessWidget {
  const PrincipalScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi Tianguis'),
        centerTitle: true,
      ),
      body: Padding(
          padding: EdgeInsets.only(left: 10, right: 10),
          child: ProductGrid(),
        ),
    );
  }
}