import 'package:test/test.dart';
import 'package:darwin/darwin.dart';
import 'dart:math';
import 'dart:async';

void main() {
  Generation<MyPhenotype, bool, SingleObjectiveResult> firstGeneration;
  MyEvaluator evaluator;
  GenerationBreeder<MyPhenotype, bool, SingleObjectiveResult>? breeder;
  late GeneticAlgorithm algo;

  group('Genetic algorithm', () {
    // Set up the variables.
    setUp(() {
      // Create first generation.
      firstGeneration = Generation<MyPhenotype, bool, SingleObjectiveResult>();

      // Fill it with random phenotypes.
      while (firstGeneration.members.length < 10) {
        var member = MyPhenotype.random();
        // Guard against a winning phenotype in first generation.
        if (member.genes.any((gene) => gene == false)) {
          firstGeneration.members.add(member);
        }
      }

      // Evaluators take each phenotype and assign a fitness value to it according
      // to some fitness function.
      evaluator = MyEvaluator();

      // Breeders are in charge of creating new generations from previous ones (that
      // have been graded by the evaluator).
      breeder = GenerationBreeder<MyPhenotype, bool, SingleObjectiveResult>(
          () => MyPhenotype())
        ..crossoverProbability = 0.8;

      algo = GeneticAlgorithm<MyPhenotype, bool, SingleObjectiveResult>(
          firstGeneration, evaluator, breeder, printf: (_) {
        return;
      }, statusf: (_) {
        return;
      });
    });

    test('terminates', () async {
      // Start the algorithm.
      await algo.runUntilDone();
      expect(algo.currentGeneration, greaterThan(0));
    });

    test('converges to better fitness', () async {
      // Start the algorithm.
      await algo.runUntilDone();
      // Remember, lower fitness result is better.
      expect(algo.generations.first.bestFitness,
          greaterThanOrEqualTo(algo.generations.last.bestFitness!));
    });

    test('works without fitness sharing', () async {
      breeder!.fitnessSharing = false;
      // Start the algorithm.
      await algo.runUntilDone();
      // Remember, lower fitness result is better.
      expect(algo.generations.first.bestFitness,
          greaterThanOrEqualTo(algo.generations.last.bestFitness!));
    });

    test('works without elitism', () async {
      breeder!.elitismCount = 0;
      // Start the algorithm.
      await algo.runUntilDone();
      // Remember, lower fitness result is better.
      expect(algo.generations.first.bestFitness,
          greaterThanOrEqualTo(algo.generations.last.bestFitness!));
    });

    test('onGenerationEvaluatedController works', () async {
      // Register the hook;
      algo.onGenerationEvaluated.listen((Generation g) {
        expect(g.averageFitness, isNotNull);
        expect(g.best, isNotNull);
      });

      // Start the algorithm.
      await algo.runUntilDone();
    });

    test('Generation.best is assigned to last generation after done', () async {
      // Start the algorithm.
      await algo.runUntilDone();
      expect(algo.generations.last.best, isNotNull);
    });
  });
}

Random random = Random();

class MyEvaluator
    extends PhenotypeEvaluator<MyPhenotype, bool, SingleObjectiveResult> {
  @override
  Future<SingleObjectiveResult> evaluate(MyPhenotype phenotype) {
    // This implementation just counts false values - the more false values,
    // the worse outcome of the fitness function.
    final result = SingleObjectiveResult(
        phenotype.genes.where((bool v) => v == false).length.toDouble());
    return Future.value(result);
  }
}

class MyPhenotype extends Phenotype<bool, SingleObjectiveResult> {
  static int geneCount = 6;

  MyPhenotype();

  MyPhenotype.random() {
    genes = List<bool>.generate(geneCount, (index) => random.nextBool());
  }

  @override
  bool mutateGene(bool gene, num strength) {
    return !gene;
  }
}
