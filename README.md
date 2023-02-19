Dart Isolate RPC. Wrapping Isolate message-drive style into RPC style service 
reduced significant overhead compared to `Isolate.run`.

## Features

This library reduce the significant overheads of `Isolate.run`.

`Isolate.run` create new Isolate on every single call. In the M1Pro macbook benchmark, 
each Isolate startup overhead is about ~85us*.

Imagine if you are firing asynchronous offscreen operations constantly based on UI interactions, such as sending
analytics, fetching remote API, etc., you might want to eliminate this overhead.

This library provide a simple solution to this problem and yet can as an `Isolate.run` alternative for 
Dart SDK < 2.19.0. 

*See benchmark result: https://github.com/gaplo917/isolate_rpc/blob/main/benchmark/main.dart

## Getting started

1. Create a single RPC service with `RpcService<RequestType, ResponseType>` using `IsolateRpc.single`.
```dart
// define a single Rpc service with exactly one Isolate, isolate will be spawned immediately.
RpcService<int, int> rpcService = IsolateRpc.single(processor: (data) => data + 1, debugName: "rpc");
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

create a pool of RPC services to improve performance when there are computational tasks, i.e., JSON serialization.
```dart
RpcService<int, int> rpcServicePool = IsolateRpc.pool(size: 4, processor: (data) => data + 1, debugNamePrefix: "rpc-pool");
```

## Benchmark (compared with `Isolate.run`)
See benchmark result: https://github.com/gaplo917/isolate_rpc/blob/main/benchmark/main.dart

## License
MIT