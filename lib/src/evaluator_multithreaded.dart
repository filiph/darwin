library darwin.evaluator.multithreaded;

import 'dart:async';

import 'package:darwin/src/evaluator.dart';
import 'package:darwin/src/phenotype.dart';
import 'package:darwin/isolate_worker.dart';
import 'package:meta/meta.dart';

/**
 * For use when multiple experiments should be done with each phenotype.
 */
@experimental
abstract class MultithreadedPhenotypeSerialEvaluator<T extends Phenotype>
    extends PhenotypeEvaluator<T> {
  final IsolateWorkerPool _pool;
  final TaskConstructor _taskConstructor;

  static const int BATCH_SIZE = 5;

  MultithreadedPhenotypeSerialEvaluator(this._taskConstructor)
      : _pool = new IsolateWorkerPool();

  @override
  Future init() async {
    await _pool.init();
  }

  @override
  void destroy() {
    _pool.destroy();
  }

  Future<num> evaluate(T phenotype) async {
    printf("Evaluating $phenotype");

    num cummulativeResult = 0;
    int offset = 0;

    while (true) {
      var futures = new List<Future>(BATCH_SIZE);
      for (int i = 0; i < BATCH_SIZE; i++) {
        IsolateTask task = _taskConstructor(phenotype, offset + i);
        futures[i] = _pool.send(task);
      }

      List results = await Future.wait(futures);
      print(results);
      cummulativeResult +=
          results.where((r) => r != null).fold(0, (a, b) => a + b);
      print(cummulativeResult);

      if (results.any((r) => r == null)) break;

      offset += BATCH_SIZE;
    }
    return cummulativeResult;
  }
}

typedef IsolateTask TaskConstructor(Phenotype phenotype, int experimentIndex);
