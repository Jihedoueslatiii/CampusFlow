// models/feature.dart
import 'package:flutter/cupertino.dart';

enum FeaturePriority {
  critical,
  high,
  medium,
  low,
}

class AppFeature {
  final String id;
  final String title;
  final String description;
  final IconData icon;
  final String route;
  final FeaturePriority priority;
  final bool implemented;

  const AppFeature({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.route,
    required this.priority,
    this.implemented = false,
  });
}