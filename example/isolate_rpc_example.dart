import 'package:isolate_rpc/isolate_rpc.dart';

void main() async {
  // #1 example to define a single Rpc service with exactly one Isolate.
  RpcService<int, int> rpcService = IsolateRpc.single(processor: (data) => data + 1, debugName: "rpc");

  // execute normal RpcRequest in isolate
  RpcResponse<int> resp = await rpcService.execute(1);

  print(resp.result); // output: 2

  rpcService.shutdown(); // close the receive port and underlying Isolate.

  // #2 example to define a pool Rpc service with 4 isolates underlying.
  RpcService<int, int> rpcServicePool = IsolateRpc.pool(size: 4, processor: (data) => data + 1, debugNamePrefix: "rpc-pool");

  // execute normal RpcRequest in isolate
  RpcResponse<int> resp2 = await rpcServicePool.execute(1);

  print(resp2.result); // output: 2

  rpcServicePool.shutdown(); // stop receiving new execution and clean up underlying Isolates.

  // #3 error handling example - implementation throws exception
  RpcService<int, int> badRpcService = IsolateRpc.single(processor: (request) => throw ArgumentError("missing XXX"), debugName: "bad-rpc");

  RpcResponse<int> badResp = await badRpcService.execute(1);

  // match your own error
  if(badResp.error is ArgumentError) {
    print(badResp.error); // output: Invalid argument(s): missing XXX
    print(badResp.error?.stackTrace); // output: {error stacktrace}
    print(badResp.result); // output: null
  }

  badRpcService.shutdown(); // close the receive port and underlying Isolate.

  // #4 error handling example 2 - service already shut down
  RpcResponse<int> shutDownResp = await badRpcService.execute(1);

  // specific error introduced in this library
  if(shutDownResp.error is RpcError) {
    print(shutDownResp.error); // output: RpcError: RpcService(id=0, debugName=bad-rpc) has been shut down.
    print(shutDownResp.result); // output: null
  }
}
