import 'dart:async';
import 'dart:convert';

import 'package:depot/depot.dart';
import 'package:depot/src/depot_exceptions.dart';
import 'package:depot/src/tram.dart';
import 'package:depot/src/tram_call.dart';
import 'package:rxdart/rxdart.dart';

enum MessageType { command, request, subscribe, unsubscribe, result }
typedef OutgoingCallback = void Function(String);
typedef ParametrizedOutgoingCallback = void Function(String, [Map<Symbol, dynamic> parameters]);

MessageType getMessageType(CallMode mode) {
  switch (mode) {
    case CallMode.command:
      return MessageType.command;
    case CallMode.request:
      return MessageType.request;
    case CallMode.subscribe:
      return MessageType.subscribe;
  }
}

class Enumerator {
  int value = 0;
  int get next => ++value;
}

class EnrichedMessage {
  final String value;
  final Map<Symbol, dynamic> parameters;
  EnrichedMessage(this.value, [this.parameters = const {}]);
  Map<String, dynamic>? get mapValue {
    try {
      final mapValue = jsonDecode(value) as Map<String, dynamic>;
      if (mapValue['id'] is int && mapValue['type'] is String) {
        return mapValue;
      } else {
        return null;
      }
    } catch (error) {
      return null;
    }
  }
}

class Transport {
  Map<int, TramCall> calls = {};
  Map<int, StreamSubscription<dynamic>> streams = {};
  Enumerator enumerator = Enumerator();
  Stream<EnrichedMessage> incomingStream;
  final Function outgoingCallback;
  BehaviorSubject<bool> _ready = BehaviorSubject.seeded(false);
  bool get ready => _ready.value;
  Stream<bool> get readyStream => _ready.stream;
  void start() => _ready.add(true);
  void stop() => _ready.add(false);
  final bool _isRich;

  Transport(this.incomingStream, OutgoingCallback this.outgoingCallback): _isRich = false {
    incomingStream.listen(onIncomingMessage);
  }

  Transport.parametrized(this.incomingStream, ParametrizedOutgoingCallback this.outgoingCallback): _isRich = true {
    incomingStream.listen(onIncomingMessage);
  }

  void onIncomingMessage(EnrichedMessage enrichedMessage) {
    final message = enrichedMessage.mapValue;
    if (message == null) {
      return;
    }
    final messageId = message['id'] as int;
    final messageType = MessageType.values.byName(message['type'] as String);
    switch (messageType) {
      case MessageType.command:
        final tramCall = TramCall.fromMap(message['payload'] as Map<String, dynamic>);
        if (!Depot.trams.containsKey(tramCall.moduleType)) {
          throw TypeNotFoundException(tramCall.moduleType);
        }
        final tram = Depot.trams[tramCall.moduleType]! as LocalTram;
        tram.runMethod(method: tramCall.symbol,
            positionalArguments: tramCall.positionalArguments,
            namedArguments: tramCall.namedArguments,
            zoneValues: enrichedMessage.parameters);
        break;
      case MessageType.request:
        final tramCall = TramCall.fromMap(message['payload'] as Map<String, dynamic>);
        if (!Depot.trams.containsKey(tramCall.moduleType)) {
          throw TypeNotFoundException(tramCall.moduleType);
        }
        final tram = Depot.trams[tramCall.moduleType]; // ! as LocalTram;
        if (tram == null || !tram.isLocal) break;
        final result = (tram as LocalTram).runMethod(method: tramCall.symbol,
            positionalArguments: tramCall.positionalArguments,
            namedArguments: tramCall.namedArguments,
            zoneValues: enrichedMessage.parameters) as Future<dynamic>;
        result.then((value) => outgoingResultMessage(messageId, value, enrichedMessage.parameters));
        break;
      case MessageType.subscribe:
        final tramCall = TramCall.fromMap(message['payload'] as Map<String, dynamic>);
        if (!Depot.trams.containsKey(tramCall.moduleType)) {
          throw TypeNotFoundException(tramCall.moduleType);
        }
        final tram = Depot.trams[tramCall.moduleType]; // ! as LocalTram;
        if (tram == null || !tram.isLocal) break;
        final result = (tram as LocalTram).runMethod(method: tramCall.symbol,
            positionalArguments: tramCall.positionalArguments,
            namedArguments: tramCall.namedArguments,
            zoneValues: enrichedMessage.parameters) as Stream<dynamic>;
        streams[messageId] = result.listen((value) => outgoingResultMessage(messageId, value, enrichedMessage.parameters));
        break;
      case MessageType.unsubscribe:
        if (streams.containsKey(messageId)) {
          streams.remove(messageId)!.cancel();
        }
        break;
      case MessageType.result:
        if (calls.containsKey(messageId)) {
          final tramCall = calls[messageId]!;
          if (tramCall.mode == CallMode.request) {
            calls.remove(messageId)!.returner.complete(Transferable.materialize(message['value']));
          } else if (tramCall.mode == CallMode.subscribe) {
            tramCall.returner.add(Transferable.materialize(message['value']));
          } else {
            throw RequestFoundException(messageId);
          }
        }
        break;
    }
  }

  void outgoingResultMessage(int messageId, dynamic value, [Map<Symbol, dynamic> parameters = const {}]) {
    final message = jsonEncode({'id': messageId, 'type': 'result', 'value': Transferable.serialize(value)});
    if (_isRich) {
      outgoingCallback(message, parameters);
    } else {
      outgoingCallback(message);
    }
  }

  dynamic makeCall(TramCall call) {
    final messageId = enumerator.next;
    calls[messageId] = call;
    final message = jsonEncode({
      'id': messageId,
      'type': getMessageType(call.mode).name,
      'payload': call.toMap(),
    });
    outgoingCallback(message);
    switch (call.mode) {
      case CallMode.command:
        return null;
      case CallMode.request:
        return call.returner.future;
      case CallMode.subscribe:
        return call.returner.stream;
    }
  }
}
