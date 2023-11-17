import 'dart:async';

import 'package:depot/src/depot_exceptions.dart';
import 'package:depot/src/facade.dart';
import 'package:depot/src/module.dart';
import 'package:depot/src/returner.dart';
import 'package:depot/src/tram.dart';
import 'package:depot/src/tram_call.dart';
import 'package:depot/src/transferable.dart';
import 'package:depot/src/transport.dart';

/// Depot is a repository for data model fragments, with the ability to cache requests if the fragments not initialized
/// yet.
class Depot<F extends Facade> {
  static final Map<Type, Tram> trams = {};
  static final List<TramCall> queue = [];
  static final socketIncomingStreamController = StreamController<EnrichedMessage>();
  static void Function(String) socketOutgoingCallback = (String value) => null;
  static final socketTransport =
      Transport(socketIncomingStreamController.stream, (String value) => socketOutgoingCallback(value));
  static final isolateIncomingStreamController = StreamController<EnrichedMessage>();
  static void Function(String) isolateOutgoingCallback = (String value) => null;
  static final isolateTransport =
      Transport(isolateIncomingStreamController.stream, (String value) => isolateOutgoingCallback(value));

  static void Function(String) logger = print;

  // Facade? selectedModule;

  // All data is contained in static fields, this map just contains typed mappings
  static final Map<Type, Depot> _self = {}; // Depot._internal();

  Depot._internal();

  /// This factory constructor binds the type parameter (module name) to the singleton instance
  factory Depot() {
    if (!_self.containsKey(F)) {
      _self[F] = Depot<F>._internal();
    }
    return _self[F] as Depot<F>;
  }

  /// Sets logger to output debug information. The default is print to console
  static void setLogger(void Function(String) stringLogger) {
    logger = stringLogger;
  }

  /// Registers the module and instantiates it in current runtime
  void localRegister<T extends Facade>(
      {required FacadeConstructor<T> constructor, required String name, required Module module}) {
    final tram = LocalTram<T>(name, constructor, module);
    trams[T] = tram;
  }

  /// Registers the module from other runtime, connected by specified remote transport
  void RemoteRegister<T extends Facade>({
    required FacadeConstructor<T> constructor,
    required String name,
    required Transport transport
  }) {
    trams[T] = RemoteTram<T>(name, constructor, transport);
  }

  /// Registers the module from other runtime, connected by socket transport
  void socketRegister<T extends Facade>({
    required FacadeConstructor<T> constructor,
    required String name,
  }) => RemoteRegister(constructor: constructor, name: name, transport: socketTransport);

  /// Registers the module running in isolate
  void isolateRegister<T extends Facade>({
    required FacadeConstructor<T> constructor,
    required String name,
  }) => RemoteRegister(constructor: constructor, name: name, transport: isolateTransport);

  // Tram getModuleByName(String name) => glossary[name]!;

  String getModuleNameByType(Type type) => trams.containsKey(type) ? trams[type]!.name : throw NoTramException(type);

  Type getModuleTypeByName(String name) => trams.entries
      .firstWhere((element) => element.value.name == name, orElse: () => throw NoTramNameException(name))
      .key;

  /// Presents Facade from the Depot to make fire-and-forget commands
  F command() {
    late final Tram<F> tram;
    if (trams.containsKey(F)) {
      tram = trams[F]! as Tram<F>;
    } else {
      throw NoTramException(F);
    }

    return tram.facadeConstructor(CallMode.command, tram, Returner<void>.new);
  }

  /// Presents Facade from the Depot to make asynchronous requests
  F request<R>() {
    late final Tram<F> tram;
    if (trams.containsKey(F)) {
      tram = trams[F]! as Tram<F>;
    } else {
      throw NoTramException(F);
    }

    return tram.facadeConstructor(CallMode.request, tram, Returner<R>.new);
  }

  /// Presents Facade from the Depot to make subscriptions
  F subscribe<R>() {
    late final Tram<F> tram;
    if (trams.containsKey(F)) {
      tram = trams[F]! as Tram<F>;
    } else {
      throw NoTramException(F);
    }

    return tram.facadeConstructor(CallMode.subscribe, tram, Returner<R>.new);
  }

  TramCall deserialize(Map<String, dynamic> data, String moduleName) => TramCall(
      mode: CallMode.values.firstWhere((variant) => variant.name == data['mode']),
      symbol: Symbol(data['symbol'] as String),
      positionalArguments: (data['positionalArguments'] as List<dynamic>).map(Transferable.materialize).toList(),
      namedArguments: (data['namedArguments'] as Map<String, dynamic>)
          .map((key, value) => MapEntry(Symbol(key), Transferable.materialize)),
      moduleType: getModuleTypeByName(moduleName),
      returner: Returner<void>());
}
