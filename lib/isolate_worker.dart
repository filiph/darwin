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
abstract class IsolateTask<T, S> {
  static final Random _random = new Random();
  final int id;
  S result;

  static const int MAX_INT = (1 << 32) - 1;

  IsolateTask() : id = IsolateTask._random.nextInt(MAX_INT);

  S execute();
}

/// A single worker representing one [Isolate].
class IsolateWorker {
  ReceivePort receivePort;
  SendPort _isolatePort;

  Map<int, Completer> _completers = new Map();
  int get queueLength => _completers.length;
  bool get isBusy => _completers.isNotEmpty;
  static const int MAX_QUEUE = 100;
  bool get isTooBusy => queueLength > MAX_QUEUE;
  bool _ready = false;
  StreamSubscription _portSubscription;

  // Worker(ReceivePort receivePort) : receivePort = receivePort;
  IsolateWorker() {}

  Future init() async {
    if (_ready) return new Future.value();
    var completer = new Completer();

    receivePort = new ReceivePort();
    await Isolate.spawn(_entryPoint, receivePort.sendPort);

    _portSubscription = receivePort.listen((message) {
      if (message is SendPort) {
        _isolatePort = message;
        completer.complete();
      } else {
        IsolateTask task = message as IsolateTask;
        if (!_completers.containsKey(task.id)) {
          throw new StateError("Task ${task.id} not present.");
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

  Future send(IsolateTask task) {
    var completer = new Completer();
    _completers[task.id] = completer;
    _isolatePort.send(task);
    return completer.future;
  }
}

/// A pool of workers.
///
/// It's recommended that [count] is less or equal to the number of CPU cores.
class IsolateWorkerPool {
  final int count;
  final List<IsolateWorker> _workers;

  bool _initialized = false;

  IsolateWorkerPool({int count: 4})
      : count = count,
        _workers = new List<IsolateWorker>(count);

  Future init() async {
    for (int i = 0; i < count; i++) {
      var worker = new IsolateWorker();
      await worker.init();
      _workers[i] = worker;
    }
    _initialized = true;
  }

  void destroy() {
    _workers.forEach((w) => w.destroy());
  }

  static final Random _random = new Random();

  Future send(IsolateTask task) async {
    if (!_initialized) {
      throw new StateError("Must run init() first before using pool.");
    }
    var worker = _workers[_random.nextInt(count)];

    while (worker.isTooBusy) {
      await new Future.delayed(const Duration(milliseconds: 10));
    }
    return worker.send(task);
  }

  Future<List> sendMany(List<IsolateTask> tasks) async {
    // return Future.wait(tasks.map((t) => send(t)));
    List<Future> futures = new List(tasks.length);
    int i = 0;

    // int done = 0;
    while (i < tasks.length) {
      var task = tasks[i];
      int j = 0;
      while (_workers[j].isTooBusy) {
        j++;
        if (j >= count) {
          await new Future.delayed(const Duration(milliseconds: 10));
          j = 0;
        }
      }
      futures[i] = _workers[j].send(task);
      i++;
      j++;
    }

    return Future.wait(futures);
  }
}

void _entryPoint(SendPort sendPort) {
  var port = new ReceivePort();
  port.listen((IsolateTask task) {
    task.result = task.execute();
    sendPort.send(task);
  });
  sendPort.send(port.sendPort);
}
