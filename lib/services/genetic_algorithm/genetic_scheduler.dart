// lib/services/genetic_algorithm/genetic_scheduler.dart
import 'chromosome.dart';
import 'population_manager.dart';
import 'fitness_calculator.dart';
import 'ga_config.dart';

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

      // Trier par fitness
      population.sort((a, b) => b.fitness.compareTo(a.fitness));

      // Mettre à jour la meilleure solution
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

      // Vérifier la condition d'arrêt
      if (stagnationCount >= GAConfig.stagnationLimit) {
        print('⏹️ Arrêt précoce à la génération $generation (stagnation)');
        break;
      }

      if (bestSolution.fitness >= 95.0) {
        print('✅ Solution optimale trouvée à la génération $generation');
        break;
      }

      // Créer la nouvelle génération
      population = _createNewGeneration(population);
    }

    bestSolution.sortGenes();
    print('🎉 Génération terminée - Fitness finale: ${bestSolution.fitness.toStringAsFixed(2)}');

    return bestSolution;
  }

  List<Chromosome> _createNewGeneration(List<Chromosome> oldPopulation) {
    final newPopulation = <Chromosome>[];

    // Élitisme - garder les meilleurs
    final elitismCount = (GAConfig.populationSize * GAConfig.elitismRate).floor();
    for (int i = 0; i < elitismCount; i++) {
      newPopulation.add(Chromosome.copy(oldPopulation[i]));
    }

    // Remplir le reste de la population
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