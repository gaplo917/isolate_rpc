import 'dart:async';
import 'dart:isolate';

import 'package:benchmark_harness/benchmark_harness.dart';

import '../common.dart';

class IsolateRunNoComputeBenchmark extends AsyncBenchmarkBase with BenchmarkTask, BenchmarkCompute {
  @override
  final int numOfTasks;

  @override
  final int concurrency;

  IsolateRunNoComputeBenchmark({required this.numOfTasks, required this.concurrency})
      : super('IsolateRun,NoCompute(n=$numOfTasks,c=$concurrency)');

  @override
  Future<void> exercise() => run();

  @override
  Future<void> run() async {
    return runTasks((i) => Isolate.run(() async {
          return noCompute();
        }));
  }
}
