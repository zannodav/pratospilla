import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:pratospilla/views/home_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inizializza la formattazione date per l'italiano
  await initializeDateFormatting('it', null);

  try {
    // Inizializzazione Firebase [DEFAULT] con controllo preventivo
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: const FirebaseOptions(
          apiKey: "AIzaSyCO67gnUjg7o4gmS_NNeA_c3tt4aOqX3dg",
          projectId: "pratospilla-b325d",
          authDomain: "pratospilla-b325d.firebaseapp.com",
          storageBucket:
              "pratospilla-b325d.firebasestorage.app", // Standard format
          messagingSenderId: "905404341597",
          appId: "1:905404341597:web:af171cc0d12a0313ad5cb4",
          measurementId: "G-7T7BGS7BQD",
        ),
      );
      debugPrint("✅ Firebase configurato correttamente [DEFAULT]");
      debugPrint("ℹ️  Storage Bucket: ${Firebase.app().options.storageBucket}");
    } else {
      debugPrint("ℹ️  Firebase già inizializzato.");
    }
  } catch (e) {
    debugPrint("❌ Errore critico inizializzazione Firebase: $e.");
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Vacanze a PratoSpilla',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
        useMaterial3: true,
        fontFamily: 'Roboto',
      ),
      home: const HomePage(),
    );
  }
}
