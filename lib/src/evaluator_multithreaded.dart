library darwin.evaluator.multithreaded;

import 'dart:async';

import 'package:darwin/src/evaluator.dart';
import 'package:darwin/src/phenotype.dart';
import 'package:darwin/isolate_worker.dart';
import 'package:darwin/src/result.dart';
import 'package:meta/meta.dart';

/// For use when multiple experiments should be done with each phenotype.
@experimental
abstract class MultithreadedPhenotypeSerialEvaluator<P extends Phenotype<G, R>,
    G, R extends FitnessResult> extends PhenotypeEvaluator<P, G, R> {
  final IsolateWorkerPool<P, R> _pool;
  final TaskConstructor<P, R> _taskConstructor;
  final FitnessResultCombinator<R> _resultCombinator;
  final R _initialResult;

  static const int batchSize = 5;

  MultithreadedPhenotypeSerialEvaluator(
      this._taskConstructor, this._resultCombinator, this._initialResult)
      : _pool = IsolateWorkerPool<P, R>();

  @override
  Future init() async {
    await _pool.init();
  }

  @override
  void destroy() {
    _pool.destroy();
  }

  @override
  Future<R> evaluate(P phenotype) async {
    printf('Evaluating $phenotype');

    var cumulativeResult = _initialResult;
    var offset = 0;

    while (true) {
      var futures = List<Future<R?>>.generate(
        batchSize,
        (i) => _pool.send(_taskConstructor(phenotype, offset + i)),
      );

      var results = await Future.wait(futures);
      for (final result in results) {
        if (result == null) continue;
        cumulativeResult = _resultCombinator(cumulativeResult, result);
      }
      // print(cumulativeResult);

      if (results.any((r) => r == null)) break;

      offset += batchSize;
    }
    return cumulativeResult;
  }
}

typedef TaskConstructor<T, R> = IsolateTask<T, R> Function(
    T phenotype, int experimentIndex);
