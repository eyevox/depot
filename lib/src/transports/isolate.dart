import 'dart:isolate';
import 'package:depot/depot.dart';

class DepotIsolate {
  static final ReceivePort port = ReceivePort();
  static late final Isolate isolate;

  static DepotIsolate self = DepotIsolate.internal();
  factory DepotIsolate() => self;

  DepotIsolate.internal();

  Future<void> init(String address) async {
    isolate = await Isolate.spawnUri(Uri.parse(address), [], port.sendPort);
    Depot.isolateOutgoingCallback = (String value) => isolate.controlPort.send(value);
    port.listen((message) {
      Depot.isolateIncomingStreamController.add(message.data);
    });
  }
}
