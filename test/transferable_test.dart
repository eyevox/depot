import 'dart:convert';

// import 'package:depot/depot.dart';
import 'package:depot/src/transferable.dart';
import 'package:depot/src/transferable_types/transferable_list.dart';
import 'package:depot/src/transferable_types/transferable_map.dart';
import 'package:depot/src/transferable_types/transferable_set.dart';
import 'package:test/test.dart';

import '../example/transferable_example.dart';

dynamic _mockUseTransport(dynamic data) {
  final encodedData = json.encode(data);
  return json.decode(encodedData);
}

void main() {
  group('Test transferable', () {
    // final depot = Depot();
    // depot.register<ExampleUserModuleFacade>(ExampleUserModuleFacade.new, ExampleUserModule());
    StartState state1 = StartState(DateTime.now(), StartPosition.ready);
    StartState state2 = StartState(DateTime.now().add(const Duration(hours: 1)), StartPosition.go);

    setUpAll(() {
      Transferable.register<StartState>('StartState', StartState.fromMap);
      Transferable.register<RunnerData>('RunnerData', RunnerData.fromMap);
      Transferable.registerEnum<StartPosition>(
          'StartPosition', StartPosition.values.byName);
    });

    test('Transfer DateTime test', () async {
      final stamp = DateTime.now();
      final serialized = Transferable.serialize(stamp);
      final result = Transferable.materialize(serialized);
      expect(stamp, equals(result));
    });

    test('Transfer DateTime test', () async {
      final list = <int>[1, 2, 3, 4, 5];
      final serialized = Transferable.serialize(list);
      final result = Transferable.materialize(serialized);
      expect(list.runtimeType, equals(result.runtimeType));
      expect(list, equals(result));
    });

    test('Basic transferable test', () async {
      final startStateMap = <String, dynamic>{
        'transferableType': 'StartState',
        'value': {
          'startTime': {
            'plainType': 'DateTime',
            'value': '2022-10-19T22:54:31.300Z'
          },
          'state': {'enumType': 'StartPosition', 'value': 'ready'}
        }
      };
      final startState =
          StartState.fromMap(startStateMap['value'] as Map<String, dynamic>);
      final resultMap = Transferable.serialize(startState);
      expect(jsonEncode(startStateMap), equals(jsonEncode(resultMap)));
    });

    test('Hierarchical transferable test', () async {
      final runnerDataMap = <String, dynamic>{
        'transferableType': 'RunnerData',
        'value': {
          'runner': 'Bolt',
          'states': {
            'transferableListType': 'StartState',
            'value': [
              {
              //  'transferableType': 'StartState',
              //  'value': {
                  'startTime': {
                    'plainType': 'DateTime',
                    'value': '2022-10-19T22:54:31.000Z'
                  },
                  'state': {'enumType': 'StartPosition', 'value': 'ready'}
              //  }
              }
            ]
          }
        }
      };
      final runnerData =
          RunnerData.fromMap(runnerDataMap['value'] as Map<String, dynamic>);
      final resultMap = Transferable.serialize(runnerData);
      expect(jsonEncode(runnerDataMap), equals(jsonEncode(resultMap)));
    });

    test('Modify transferable copy', () async {
      final runnerDataMap = <String, dynamic>{
        'transferableType': 'RunnerData',
        'value': {
          'runner': 'Bolt',
          'states': {
            'transferableListType': 'StartState',
            'value': [
              {
                'startTime': {
                  'plainType': 'DateTime',
                  'value': '2022-10-19T22:54:31.000Z'
                },
                'state': {'enumType': 'StartPosition', 'value': 'ready'}
              }
            ]
          }
        }
      };
      final runnerData =
          RunnerData.fromMap(runnerDataMap['value'] as Map<String, dynamic>);
      final runnerDataCopy = Transferable.copy(runnerData);

      expect(jsonEncode(runnerDataMap),
          equals(jsonEncode(Transferable.serialize(runnerDataCopy))));
      runnerData.states.first.state = StartPosition.steady;
      expect(jsonEncode(runnerDataMap),
          isNot(jsonEncode(Transferable.serialize(runnerData))));
      expect(jsonEncode(runnerDataMap),
          equals(jsonEncode(Transferable.serialize(runnerDataCopy))));
    });

    test('Test empty transferable list', () async {
      final list = TransferableList<StartState>();
      final serialized = Transferable.serialize(list);
      final rawData = _mockUseTransport(serialized);
      final data = Transferable.materialize(rawData);

      expect(data, equals(list));
    });

    test('Test empty transferable map', () async {
      final map = TransferableMap<StartState>();
      final serialized = Transferable.serialize(map);
      final rawData = _mockUseTransport(serialized);
      final data = Transferable.materialize(rawData);

      expect(data, equals(map));
    });

    test('Test transferable list with data', () async {
      final list = TransferableList<StartState>([
        StartState.fromMap({
          'startTime': {
            'plainType': 'DateTime',
            'value': '2022-10-19T22:54:31.000Z'
          },
          'state': {'enumType': 'StartPosition', 'value': 'ready'}
        })
      ]);
      final serialized = Transferable.serialize(list);
      final rawData = _mockUseTransport(serialized);
      final data = Transferable.materialize(rawData);

      expect(data.runtimeType, equals(list.runtimeType));
      expect(data.first == list.first, isTrue);
    });

    test('Test transferable map with data', () async {
      final map = TransferableMap<StartState>({
        'one': StartState.fromMap({
          'startTime': {
            'plainType': 'DateTime',
            'value': '2022-10-19T22:54:31.000Z'
          },
          'state': {'enumType': 'StartPosition', 'value': 'ready'}
        })
      });
      final serialized = Transferable.serialize(map);
      final rawData = _mockUseTransport(serialized);
      final data = Transferable.materialize(rawData);

      expect(data.runtimeType, equals(map.runtimeType));
      expect((data as TransferableMap<StartState>).values.first == map.values.first, isTrue);
    });

    test('Test transferable', () async {
      RunnerData runnerData = RunnerData('data', TransferableList([state1, state2]));

      final resultMap = Transferable.serialize(runnerData);
      final data = Transferable.materialize(resultMap); //  as RunnerData

      expect(data.runtimeType, equals(runnerData.runtimeType));
      expect(data.runner, equals(runnerData.runner));
    });

    test('Test transferable set with data', () async {
      final set = TransferableSet<StartState>({state1});
      set.add(state2);
      final serialized = Transferable.serialize(set);
      final data = Transferable.materialize(serialized); // as Set<StartState> // type '_InternalLinkedHashMap<String, dynamic>' is not a subtype of type 'Set<StartState>' in type cast

      expect(set.contains(state2), isTrue);
      expect(set.lookup(state1), equals(state1));
      expect(data.runtimeType, equals(set.runtimeType));
      expect((data as TransferableSet<StartState>).length == set.length, isTrue);
    });

  });
}
