import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:mi_tianguis/firebase_options.dart';
import 'package:mi_tianguis/views/detalles_negocio_screen.dart';
import 'package:mi_tianguis/views/lista_negocios.dart';
import 'package:mi_tianguis/views/principal_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true,
  );

  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      initialRoute: '/',
      routes: {
        '/': (context)  => PrincipalScreen(),
        'principalScreen': (context) => PrincipalScreen(),
        'listaNegocios': (context) => ListaNegocios(),
        'detallesNegocio': (context) => const DetallesNegocioScreen(),
      },
    );
  }
}
