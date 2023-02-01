import 'package:depot/src/depot_base.dart';
import 'package:depot/src/tram_call.dart';
import 'package:depot/src/transport.dart';
import 'package:test/scaffolding.dart';

import '../example/module_example.dart';

void main() {
  setUpAll(
    () {
      Depot().localRegister<ExampleUserModuleFacade>(
          constructor: ExampleUserModuleFacade.new, module: ExampleUserModule(), name: ExampleUserModuleFacade.name);
    },
  );

  group(
    'Transport testing',
    () {
      Stream<EnrichedMessage> getStream(String message) => Stream.value(EnrichedMessage(message));

      test('Command', () async {
        const testMessage =
            '{"id": 1, "type": "command", "payload": {"mode": "command", "symbol": "setUserName", "positionalArguments": ["Rick"], "namedArguments": {}, "moduleType": "ExampleUserModuleFacade"}}';

        // ignore: avoid_print
        final transport = Transport(getStream(testMessage), (message) => print(message));

        final testTram = <String, dynamic>{
          'mode': 'command',
          'symbol': 'setUserName',
          'positionalArguments': ['Rick'],
          'namedArguments': <String, dynamic>{},
          'moduleType': 'ExampleUserModuleFacade'
        };

        transport.makeCall(TramCall.fromMap(testTram));
      });

      test('Request', () async {
        const testMessage =
            '{"id": 1, "type": "request", "payload": {"mode": "request", "symbol": "userName", "positionalArguments": [], "namedArguments": {}, "moduleType": "ExampleUserModuleFacade"}}';

        // ignore: avoid_print
        final transport = Transport(getStream(testMessage), (message) => print(message));

        final testTram = <String, dynamic>{
          'mode': 'request',
          'symbol': '#userName',
          'positionalArguments': [],
          'namedArguments': <String, dynamic>{},
          'moduleType': 'ExampleUserModuleFacade'
        };

        transport.makeCall(TramCall.fromMap(testTram));
      });
      test('Subscribe', () async {
        const testMessage =
            '{"id": 1, "type": "subscribe", "payload": {"mode": "subscribe", "symbol": "userNameStream", "positionalArguments": [], "namedArguments": {}, "moduleType": "ExampleUserModuleFacade"}}';

        // ignore: avoid_print
        final transport = Transport(getStream(testMessage), (message) => print(message));

        final testTram = <String, dynamic>{
          'mode': 'subscribe',
          'symbol': '#userNameStream',
          'positionalArguments': [],
          'namedArguments': <String, dynamic>{},
          'moduleType': 'ExampleUserModuleFacade'
        };

        transport.makeCall(TramCall.fromMap(testTram));
      });

      test('Unsubscribe', () async {});
      test('Result', () async {});
    },
  );
}
