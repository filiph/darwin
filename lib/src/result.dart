import 'package:meta/meta.dart';

/// This is an encoding of a phenotype's fitness. In simple cases, you can
/// just use [SingleObjectiveResult], which is just a single [double],
/// essentially.
///
/// But many scenarios require multi-dimensional fitness results. For example,
/// a car can have various degrees of being comfortable, safe and fast.
/// When comparing two cars, you don't want to just average the three traits
/// into one. This is the idea behind Pareto fronts and
/// [Multi-objective optimization](https://en.wikipedia.org/wiki/Multi-objective_optimization).
abstract class FitnessResult implements Comparable<FitnessResult> {
  /// Fitness results compare according to their [paretoRank] first and
  /// then according to the result of [evaluate].
  ///
  /// Subclasses are free to override this when they need a more involved
  /// approach (but in general, they should keep the precedence of
  /// [paretoRank] to all else.
  @override
  int compareTo(FitnessResult other) {
    if (paretoRank != other.paretoRank) {
      return paretoRank.compareTo(other.paretoRank);
    }
    return evaluate().compareTo(other.evaluate());
  }

  /// A result dominates other results if it's better in every aspect.
  ///
  /// Subclasses are supposed to overload this method.
  bool dominates(covariant FitnessResult other);

  /// Pareto rank of the fitness result. This is computed and assigned
  /// in [GeneticAlgorithm._assignParetoRanks].
  @nonVirtual
  int paretoRank = 1;

  /// Evaluates to a single numeric value. This goes against
  /// the multi-dimensionality of this class, but it's sometimes useful.
  /// For example, fitness sharing needs it, and it's easier for printing
  /// to the user.
  double evaluate();
}

/// A way to combine results.
typedef FitnessResultCombinator<T extends FitnessResult> = T Function(T a, T b);

/// A subclass of [FitnessResult] that is just a single [value]
/// (of type [double]).
class SingleObjectiveResult extends FitnessResult {
  /// The actual value of the result. Following convention, the lower the value,
  /// the better the result.
  double value;

  SingleObjectiveResult(this.value);

  @override
  double evaluate() => value;

  @override
  bool dominates(SingleObjectiveResult other) {
    return value < other.value;
  }
}

SingleObjectiveResult singleObjectiveResultCombinator(
    SingleObjectiveResult a, SingleObjectiveResult b) {
  return SingleObjectiveResult(a.value + b.value);
}
