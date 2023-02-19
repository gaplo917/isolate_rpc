import 'dart:async';
import 'dart:isolate';
import 'package:logging/logging.dart';

class RpcResponse<T> {
  /// Original Rpc request id
  final int requestId;

  /// Rpc service id, that could be defined in [IsolateRpc.single].
  final int serviceId;

  /// Contain the underlying error. Either [RemoteError] or [RpcError].
  ///
  /// if the isolate process successfully, this field will be null.
  final Error? error;

  /// Contain the processed response.
  ///
  /// if the isolate process unsuccessfully, this field will be null
  final T? result;

  RpcResponse({required this.requestId, required this.serviceId, required this.error, required this.result});

  @override
  String toString() {
    return 'RpcResponse{requestId: $requestId, serviceId: $serviceId, error: $error, result: $result}';
  }
}

/// Be thrown when bad things happens inside the [RpcService]
///
/// for example, when [RpcService] has been shut down but still running [RpcService.execute].
class RpcError extends Error {
  final String? message;

  RpcError([this.message]);

  @override
  String toString() {
    var message = this.message;
    return (message != null) ? "RpcError: $message" : "RpcError";
  }
}

class _RpcRequest<T> {
  final int id;
  final int serviceId;
  final T data;

  _RpcRequest({required this.id, required this.serviceId, required this.data});

  @override
  String toString() {
    return '_RpcRequest{id: $id, serviceId: $serviceId, data: $data}';
  }
}

abstract class RpcService<T, U> {
  Future<RpcResponse<U>> execute(T data);

  Future<void> shutdown();
}

/// A simple interface exposed to public
abstract class IsolateRpcExecutor<T, U> implements RpcService<T, U> {
  abstract final int size;
}

/// Simple round-robin load balanced service pool for computational intensive
/// processing i.e., image processing, json serialization.
class _SimpleIsolateRpcExecutor<T, U> implements IsolateRpcExecutor<T, U> {
  @override
  final int size;

  final List<RpcService<T, U>> _services;

  int _seq = 0;

  _SimpleIsolateRpcExecutor({required this.size, required List<RpcService<T, U>> services})
      : _services = services;

  @override
  Future<RpcResponse<U>> execute(T data) async {
    return _services[_seq++ % size].execute(data);
  }

  @override
  Future<void> shutdown() async {
    for (final service in _services) {
      await service.shutdown();
    }
  }
}

/// IsolateRpcService abstract a complex message-driven handling to a more intuitive RPC style when using Isolate.
///
/// The concept is similar to [Isolate.run]. However, IsolateRpcService only create single Isolate while
/// [Isolate.run] create NEW Isolate for each call. Thus, IsolateRpcService eliminates the overhead of creating
/// a new Isolate and is much more efficient to offload IO tasks from main thread.
///
/// For handling computational heavy tasks, I would recommend to use
/// ```dart
/// IsolateRpcService.pool(size: Platform.numberOfProcessors - 1, processor: (_) => {});
/// ```
///
/// Example
/// ```dart
/// RpcService<int, int> rpcService = IsolateRpc.create(processor: (data) => data + 1, debugName: "rpc");
///
/// RpcResponse<int> resp = await rpcService.execute(1);
///
/// print(resp.result); // output: 2
///
/// rpcService.shutdown(); // close the receive port and underlying Isolate.
/// ```
class IsolateRpcService<T, U> implements RpcService<T, U> {
  final int id;

  /// debugName will be assigned to the underlying Isolate
  final String? debugName;

  /// provide package:logging logger to log information.
  ///
  /// All debug logs are set to `finest` level.
  final Logger? logger;

  /// holding _isolate reference to control the lifecycle
  late final Future<Isolate> _isolate;

  /// the main thread message receiver to receive Isolate RpcResponse<U> message
  late final RawReceivePort _receivePort;

  /// A future message sender replied by the first message from Isolate
  final _sendPort = Completer<SendPort>();

  /// [_completerMap] is a buffer to store uncompleted rpc execution callback.
  ///
  /// Note: the size grows when there is a backpressure (the rate of producing message is faster than consuming)
  /// of the RpcService.
  ///
  /// For handling computational intensive tasks, please consider to use [IsolateRpc.pool].
  final _completerMap = <int, Completer<RpcResponse<U>>>{};

  /// unique sequence id for each RPC call
  int _rpcSeq = 0;

  bool _isShutDown = false;

  IsolateRpcService._({required FutureOr<U> Function(T data) processor, this.id = 0, this.debugName, this.logger}) {
    var resultPort = RawReceivePort();
    resultPort.handler = (message) {
      if (message is RpcResponse) {
        logger?.finest(() => "receive response $message");
        final int rid = message.requestId;
        final int svcId = message.serviceId;
        final Error? error = message.error;
        final dynamic result = message.result;
        if (error == null) {
          _completerMap[rid]?.complete(RpcResponse(
            requestId: rid,
            serviceId: svcId,
            error: null,
            result: result,
          ));
        } else {
          _completerMap[rid]?.complete(RpcResponse(
            requestId: rid,
            serviceId: svcId,
            error: error,
            result: null,
          ));
        }
        _completerMap.remove(rid);
      } else if (message is SendPort) {
        _sendPort.complete(message);
      } else {
        logger?.finest(() => "unknown message $message");
      }
    };
    this._isolate = Isolate.spawn<_IsolateProcessor>(
        _IsolateProcessor.entryPoint, _IsolateProcessor<T, U>(processor: processor, port: resultPort.sendPort),
        onExit: resultPort.sendPort, onError: resultPort.sendPort);

    this._receivePort = resultPort;
  }

  /// Send RpcRequest<T> message to Isolate and wait until Isolate to respond.
  @override
  Future<RpcResponse<U>> execute(T data) async {
    Completer<RpcResponse<U>> completer = Completer();
    var rid = _rpcSeq++;
    if (_isShutDown) {
      return RpcResponse(
          requestId: rid,
          serviceId: id,
          error: RpcError("RpcService(id=$id, debugName=$debugName) has been shut down."),
          result: null);
    }
    final _RpcRequest request = _RpcRequest(id: rid, serviceId: id, data: data);

    _completerMap.putIfAbsent(rid, () => completer);

    logger?.finest(() => "execute $request");

    (await _sendPort.future).send(request);

    return completer.future.whenComplete(() => logger?.finest(() => "$request completed"));
  }

  /// Immediately stop receiving RpcResponse from Isolate and kill the underlying isolate
  @override
  Future<void> shutdown() async {
    _isShutDown = true;
    // stop receive message immediately
    this._receivePort.close();

    // kill the isolate immediately
    (await this._isolate).kill(priority: Isolate.immediate);

    return Future.value();
  }
}

/// An Isolate entry point to receive RpcRequest messages and then process asynchronously
/// based on user input [processor] function.
class _IsolateProcessor<T, U> {
  final FutureOr<U> Function(T request) processor;

  final SendPort port;

  final Logger? logger;

  _IsolateProcessor({required this.processor, required this.port, this.logger});

  static void entryPoint(_IsolateProcessor processor) {
    processor.process();
  }

  /// Process each incoming RpcRequest using [processor]
  void process() {
    RawReceivePort resultPort = RawReceivePort();
    resultPort.handler = (message) async {
      if (message is _RpcRequest) {
        logger?.finest(() => "receive RPC request $message");
        final int rid = message.id;
        final int svcId = message.serviceId;
        final dynamic data = message.data;
        try {
          final U result = await processor(data);
          final resp = RpcResponse(requestId: rid, serviceId: svcId, error: null, result: result);
          logger?.finest(() => "processed RPC request $message with response=$resp");
          port.send(resp);
        } on Error catch (e) {
          logger?.severe(() => "cannot process RPC request $message", e, e.stackTrace);

          // catch all errors and wrapped with an RemoteError to represent error from Isolate
          port.send(RpcResponse(
              requestId: rid,
              serviceId: svcId,
              error: e,
              result: null));
        }
      }
    };

    port.send(resultPort.sendPort);
  }
}

class IsolateRpc {

  /// create a round-robin load balanced isolate pool for computational intensive and high concurrency processing.
  /// processing i.e., image processing.
  ///
  /// The created isolates in the pool will have debugName: ${debugNamePrefix}_${index} and id: ${index}
  static RpcService<T, U> pool<T, U>(
      {required int size, required FutureOr<U> Function(T) processor, String debugNamePrefix = "rpc_pool", Logger? logger}) {
    List<RpcService<T, U>> services = [];
    for (var i = 0; i < size; i++) {
      services.add(single(id: i, processor: processor, debugName: "${debugNamePrefix}_$i", logger: logger));
    }
    return _SimpleIsolateRpcExecutor<T, U>(size: size, services: services.toList(growable: false));
  }

  /// create a single isolate powered rpc service. Good for I/O tasks and light-weight tasks.
  /// i.e., HTTP call and json serialization
  static RpcService<T, U> single<T, U>(
      {required FutureOr<U> Function(T data) processor, int id = 0, String? debugName, Logger? logger}) {
    return IsolateRpcService._(processor: processor, id: id, debugName: debugName, logger: logger);
  }
}