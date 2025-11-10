// lib/services/genetic_algorithm/chromosome.dart
import 'package:flutter/material.dart';
import 'ga_config.dart'; // Ajout de cet import

class Gene {
  int matiereId;
  String matiereNom;
  int professeurId;
  String professeurNom;
  String jour;
  TimeOfDay heureDebut;
  TimeOfDay heureFin;
  String salle;

  Gene({
    required this.matiereId,
    required this.matiereNom,
    required this.professeurId,
    required this.professeurNom,
    required this.jour,
    required this.heureDebut,
    required this.heureFin,
    required this.salle,
  });

  Gene.copy(Gene other)
      : matiereId = other.matiereId,
        matiereNom = other.matiereNom,
        professeurId = other.professeurId,
        professeurNom = other.professeurNom,
        jour = other.jour,
        heureDebut = other.heureDebut,
        heureFin = other.heureFin,
        salle = other.salle;

  Map<String, dynamic> toMap() {
    return {
      'matiereId': matiereId,
      'matiereNom': matiereNom,
      'professeurId': professeurId,
      'professeurNom': professeurNom,
      'jour': jour,
      'heureDebut': '${heureDebut.hour}:${heureDebut.minute}',
      'heureFin': '${heureFin.hour}:${heureFin.minute}',
      'salle': salle,
    };
  }

  @override
  String toString() {
    return '$matiereNom ($jour ${heureDebut.hour}:${heureDebut.minute} - $salle)';
  }
}

class Chromosome {
  List<Gene> genes;
  double fitness;

  Chromosome(this.genes, {this.fitness = 0.0});

  Chromosome.copy(Chromosome other)
      : genes = List<Gene>.from(other.genes.map((g) => Gene.copy(g))),
        fitness = other.fitness;

  void sortGenes() {
    genes.sort((a, b) {
      final jourOrder = GAConfig.jours.indexOf(a.jour).compareTo(GAConfig.jours.indexOf(b.jour));
      if (jourOrder != 0) return jourOrder;

      final debutA = a.heureDebut.hour * 60 + a.heureDebut.minute;
      final debutB = b.heureDebut.hour * 60 + b.heureDebut.minute;
      return debutA.compareTo(debutB);
    });
  }

  @override
  String toString() {
    return 'Chromosome(fitness: $fitness, genes: ${genes.length})';
  }
}