import "package:unittest/unittest.dart";
import "package:darwin/darwin.dart";
import "dart:math";
import "dart:async";

void main() {
  Generation<MyPhenotype> firstGeneration;
  MyEvaluator evaluator;
  GenerationBreeder breeder;
  GeneticAlgorithm algo;
  
  group("Genetic algorithm", () {
    
    // Set up the variables.
    setUp(() {
      // Create first generation.
      firstGeneration = new Generation<MyPhenotype>();
      
      // Fill it with random phenotypes.
      for (int i = 0; i < 10; i++) {
        firstGeneration.members.add(new MyPhenotype.Random());
      }
      
      // Evaluators take each phenotype and assign a fitness value to it according
      // to some fitness function.
      evaluator = new MyEvaluator();
      
      // Breeders are in charge of creating new generations from previous ones (that
      // have been graded by the evaluator). 
      breeder = new GenerationBreeder(() => new MyPhenotype())
        ..crossoverPropability = 0.8;
      
      algo = new GeneticAlgorithm(firstGeneration, evaluator, breeder);
    });
    
    test("terminates", () {
      // Start the algorithm.
      algo.runUntilDone()
        .then(expectAsync1((_) {
          expect(algo.currentGeneration, greaterThan(0));
        }));
    });
    
    test("converges to better fitness", () {
      // Start the algorithm.
      algo.runUntilDone()
        .then(expectAsync1((_) {
          // Remember, lower fitness result is better.
          expect(algo.generations.first.bestFitness,
              greaterThan(algo.generations.last.bestFitness));
        }));
    });
    
    test("works without fitness sharing", () {
      breeder.fitnessSharing = false;
      // Start the algorithm.
      algo.runUntilDone()
        .then(expectAsync1((_) {
          // Remember, lower fitness result is better.
          expect(algo.generations.first.bestFitness,
              greaterThan(algo.generations.last.bestFitness));
        }));
    });
  });
}

Random random = new Random(); 

class MyEvaluator extends PhenotypeEvaluator<MyPhenotype> {
  Future<num> evaluate(MyPhenotype phenotype) {
    // This implementation just counts false values - the more false values,
    // the worse outcome of the fitness function.
    return new Future.value(
        phenotype.genes.where((bool v) => v == false).length);
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