// lib/services/genetic_algorithm/fitness_calculator.dart
import 'chromosome.dart';
import 'ga_config.dart';

class FitnessCalculator {
  static double calculateFitness(Chromosome chromosome, List<Map<String, dynamic>> matieres) {
    double score = 100.0; // Score de base

    // Contraintes CRITIQUES (fortes pénalités)
    score -= _evaluateHardConflicts(chromosome);

    // Contraintes SOUPLES (pénalités modérées)
    score += _evaluateSoftConstraints(chromosome, matieres);

    chromosome.fitness = score;
    return score;
  }

  static double _evaluateHardConflicts(Chromosome chromosome) {
    double penalty = 0.0;

    // Conflits salle
    penalty += _evaluateRoomConflicts(chromosome);

    // Conflits professeur
    penalty += _evaluateTeacherConflicts(chromosome);

    return penalty;
  }

  static double _evaluateRoomConflicts(Chromosome chromosome) {
    double penalty = 0.0;
    final roomSchedule = <String, List<Gene>>{};

    for (var gene in chromosome.genes) {
      final key = '${gene.jour}_${gene.salle}';
      if (!roomSchedule.containsKey(key)) {
        roomSchedule[key] = [];
      }

      for (var existingGene in roomSchedule[key]!) {
        if (_timeOverlap(gene, existingGene)) {
          penalty += 15.0; // Forte pénalité pour conflit salle
        }
      }
      roomSchedule[key]!.add(gene);
    }

    return penalty;
  }

  static double _evaluateTeacherConflicts(Chromosome chromosome) {
    double penalty = 0.0;
    final teacherSchedule = <int, List<Gene>>{};

    for (var gene in chromosome.genes) {
      if (!teacherSchedule.containsKey(gene.professeurId)) {
        teacherSchedule[gene.professeurId] = [];
      }

      for (var existingGene in teacherSchedule[gene.professeurId]!) {
        if (gene.jour == existingGene.jour && _timeOverlap(gene, existingGene)) {
          penalty += 20.0; // Très forte pénalité pour conflit professeur
        }
      }
      teacherSchedule[gene.professeurId]!.add(gene);
    }

    return penalty;
  }

  static double _evaluateSoftConstraints(Chromosome chromosome, List<Map<String, dynamic>> matieres) {
    double bonus = 0.0;

    // Bonus pour équilibre de charge quotidienne
    bonus += GAConfig.weightBalancedDay * _evaluateDailyBalance(chromosome);

    // Bonus pour éviter les trous entre cours
    bonus += GAConfig.weightNoGaps * _evaluateNoGaps(chromosome);

    // Bonus pour adéquation salle
    bonus += GAConfig.weightRoomPref * _evaluateRoomSuitability(chromosome);

    // Bonus pour préférences des professeurs
    bonus += GAConfig.weightTeacherPref * _evaluateTeacherPreferences(chromosome);

    return bonus;
  }

  static double _evaluateDailyBalance(Chromosome chromosome) {
    final dailyCount = <String, int>{};
    for (var gene in chromosome.genes) {
      dailyCount[gene.jour] = (dailyCount[gene.jour] ?? 0) + 1;
    }

    if (dailyCount.isEmpty) return 0.0;

    final average = chromosome.genes.length / dailyCount.length;
    double variance = 0.0;

    for (var count in dailyCount.values) {
      variance += (count - average) * (count - average);
    }

    // Plus la variance est faible, plus le bonus est élevé
    return 10.0 / (1.0 + variance);
  }

  static double _evaluateNoGaps(Chromosome chromosome) {
    double bonus = 0.0;
    final dailyGenes = <String, List<Gene>>{};

    // Grouper les gènes par jour
    for (var gene in chromosome.genes) {
      if (!dailyGenes.containsKey(gene.jour)) {
        dailyGenes[gene.jour] = [];
      }
      dailyGenes[gene.jour]!.add(gene);
    }

    // Pour chaque jour, calculer l'efficacité de l'emploi du temps
    for (var entry in dailyGenes.entries) {
      final genes = entry.value;
      genes.sort((a, b) {
        final debutA = a.heureDebut.hour * 60 + a.heureDebut.minute;
        final debutB = b.heureDebut.hour * 60 + b.heureDebut.minute;
        return debutA.compareTo(debutB);
      });

      // Calculer les trous entre cours
      double totalGap = 0.0;
      for (int i = 0; i < genes.length - 1; i++) {
        final finCurrent = genes[i].heureFin.hour * 60 + genes[i].heureFin.minute;
        final debutNext = genes[i + 1].heureDebut.hour * 60 + genes[i + 1].heureDebut.minute;
        final gap = debutNext - finCurrent;

        if (gap > 0 && gap <= 90) { // Trou raisonnable
          bonus += 0.5;
        } else if (gap > 90) { // Trou trop long
          bonus -= 0.2;
        }
      }
    }

    return bonus;
  }

  static double _evaluateRoomSuitability(Chromosome chromosome) {
    // Ici vous pourriez implémenter une logique d'adéquation salle/cours
    // Ex: salles spécialisées pour certains types de cours
    return 2.0; // Bonus de base
  }

  static double _evaluateTeacherPreferences(Chromosome chromosome) {
    // Ici vous pourriez implémenter les préférences des professeurs
    // Ex: certains préfèrent le matin, d'autres l'après-midi
    return 3.0; // Bonus de base
  }

  static bool _timeOverlap(Gene gene1, Gene gene2) {
    if (gene1.jour != gene2.jour) return false;

    final debut1 = gene1.heureDebut.hour * 60 + gene1.heureDebut.minute;
    final fin1 = gene1.heureFin.hour * 60 + gene1.heureFin.minute;
    final debut2 = gene2.heureDebut.hour * 60 + gene2.heureDebut.minute;
    final fin2 = gene2.heureFin.hour * 60 + gene2.heureFin.minute;

    return debut1 < fin2 && fin1 > debut2;
  }
}