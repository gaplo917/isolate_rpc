import 'package:isolate_rpc/isolate_rpc.dart';

void main() async {
  // #1 example to define a single Rpc service with exactly one Isolate.
  IsolateRpc<int, int> rpc = IsolateRpc.single(processor: (data) => data + 1, debugName: "rpc");

  // execute normal RpcRequest in isolate
  IsolateRpcResponse<int> resp = await rpc.execute(1);

  print(resp.result); // output: 2

  rpc.shutdown(); // close the receive port and underlying Isolate.

  // #2 example to define a pool Rpc service with 4 isolates underlying.
  IsolateRpc<int, int> rpcPool = IsolateRpc.pool(size: 4, processor: (data) => data + 1, debugNamePrefix: "rpc-pool");

  // execute normal RpcRequest in isolate
  IsolateRpcResponse<int> resp2 = await rpcPool.execute(1);

  print(resp2.result); // output: 2

  rpcPool.shutdown(); // stop receiving new execution and clean up underlying Isolates.

  // #3 error handling example - implementation throws exception
  IsolateRpc<int, int> badRpc = IsolateRpc.single(processor: (request) => throw ArgumentError("missing XXX"), debugName: "bad-rpc");

  IsolateRpcResponse<int> badResp = await badRpc.execute(1);

  // match your own error
  if(badResp.error is ArgumentError) {
    print(badResp.error); // output: Invalid argument(s): missing XXX
    print(badResp.error?.stackTrace); // output: {error stacktrace}
    print(badResp.result); // output: null
  }

  badRpc.shutdown(); // close the receive port and underlying Isolate.

  // #4 error handling example 2 - service already shut down
  IsolateRpcResponse<int> shutDownResp = await badRpc.execute(1);

  // specific error introduced in this library
  if(shutDownResp.error is IsolateRpcError) {
    print(shutDownResp.error); // output: RpcError: IsolateRpc(id=0, debugName=bad-rpc) has been shut down.
    print(shutDownResp.result); // output: null
  }
}
