import 'package:sqflite/sqflite.dart';
import '../models/emploi_temps_model.dart';
import 'database_service.dart';
import 'package:flutter/material.dart';
import 'dart:math';

// Configuration de l'algorithme génétique
class GAConfig {
  static const int populationSize = 80;
  static const int maxGenerations = 300;
  static const double crossoverRate = 0.8;
  static const double mutationRate = 0.15;
  static const int tournamentSize = 5;
  static const double elitismRate = 0.1;
  static const int stagnationLimit = 30;

  // Poids pour la fonction fitness
  static const double weightNoConflict = 25.0;
  static const double weightTeacherPref = 4.0;
  static const double weightRoomPref = 2.0;
  static const double weightBalancedDay = 3.0;
  static const double weightNoGaps = 1.5;

  static final List<String> jours = ['Lundi', 'Mardi', 'Mercredi', 'Jeudi', 'Vendredi'];
  static final List<Map<String, TimeOfDay>> creneaux = [
    {'debut': TimeOfDay(hour: 8, minute: 0), 'fin': TimeOfDay(hour: 10, minute: 0)},
    {'debut': TimeOfDay(hour: 10, minute: 15), 'fin': TimeOfDay(hour: 12, minute: 15)},
    {'debut': TimeOfDay(hour: 14, minute: 0), 'fin': TimeOfDay(hour: 16, minute: 0)},
    {'debut': TimeOfDay(hour: 16, minute: 15), 'fin': TimeOfDay(hour: 18, minute: 15)},
  ];
  static final List<String> salles = ['A101', 'A102', 'B201', 'B202', 'C301', 'C302'];
}

// Représentation d'un gène (cours placé) - Version MUTABLE pour l'algorithme génétique
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
}

// Chromosome = emploi du temps complet
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
}

// Calculateur de fitness
class FitnessCalculator {
  static double calculateFitness(Chromosome chromosome, List<Map<String, dynamic>> matieres) {
    double score = 100.0;

    // Contraintes CRITIQUES
    score -= _evaluateHardConflicts(chromosome);

    // Contraintes SOUPLES
    score += _evaluateSoftConstraints(chromosome);

    chromosome.fitness = score > 0 ? score : 0;
    return chromosome.fitness;
  }

  static double _evaluateHardConflicts(Chromosome chromosome) {
    double penalty = 0.0;
    final roomSchedule = <String, List<Gene>>{};
    final teacherSchedule = <int, List<Gene>>{};

    for (var gene in chromosome.genes) {
      // Conflits salle
      final roomKey = '${gene.jour}_${gene.salle}';
      if (!roomSchedule.containsKey(roomKey)) {
        roomSchedule[roomKey] = [];
      }
      for (var existingGene in roomSchedule[roomKey]!) {
        if (_timeOverlap(gene, existingGene)) {
          penalty += 15.0;
        }
      }
      roomSchedule[roomKey]!.add(gene);

      // Conflits professeur
      if (!teacherSchedule.containsKey(gene.professeurId)) {
        teacherSchedule[gene.professeurId] = [];
      }
      for (var existingGene in teacherSchedule[gene.professeurId]!) {
        if (gene.jour == existingGene.jour && _timeOverlap(gene, existingGene)) {
          penalty += 20.0;
        }
      }
      teacherSchedule[gene.professeurId]!.add(gene);
    }

    return penalty;
  }

  static double _evaluateSoftConstraints(Chromosome chromosome) {
    double bonus = 0.0;

    // Équilibre de charge quotidienne
    bonus += GAConfig.weightBalancedDay * _evaluateDailyBalance(chromosome);

    // Éviter les trous entre cours
    bonus += GAConfig.weightNoGaps * _evaluateNoGaps(chromosome);

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

    return 10.0 / (1.0 + variance);
  }

  static double _evaluateNoGaps(Chromosome chromosome) {
    double bonus = 0.0;
    final dailyGenes = <String, List<Gene>>{};

    for (var gene in chromosome.genes) {
      if (!dailyGenes.containsKey(gene.jour)) {
        dailyGenes[gene.jour] = [];
      }
      dailyGenes[gene.jour]!.add(gene);
    }

    for (var genes in dailyGenes.values) {
      genes.sort((a, b) {
        final debutA = a.heureDebut.hour * 60 + a.heureDebut.minute;
        final debutB = b.heureDebut.hour * 60 + b.heureDebut.minute;
        return debutA.compareTo(debutB);
      });

      for (int i = 0; i < genes.length - 1; i++) {
        final finCurrent = genes[i].heureFin.hour * 60 + genes[i].heureFin.minute;
        final debutNext = genes[i + 1].heureDebut.hour * 60 + genes[i + 1].heureDebut.minute;
        final gap = debutNext - finCurrent;

        if (gap > 0 && gap <= 60) {
          bonus += 0.5; // Petit trou acceptable
        }
      }
    }

    return bonus;
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

// Gestionnaire de population
class PopulationManager {
  final Random _random = Random();
  final List<Map<String, dynamic>> _matieres;

  PopulationManager(this._matieres);

  List<Chromosome> initializePopulation() {
    final population = <Chromosome>[];

    for (int i = 0; i < GAConfig.populationSize; i++) {
      final chromosome = _createRandomChromosome();
      FitnessCalculator.calculateFitness(chromosome, _matieres);
      population.add(chromosome);
    }

    return population;
  }

  Chromosome tournamentSelection(List<Chromosome> population) {
    final tournament = <Chromosome>[];

    for (int i = 0; i < GAConfig.tournamentSize; i++) {
      tournament.add(population[_random.nextInt(population.length)]);
    }

    tournament.sort((a, b) => b.fitness.compareTo(a.fitness));
    return Chromosome.copy(tournament.first);
  }

  List<Chromosome> crossover(Chromosome parent1, Chromosome parent2) {
    if (_random.nextDouble() > GAConfig.crossoverRate) {
      return [Chromosome.copy(parent1), Chromosome.copy(parent2)];
    }

    final child1 = Chromosome([]);
    final child2 = Chromosome([]);

    final crossoverPoint = _random.nextInt(parent1.genes.length);

    for (int i = 0; i < parent1.genes.length; i++) {
      if (i < crossoverPoint) {
        child1.genes.add(Gene.copy(parent1.genes[i]));
        child2.genes.add(Gene.copy(parent2.genes[i]));
      } else {
        child1.genes.add(Gene.copy(parent2.genes[i]));
        child2.genes.add(Gene.copy(parent1.genes[i]));
      }
    }

    return [child1, child2];
  }

  void mutate(Chromosome chromosome) {
    for (int i = 0; i < chromosome.genes.length; i++) {
      if (_random.nextDouble() < GAConfig.mutationRate) {
        final gene = chromosome.genes[i];
        final mutationType = _random.nextInt(3);

        switch (mutationType) {
          case 0:
            gene.jour = GAConfig.jours[_random.nextInt(GAConfig.jours.length)];
            break;
          case 1:
            final creneau = GAConfig.creneaux[_random.nextInt(GAConfig.creneaux.length)];
            gene.heureDebut = creneau['debut']!;
            gene.heureFin = creneau['fin']!;
            break;
          case 2:
            gene.salle = GAConfig.salles[_random.nextInt(GAConfig.salles.length)];
            break;
        }
      }
    }
  }

  Chromosome _createRandomChromosome() {
    final genes = <Gene>[];

    for (var matiere in _matieres) {
      final jour = GAConfig.jours[_random.nextInt(GAConfig.jours.length)];
      final creneau = GAConfig.creneaux[_random.nextInt(GAConfig.creneaux.length)];
      final salle = GAConfig.salles[_random.nextInt(GAConfig.salles.length)];

      final gene = Gene(
        matiereId: matiere['matiereId'],
        matiereNom: matiere['matiereNom'],
        professeurId: matiere['profId'],
        professeurNom: matiere['profNom'],
        jour: jour,
        heureDebut: creneau['debut']!,
        heureFin: creneau['fin']!,
        salle: salle,
      );

      genes.add(gene);
    }

    return Chromosome(genes);
  }
}

// Scheduler principal avec algorithme génétique
class GeneticScheduler {
  final List<Map<String, dynamic>> _matieres;
  final PopulationManager _populationManager;

  GeneticScheduler(this._matieres) : _populationManager = PopulationManager(_matieres);

  Future<Chromosome> generateSchedule() async {
    print('🧬 Début de la génération avec algorithme génétique...');
    print('📊 Nombre de matières: ${_matieres.length}');

    var population = _populationManager.initializePopulation();
    Chromosome bestSolution = Chromosome.copy(population.first);
    int stagnationCount = 0;

    for (int generation = 0; generation < GAConfig.maxGenerations; generation++) {
      // Évaluer la population
      for (var chromosome in population) {
        FitnessCalculator.calculateFitness(chromosome, _matieres);
      }

      population.sort((a, b) => b.fitness.compareTo(a.fitness));

      final currentBest = population.first;
      if (currentBest.fitness > bestSolution.fitness) {
        bestSolution = Chromosome.copy(currentBest);
        stagnationCount = 0;

        if (generation % 50 == 0) {
          print('🎯 Génération $generation - Meilleure fitness: ${bestSolution.fitness.toStringAsFixed(2)}');
        }
      } else {
        stagnationCount++;
      }

      if (stagnationCount >= GAConfig.stagnationLimit) {
        print('⏹️ Arrêt précoce à la génération $generation');
        break;
      }

      if (bestSolution.fitness >= 90.0) {
        print('✅ Solution optimale trouvée à la génération $generation');
        break;
      }

      population = _createNewGeneration(population);
    }

    bestSolution.sortGenes();
    print('🎉 Génération terminée - Fitness finale: ${bestSolution.fitness.toStringAsFixed(2)}');

    return bestSolution;
  }

  List<Chromosome> _createNewGeneration(List<Chromosome> oldPopulation) {
    final newPopulation = <Chromosome>[];

    // Élitisme
    final elitismCount = (GAConfig.populationSize * GAConfig.elitismRate).floor();
    for (int i = 0; i < elitismCount; i++) {
      newPopulation.add(Chromosome.copy(oldPopulation[i]));
    }

    // Remplir le reste
    while (newPopulation.length < GAConfig.populationSize) {
      final parent1 = _populationManager.tournamentSelection(oldPopulation);
      final parent2 = _populationManager.tournamentSelection(oldPopulation);

      final children = _populationManager.crossover(parent1, parent2);

      for (var child in children) {
        _populationManager.mutate(child);
        FitnessCalculator.calculateFitness(child, _matieres);
        newPopulation.add(child);

        if (newPopulation.length >= GAConfig.populationSize) break;
      }
    }

    return newPopulation;
  }
}

class EmploiTempsService {
  final DatabaseService _databaseService = DatabaseService();

  // Générer l'emploi du temps avec Algorithme Génétique
  Future<void> genererEmploiTempsIA(List<Map<String, dynamic>> matieresAvecProfs) async {
    final db = await _databaseService.database;
    final semaineNum = _getNumeroSemaine(DateTime.now());

    // Supprimer l'ancien emploi du temps de la semaine
    await db.delete(
      'emploi_temps',
      where: 'semaineNum = ?',
      whereArgs: [semaineNum],
    );

    print('🚀 Lancement de l\'algorithme génétique...');

    try {
      // Utiliser l'algorithme génétique
      final scheduler = GeneticScheduler(matieresAvecProfs);
      final bestSchedule = await scheduler.generateSchedule();

      // Sauvegarder dans la base de données
      for (final gene in bestSchedule.genes) {
        final emploi = EmploiTemps(
          matiereId: gene.matiereId,
          matiereNom: gene.matiereNom,
          jour: gene.jour,
          heureDebut: gene.heureDebut,
          heureFin: gene.heureFin,
          salle: gene.salle,
          professeurId: gene.professeurId,
          professeurNom: gene.professeurNom,
          semaineNum: semaineNum,
        );

        await db.insert('emploi_temps', emploi.toMap());
      }

      print('💾 Emploi du temps sauvegardé avec ${bestSchedule.genes.length} cours');
    } catch (e) {
      print('❌ Erreur lors de la génération: $e');
      // Fallback: utiliser l'ancienne méthode si l'IA échoue
      await _genererEmploiTempsFallback(matieresAvecProfs, db, semaineNum);
    }
  }

  // Méthode fallback (votre ancienne méthode)
  Future<void> _genererEmploiTempsFallback(
      List<Map<String, dynamic>> matieresAvecProfs,
      Database db,
      int semaineNum
      ) async {
    print('🔄 Utilisation de la méthode fallback...');

    final jours = ['Lundi', 'Mardi', 'Mercredi', 'Jeudi', 'Vendredi'];
    final creneaux = [
      {'debut': TimeOfDay(hour: 8, minute: 0), 'fin': TimeOfDay(hour: 10, minute: 0)},
      {'debut': TimeOfDay(hour: 10, minute: 15), 'fin': TimeOfDay(hour: 12, minute: 15)},
      {'debut': TimeOfDay(hour: 14, minute: 0), 'fin': TimeOfDay(hour: 16, minute: 0)},
      {'debut': TimeOfDay(hour: 16, minute: 15), 'fin': TimeOfDay(hour: 18, minute: 15)},
    ];
    final salles = ['A101', 'A102', 'B201', 'B202', 'C301', 'C302'];

    final emplois = <EmploiTemps>[];
    final sallesOccupees = <String, List<Map<String, dynamic>>>{};
    final profsOccupees = <int, List<Map<String, dynamic>>>{};

    final matieresMelangees = List.from(matieresAvecProfs)..shuffle();

    for (final matiere in matieresMelangees) {
      var placee = false;

      for (final jour in jours) {
        for (final creneau in creneaux) {
          for (final salle in salles) {
            final conflitSalle = _aConflitSalle(sallesOccupees, salle, jour, creneau);
            final conflitProf = _aConflitProf(profsOccupees, matiere['profId'], jour, creneau);

            if (!conflitSalle && !conflitProf) {
              final emploi = EmploiTemps(
                matiereId: matiere['matiereId'],
                matiereNom: matiere['matiereNom'],
                jour: jour,
                heureDebut: creneau['debut']!,
                heureFin: creneau['fin']!,
                salle: salle,
                professeurId: matiere['profId'],
                professeurNom: matiere['profNom'],
                semaineNum: semaineNum,
              );

              emplois.add(emploi);
              _ajouterOccupation(sallesOccupees, salle, jour, creneau);
              _ajouterOccupation(profsOccupees, matiere['profId'], jour, creneau);
              placee = true;
              break;
            }
          }
          if (placee) break;
        }
        if (placee) break;
      }
    }

    for (final emploi in emplois) {
      await db.insert('emploi_temps', emploi.toMap());
    }
  }

  bool _aConflitSalle(Map<String, List<Map<String, dynamic>>> occupations,
      String salle, String jour, Map<String, TimeOfDay> creneau) {
    if (!occupations.containsKey(salle)) return false;

    return occupations[salle]!.any((occ) {
      return occ['jour'] == jour && _creneauxSeChevauchent(occ['creneau'], creneau);
    });
  }

  bool _aConflitProf(Map<int, List<Map<String, dynamic>>> occupations,
      int profId, String jour, Map<String, TimeOfDay> creneau) {
    if (!occupations.containsKey(profId)) return false;

    return occupations[profId]!.any((occ) {
      return occ['jour'] == jour && _creneauxSeChevauchent(occ['creneau'], creneau);
    });
  }

  bool _creneauxSeChevauchent(Map<String, TimeOfDay> creneau1, Map<String, TimeOfDay> creneau2) {
    final debut1 = creneau1['debut']!.hour * 60 + creneau1['debut']!.minute;
    final fin1 = creneau1['fin']!.hour * 60 + creneau1['fin']!.minute;
    final debut2 = creneau2['debut']!.hour * 60 + creneau2['debut']!.minute;
    final fin2 = creneau2['fin']!.hour * 60 + creneau2['fin']!.minute;

    return (debut1 < fin2 && fin1 > debut2);
  }

  void _ajouterOccupation(Map<dynamic, List<Map<String, dynamic>>> occupations,
      dynamic key, String jour, Map<String, TimeOfDay> creneau) {
    if (!occupations.containsKey(key)) {
      occupations[key] = [];
    }
    occupations[key]!.add({'jour': jour, 'creneau': creneau});
  }

  int _getNumeroSemaine(DateTime date) {
    final firstJan = DateTime(date.year, 1, 1);
    final difference = date.difference(firstJan);
    return (difference.inDays / 7).floor() + 1;
  }

  // Récupérer l'emploi du temps d'un étudiant
  Future<List<EmploiTemps>> getEmploiTempsEtudiant(int etudiantId) async {
    final db = await _databaseService.database;
    final semaineNum = _getNumeroSemaine(DateTime.now());

    final List<Map<String, dynamic>> maps = await db.rawQuery('''
      SELECT et.* FROM emploi_temps et
      INNER JOIN etudiant_matieres em ON et.matiereId = em.matiere_id
      WHERE em.etudiant_id = ? AND et.semaineNum = ?
      ORDER BY 
        CASE et.jour
          WHEN 'Lundi' THEN 1
          WHEN 'Mardi' THEN 2
          WHEN 'Mercredi' THEN 3
          WHEN 'Jeudi' THEN 4
          WHEN 'Vendredi' THEN 5
          ELSE 6
        END,
        et.heureDebut
    ''', [etudiantId, semaineNum]);

    return List.generate(maps.length, (i) => EmploiTemps.fromMap(maps[i]));
  }

  // Récupérer l'emploi du temps d'un professeur
  Future<List<EmploiTemps>> getEmploiTempsProfesseur(int professeurId) async {
    final db = await _databaseService.database;
    final semaineNum = _getNumeroSemaine(DateTime.now());

    final List<Map<String, dynamic>> maps = await db.query(
      'emploi_temps',
      where: 'professeurId = ? AND semaineNum = ?',
      whereArgs: [professeurId, semaineNum],
      orderBy: 'jour, heureDebut',
    );

    return List.generate(maps.length, (i) => EmploiTemps.fromMap(maps[i]));
  }

  // Vérifier si un emploi du temps existe pour la semaine
  Future<bool> emploiTempsExistePourSemaine() async {
    final db = await _databaseService.database;
    final semaineNum = _getNumeroSemaine(DateTime.now());

    final List<Map<String, dynamic>> maps = await db.rawQuery('''
      SELECT COUNT(*) as count FROM emploi_temps 
      WHERE semaineNum = ?
    ''', [semaineNum]);

    return maps.first['count'] > 0;
  }
}