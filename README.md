Dart Isolate RPC. A simple RPC-style designed API to ease Isolate usage.

## Features

`isolate_rpc` provide a simpler solution to offload tasks into Isolate and yet can as an `Isolate.run` alternative with 
better performance for Dart SDK < 2.19.0.

This library significantly reduced overheads of `Isolate.run`. `Isolate.run` create new 
Isolate on every single call. In the M1Pro macbook benchmark, each Isolate startup overhead is about ~85us*.

Imagine if you are firing asynchronous offscreen operations constantly based on UI interactions, such as sending
analytics, fetching remote API, etc., you might want to eliminate this overhead.

*See benchmark result: https://github.com/gaplo917/isolate_rpc/blob/main/benchmark/main.dart

## Getting started

1. Create a single RPC service with `RpcService<RequestType, ResponseType>` using `IsolateRpc.single`.
```dart
// define a single Rpc service with exactly one Isolate, isolate will be spawned immediately.
RpcService<int, int> rpcService = IsolateRpc.single(
    processor: (data) => data + 1, // the execution logics, i.e. this is a plus one operation
    debugName: "rpc" // this will be used as the Isolate name
);
```

2. Execute with `1` as an input, and receive `RpcResponse<T>` response.
```dart
// execute normal RpcRequest in isolate
RpcResponse<int> resp = await rpcService.execute(1);

print(resp.result); // output: 2
```

3. Shut down the rpcService when you no longer need it.
```dart
rpcService.shutdown(); // close the receive port and underlying Isolate.
```

## Advance Usage

Creating a pool of RPC services to improve performance when there are computational tasks, i.e., JSON serialization.
```dart
RpcService<int, int> rpcServicePool = IsolateRpc.pool(
    size: 4, 
    processor: (data) => data + 1, 
    debugNamePrefix: "rpc-pool" // internally use "rpc-pool-0","rpc-pool-1","rpc-pool-2","rpc-pool-3"
);
```

Creating an RPC service with `package:logging` logger
```dart

// To receive all the logs from the Rpc service.
var rpcService = IsolateRpc.single(
    processor: (data) => data + 1,
    debugName: "rpc",
    logger: Logger("rpc_logger")
);

void main() {
  Logger.root.level = Level.FINEST;
  
  // pattern example to log with the Isolate
  log.onRecord.listen((record) {
    print('${Isolate.current.debugName}: ${record.level.name}: ${record.time}: ${record.message}');
  });

}
```

Cast to the underlying instance class to get more information
```dart
var rpcService = IsolateRpc.single(
    processor: (data) => data + 1, 
    debugName: "rpc"
) as IsolateRpcService<int, int>;

var rpcServicePool = IsolateRpc.pool(
    size: 4, 
    processor: (data) => data + 1, 
    debugNamePrefix: "rpc-pool"
) as IsolateRpcExecutor<int, int>;
```


## Benchmark (compared with `Isolate.run`)
See benchmark implementation: https://github.com/gaplo917/isolate_rpc/blob/main/benchmark

`NoCompute`: no workload, just complete the isolate task immediately
`Compute`: large json (300 items in json array) serialization and deserialization

```dart
/// # execution script
/// dart compile exe benchmark/main.dart -o ./benchmark/main
/// ./benchmark/main
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
```

## License
MIT