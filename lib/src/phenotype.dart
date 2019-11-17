library darwin.phenotype;

import 'dart:convert';

import 'package:darwin/src/result.dart';

/// A phenotype (also called chromosome or genotype) is one particular solution
/// to the problem (equation). The solution is encoded in [genes].
///
/// After being evaluated by an [Evaluator], the phenotypes [result] is filled
/// with the output of the fitness function. If niching is at play, the result
/// is then modified into [resultWithFitnessSharingApplied].
///
/// Phenotype can have genes of any type [G], although most often, [G] will be
/// either [bool] (binary genes) or [num] (continuous genes).
///
/// Subclasses must define [mutateGene], which returns a gene mutated by a given
/// strength.
abstract class Phenotype<G, R extends FitnessResult>
    implements Comparable<Phenotype<G, R>> {
  List<G> genes;
  R result = null;
  num resultWithFitnessSharingApplied = null;

  G mutateGene(G gene, num strength);

  toString() => "Phenotype<$genesAsString>";

  String get genesAsString => json.encode(genes);

  int compareTo(Phenotype<G, R> other) => this.result.compareTo(other.result);

  /// Returns the degree to which this chromosome has dissimilar genes with the
  /// other. If chromosomes are identical, returns [:0.0:]. If all genes are
  /// different, returns [:1.0:].
  ///
  /// Genes are considered different when they are not equal. There is no
  /// half-different gene (which would make sense for [num] genes, for example).
  /// You should make sure genes have sane equality and [hashCode].
  num computeHammingDistance(covariant Phenotype<G, R> other) {
    int length = genes.length;
    int similarCount = 0;
    for (int i = 0; i < genes.length; i++) {
      if (genes[i] == other.genes[i]) {
        similarCount++;
      }
    }
    return (1 - similarCount / length);
  }
}
