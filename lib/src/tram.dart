import 'dart:async';

import 'package:depot/src/facade.dart';
import 'package:depot/src/module.dart';
import 'package:depot/src/tram_call.dart';
import 'package:depot/src/depot_base.dart';
import 'package:rxdart/rxdart.dart';

/// Tram is a base class for model component

enum TramConnection { local, isolate, socket, stub }

enum TramState {
  idle,
  initializing,
  ready,
  paused,
}

// The tram is the basic Depot entity, connecting Facade interface with Module implementation
abstract class Tram<F extends Facade> {
  String get name => _name;

  final Type facadeType;
  final FacadeConstructor<F> facadeConstructor;
  TramConnection get connection;
  final BehaviorSubject<TramState> state;
  final String _name;

  // late final Type returnType;

  final List<TramCall> queue = [];

  Tram(this._name, this.facadeConstructor)
      : facadeType = F,
        // connection = TramConnection.local,
        state = BehaviorSubject.seeded(TramState.initializing) {}
}

// The tram to connect Modules running in the same isolate
class LocalTram<F extends Facade> extends Tram<F> {
  final Module guts;

  // static final List<TramCall> queue = [];

  LocalTram(super._name, super.facadeConstructor, this.guts) : super() {
    guts.initialize.then((_) {
      // print('>>>> Tram initialized');
      state.add(TramState.ready);
      processQueue();
    });
  }

  // Pushed queued calls to target Module after the connection was established
  void processQueue() {
    // print('>>>> Queue processing: ${queue.length}');
    while (queue.isNotEmpty) {
      final element = queue.removeAt(0);
      // final endpoint = guts.endpoints[element.symbol]!;
      final result = runMethod(
          method: element.symbol,
          positionalArguments: element.positionalArguments,
          namedArguments: element.namedArguments);
      if (element.mode == CallMode.request) {
        element.returner.complete(result);
      }
      if (element.mode == CallMode.subscribe) {
        element.returner.addStream(result);
      }
    }
  }

  dynamic runMethod(
      {required Symbol method,
      List<dynamic> positionalArguments = const [],
      Map<Symbol, dynamic> namedArguments = const {},
      Map<Symbol, dynamic> zoneValues = const {}}) {
    final String logPrefix =
        '[${Zone.current[#DepotModuleName] ?? 'rootZone'} > $name]: ${guts.endpoints[method]!.mode.name}';
    Depot.logger('$logPrefix ($method) called with ${namedArguments.isNotEmpty ? namedArguments : positionalArguments}');
    return runZonedGuarded<dynamic>(
        () => Function.apply(guts.endpoints[method]!.call, positionalArguments, namedArguments), (error, stack) {
      Depot.logger('$logPrefix encountered error: $error, Stacktrace was: $stack');
    }, zoneValues: Map.of(zoneValues)..[#DepotModuleName] = name);
  }

  @override
  TramConnection get connection => TramConnection.local;
}

class SocketTram<F extends Facade> extends Tram<F> {
  SocketTram(super._name, super.facadeConstructor) : super() {
    Depot.socketTransport.readyStream.listen((ready) {
      if (ready) {
        processQueue();
      }
    });
  }

  // Pushed queued calls to target Module after the connection was established
  void processQueue() {
    // print('>>>> Queue processing: ${queue.length}');
    while (queue.isNotEmpty) {
      final element = queue.removeAt(0);
      // final endpoint = guts.endpoints[element.symbol]!;
      final result = Depot.socketTransport.makeCall(element);
      if (element.mode == CallMode.request) {
        element.returner.complete(result);
      }
      if (element.mode == CallMode.subscribe) {
        element.returner.addStream(result);
      }
    }
  }

  @override
  TramConnection get connection => TramConnection.socket;
}

class IsolateTram<F extends Facade> extends Tram<F> {
  IsolateTram(super._name, super.facadeConstructor) : super() {
    Depot.isolateTransport.readyStream.listen((ready) {
      if (ready) {
        processQueue();
      }
    });
  }

  // Pushed queued calls to target Module after the connection was established
  void processQueue() {
    // print('>>>> Queue processing: ${queue.length}');
    while (queue.isNotEmpty) {
      final element = queue.removeAt(0);
      // final endpoint = guts.endpoints[element.symbol]!;
      final result = Depot.isolateTransport.makeCall(element);
      if (element.mode == CallMode.request) {
        element.returner.complete(result);
      }
      if (element.mode == CallMode.subscribe) {
        element.returner.addStream(result);
      }
    }
  }

  @override
  TramConnection get connection => TramConnection.isolate;
}
