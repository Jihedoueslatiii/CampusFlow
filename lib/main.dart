import 'package:flutter/material.dart';
import 'screens/home_page.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() {
  runApp(const CampusFlowApp());
}

class CampusFlowApp extends StatelessWidget {
  const CampusFlowApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Campus Flow',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
      home: const LocaleInitializer(),
    );
  }
}

class LocaleInitializer extends StatefulWidget {
  const LocaleInitializer({super.key});

  @override
  State<LocaleInitializer> createState() => _LocaleInitializerState();
}

class _LocaleInitializerState extends State<LocaleInitializer> {
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeLocales();
  }

  Future<void> _initializeLocales() async {
    try {
      await initializeDateFormatting('fr_FR', null);
      await initializeDateFormatting('en_US', null);
      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
      }
    } catch (e) {
      debugPrint('Error initializing locales: $e');
      if (mounted) {
        setState(() {
          _isInitialized = true; // Continue anyway
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }
    return const HomePage();
  }
}