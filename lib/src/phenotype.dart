import 'dart:convert';

import 'package:meta/meta.dart';

import 'result.dart';

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
  late List<G> genes;

  /// This is populated later by the algorithm.
  @nonVirtual
  R? result;

  /// This is populated later by the algorithm if the evaluator applies
  /// fitness sharing.
  @nonVirtual
  num? resultWithFitnessSharingApplied;

  /// Takes [gene] and returns a new one, mutated by [strength].
  ///
  /// For example, if the phenotype is encoded by genes that are integers
  /// in the range `0` to `100`, and [gene] equals `50`, then:
  ///
  /// - If [strength] is `0.0` (minimum), then no mutation takes place, and
  ///   the returned value is `50`.
  /// - If [strength] is `1.0` (maximum), then the returned value should be
  ///   completely random and independent from the given [gene]. In our case,
  ///   the returned value will be anything between `0` and `100`.
  /// - If [strength] is anything between those values, the mutation should
  ///   interpolate between the two extremes. The returned value will be
  ///   _somewhat_ similar to the original [gene].
  ///
  /// By default, [GenerationBreeder] calls this method with [strength] of
  /// `1.0`. Unless you're doing something special, you may be able to ignore
  /// [strength] altogether and just return a random gene every time.
  G mutateGene(G gene, num strength);

  @override
  String toString() => 'Phenotype<$genesAsString>';

  String get genesAsString => json.encode(genes);

  @override
  int compareTo(Phenotype<G, R> other) => result!.compareTo(other.result!);

  /// Returns the degree to which this chromosome has dissimilar genes with the
  /// other. If chromosomes are identical, returns `0.0`. If all genes are
  /// different, returns `1.0`.
  ///
  /// Genes are considered different when they are not equal. There is no
  /// half-different gene (which would make sense for [num] genes, for example).
  /// You should make sure genes have sane equality and [hashCode].
  num computeHammingDistance(covariant Phenotype<G, R> other) {
    var length = genes.length;
    var similarCount = 0;
    for (var i = 0; i < genes.length; i++) {
      if (genes[i] == other.genes[i]) {
        similarCount++;
      }
    }
    return (1 - similarCount / length);
  }
}
