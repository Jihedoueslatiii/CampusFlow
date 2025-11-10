import 'package:flutter/material.dart';
import 'package:compusflow/screens/wrapper.dart';

void main() {
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
      home: Wrapper(),
      debugShowCheckedModeBanner: false,
    );
  }
}