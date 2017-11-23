import "dart:math";

import "package:darwin/darwin.dart";
import 'package:darwin/isolate_worker.dart';
import 'package:darwin/src/evaluator_multithreaded.dart';
import "package:test/test.dart";

void main() {
  Generation<MyPhenotype> firstGeneration;
  MyEvaluator evaluator;
  GenerationBreeder breeder;
  GeneticAlgorithm algo;

  group("Multithreaded algo", () {
    // Set up the variables.
    setUp(() {
      // Create first generation.
      firstGeneration = new Generation<MyPhenotype>();

      // Fill it with random phenotypes.
      while (firstGeneration.members.length < 10) {
        var member = new MyPhenotype.Random();
        // Guard against a winning phenotype in first generation.
        if (member.genes.any((gene) => gene == false)) {
          firstGeneration.members.add(member);
        }
      }

      // Evaluators take each phenotype and assign a fitness value to it according
      // to some fitness function.
      evaluator = new MyEvaluator((ph, i) => new MyIsolateTask(ph, i));

      // Breeders are in charge of creating new generations from previous ones (that
      // have been graded by the evaluator).
      breeder = new GenerationBreeder(() => new MyPhenotype())
        ..crossoverPropability = 0.8;

      algo = new GeneticAlgorithm(firstGeneration, evaluator, breeder);
    });

    test("terminates", () async {
      // Start the algorithm.
      await algo.runUntilDone();
      expect(algo.currentGeneration, greaterThan(0));
    });

    test("converges to better fitness", () async {
      // Start the algorithm.
      await algo.runUntilDone();
      // Remember, lower fitness result is better.
      expect(algo.generations.first.bestFitness,
          greaterThanOrEqualTo(algo.generations.last.bestFitness));
    });

    test("works without fitness sharing", () async {
      breeder.fitnessSharing = false;
      // Start the algorithm.
      await algo.runUntilDone();
      // Remember, lower fitness result is better.
      expect(algo.generations.first.bestFitness,
          greaterThanOrEqualTo(algo.generations.last.bestFitness));
    });

    test("works without elitism", () async {
      breeder.elitismCount = 0;
      // Start the algorithm.
      await algo.runUntilDone();
      // Remember, lower fitness result is better.
      expect(algo.generations.first.bestFitness,
          greaterThanOrEqualTo(algo.generations.last.bestFitness));
    });

    test("onGenerationEvaluatedController works", () async {
      // Register the hook;
      algo.onGenerationEvaluated.listen((Generation g) {
        expect(g.averageFitness, isNotNull);
        expect(g.best, isNotNull);
      });

      // Start the algorithm.
      algo.runUntilDone();
    });

    test("Generation.best is assigned to last generation after done", () async {
      // Start the algorithm.
      await algo.runUntilDone();
      expect(algo.generations.last.best, isNotNull);
    });
  });
}

Random random = new Random();

class MyEvaluator extends MultithreadedPhenotypeSerialEvaluator<MyPhenotype> {
  MyEvaluator(TaskConstructor taskConstructor) : super(taskConstructor);
}

class MyIsolateTask extends IsolateTask {
  final MyPhenotype phenotype;
  final int experimentIndex;
  MyIsolateTask(this.phenotype, this.experimentIndex);

  execute() {
    if (experimentIndex > 10) return null;
    return phenotype.genes.where((bool v) => v == false).length;
  }
}

class MyPhenotype extends Phenotype<bool> {
  static int geneCount = 6;

  MyPhenotype();

  MyPhenotype.Random() {
    genes = new List<bool>(geneCount);
    for (int i = 0; i < geneCount; i++) {
      genes[i] = random.nextBool();
    }
  }

  bool mutateGene(bool gene, num strength) {
    return !gene;
  }
}
