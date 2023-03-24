
import 'dart:math';

import 'common.dart';
import 'communication/dart_benchmark_rpc.dart';
import 'compute/dart_benchmark.dart';
import 'compute/dart_benchmark_rpc.dart';
import 'compute/dart_benchmark_rpc_pool.dart';
import 'no_compute/dart_benchmark.dart';
import 'no_compute/dart_benchmark_rpc.dart';
import 'no_compute/dart_benchmark_rpc_pool.dart';

/// # execution script
/// dart compile exe benchmark/main.dart -o ./benchmark/main
/// ./benchmark/main
///
/// NoCompute: no workload, just complete the isolate task immediately
/// Compute: large json (300 items in json array) serialization and deserialization
///
/// running benchmark numOfTasks=1, concurrency=1
/// IsolateRun,NoCompute(n=1,c=1)(RunTime): 87.20392413342054 us.
/// IsolateRpc,NoCompute(n=1,c=1)(RunTime): 4.599250324820917 us.
/// IsolateRpcPool,NoCompute(n=1,c=1,poolSize=10)(RunTime): 4.520818358130009 us.
/// IsolateRun,Compute(n=1,c=1)(RunTime): 361.96815056098444 us.
/// IsolateRpc,Compute(n=1,c=1)(RunTime): 226.50939977349944 us.
/// IsolateRpcPool,Compute(n=1,c=1,poolSize=10)(RunTime): 210.5962935663894 us.
///
///
/// running benchmark numOfTasks=2, concurrency=2
/// IsolateRun,NoCompute(n=2,c=2)(RunTime): 151.93398663020358 us.
/// IsolateRpc,NoCompute(n=2,c=2)(RunTime): 9.917934502320785 us.
/// IsolateRpcPool,NoCompute(n=2,c=2,poolSize=10)(RunTime): 10.31331700399639 us.
/// IsolateRun,Compute(n=2,c=2)(RunTime): 478.0542413381123 us.
/// IsolateRpc,Compute(n=2,c=2)(RunTime): 422.2839349799451 us.
/// IsolateRpcPool,Compute(n=2,c=2,poolSize=10)(RunTime): 228.39888089528378 us.
///
///
/// running benchmark numOfTasks=4, concurrency=4
/// IsolateRun,NoCompute(n=4,c=4)(RunTime): 272.6056971514243 us.
/// IsolateRpc,NoCompute(n=4,c=4)(RunTime): 15.622141161032307 us.
/// IsolateRpcPool,NoCompute(n=4,c=4,poolSize=10)(RunTime): 16.181924835147054 us.
/// IsolateRun,Compute(n=4,c=4)(RunTime): 793.5767552558508 us.
/// IsolateRpc,Compute(n=4,c=4)(RunTime): 818.5012274959083 us.
/// IsolateRpcPool,Compute(n=4,c=4,poolSize=10)(RunTime): 283.7988081725312 us.
///
///
/// running benchmark numOfTasks=8, concurrency=8
/// IsolateRun,NoCompute(n=8,c=8)(RunTime): 510.0441101478837 us.
/// IsolateRpc,NoCompute(n=8,c=8)(RunTime): 23.258210066052655 us.
/// IsolateRpcPool,NoCompute(n=8,c=8,poolSize=10)(RunTime): 24.08178107427966 us.
/// IsolateRun,Compute(n=8,c=8)(RunTime): 1387.009015256588 us.
/// IsolateRpc,Compute(n=8,c=8)(RunTime): 1640.1450819672132 us.
/// IsolateRpcPool,Compute(n=8,c=8,poolSize=10)(RunTime): 477.5835721107927 us.
///
///
/// running benchmark numOfTasks=16, concurrency=16
/// IsolateRun,NoCompute(n=16,c=16)(RunTime): 1183.6209343583678 us.
/// IsolateRpc,NoCompute(n=16,c=16)(RunTime): 37.12607896641978 us.
/// IsolateRpcPool,NoCompute(n=16,c=16,poolSize=10)(RunTime): 38.0285589336984 us.
/// IsolateRun,Compute(n=16,c=16)(RunTime): 2856.30242510699 us.
/// IsolateRpc,Compute(n=16,c=16)(RunTime): 3342.764607679466 us.
/// IsolateRpcPool,Compute(n=16,c=16,poolSize=10)(RunTime): 1092.5019115237576 us.
///
///
/// running benchmark numOfTasks=32, concurrency=32
/// IsolateRun,NoCompute(n=32,c=32)(RunTime): 2181.123093681917 us.
/// IsolateRpc,NoCompute(n=32,c=32)(RunTime): 68.79331338355175 us.
/// IsolateRpcPool,NoCompute(n=32,c=32,poolSize=10)(RunTime): 71.01860663305163 us.
/// IsolateRun,Compute(n=32,c=32)(RunTime): 6355.952531645569 us.
/// IsolateRpc,Compute(n=32,c=32)(RunTime): 6755.542087542088 us.
/// IsolateRpcPool,Compute(n=32,c=32,poolSize=10)(RunTime): 2062.99793814433 us.
///
///
/// running benchmark numOfTasks=64, concurrency=64
/// IsolateRun,NoCompute(n=64,c=64)(RunTime): 4425.419426048565 us.
/// IsolateRpc,NoCompute(n=64,c=64)(RunTime): 148.14302644248573 us.
/// IsolateRpcPool,NoCompute(n=64,c=64,poolSize=10)(RunTime): 133.5073760096122 us.
/// IsolateRun,Compute(n=64,c=64)(RunTime): 10957.77049180328 us.
/// IsolateRpc,Compute(n=64,c=64)(RunTime): 13419.46 us.
/// IsolateRpcPool,Compute(n=64,c=64,poolSize=10)(RunTime): 4335.233766233766 us.
///
///
/// running communication benchmark numOfTasks=100
/// IsolateRpc,Communication(n=100,c=1,len=0)(RunTime): 412.72348328518365 us.
/// IsolateRpc,Communication(n=100,c=1,len=1024)(RunTime): 433.4140845070423 us.
/// IsolateRpc,Communication(n=100,c=1,len=2048)(RunTime): 440.8589376239806 us.
/// IsolateRpc,Communication(n=100,c=1,len=4096)(RunTime): 475.71462544589775 us.
/// IsolateRpc,Communication(n=100,c=1,len=8192)(RunTime): 509.73955147808357 us.
/// IsolateRpc,Communication(n=100,c=1,len=16384)(RunTime): 549.8147333699835 us.
/// IsolateRpc,Communication(n=100,c=1,len=32768)(RunTime): 673.4208754208754 us.
/// IsolateRpc,Communication(n=100,c=1,len=65536)(RunTime): 930.1306369130637 us.
/// IsolateRpc,Communication(n=100,c=1,len=131072)(RunTime): 1485.275426874536 us.
/// IsolateRpc,Communication(n=100,c=1,len=262144)(RunTime): 8773.219298245614 us.
/// IsolateRpc,Communication(n=100,c=1,len=524288)(RunTime): 17218.863247863246 us.
/// IsolateRpc,Communication(n=100,c=1,len=1048576)(RunTime): 30766.378787878788 us.
/// IsolateRpc,Communication(n=100,c=1,len=2097152)(RunTime): 52771.18421052631 us.
/// IsolateRpc,Communication(n=100,c=1,len=4194304)(RunTime): 91668.81818181818 us.
/// IsolateRpc,Communication(n=100,c=1,len=8388608)(RunTime): 195339.54545454544 us.
/// IsolateRpc,Communication(n=100,c=1,len=16777216)(RunTime): 365409.6666666667 us.
/// IsolateRpc,Communication(n=100,c=1,len=33554432)(RunTime): 733560.3333333334 us.
/// IsolateRpc,Communication(n=100,c=1,len=67108864)(RunTime): 1448395.0 us.
/// IsolateRpc,Communication(n=100,c=1,len=134217728)(RunTime): 2820773.0 us.
/// IsolateRpc,Communication(n=100,c=1,len=268435456)(RunTime): 5762662.0 us.
/// IsolateRpc,Communication(n=100,c=1,len=536870912)(RunTime): 12541032.0 us.
/// IsolateRpc,Communication(n=100,c=1,len=1073741824)(RunTime): 33607697.0 us.
void main(List<String> arguments) async {
  await createSuite(numOfTasks: 1, concurrency: 1);

  await createSuite(numOfTasks: 2, concurrency: 2);

  await createSuite(numOfTasks: 4, concurrency: 4);

  await createSuite(numOfTasks: 8, concurrency: 8);

  await createSuite(numOfTasks: 16, concurrency: 16);

  await createSuite(numOfTasks: 32, concurrency: 32);

  await createSuite(numOfTasks: 64, concurrency: 64);

  await createCommunicationSuite(numOfTasks: 100);
}

Future<void> createSuite({required int numOfTasks, required int concurrency}) async {
  print("running benchmark numOfTasks=$numOfTasks, concurrency=$concurrency");

  await delay(1000);
  await IsolateRunNoComputeBenchmark(numOfTasks: numOfTasks, concurrency: concurrency).report();

  await delay(1000);
  await IsolateRpcNoComputeBenchmark(numOfTasks: numOfTasks, concurrency: concurrency).report();

  await delay(1000);
  await IsolateRpcPoolNoComputeBenchmark(numOfTasks: numOfTasks, concurrency: concurrency).report();

  await delay(1000);
  await IsolateRunComputeBenchmark(numOfTasks: numOfTasks, concurrency: concurrency).report();

  await delay(1000);
  await IsolateRpcComputeBenchmark(numOfTasks: numOfTasks, concurrency: concurrency).report();

  await delay(1000);
  await IsolateRpcPoolComputeBenchmark(numOfTasks: numOfTasks, concurrency: concurrency).report();

  print("\n");
}

Future<void> createCommunicationSuite({required int numOfTasks}) async {
  print("running communication benchmark numOfTasks=$numOfTasks");

  await delay(1000);
  await IsolateRpcCommunicationBenchmark(numOfTasks: numOfTasks, concurrency: 1, length: 0).report();

  // 1kB - 1GB
  for(var i = 10; i < 31; i++){
    await delay(1000);
    await IsolateRpcCommunicationBenchmark(numOfTasks: numOfTasks, concurrency: 1, length: pow(2, i).toInt()).report();
  }

}