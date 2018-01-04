library darwin.evaluator.multithreaded;

import 'dart:async';

import 'package:darwin/src/evaluator.dart';
import 'package:darwin/src/phenotype.dart';
import 'package:darwin/isolate_worker.dart';
import 'package:darwin/src/result.dart';
import 'package:meta/meta.dart';

/**
 * For use when multiple experiments should be done with each phenotype.
 */
@experimental
abstract class MultithreadedPhenotypeSerialEvaluator<P extends Phenotype<G, R>,
    G, R extends FitnessResult> extends PhenotypeEvaluator<P, G, R> {
  final IsolateWorkerPool _pool;
  final TaskConstructor _taskConstructor;
  final FitnessResultCombinator<R> _resultCombinator;
  final R _initialResult;

  static const int BATCH_SIZE = 5;

  MultithreadedPhenotypeSerialEvaluator(
      this._taskConstructor, this._resultCombinator, this._initialResult)
      : _pool = new IsolateWorkerPool();

  @override
  Future init() async {
    await _pool.init();
  }

  @override
  void destroy() {
    _pool.destroy();
  }

  Future<R> evaluate(P phenotype) async {
    printf("Evaluating $phenotype");

    R cumulativeResult = _initialResult;
    int offset = 0;

    while (true) {
      var futures = new List<Future>(BATCH_SIZE);
      for (int i = 0; i < BATCH_SIZE; i++) {
        IsolateTask task = _taskConstructor(phenotype, offset + i);
        futures[i] = _pool.send(task);
      }

      List<R> results = await Future.wait(futures);
      // print(results);
      for (final result in results) {
        if (result == null) continue;
        cumulativeResult = _resultCombinator(cumulativeResult, result);
      }
      // print(cumulativeResult);

      if (results.any((r) => r == null)) break;

      offset += BATCH_SIZE;
    }
    return cumulativeResult;
  }
}

typedef IsolateTask TaskConstructor<T>(T phenotype, int experimentIndex);
