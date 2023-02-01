import 'package:depot/depot.dart';
import 'package:depot/src/depot_exceptions.dart';
import 'package:test/test.dart';
import '../example/module_example.dart';

void main() {
  group('Local depot testing', () {
    Depot().localRegister<ExampleUserModuleFacade>(
        constructor: ExampleUserModuleFacade.new, module: ExampleUserModule(), name: ExampleUserModuleFacade.name);
    Depot().localRegister<SettingsModuleFacade>(
        constructor: SettingsModuleFacade.new, module: SettingsModule(), name: SettingsModuleFacade.name);

    test('First Test', () async {
      Depot<ExampleUserModuleFacade>().subscribe<String>().userNameStream().listen((event) {
        print('Username stream got $event');
      });
      await Depot<ExampleUserModuleFacade>().request<String>().userName().then(expectAsync1((name) {
        expect(name, equals('John Doe'));
      }));
      await Future.delayed(Duration(milliseconds: 50));
      Depot<ExampleUserModuleFacade>().command().setUserName('Jane Doe');
      await Depot<ExampleUserModuleFacade>().request<String>().userName().then(expectAsync1((name) {
        expect(name, equals('Jane Doe'));
      }));
    });

    test('Exceptions Test', () async {
      // Если модуль не был добавлен в Depot вызывается NoTramException
      await expectLater(Depot<ExampleUserModule>().command, throwsA(isA<NoTramException>()));
      // Если комманда не была добвалена в Module, вызывает эксепшн NoMethodException
      await expectLater(Depot<ExampleUserModuleFacade>().command().noSuchFunction, throwsA(isA<NoMethodException>()));
      // command, request, subscribe возвращают Facade указанного типа
      expect(Depot<ExampleUserModuleFacade>().command(), equals(isA<ExampleUserModuleFacade>()));
      //На будущее если добавится проверка на корректность использования command, request или subscribe
      // expect(depot.request<ExampleUserModuleFacade>(), throwsA('someException'));
      // TODO(somebody): написать тест для исключения ModuleClosedException
    });

    test('Queue test', () {
      void testQueue(List<String> names) => names.forEach(Depot<ExampleUserModuleFacade>().command().setUserName);
      final nameStream = Depot<ExampleUserModuleFacade>().subscribe<String>().userNameStream();

      final names = <String>['John Smith', 'Richard Roe', 'Jack Ryan'];
      // Jane Doe передается в стрим на строчке 19
      expect(nameStream, emitsInOrder(['Jane Doe', ...names]));
      testQueue(names);
    });
  });
}
