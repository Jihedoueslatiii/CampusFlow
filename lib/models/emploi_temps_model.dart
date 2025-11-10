import 'package:flutter/material.dart';

class EmploiTemps {
  int? id;
  int matiereId;
  String matiereNom;
  String jour; // 'Lundi', 'Mardi', etc.
  TimeOfDay heureDebut;
  TimeOfDay heureFin;
  String salle;
  int professeurId;
  String professeurNom;
  int semaineNum; // Numéro de semaine

  EmploiTemps({
    this.id,
    required this.matiereId,
    required this.matiereNom,
    required this.jour,
    required this.heureDebut,
    required this.heureFin,
    required this.salle,
    required this.professeurId,
    required this.professeurNom,
    required this.semaineNum,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'matiereId': matiereId,
      'matiereNom': matiereNom,
      'jour': jour,
      'heureDebut': '${heureDebut.hour}:${heureDebut.minute}',
      'heureFin': '${heureFin.hour}:${heureFin.minute}',
      'salle': salle,
      'professeurId': professeurId,
      'professeurNom': professeurNom,
      'semaineNum': semaineNum,
    };
  }

  factory EmploiTemps.fromMap(Map<String, dynamic> map) {
    final debutParts = (map['heureDebut'] as String).split(':');
    final finParts = (map['heureFin'] as String).split(':');

    return EmploiTemps(
      id: map['id'],
      matiereId: map['matiereId'],
      matiereNom: map['matiereNom'],
      jour: map['jour'],
      heureDebut: TimeOfDay(
        hour: int.parse(debutParts[0]),
        minute: int.parse(debutParts[1]),
      ),
      heureFin: TimeOfDay(
        hour: int.parse(finParts[0]),
        minute: int.parse(finParts[1]),
      ),
      salle: map['salle'],
      professeurId: map['professeurId'],
      professeurNom: map['professeurNom'],
      semaineNum: map['semaineNum'],
    );
  }

  String get duree {
    final debut = heureDebut.hour * 60 + heureDebut.minute;
    final fin = heureFin.hour * 60 + heureFin.minute;
    final totalMinutes = fin - debut;
    final hours = totalMinutes ~/ 60;
    final minutes = totalMinutes % 60;
    return '${hours}h${minutes > 0 ? '${minutes}min' : ''}';
  }
}