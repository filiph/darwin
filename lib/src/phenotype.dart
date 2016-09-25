part of darwin;

/**
 * A phenotype (also called chromosome or genotype) is one particular solution
 * to the problem (equation). The solution is encoded in [genes].
 *
 * After being evaluated by an [Evaluator], the phenotypes [result] is filled
 * with the output of the fitness function. If niching is at play, the result
 * is then modified into [_resultWithFitnessSharingApplied].
 *
 * Phenotype can have genes of any type [T], although most often, [T] will be
 * either [bool] (binary genes) or [num] (continuous genes).
 *
 * Subclasses must define [mutateGene], which returns a gene mutated by a given
 * strength.
 */
abstract class Phenotype<T> {
  List<T> genes;
  num result = null;
  num _resultWithFitnessSharingApplied = null;

  T mutateGene(T gene, num strength);

  toString() => "Phenotype<$genesAsString>";

  String get genesAsString => JSON.encode(genes);
}
