import 'dart:async';

import 'package:benchmark_harness/benchmark_harness.dart';
import 'package:isolate_rpc/isolate_rpc.dart';

import '../common.dart';

class IsolateRpcNoComputeBenchmark extends AsyncBenchmarkBase with BenchmarkTask, BenchmarkCompute {
  @override
  final int numOfTasks;

  @override
  final int concurrency;

  IsolateRpcNoComputeBenchmark({required this.numOfTasks, required this.concurrency})
      : super('IsolateRpc,NoCompute(n=$numOfTasks,c=$concurrency)');

  late IsolateRpc<void, bool> rpc;

  @override
  Future<void> setup() {
    rpc = IsolateRpc.single(processor: (request) async {
      return noCompute();
    });
    return Future.value();
  }

  @override
  Future<void> teardown() async {
    return rpc.shutdown();
  }

  @override
  Future<void> exercise() => run();

  @override
  Future<void> run() async {
    return runTasks((i) => rpc.execute(null));
  }
}
