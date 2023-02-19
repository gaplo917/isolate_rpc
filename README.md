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
See benchmark result: https://github.com/gaplo917/isolate_rpc/blob/main/benchmark/main.dart

## License
MIT