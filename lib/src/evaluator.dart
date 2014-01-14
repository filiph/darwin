part of darwin;

// TODO: can be implemented as an Isolate
abstract class PhenotypeEvaluator<T extends Phenotype> {
  Object userData;
  Completer _completer;
  Future<num> evaluate(T phenotype);
  
  PrintFunction printf = print;
}

abstract class PhenotypeSerialEvaluator<T extends Phenotype> 
      extends PhenotypeEvaluator<T> {
  /**
   * Runs one of the experiments to be performed on the given [phenotype].
   * Should complete with the result of the [IterativeFitnessFunction], or with
   * [:null:] when there are no other experiments to run.
   */
  Future<num> runOneEvaluation(T phenotype, int experimentIndex);
  
  void _next(T phenotype, int experimentIndex) {
    runOneEvaluation(phenotype, experimentIndex)
    .then((num result) {
      if (result == null) {
        printf("Cummulative result for phenotype: $cummulativeResult");
        _completer.complete(cummulativeResult);
      } else if (result.isInfinite) {
        printf("Result for experiment #$experimentIndex: FAIL\nFailing phenotype");
        _completer.complete(double.INFINITY);
      } else {
        cummulativeResult += result;
        printf("Result for experiment: $result (cummulative: $cummulativeResult)");
        _next(phenotype, experimentIndex + 1);
      }
    });
  }
  
  num cummulativeResult;
  
  Future<num> evaluate(T phenotype) {
    printf("Evaluating $phenotype");
    cummulativeResult = 0;
    userData = null;
    _completer = new Completer();
    _next(phenotype, 0);
    return _completer.future;
  }
}