library darwin.breeder;

import 'dart:math' as Math;

import 'package:darwin/src/phenotype.dart';
import 'package:darwin/src/generation.dart';

class GenerationBreeder<T extends Phenotype> {
  GenerationBreeder(T createBlankPhenotype())
      : createBlankPhenotype = createBlankPhenotype;

  /**
   * Function that generates blank (or random) phenotypes of type [T]. This
   * needs to be provided because `new T();` can't be used.
   */
  final Function createBlankPhenotype;

  num mutationRate =
      0.01; // 0.01 means that every gene has 1% probability of mutating
  num mutationStrength = 1.0; // 1.0 means any value can become any other value
  num crossoverPropability = 1.0;

  bool fitnessSharing = true;
  num fitnessSharingRadius = 0.1;
  num fitnessSharingAlpha = 1;

  /**
   * Number of best phenotypes that are copied verbatim to next generation.
   */
  int elitismCount = 1;

  Generation<T> breedNewGeneration(List<Generation> precursors) {
    Generation<T> newGen = new Generation<T>();
    // TODO: allow for taking more than the very last generation?
    List<T> pool = precursors.last.members.toList(growable: false);
    assert(pool.every((T ph) => ph.result != null));
    pool.sort((T a, T b) => (a.result - b.result).toInt());
    int length = precursors.last.members.length;

    // Elitism
    for (int i = 0; i < elitismCount; i++) {
      T clone1 = createBlankPhenotype();
      clone1.genes = pool.first.genes;
      newGen.members.add(clone1);
    }

    // Crossover breeding
    while (newGen.members.length < length) {
      T parent1 = getRandomTournamentWinner(pool);
      T parent2 = getRandomTournamentWinner(pool);
      T child1 = createBlankPhenotype();
      T child2 = createBlankPhenotype();
      List<List<bool>> childrenGenes = crossoverParents(parent1, parent2,
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
    newGen.members
        .skip(elitismCount) // Do not mutate elite.
        .forEach((T ph) => mutate(ph));
    return newGen;
  }

  /**
   * Picks two phenotypes from the pool at random, compares them, and returns
   * the one with the better fitness.
   */
  T getRandomTournamentWinner(List<T> pool) {
    Math.Random random = new Math.Random();
    T first = pool[random.nextInt(pool.length)];
    T second;
    while (true) {
      second = pool[random.nextInt(pool.length)];
      if (second != first) break;
    }
    assert(first.result != null);
    assert(second.result != null);

    if (first.resultWithFitnessSharingApplied != null &&
        second.resultWithFitnessSharingApplied != null) {
      // Fitness sharing was applied. Compare those numbers.
      if (first.resultWithFitnessSharingApplied <
          second.resultWithFitnessSharingApplied) {
        return first;
      } else {
        return second;
      }
    }

    if (first.result < second.result) {
      return first;
    } else {
      return second;
    }
  }

  void mutate(T phenotype, {num mutationRate, num mutationStrength}) {
    if (mutationRate == null) mutationRate = this.mutationRate;
    if (mutationStrength == null) mutationStrength = this.mutationStrength;
    Math.Random random = new Math.Random();
    for (int i = 0; i < phenotype.genes.length; i++) {
      if (random.nextDouble() < mutationRate) {
        phenotype.genes[i] =
            phenotype.mutateGene(phenotype.genes[i], mutationStrength);
      }
    }
  }

  /**
   * Returns a [List] of length 2 (2 children), each having a List of genes
   * created by crossing over parents' genes.
   *
   * The crossover only happens with [crossoverPropability]. Otherwise, exact
   * copies of parents are returned.
   */
  List<List<Object>> crossoverParents(T a, T b, {int crossoverPointsCount: 2}) {
    Math.Random random = new Math.Random();

    if (random.nextDouble() < (1 - crossoverPropability)) {
      // No crossover. Return genes as they are.
      return [
        new List.from(a.genes, growable: false),
        new List.from(b.genes, growable: false)
      ];
    }

    assert(crossoverPointsCount < a.genes.length - 1);
    int length = a.genes.length;
    assert(length == b.genes.length);
    Set<int> crossoverPoints = new Set<int>();

    // Genes:   0 1 2 3 4 5 6
    // Xpoints:  0 1 2 3 4 5
    while (crossoverPoints.length < crossoverPointsCount) {
      crossoverPoints.add(random.nextInt(length - 1));
    }
    List<Object> child1genes = new List(length);
    List<Object> child2genes = new List(length);
    bool crossover = false;
    for (int i = 0; i < length; i++) {
      if (!crossover) {
        child1genes[i] = a.genes[i];
        child2genes[i] = b.genes[i];
      } else {
        child1genes[i] = b.genes[i];
        child2genes[i] = a.genes[i];
      }
      if (crossoverPoints.contains(i)) {
        crossover = !crossover;
      }
    }
    return [child1genes, child2genes];
  }

  /**
   * Iterates over [members] and raises their fitness score according to
   * their uniqueness.
   *
   * If [fitnessSharing] is [:false:], doesn't do anything.
   *
   * Algorithm as described in Jeffrey Horn: The Nature of Niching, pp 20-21.
   * http://citeseerx.ist.psu.edu/viewdoc/download?doi=10.1.1.33.8352&rep=rep1&type=pdf
   */
  void applyFitnessSharingToResults(Generation<T> generation) {
    if (fitnessSharing == false) return;

    generation.members.forEach((T ph) {
      num nicheCount = generation
          .getSimilarPhenotypes(ph, fitnessSharingRadius)
          .map((T other) => ph.computeHammingDistance(
              other)) // XXX: computing hamming distance twice (in getSimilarPhenotypes and here)
          .fold(
              0,
              (num sum, num distance) => sum +
                  (1 -
                      Math.pow(distance / fitnessSharingRadius,
                          fitnessSharingAlpha)));
      // The algorithm is modified - we multiply the result instead of
      // dividing it. (Because we count 0.0 as perfect fitness. The smaller
      // the result number, the fitter the phenotype.)
      ph.resultWithFitnessSharingApplied = ph.result * nicheCount;
    });
  }
}
