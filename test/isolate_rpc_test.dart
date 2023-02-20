import 'package:collection/collection.dart';
import 'package:isolate_rpc/isolate_rpc.dart';
import 'package:test/test.dart';

class ComplexModel {
  final int int0;
  final String string0;
  final double double0;
  final bool bool0;
  final Map<String, ComplexModel> map;
  final List<ComplexModel> list;

  factory ComplexModel.dummy() {
    return ComplexModel(int0: 1, string0: "1", double0: 1.0, bool0: false, map: {}, list: []);
  }

  const ComplexModel(
      {required this.int0,
      required this.string0,
      required this.double0,
      required this.bool0,
      required this.map,
      required this.list});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ComplexModel &&
          runtimeType == other.runtimeType &&
          int0 == other.int0 &&
          string0 == other.string0 &&
          double0 == other.double0 &&
          bool0 == other.bool0 &&
          MapEquality().equals(map, other.map) &&
          ListEquality().equals(list, other.list);

  @override
  int get hashCode =>
      int0.hashCode ^ string0.hashCode ^ double0.hashCode ^ bool0.hashCode ^ map.hashCode ^ list.hashCode;

  @override
  String toString() {
    return 'ComplexModel{int0: $int0, string0: $string0, double0: $double0, bool0: $bool0, map: $map, list: $list}';
  }
}

void main() {
  test('when Rpc execution is success, result should wrapped in RpcResponse and metadata should be correct', () async {
    var id = 999;
    var debugName = "testing";
    IsolateRpcService<int, int> rpc = IsolateRpc.single<int, int>(processor: (a) => a + 1, id: id, debugName: debugName) as IsolateRpcService<int, int>;
    IsolateRpcResponse<int> resp = await rpc.execute(1);
    expect(rpc.id, equals(id));
    expect(rpc.debugName, equals(debugName));
    expect(resp.serviceId, equals(id));
    expect(resp.requestId, equals(0));
    expect(resp.error, equals(null));
    expect(resp.result, equals(2));
  });

  test('when Rpc execution is fail, should return error in RpcResponse', () async {
    var error = UnimplementedError("test");
    IsolateRpc<int, int> rpc = IsolateRpc.single(processor: (a) => throw error);
    IsolateRpcResponse<int> resp = await rpc.execute(1);
    expect(resp.error is UnimplementedError, isTrue);
    var remoteError = resp.error;
    if (remoteError is UnimplementedError) {
      expect(remoteError.toString(), equals(error.toString()));
    }
    expect(resp.result, equals(null));
  });

  test('request id should be increased', () async {
    IsolateRpc<int, int> rpc = IsolateRpc.single(processor: (a) => a + 1);
    var resp1 = await rpc.execute(1);
    var resp2 = await rpc.execute(1);

    expect(resp1.requestId, equals(0));
    expect(resp2.requestId, equals(1));
  });

  test('shutdown rpc service should throw RpcError', () async {
    IsolateRpc<int, int> rpc = IsolateRpc.single(processor: (a) => a + 1);
    rpc.shutdown();

    var resp = await rpc.execute(1);
    expect(resp.error is IsolateRpcError, isTrue);
    expect(resp.error.toString(), contains("has been shut down"));
  });

  test('complex type should work', () async {
    var req = ComplexModel(int0: 2, string0: "2", double0: 2.0, bool0: false, map: {"0": ComplexModel.dummy()}, list:[ComplexModel.dummy()]);
    IsolateRpc<ComplexModel, ComplexModel> rpc = IsolateRpc.single(processor: (a) => a);
    IsolateRpcResponse<ComplexModel> resp = await rpc.execute(req);
    var result = resp.result!;

    expect(result.int0, equals(2));
    expect(result.string0, equals("2"));
    expect(result.double0, equals(2.0));
    expect(result.bool0, equals(false));
    expect(result.map["0"] == ComplexModel.dummy(), isTrue);
    expect(result.list[0] == ComplexModel.dummy(), isTrue);
  });

}
