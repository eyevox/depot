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

  factory Depot() {
    if (!_self.containsKey(F)) {
      _self[F] = Depot<F>._internal();
    }
    return _self[F] as Depot<F>;
  }

  static void setLogger(void Function(String) stringLogger) {
    logger = stringLogger;
  }

  /// Adds the Module to the Depot, using Facade as an interface
  /// This method uses Type.toString as tram name, so names are lost on minification
  /// Please, update your module with name getter and use localRegister
  @Deprecated(
      'This method uses Type.toString as tram name, so names are lost on minification. Please, update your module with name getter and use localRegister')
  void register<F extends Facade>(FacadeConstructor<F> facadeConstructor, Module module,
      [TramConnection connection = TramConnection.local]) {
    switch (connection) {
      case TramConnection.local:
        final tram = LocalTram<F>(F.toString(), facadeConstructor, module);
        trams[F] = tram;
        break;
      case TramConnection.isolate:
        // TODO: Handle this case.
        break;
      case TramConnection.socket:
        final tram = SocketTram<F>(F.toString(), facadeConstructor);
        trams[F] = tram;
        break;
      case TramConnection.stub:
        // TODO: Handle this case.
        break;
    }
  }

  void localRegister<F extends Facade>(
      {required FacadeConstructor<F> constructor, required String name, required Module module}) {
    final tram = LocalTram<F>(name, constructor, module);
    trams[F] = tram;
  }

  void socketRegister<F extends Facade>({
    required FacadeConstructor<F> constructor,
    required String name,
  }) {
    final tram = SocketTram<F>(name, constructor);
    trams[F] = tram;
  }

  void isolateRegister<F extends Facade>({
    required FacadeConstructor<F> constructor,
    required String name,
  }) {
    final tram = IsolateTram<F>(name, constructor);
    trams[F] = tram;
  }

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

    switch (tram.connection) {
      case TramConnection.local:
        return tram.facadeConstructor(CallMode.command, tram, Returner<void>.new);
      case TramConnection.isolate:
        // TODO: Handle this case.
        break;
      case TramConnection.socket:
        // TODO: Handle this case.
        break;
      case TramConnection.stub:
        // TODO: Handle this case.
        break;
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

    switch (tram.connection) {
      case TramConnection.local:
        return tram.facadeConstructor(CallMode.request, tram, Returner<R>.new);
      case TramConnection.isolate:
        // TODO: Handle this case.
        break;
      case TramConnection.socket:
        // TODO: Handle this case.
        break;
      case TramConnection.stub:
        // TODO: Handle this case.
        break;
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

    switch (tram.connection) {
      case TramConnection.local:
        return tram.facadeConstructor(CallMode.subscribe, tram, Returner<R>.new);
      case TramConnection.isolate:
        // TODO: Handle this case.
        break;
      case TramConnection.socket:
        // TODO: Handle this case.
        break;
      case TramConnection.stub:
        // TODO: Handle this case.
        break;
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
