import 'dart:async';
import 'dart:typed_data';

import 'package:benchmark_harness/benchmark_harness.dart';
import 'package:isolate_rpc/isolate_rpc.dart';

import '../common.dart';

class IsolateRpcNoComputeBenchmark extends AsyncBenchmarkBase with BenchmarkTask, BenchmarkCompute {
  @override
  final int numOfTasks;

  @override
  final int concurrency;

  IsolateRpcNoComputeBenchmark({required this.numOfTasks, required this.concurrency}) : super('IsolateRpcNoComputeBenchmark(n=$numOfTasks,rps=$concurrency)');

  late RpcService<void, bool> rpcService;

  @override
  Future<void> setup() {
    rpcService = IsolateRpc.single(processor: (request) async {
      return noCompute();
    });
    return Future.value();
  }

  @override
  Future<void> teardown() async {
    return rpcService.shutdown();
  }

  @override
  Future<void> exercise() => run();

  @override
  Future<void> run() async {
    return runTasks((i) => rpcService.execute(null));
  }
}
