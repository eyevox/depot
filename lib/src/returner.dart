import 'dart:async';

import 'package:depot/src/depot_exceptions.dart';

/// This class encloses the type argument for future use
/// See https://stackoverflow.com/questions/62819244/is-statement-with-a-variable-type
class Returner<R> {
  Completer<R> returnFuture = Completer<R>();
  StreamController<R> returnStream = StreamController<R>();

  Future<R> get future => returnFuture.future;
  Stream<R> get stream => returnStream.stream;

  void complete(dynamic value) {
    if (value is R || value is Future<R>) {
      returnFuture.complete(value);
    } else {
      throw ReturnTypeException(value.runtimeType, R);
    }
  }

  void add(dynamic value) {
    if (value is R) {
      returnStream.add(value);
    } else {
      throw ReturnTypeException(value.runtimeType, R);
    }
  }

  void addStream(dynamic value) {
    returnStream.addStream(value);
  }
}
