
import 'package:depot/depot.dart';
import 'package:depot/src/returner.dart';
import 'package:depot/src/tram_call.dart';

class Endpoint<T> {
  CallMode mode;
  Type returnType;
  Function call;
  Endpoint.command(this.call) : returnType = Null, mode = CallMode.command;
  Endpoint.request(this.call, this.returnType) : mode = CallMode.request;
  Endpoint.subscribe(this.call, this.returnType) : mode = CallMode.subscribe;
}

class Module {
  void addCommand(Symbol name, Function command) {
    endpoints[name] = Endpoint.command(command);
  }
  void addRequest<T>(Symbol name, Function command) {
    endpoints[name] = Endpoint.request(command, T);
  }
  void addSubscribe<T>(Symbol name, Function command) {
    endpoints[name] = Endpoint.subscribe(command, T);
  }
  Map<Symbol, Endpoint<dynamic>> endpoints = {};
  Future<void> get initialize => Future.value();
  ReturnerConstructor get returnerConstructor => Returner<void>.new;
  Future<void> reset() async {}
}
