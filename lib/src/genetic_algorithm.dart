library darwin.genetic_algorithm;

import 'dart:async';

import 'package:darwin/src/breeder.dart';
import 'package:darwin/src/evaluator.dart';
import 'package:darwin/src/generation.dart';
import 'package:darwin/src/phenotype.dart';
import 'package:darwin/src/result.dart';

class GeneticAlgorithm<P extends Phenotype<G, R>, G, R extends FitnessResult> {
  final int generationSize;
  int maxExperiments = 20000;

  /// When any [Phenotype] scores lower than this, the genetic algorithm
  /// has ended.
  R? thresholdResult;
  final int maxGenerationsInMemory = 100;

  int currentExperiment = 0;
  int currentGeneration = 0;

  Stream<Generation<P, G, R>> get onGenerationEvaluated =>
      _onGenerationEvaluatedController.stream;
  late StreamController<Generation<P, G, R>> _onGenerationEvaluatedController;

  final generations = <Generation<P, G, R>>[];
  Iterable<P> get population =>
      generations.expand((Generation<P, G, R> gen) => gen.members);
  final PhenotypeEvaluator<P, G, R> evaluator;
  final GenerationBreeder<P, G, R>? breeder;

  GeneticAlgorithm(
      Generation<P, G, R> firstGeneration, this.evaluator, this.breeder,
      {this.printf = print, this.statusf = print})
      : generationSize = firstGeneration.members.length {
    generations.add(firstGeneration);
    evaluator.printf = printf;

    _onGenerationEvaluatedController = StreamController<Generation<P, G, R>>();
  }

  Future<void> runUntilDone() async {
    await evaluator.init();

    while (true) {
      await _evaluateNextGeneration();

      if (currentExperiment >= maxExperiments) {
        printf('All experiments done ($currentExperiment)');
        break;
      }

      if (thresholdResult != null &&
          generations.last.members
              .any((P ph) => ph.result!.compareTo(thresholdResult!) < 0)) {
        printf('One of the phenotypes got over the threshold.');
        break;
      }

      _onGenerationEvaluatedController.add(generations.last);
      _createNewGeneration();
      currentGeneration++;
    }
    evaluator.destroy();
  }

  /// Function used for printing info about the progress of the genetic
  /// algorithm. This is the standard console [print] by default.
  final PrintFunction printf;

  /// Function used for showing status of the genetic algorithm, with the
  /// assumption that previous status text is rewritten by new status text.
  /// This is also initialized with [print] by default, but that's not
  /// the ideal implementation.
  final PrintFunction statusf;

  Future<void> _evaluateNextGeneration() async {
    await _runEvaluations();

    printf('Applying niching to results.');
    breeder!.applyFitnessSharingToResults(generations.last);
    printf('Generation #$currentGeneration evaluation done. Results:');
    printf('- ${generations.last.averageFitness!.toStringAsFixed(2)} AVG');
    printf('- ${generations.last.bestFitness!.toStringAsFixed(2)} BEST');
    statusf('''
GENERATION #$currentGeneration
AVG  ${generations.last.averageFitness!.toStringAsFixed(2)}
BEST ${generations.last.bestFitness!.toStringAsFixed(2)}
''');
    printf('---');
  }

  void _createNewGeneration() {
    printf('CREATING NEW GENERATION');
    generations.add(breeder!.breedNewGeneration(generations));
    printf('var newGen = [');
    for (var ph in generations.last.members) {
      printf('${ph.genesAsString},');
    }
    printf('];');
    while (generations.length > maxGenerationsInMemory) {
      printf('- exceeding max generations, removing one from memory');
      generations.removeAt(0);
    }
  }

  /// Pareto rank according to Konak 2006:
  /// http://www.eng.auburn.edu/sites/personal/aesmith/files/publications/journal/Multi-objective%20optimization%20using%20genetic%20algorithms.pdf
  void _assignParetoRanks() {
    // No need to do this for single-objective results.
    if (generations.last.members.first is SingleObjectiveResult) return;

    for (final ph in generations.last.members) {
      var rank = 1;
      for (final other in generations.last.members) {
        if (ph == other) continue;
        if (other.result!.dominates(ph.result!)) {
          rank += 1;
        }
      }
      ph.result!.paretoRank = rank;
    }
  }

  /// Evaluates the latest generation and completes when done.
  Future<void> _runEvaluations() async {
    for (final currentPhenotype in generations.last.members) {
      final result = await evaluator.evaluate(currentPhenotype);
      currentPhenotype.result = result;
      currentExperiment++;
    }

    _assignParetoRanks();
    generations.last.computeSummary();
  }
}

typedef PrintFunction = void Function(Object o);
