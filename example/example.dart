import 'dart:async';
import 'dart:math';

import 'package:darwin/darwin.dart';

Future<void> main() async {
  // Create first generation, either by random or by continuing with existing
  // progress.
  var firstGeneration = Generation<MyPhenotype, bool, SingleObjectiveResult>()
    ..members.addAll(List.generate(10, (_) => MyPhenotype.random()));

  // Evaluators take each phenotype and assign a fitness value to it according
  // to some fitness function.
  var evaluator = MyEvaluator();

  // Breeders are in charge of creating new generations from previous ones (that
  // have been graded by the evaluator). Their only required argument is
  // a function that returns a blank phenotype.
  var breeder = GenerationBreeder<MyPhenotype, bool, SingleObjectiveResult>(
      () => MyPhenotype())
    ..crossoverProbability = 0.8;

  var algo = GeneticAlgorithm<MyPhenotype, bool, SingleObjectiveResult>(
    firstGeneration,
    [evaluator],
    breeder,
  );

  // Start the algorithm.
  await algo.runUntilDone();

  // Print all members of the last generation when done.
  for (var ph in algo.generations.last.members) {
    print(ph.genesAsString);
  }
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
    genes = List.generate(geneCount, (index) => random.nextBool());
  }

  @override
  bool mutateGene(bool gene, num strength) {
    return !gene;
  }
}
