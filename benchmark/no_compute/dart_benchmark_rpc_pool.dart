import 'dart:async';

import 'package:benchmark_harness/benchmark_harness.dart';
import 'package:isolate_rpc/isolate_rpc.dart';

import '../common.dart';

class IsolateRpcPoolNoComputeBenchmark extends AsyncBenchmarkBase with BenchmarkTask, BenchmarkCompute {
  @override
  final int numOfTasks;

  @override
  final int concurrency;

  static final poolSize = 4;

  IsolateRpcPoolNoComputeBenchmark({required this.numOfTasks, required this.concurrency})
      : super('IsolateRpcPoolNoComputeBenchmark(n=$numOfTasks,rps=$concurrency,poolSize=$poolSize)');

  late RpcService<void, bool> rpcExecutor;

  @override
  Future<void> setup() {
    rpcExecutor = IsolateRpc.pool(
        size: 1,
        processor: (_) async {
          return noCompute();
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
