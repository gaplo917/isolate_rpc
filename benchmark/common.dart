
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

Future<void> delay(int ms) {
  var completer = Completer();
  Timer(Duration(milliseconds: ms), () => completer.complete());
  return completer.future;
}

mixin BenchmarkImageBinary {
  Uint8List get benchmarkImageBinary {
    return File("./static/test.jpeg").readAsBytesSync();
  }
}

mixin BenchmarkTask {
  int get numOfTasks;
  int? get concurrency;


  Future<void> _runTask(Future<dynamic> Function(int i) fn) async {
    List<Future<dynamic>> queue = [];
    final n = numOfTasks;
    final c = concurrency;
    var cnt = 0;

    if(c != null) {
      for (var i = 0; i < c; i++) {
        queue.add(fn(cnt++));
      }
    }
    await Future.wait(queue);
  }

  Future<void> runTasks(Future<dynamic> Function(int i) fn) async {
    List<Future<dynamic>> queue = [];
    final n = numOfTasks;
    final c = concurrency;
    var cnt = 0;

    Future<dynamic> next() async {
      if(cnt >= n) {
        return;
      }
      await fn(cnt++).then((a) => next());
    }

    if(c != null) {
      for (var i = 0; i < c && i < n; i++) {
        queue.add(next());
      }
    }
    await Future.wait(queue);
  }
}

mixin BenchmarkCompute {
  bool noCompute() {
    return true;
  }

  bool compute() {
    // create large json object
    var jsonConvertible = List.filled(100, [
      {'score': 40},
      {'score': 80},
      {'score': 100, 'overtime': true, 'special_guest': null}
    ]).reduce((value, element) => value + element);

    var jsonText = jsonEncode(jsonConvertible);
    return jsonText == jsonDecode(jsonText);
  }
}