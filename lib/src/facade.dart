import 'package:depot/src/depot_exceptions.dart';
import 'package:depot/src/returner.dart';
import 'package:depot/src/symbol_utilities.dart';
import 'package:depot/src/tram.dart';
import 'package:depot/src/tram_call.dart';

import '../depot.dart';

typedef ReturnerConstructor = Returner Function();
typedef FacadeConstructor<F extends Facade> = F Function(CallMode mode, Tram tram, ReturnerConstructor returner);

class Facade {
  final CallMode _mode;
  final Tram<dynamic> _tram;
  final ReturnerConstructor returnerConstructor;

  const Facade(this._mode, this._tram, this.returnerConstructor);

  static String get name => '';
}

mixin FacadeLocal on Facade {
  // The black magic works here, dynamic typing is intentional
  @override
  dynamic noSuchMethod(Invocation invocation) {
    final tram = _tram as LocalTram;
    final symbol = invocation.memberName;
    // print('_tram.state.value is: ${tram.state.value}');
    if (tram.state.value == TramState.idle || tram.state.value == TramState.initializing) {
      late final TramCall queueCall;
      // late final Type returnType;
      switch (_mode) {
        case CallMode.command:
          queueCall =
              TramCall.command(moduleType: tram.facadeType, invocation: invocation, returner: returnerConstructor());
          tram.queue.add(queueCall);
          // print('command queued, queue length: ${tram.queue.length}');
          return;
        case CallMode.request:
          queueCall = TramCall.request(
              moduleType: tram.facadeType, invocation: invocation, returner: returnerConstructor());
          tram.queue.add(queueCall);
          // print('request queued, queue length: ${tram.queue.length}');
          return queueCall.returner.future;
        case CallMode.subscribe:
          queueCall = TramCall.subscribe(
              moduleType: tram.facadeType, invocation: invocation, returner: returnerConstructor());
          tram.queue.add(queueCall);
          // print('subscribe queued, queue length: ${tram.queue.length}');
          return queueCall.returner.stream;
      }
    } else if (tram.state.value == TramState.ready) {
      if (tram.guts.endpoints.containsKey(symbol)) {
        return tram.runMethod(method: symbol,
            positionalArguments: Transferable.copy(invocation.positionalArguments) as List<dynamic>,
            namedArguments: toSymbolKeys(
                Transferable.copy(toStringKeys(invocation.namedArguments)) as Map<String, dynamic>));
      } else {
        throw NoMethodException(tram.facadeType, symbol);
      }
    } else {
      throw ModuleClosedException(tram.facadeType);
    }
  }
}

mixin FacadeSocket on Facade {
  // The black magic works here, dynamic typing is intentional
  @override
  dynamic noSuchMethod(Invocation invocation) {
    late final TramCall call;
    late final returnValue;
    // print('_tram.state.value is: ${_tram.state.value}');
    switch (_mode) {
      case CallMode.command:
        call = TramCall.command(moduleType: _tram.facadeType, invocation: invocation, returner: returnerConstructor());
        returnValue = null;
        break;
      case CallMode.request:
        call = TramCall.request(
            moduleType: _tram.facadeType, invocation: invocation, returner: returnerConstructor());
        returnValue = call.returner.future;
        break;
      case CallMode.subscribe:
        call = TramCall.subscribe(
            moduleType: _tram.facadeType, invocation: invocation, returner: returnerConstructor());
        returnValue = call.returner.stream;
        break;
    }
    if (Depot.socketTransport.ready) {
      _tram.queue.add(call);
      // print('command queued, queue length: ${_tram.queue.length}');
      return returnValue;
    } else {
      // print('command fired, queue length: ${_tram.queue.length}');
      return Depot.socketTransport.makeCall(call);
    }
  }
}

mixin FacadeIsolate on Facade {
  // The black magic works here, dynamic typing is intentional
  @override
  dynamic noSuchMethod(Invocation invocation) {
    late final TramCall call;
    late final returnValue;
    // print('_tram.state.value is: ${_tram.state.value}');
    switch (_mode) {
      case CallMode.command:
        call = TramCall.command(moduleType: _tram.facadeType, invocation: invocation, returner: returnerConstructor());
        returnValue = null;
        break;
      case CallMode.request:
        call = TramCall.request(
            moduleType: _tram.facadeType, invocation: invocation, returner: returnerConstructor());
        returnValue = call.returner.future;
        break;
      case CallMode.subscribe:
        call = TramCall.subscribe(
            moduleType: _tram.facadeType, invocation: invocation, returner: returnerConstructor());
        returnValue = call.returner.stream;
        break;
    }
    if (Depot.isolateTransport.ready) {
      _tram.queue.add(call);
      // print('command queued, queue length: ${_tram.queue.length}');
      return returnValue;
    } else {
      // print('command fired, queue length: ${_tram.queue.length}');
      return Depot.isolateTransport.makeCall(call);
    }
  }
}
