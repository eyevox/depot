import 'package:depot/src/depot_base.dart';
import 'package:depot/src/returner.dart';
import 'package:depot/src/symbol_utilities.dart';
import 'package:depot/src/transferable.dart';

enum CallMode {
  command,
  request,
  subscribe,
}

class TramCall {
  CallMode mode;
  Type moduleType;
  Symbol symbol;
  List<dynamic> positionalArguments;
  Map<Symbol, dynamic> namedArguments;
  Returner returner;

  TramCall({
    required this.mode,
    required this.symbol,
    required this.moduleType,
    required this.returner,
    this.positionalArguments = const [],
    this.namedArguments = const {}
  });

  TramCall.command({required this.moduleType, required Invocation invocation, required this.returner})
      : mode = CallMode.command,
        symbol = invocation.memberName,
        positionalArguments = invocation.positionalArguments,
        namedArguments = invocation.namedArguments;

  TramCall.request({required this.moduleType, required Invocation invocation, required this.returner}) // , required this.returnType})
      : mode = CallMode.request,
        symbol = invocation.memberName,
        positionalArguments = invocation.positionalArguments,
        namedArguments = invocation.namedArguments;

  TramCall.subscribe({required this.moduleType, required Invocation invocation, required this.returner}) // , required this.returnType})
      : mode = CallMode.subscribe,
        symbol = invocation.memberName,
        positionalArguments = invocation.positionalArguments,
        namedArguments = invocation.namedArguments;

  Map<String, dynamic> toMap() {
    final result = <String, dynamic>{
      'moduleType': Depot().getModuleNameByType(moduleType),
      'mode': mode.name,
      'symbol': symbolToString(symbol),
      'positionalArguments': positionalArguments.fold<List<dynamic>>([], (list, value) {
        list.add(Transferable.serialize(value));
        return list;
      }),
      'namedArguments': namedArguments.map<String, dynamic>((name, value) => MapEntry(symbolToString(name), Transferable.serialize(value))),
    };
    return result;
  }

  TramCall.fromMap(Map<String, dynamic> data) :
        mode = CallMode.values.byName(data['mode'] as String),
        symbol = Symbol(data['symbol'] as String),
        positionalArguments = (data['positionalArguments'] as List<dynamic>).map(Transferable.materialize).toList(growable: false),
        namedArguments = (data['namedArguments'] as Map<String, dynamic>).map((key, value) => MapEntry(Symbol(key), Transferable.materialize(value))),
        moduleType = Depot().getModuleTypeByName(data['moduleType'] as String),
        returner = Returner<void>();
}
