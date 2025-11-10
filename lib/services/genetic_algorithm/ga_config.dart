import 'package:flutter/material.dart';

class GAConfig {
  // Paramètres de l'algorithme génétique
  static const int populationSize = 100;
  static const int maxGenerations = 500;
  static const double crossoverRate = 0.85;
  static const double mutationRate = 0.15;
  static const int tournamentSize = 7;
  static const double elitismRate = 0.1;
  static const int stagnationLimit = 50;

  // Poids pour la fonction fitness
  static const double weightNoConflict = 20.0;
  static const double weightTeacherPref = 5.0;
  static const double weightRoomPref = 3.0;
  static const double weightBalancedDay = 4.0;
  static const double weightNoGaps = 2.0;
  static const double weightCurriculum = 3.0;

  // Configuration temporelle
  static final List<String> jours = ['Lundi', 'Mardi', 'Mercredi', 'Jeudi', 'Vendredi'];
  static final List<Map<String, TimeOfDay>> creneaux = [
    {'debut': TimeOfDay(hour: 8, minute: 0), 'fin': TimeOfDay(hour: 9, minute: 30)},
    {'debut': TimeOfDay(hour: 9, minute: 45), 'fin': TimeOfDay(hour: 11, minute: 15)},
    {'debut': TimeOfDay(hour: 11, minute: 30), 'fin': TimeOfDay(hour: 13, minute: 0)},
    {'debut': TimeOfDay(hour: 14, minute: 0), 'fin': TimeOfDay(hour: 15, minute: 30)},
    {'debut': TimeOfDay(hour: 15, minute: 45), 'fin': TimeOfDay(hour: 17, minute: 15)},
  ];

  static final List<String> salles = ['A101', 'A102', 'B201', 'B202', 'C301', 'C302'];
}