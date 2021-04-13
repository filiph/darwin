/// Allows for easy multithreading when you have computational tasks that
/// can be defined by a single method in a single extended class.
///
/// Example:
///
///     var pool = new IsolateWorkerPool();
///     await pool.init();
///     var tasks = [];
///     for (int i = 0; i < 1000; i++) {
///       tasks.add(new FibonacciTask(30));
///     }
///     var results = await pool.sendMany(tasks);
///     results.forEach(print);
///     pool.destroy();
///
/// In this case, the FibonacciTask can be defined thusly:
///
///     class FibonacciTask extends IsolateTask /*<int, int>*/ {
///       FibonacciTask(int payload) : super(payload);
///
///       @override
///       int execute(int payload) {
///         return fibonacci(payload);
///       }
///     }
library isolate_worker;

import 'dart:async';
import 'dart:math';
import 'dart:isolate';

/// Extend this class like so:
///
///     class FibonacciTask extends IsolateTask /*<int, int>*/ {
///       FibonacciTask(int payload) : super(payload);
///
///       @override
///       int execute(int payload) {
///         return fibonacci(payload);
///       }
///     }
abstract class IsolateTask<T, R> {
  static final Random _random = Random();
  final int id;
  R? result;

  static const int MAX_INT = (1 << 32) - 1;

  IsolateTask() : id = IsolateTask._random.nextInt(MAX_INT);

  R execute();
}

/// A single worker representing one [Isolate].
class IsolateWorker<T, R> {
  late ReceivePort receivePort;
  late SendPort _isolatePort;

  final Map<int, Completer> _completers = <int, Completer>{};
  int get queueLength => _completers.length;
  bool get isBusy => _completers.isNotEmpty;
  static const int MAX_QUEUE = 100;
  bool get isTooBusy => queueLength > MAX_QUEUE;
  late StreamSubscription _portSubscription;

  // Worker(ReceivePort receivePort) : receivePort = receivePort;
  IsolateWorker();

  Future<Null> init() async {
    if (_ready) return Future.value();
    var completer = Completer<Null>();

    receivePort = ReceivePort();
    await Isolate.spawn(_entryPoint, receivePort.sendPort);

    _portSubscription = receivePort.listen((Object? message) {
      if (message is SendPort) {
        _isolatePort = message;
        completer.complete();
      } else {
        var task = message as IsolateTask<T, R>;
        if (!_completers.containsKey(task.id)) {
          throw StateError('Task ${task.id} not present.');
        }
        _completers[task.id]?.complete(task.result);
        _completers.remove(task.id);
      }
    });
    return completer.future;
  }

  void destroy() {
    _portSubscription.cancel();
  }

  Future<R?> send(IsolateTask<T, R> task) {
    var completer = Completer<R?>();
    _completers[task.id] = completer;
    _isolatePort.send(task);
    return completer.future;
  }
}

/// A pool of workers.
///
/// It's recommended that [count] is less or equal to the number of CPU cores.
class IsolateWorkerPool<T, R> {
  final int count;
  late final List<IsolateWorker<T, R>> _workers;

  bool _initialized = false;

  IsolateWorkerPool({int count = 4}) : count = count;

  Future init() async {
    var futures =
        List<Future<IsolateWorker<T, R>>>.generate(count, (index) async {
      var worker = IsolateWorker<T, R>();
      await worker.init();
      return worker;
    });
    _workers = await Future.wait(futures);
    _initialized = true;
  }

  void destroy() {
    _workers.forEach((w) => w.destroy());
  }

  static final Random _random = Random();

  Future<R?> send(IsolateTask<T, R> task) async {
    if (!_initialized) {
      throw StateError('Must run init() first before using pool.');
    }
    var worker = _workers[_random.nextInt(count)];

    while (worker.isTooBusy) {
      await Future<Null>.delayed(const Duration(milliseconds: 10));
    }
    return worker.send(task);
  }

  Future<List<R?>> sendMany(List<IsolateTask<T, R>> tasks) async {
    List<Future<R?>?> futures = List<Future<R>?>.filled(tasks.length, null);
    var i = 0;

    // int done = 0;
    while (i < tasks.length) {
      var task = tasks[i];
      var j = 0;
      while (_workers[j].isTooBusy) {
        j++;
        if (j >= count) {
          await Future<Null>.delayed(const Duration(milliseconds: 10));
          j = 0;
        }
      }
      futures[i] = _workers[j].send(task);
      i++;
      j++;
    }

    return Future.wait(futures as Iterable<Future<R?>>);
  }
}

void _entryPoint(SendPort sendPort) {
  var port = ReceivePort();
  port.listen((dynamic message) {
    var task = message as IsolateTask;
    task.result = task.execute();
    sendPort.send(task);
  });
  sendPort.send(port.sendPort);
}
