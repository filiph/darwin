import "package:unittest/unittest.dart";
import "package:darwin/darwin.dart";
import "dart:math";
import "dart:async";

void main() {
  Generation<MyPhenotype> firstGeneration;
  MyEvaluator evaluator;
  MyGenerationBreeder breeder;
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
      breeder = new MyGenerationBreeder()
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

class MyGenerationBreeder extends GenerationBreeder<MyPhenotype> {
  Generation<MyPhenotype> breedNewGeneration(List<Generation> precursors) {
    Generation<MyPhenotype> newGen = new Generation<MyPhenotype>();
    List<MyPhenotype> pool = precursors.last.members.toList(growable: false);
    pool.sort((MyPhenotype a, MyPhenotype b) => a.result - b.result);
    int length = precursors.last.members.length;
    // Elitism
    MyPhenotype clone1 = new MyPhenotype();
    clone1.genes = pool.first.genes;
    newGen.members.add(clone1);
    // Crossover breeding
    while (newGen.members.length < length) {
      MyPhenotype parent1 = getRandomTournamentWinner(pool);
      MyPhenotype parent2 = getRandomTournamentWinner(pool);
      MyPhenotype child1 = new MyPhenotype();
      MyPhenotype child2 = new MyPhenotype();
      List<List<bool>> childrenGenes = 
          crossoverParents(parent1, parent2, 
              crossoverPointsCount: parent1.genes.length ~/ 2);
      child1.genes = childrenGenes[0];
      child2.genes = childrenGenes[1];
      newGen.members.add(child1);
      newGen.members.add(child2);
    }
    // Remove the phenotypes over length.
    while (newGen.members.length > length) {
      newGen.members.removeLast();
    }
    newGen.members.skip(1)  // Do not mutate elite.
      .forEach((MyPhenotype ph) => mutate(ph));
    return newGen;
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