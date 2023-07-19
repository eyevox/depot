import 'dart:async';

import 'package:depot/src/facade.dart';
import 'package:depot/src/module.dart';
import 'package:rxdart/rxdart.dart';

class ExampleUserModuleFacade extends Facade {
  Future<String> userName();

  Stream<String> userNameStream();

  Future<void> noSuchFunction();

  void setUserName(String name);

  ExampleUserModuleFacade(super.mode, super.tram, super.returner);

  static String get name => 'ExampleUserModuleFacade';
}

class ExampleUserModule extends Module implements ExampleUserModuleFacade {
  ExampleUserModule() {
    addRequest(#userName, userName);
    addSubscribe(#userNameStream, userNameStream);
    addCommand(#setUserName, setUserName);
    name.add('John Doe');
    Future.delayed(Duration(milliseconds: 200), () {
      print('Example module initialized');
      initializer.complete();
    });
  }

  Completer<void> initializer = Completer();

  @override
  Future<void> get initialize => initializer.future;

  BehaviorSubject<String> name = BehaviorSubject.seeded('Anonymous');

  @override
  Future<void> noSuchFunction() async {}

  @override
  Future<String> userName() {
    print('username requested');
    return Future.delayed(const Duration(milliseconds: 200), () => name.value);
  }

  @override
  void setUserName(String name) {
    this.name.add(name);
  }

  @override
  Stream<String> userNameStream() {
    return name.stream;
  }
}
