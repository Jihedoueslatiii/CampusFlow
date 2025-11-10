// lib/services/genetic_algorithm/population_manager.dart
import 'chromosome.dart';
import 'fitness_calculator.dart';
import 'ga_config.dart';
import 'dart:math';

class PopulationManager {
  final Random _random = Random();
  final List<Map<String, dynamic>> _matieres;

  PopulationManager(this._matieres);

  // Initialiser une population aléatoire
  List<Chromosome> initializePopulation() {
    final population = <Chromosome>[];

    for (int i = 0; i < GAConfig.populationSize; i++) {
      final chromosome = _createRandomChromosome();
      FitnessCalculator.calculateFitness(chromosome, _matieres);
      population.add(chromosome);
    }

    return population;
  }

  // Sélection par tournoi
  Chromosome tournamentSelection(List<Chromosome> population) {
    final tournament = <Chromosome>[];

    for (int i = 0; i < GAConfig.tournamentSize; i++) {
      tournament.add(population[_random.nextInt(population.length)]);
    }

    // Retourner le meilleur du tournoi
    tournament.sort((a, b) => b.fitness.compareTo(a.fitness));
    return Chromosome.copy(tournament.first);
  }

  // Croisement (crossover)
  List<Chromosome> crossover(Chromosome parent1, Chromosome parent2) {
    if (_random.nextDouble() > GAConfig.crossoverRate) {
      return [Chromosome.copy(parent1), Chromosome.copy(parent2)];
    }

    final child1 = Chromosome([]);
    final child2 = Chromosome([]);

    // Croisement à un point
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

  // Mutation - version corrigée
  void mutate(Chromosome chromosome) {
    for (int i = 0; i < chromosome.genes.length; i++) {
      if (_random.nextDouble() < GAConfig.mutationRate) {
        final originalGene = chromosome.genes[i];

        // Changer un aspect aléatoire du gène en créant un nouveau Gene
        final mutationType = _random.nextInt(3);
        Gene newGene;

        switch (mutationType) {
          case 0: // Changer le jour
            newGene = Gene(
              matiereId: originalGene.matiereId,
              matiereNom: originalGene.matiereNom,
              professeurId: originalGene.professeurId,
              professeurNom: originalGene.professeurNom,
              jour: GAConfig.jours[_random.nextInt(GAConfig.jours.length)],
              heureDebut: originalGene.heureDebut,
              heureFin: originalGene.heureFin,
              salle: originalGene.salle,
            );
            break;
          case 1: // Changer le créneau
            final creneau = GAConfig.creneaux[_random.nextInt(GAConfig.creneaux.length)];
            newGene = Gene(
              matiereId: originalGene.matiereId,
              matiereNom: originalGene.matiereNom,
              professeurId: originalGene.professeurId,
              professeurNom: originalGene.professeurNom,
              jour: originalGene.jour,
              heureDebut: creneau['debut']!,
              heureFin: creneau['fin']!,
              salle: originalGene.salle,
            );
            break;
          case 2: // Changer la salle
            newGene = Gene(
              matiereId: originalGene.matiereId,
              matiereNom: originalGene.matiereNom,
              professeurId: originalGene.professeurId,
              professeurNom: originalGene.professeurNom,
              jour: originalGene.jour,
              heureDebut: originalGene.heureDebut,
              heureFin: originalGene.heureFin,
              salle: GAConfig.salles[_random.nextInt(GAConfig.salles.length)],
            );
            break;
          default:
            newGene = Gene.copy(originalGene);
        }

        chromosome.genes[i] = newGene;
      }
    }
  }

  // Créer un chromosome aléatoire
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