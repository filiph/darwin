library darwin.evaluator;

import "dart:async";

import 'package:darwin/src/phenotype.dart';
import 'package:darwin/src/genetic_algorithm.dart';
import 'package:darwin/src/result.dart';

// TODO: can be implemented as an Isolate
abstract class PhenotypeEvaluator<P extends Phenotype<G, R>, G,
    R extends FitnessResult> {
  Object userData;
  Completer _completer;

  /**
   * Evaluate takes the phenotype and returns its fitness score. The lower the
   * fitness score, the better the phenotype. Fitness score of [:0.0:] means
   * that the phenotype is perfect.
   */
  Future<R> evaluate(P phenotype);

  /// Set automatically by [GeneticAlgorithm].
  PrintFunction printf = print;

  /// When evaluators need some work for initialization. By default,
  /// this just returns an immediate [Future].
  Future init() => new Future.value();

  /// When evaluators need to dispose of resources. By default, this does
  /// nothing.
  void destroy() {}
}

/**
 * For use when multiple experiments should be done with each phenotype.
 */
abstract class PhenotypeSerialEvaluator<P extends Phenotype<G, R>, G,
    R extends FitnessResult> extends PhenotypeEvaluator<P, G, R> {
  /**
   * Runs one of the experiments to be performed on the given [phenotype].
   * Should complete with the result of the [IterativeFitnessFunction], or with
   * [:null:] when there are no other experiments to run.
   */
  Future<num> runOneEvaluation(P phenotype, int experimentIndex);

  void _next(P phenotype, int experimentIndex) {
    runOneEvaluation(phenotype, experimentIndex).then((num result) {
      if (result == null) {
        printf("Cummulative result for phenotype: $cummulativeResult");
        _completer.complete(cummulativeResult);
      } else if (result.isInfinite) {
        printf(
            "Result for experiment #$experimentIndex: FAIL\nFailing phenotype");
        _completer.complete(double.INFINITY);
      } else {
        cummulativeResult += result;
        printf(
            "Result for experiment: $result (cummulative: $cummulativeResult)");
        _next(phenotype, experimentIndex + 1);
      }
    });
  }

  num cummulativeResult;

  Future<R> evaluate(P phenotype) {
    printf("Evaluating $phenotype");
    cummulativeResult = 0;
    userData = null;
    _completer = new Completer<R>();
    _next(phenotype, 0);
    return _completer.future;
  }
}
