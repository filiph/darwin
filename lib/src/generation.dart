library darwin.generation;

import 'package:darwin/src/phenotype.dart';
import 'package:darwin/src/result.dart';

class Generation<P extends Phenotype<G, R>, G, R extends FitnessResult> {
  List<P> members = <P>[];

  /// Filters the generation to phenotypes that are similar to [ph] as defined
  /// by their Hamming distance being less than [radius].
  ///
  /// This _includes_ the original [ph] (Because [ph]'s Hamming distance to
  /// itself is [:0:].)
  Iterable<P> getSimilarPhenotypes(P ph, num radius) {
    return members
        .where((P candidate) => ph.computeHammingDistance(candidate) < radius);
  }

  num? cummulativeFitness;
  num? get averageFitness {
    if (cummulativeFitness == null) return null;
    return cummulativeFitness! / members.length;
  }

  num? bestFitness;

  /// Computes [cummulativeFitness] and [bestFitness], assuming all members of
  /// the population are scored.
  void computeSummary() {
    cummulativeFitness = 0;
    for (final ph in members) {
      final result = ph.result!.evaluate()!;
      cummulativeFitness = cummulativeFitness! + result;
      if (bestFitness == null || result.compareTo(bestFitness!) < 0) {
        bestFitness = result;
        best = ph;
      }
    }
  }

  P? best;
}
