library darwin.breeder;

import 'dart:math' as math;

import 'package:darwin/src/phenotype.dart';
import 'package:darwin/src/generation.dart';
import 'package:darwin/src/result.dart';

class GenerationBreeder<P extends Phenotype<G, R>, G, R extends FitnessResult> {
  GenerationBreeder(P Function() createBlankPhenotype)
      : createBlankPhenotype = createBlankPhenotype;

  /// Function that generates blank (or random) phenotypes of type [P]. This
  /// needs to be provided because `new T();` can't be used.
  final P Function() createBlankPhenotype;

  num mutationRate =
      0.01; // 0.01 means that every gene has 1% probability of mutating
  num mutationStrength = 1.0; // 1.0 means any value can become any other value
  num crossoverPropability = 1.0;

  bool fitnessSharing = true;
  num fitnessSharingRadius = 0.1;
  num fitnessSharingAlpha = 1;

  /// Number of best phenotypes that are copied verbatim to next generation.
  int elitismCount = 1;

  Generation<P, G, R> breedNewGeneration(List<Generation<P, G, R>> precursors) {
    var newGen = Generation<P, G, R>();
    // TODO: allow for taking more than the very last generation?
    var pool = precursors.last.members.toList(growable: false);
    assert(pool.every((P ph) => ph.result != null));
    pool.sort((P a, P b) => (a.result!.compareTo(b.result!)));
    var length = precursors.last.members.length;

    // Elitism
    for (var i = 0; i < elitismCount; i++) {
      var clone1 = createBlankPhenotype();
      clone1.genes = pool[i].genes;
      newGen.members.add(clone1);
    }

    // Crossover breeding
    while (newGen.members.length < length) {
      var parent1 = getRandomTournamentWinner(pool);
      var parent2 = getRandomTournamentWinner(pool);
      var child1 = createBlankPhenotype();
      var child2 = createBlankPhenotype();
      var childrenGenes = crossoverParents(parent1, parent2,
          crossoverPointsCount: parent1.genes!.length ~/ 2);
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
        .forEach((P ph) => mutate(ph));
    return newGen;
  }

  /// Picks two phenotypes from the pool at random, compares them, and returns
  /// the one with the better fitness.
  ///
  /// TODO: add simulated annealing temperature (probability to pick the worse
  ///       individual) - but is it needed when we have niching?
  P getRandomTournamentWinner(List<P> pool) {
    var random = math.Random();
    var first = pool[random.nextInt(pool.length)];
    P second;
    while (true) {
      second = pool[random.nextInt(pool.length)];
      if (second != first) break;
    }
    assert(first.result != null);
    assert(second.result != null);

    if (first.result!.paretoRank < second.result!.paretoRank) {
      return first;
    } else if (first.result!.paretoRank > second.result!.paretoRank) {
      return second;
    }

    assert(!fitnessSharing || first.resultWithFitnessSharingApplied != null);
    assert(!fitnessSharing || second.resultWithFitnessSharingApplied != null);

    if (first.resultWithFitnessSharingApplied != null &&
        second.resultWithFitnessSharingApplied != null) {
      // Fitness sharing was applied. Compare those numbers.
      if (first.resultWithFitnessSharingApplied! <
          second.resultWithFitnessSharingApplied!) {
        return first;
      } else {
        return second;
      }
    }

    if (first.result!.compareTo(second.result!) < 0) {
      return first;
    } else {
      return second;
    }
  }

  void mutate(P phenotype, {num? mutationRate, num? mutationStrength}) {
    mutationRate ??= this.mutationRate;
    mutationStrength ??= this.mutationStrength;
    var random = math.Random();
    for (var i = 0; i < phenotype.genes!.length; i++) {
      if (random.nextDouble() < mutationRate) {
        phenotype.genes![i] =
            phenotype.mutateGene(phenotype.genes![i], mutationStrength);
      }
    }
  }

  /// Returns a [List] of length 2 (2 children), each having a List of genes
  /// created by crossing over parents' genes.
  ///
  /// The crossover only happens with [crossoverPropability]. Otherwise, exact
  /// copies of parents are returned.
  List<List<G>> crossoverParents(P a, P b, {int crossoverPointsCount = 2}) {
    var random = math.Random();

    if (random.nextDouble() < (1 - crossoverPropability)) {
      // No crossover. Return genes as they are.
      return [
        List.from(a.genes!, growable: false),
        List.from(b.genes!, growable: false)
      ];
    }

    assert(crossoverPointsCount < a.genes!.length - 1);
    var length = a.genes!.length;
    assert(length == b.genes!.length);
    var crossoverPoints = <int>{};

    // Genes:   0 1 2 3 4 5 6
    // Xpoints:  0 1 2 3 4 5
    while (crossoverPoints.length < crossoverPointsCount) {
      crossoverPoints.add(random.nextInt(length - 1));
    }
    var child1genes = List<G?>.filled(length, null);
    var child2genes = List<G?>.filled(length, null);
    var crossover = false;
    for (var i = 0; i < length; i++) {
      if (!crossover) {
        child1genes[i] = a.genes![i];
        child2genes[i] = b.genes![i];
      } else {
        child1genes[i] = b.genes![i];
        child2genes[i] = a.genes![i];
      }
      if (crossoverPoints.contains(i)) {
        crossover = !crossover;
      }
    }
    return [
      List<G>.from(child1genes, growable: false),
      List<G>.from(child2genes, growable: false)
    ];
  }

  /// Iterates over [members] and raises their fitness score according to
  /// their uniqueness.
  ///
  /// If [fitnessSharing] is [:false:], doesn't do anything.
  ///
  /// Algorithm as described in Jeffrey Horn: The Nature of Niching, pp 20-21.
  /// http://citeseerx.ist.psu.edu/viewdoc/download?doi=10.1.1.33.8352&rep=rep1&type=pdf
  void applyFitnessSharingToResults(Generation<P, G, R> generation) {
    if (fitnessSharing == false) return;

    for (final ph in generation.members) {
      final similars =
          generation.getSimilarPhenotypes(ph, fitnessSharingRadius);
      var nicheCount = 0.0;
      for (final other in similars) {
        // TODO: stop computing hamming distance twice (in getSimilarPhenotypes and here)
        final distance = ph.computeHammingDistance(other);
        nicheCount +=
            1 - math.pow(distance / fitnessSharingRadius, fitnessSharingAlpha);
      }
      // The algorithm is modified - we multiply the result instead of
      // dividing it. (Because we count 0.0 as perfect fitness. The smaller
      // the result number, the fitter the phenotype.)
      ph.resultWithFitnessSharingApplied = ph.result!.evaluate()! * nicheCount;
    }
  }
}
