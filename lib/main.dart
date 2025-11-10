import 'package:flutter/material.dart';
import 'package:compusflow/screens/wrapper.dart';
import 'package:compusflow/services/database_service.dart';
import 'package:compusflow/services//ai_ticket_service.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  _initializeApp();
  AITicketService.enableTestMode();
  print('AI TICKET TEST MODE ENABLED - Using simulated AI responses');
  runApp(const CompusFlowApp());
}

// NEW: Initialize database
void _initializeApp() async {
  final databaseService = DatabaseService();
  // This will trigger database creation/upgrade
  await databaseService.database;
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
      home: Wrapper(),
      debugShowCheckedModeBanner: false,
    );
  }
}