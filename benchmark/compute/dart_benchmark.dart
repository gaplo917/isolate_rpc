import 'dart:async';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:benchmark_harness/benchmark_harness.dart';

import '../common.dart';

class IsolateRunComputeBenchmark extends AsyncBenchmarkBase with BenchmarkTask, BenchmarkCompute {
  @override
  final int numOfTasks;

  @override
  final int concurrency;

  IsolateRunComputeBenchmark({required this.numOfTasks, required this.concurrency})
      : super('IsolateRunComputeBenchmark(n=$numOfTasks,rps=$concurrency)');

  @override
  Future<void> setup() {
    return Future.value();
  }

  @override
  Future<void> exercise() => run();

  @override
  Future<void> run() async {
    return runTasks((i) => Isolate.run(() async {
          return compute();
        }));
  }
}
