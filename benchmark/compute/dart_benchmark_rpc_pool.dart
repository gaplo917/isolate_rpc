import 'dart:async';
import 'dart:io';

import 'package:benchmark_harness/benchmark_harness.dart';
import 'package:isolate_rpc/isolate_rpc.dart';

import '../common.dart';

class IsolateRpcPoolComputeBenchmark extends AsyncBenchmarkBase
    with BenchmarkTask, BenchmarkCompute, BenchmarkImageBinary {
  @override
  final int numOfTasks;

  @override
  final int concurrency;

  static final poolSize = Platform.numberOfProcessors;

  IsolateRpcPoolComputeBenchmark({required this.numOfTasks, required this.concurrency})
      : super('IsolateRpcPool,Compute(n=$numOfTasks,c=$concurrency,poolSize=$poolSize)');

  late IsolateRpc rpcExecutor;

  @override
  Future<void> setup() {
    rpcExecutor = IsolateRpc.pool(
        size: poolSize,
        processor: (_) async {
          return compute();
        });
    return Future.value();
  }

  @override
  Future<void> teardown() async {
    await rpcExecutor.shutdown();
  }

  @override
  Future<void> exercise() => run();

  @override
  Future<void> run() async {
    return runTasks((i) => rpcExecutor.execute(null));
  }
}
