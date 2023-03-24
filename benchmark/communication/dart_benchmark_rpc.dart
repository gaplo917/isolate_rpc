import 'dart:async';
import 'dart:typed_data';

import 'package:benchmark_harness/benchmark_harness.dart';
import 'package:isolate_rpc/isolate_rpc.dart';

import '../common.dart';

class IsolateRpcCommunicationBenchmark extends AsyncBenchmarkBase with BenchmarkTask, BenchmarkCompute {
  @override
  final int numOfTasks;

  @override
  final int concurrency;

  final int length;

  late final Uint8List request = Uint8List(length);

  IsolateRpcCommunicationBenchmark({required this.numOfTasks, required this.concurrency, required this.length})
      : super('IsolateRpc,Communication(n=$numOfTasks,c=$concurrency,len=$length)');

  late IsolateRpc<Uint8List, Uint8List> rpc;

  @override
  Future<void> setup() {
    rpc = IsolateRpc.single(processor: (request) async {
      return request;
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
    return runTasks((i) => rpc.execute(request));
  }
}
