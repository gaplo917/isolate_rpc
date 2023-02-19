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

`NoCompute`: Do noting

`Compute`: A large json serialization and deserialization

```dart
/// # execution script
/// dart compile exe benchmark/main.dart -o ./benchmark/main
/// ./benchmark/main
///
/// IsolateRunNoComputeBenchmark(n=1,rps=1)(RunTime): 92.14198839030682 us.
/// IsolateRpcNoComputeBenchmark(n=1,rps=1)(RunTime): 4.515276300906892 us.
/// IsolateRpcPoolNoComputeBenchmark(n=1,rps=1,poolSize=4)(RunTime): 4.529088068117485 us.
/// IsolateRunComputeBenchmark(n=1,rps=1)(RunTime): 342.55780099332077 us.
/// IsolateRpcComputeBenchmark(n=1,rps=1)(RunTime): 224.05421754228743 us.
/// IsolateRpcPoolComputeBenchmark(n=1,rps=1,poolSize=10)(RunTime): 205.71737118173402 us.
///
/// running benchmark numOfTasks=2, concurrency=2
/// IsolateRunNoComputeBenchmark(n=2,rps=2)(RunTime): 141.49331446763352 us.
/// IsolateRpcNoComputeBenchmark(n=2,rps=2)(RunTime): 10.123024750721264 us.
/// IsolateRpcPoolNoComputeBenchmark(n=2,rps=2,poolSize=4)(RunTime): 10.259624805708452 us.
/// IsolateRunComputeBenchmark(n=2,rps=2)(RunTime): 477.8397037744864 us.
/// IsolateRpcComputeBenchmark(n=2,rps=2)(RunTime): 418.97381650607457 us.
/// IsolateRpcPoolComputeBenchmark(n=2,rps=2,poolSize=10)(RunTime): 249.86570893191754 us.
///
/// running benchmark numOfTasks=4, concurrency=4
/// IsolateRunNoComputeBenchmark(n=4,rps=4)(RunTime): 275.266308835673 us.
/// IsolateRpcNoComputeBenchmark(n=4,rps=4)(RunTime): 17.764444641826177 us.
/// IsolateRpcPoolNoComputeBenchmark(n=4,rps=4,poolSize=4)(RunTime): 18.124049623474185 us.
/// IsolateRunComputeBenchmark(n=4,rps=4)(RunTime): 768.9285439877065 us.
/// IsolateRpcComputeBenchmark(n=4,rps=4)(RunTime): 865.5746430116833 us.
/// IsolateRpcPoolComputeBenchmark(n=4,rps=4,poolSize=10)(RunTime): 363.45956750863166 us.
///
/// running benchmark numOfTasks=8, concurrency=8
/// IsolateRunNoComputeBenchmark(n=8,rps=8)(RunTime): 520.139365574623 us.
/// IsolateRpcNoComputeBenchmark(n=8,rps=8)(RunTime): 22.880426948553385 us.
/// IsolateRpcPoolNoComputeBenchmark(n=8,rps=8,poolSize=4)(RunTime): 22.989264121014276 us.
/// IsolateRunComputeBenchmark(n=8,rps=8)(RunTime): 1340.9276139410188 us.
/// IsolateRpcComputeBenchmark(n=8,rps=8)(RunTime): 1637.0875613747953 us.
/// IsolateRpcPoolComputeBenchmark(n=8,rps=8,poolSize=10)(RunTime): 465.5580637654177 us.
///
/// running benchmark numOfTasks=16, concurrency=16
/// IsolateRunNoComputeBenchmark(n=16,rps=16)(RunTime): 1509.5758490566038 us.
/// IsolateRpcNoComputeBenchmark(n=16,rps=16)(RunTime): 36.826072546492355 us.
/// IsolateRpcPoolNoComputeBenchmark(n=16,rps=16,poolSize=4)(RunTime): 38.38889422061844 us.
/// IsolateRunComputeBenchmark(n=16,rps=16)(RunTime): 2866.0085959885387 us.
/// IsolateRpcComputeBenchmark(n=16,rps=16)(RunTime): 3275.176759410802 us.
/// IsolateRpcPoolComputeBenchmark(n=16,rps=16,poolSize=10)(RunTime): 1054.1527924130664 us.
///
/// running benchmark numOfTasks=32, concurrency=32
/// IsolateRunNoComputeBenchmark(n=32,rps=32)(RunTime): 2748.6703296703295 us.
/// IsolateRpcNoComputeBenchmark(n=32,rps=32)(RunTime): 68.0847290305011 us.
/// IsolateRpcPoolNoComputeBenchmark(n=32,rps=32,poolSize=4)(RunTime): 71.61564077774197 us.
/// IsolateRunComputeBenchmark(n=32,rps=32)(RunTime): 5900.719764011799 us.
/// IsolateRpcComputeBenchmark(n=32,rps=32)(RunTime): 6624.284768211921 us.
/// IsolateRpcPoolComputeBenchmark(n=32,rps=32,poolSize=10)(RunTime): 2132.272630457934 us.
///
/// running benchmark numOfTasks=64, concurrency=64
/// IsolateRunNoComputeBenchmark(n=64,rps=64)(RunTime): 4369.454148471616 us.
/// IsolateRpcNoComputeBenchmark(n=64,rps=64)(RunTime): 133.24562104562105 us.
/// IsolateRpcPoolNoComputeBenchmark(n=64,rps=64,poolSize=4)(RunTime): 133.31922410345288 us.
/// IsolateRunComputeBenchmark(n=64,rps=64)(RunTime): 12436.567901234568 us.
/// IsolateRpcComputeBenchmark(n=64,rps=64)(RunTime): 13304.079470198676 us.
/// IsolateRpcPoolComputeBenchmark(n=64,rps=64,poolSize=10)(RunTime): 4302.621505376344 us.
```

## License
MIT