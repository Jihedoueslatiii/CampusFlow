import 'package:flutter/material.dart';
import 'package:compusflow/screens/wrapper.dart';
import 'package:intl/date_symbol_data_local.dart'; // Pour initializeDateFormatting
import 'package:intl/intl.dart';
import 'package:flutter_localizations/flutter_localizations.dart'; // Pour les délégués

// Rendre main asynchrone pour l'initialisation de la locale
void main() async {
  // Garantit que le binding des widgets est prêt
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Initialise les données de formatage pour la locale 'fr' (corrige LocaleDataException)
  await initializeDateFormatting('fr', null);

  // Définit la locale par défaut pour le package intl
  Intl.defaultLocale = 'fr_FR';

  runApp(const CompusFlowApp());
}

class CompusFlowApp extends StatelessWidget {
  const CompusFlowApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CompusFlow',
      theme: ThemeData(
        primarySwatch: Colors.indigo,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const Wrapper(),
      debugShowCheckedModeBanner: false,

      // 2. Ajout des délégués de localisation (corrige MaterialLocalizations not found)
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],

      // Définition explicite des locales supportées
      supportedLocales: const [
        Locale('fr', 'FR'),
        Locale('en', 'US'),
      ],
      // Forcer la locale française
      locale: const Locale('fr', 'FR'),
    );
  }
}