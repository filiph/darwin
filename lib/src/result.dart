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
    return evaluate()!.compareTo(other.evaluate()!);
  }

  /// A result dominates other results if it's better in every aspect.
  ///
  /// Subclasses are supposed to overload this method.
  bool dominates(covariant FitnessResult? other) {
    return false;
  }

  int paretoRank = 1;

  /// Evaluates to a single numeric value.
  double? evaluate();
}

/// A way to combine results.
typedef FitnessResultCombinator<T extends FitnessResult> = T Function(T a, T b);

class SingleObjectiveResult extends FitnessResult {
  double? value;

  @override
  int compareTo(covariant SingleObjectiveResult other) =>
      value!.compareTo(other.value!);

  @override
  double? evaluate() => value;
}

SingleObjectiveResult singleObjectiveResultCombinator(
    SingleObjectiveResult a, SingleObjectiveResult b) {
  final result = SingleObjectiveResult();
  result.value = a.value ?? 0.0 + (b.value ?? 0.0);
  return result;
}
