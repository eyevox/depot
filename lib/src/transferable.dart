import 'package:depot/src/depot_exceptions.dart';
import 'package:depot/src/transferable_types/transferable_set.dart';
import 'package:depot/src/transferable_types/transferable_list.dart';
import 'package:depot/src/transferable_types/transferable_map.dart';
import 'package:depot/src/transferable_types/transferable_type_adapter.dart';

typedef TransferableConstructor<T extends Transferable> = T Function(Map<String, dynamic> data);
typedef EnumConstructor<E extends Enum> = E Function(String data);
typedef CollectionGenerator<C extends TransferableTypeAdapter> = C Function(dynamic data);

class TransferableRecord<T extends Transferable> {
  static final records = TransferableRegistry().records;
  Type type = T;
  Type listType = List<T>;
  TransferableConstructor<T> constructor;

  TransferableRecord.internal(this.constructor);

  factory TransferableRecord(String name, TransferableConstructor<T> constructor) {
    final record = TransferableRecord.internal(constructor);
    if (records.containsKey(name)) {
      throw DoubleRegistrationException(name);
    }
    TransferableRegistry().addRecord(name, record);
    return record;
  }
}

class EnumRecord<E extends Enum> {
  static final enums = TransferableRegistry().enums;
  Type type = E;
  EnumConstructor<E> constructor;

  EnumRecord.internal(this.constructor);

  factory EnumRecord(String name, EnumConstructor<E> constructor) {
    final record = EnumRecord.internal(constructor);
    if (enums.containsKey(name)) {
      throw DoubleRegistrationException(name);
    }
    TransferableRegistry().addEnum(name, record);
    return record;
  }
}

class TransferableRegistry {
  Map<String, TransferableRecord> records = {};
  Map<String, EnumRecord> enums = {};

  Map<String, CollectionGenerator<TransferableList>> listGenerators = {};
  Map<String, CollectionGenerator<TransferableMap>> mapGenerators = {};
  Map<String, CollectionGenerator<TransferableSet>> setGenerators = {};

  // Map<String, CollectionGenerator<TransferableQueue>> queueGenerators = {};
  // Map<Type, EnumRecord> enumsByType = {};

  TransferableRegistry.internal();

  static final _self = TransferableRegistry.internal();

  factory TransferableRegistry() => _self;

  void add<T extends Transferable>(String name, TransferableConstructor<T> constructor) =>
      records[name] = TransferableRecord<T>.internal(constructor);

  void addRecord<T extends Transferable>(String name, TransferableRecord<T> record) {
    records[name] = record;
    listGenerators[name] = (data) {
      final value = (data as Iterable).map((value) => record.constructor(value)).toList();
      return TransferableList<T>(value);
    };
    mapGenerators[name] = (data) {
      final value = (data as Map<String, dynamic>).map<String, T>((key, value) => MapEntry(key, record.constructor(value)));
      return TransferableMap<T>(value);
    };
    setGenerators[name] = (data) {
      final set = (data as Iterable).map((value) => record.constructor(value)).toSet();
      return TransferableSet<T>(set);
    };
  }

  void addEnum<E extends Enum>(String name, EnumRecord<E> record) => enums[name] = record;

  TransferableConstructor get(String name) => records[name]!.constructor;

  String enumName(Type type) =>
      enums.keys.firstWhere((key) => enums[key]!.type == type, orElse: () => throw TypeNotFoundException(type));

  String transferableName(Type type) =>
      records.keys.firstWhere((key) => records[key]!.type == type, orElse: () => throw TypeNotFoundException(type));
}

abstract class Transferable {
  static TransferableRegistry registry = TransferableRegistry();

  Map<String, dynamic> toMap();

  const Transferable();

  factory Transferable.fromMap(Map<String, dynamic> data) {
    throw UnimplementedError(data.toString());
  }

  static void register<T extends Transferable>(String name, TransferableConstructor<T> constructor) {
    registry.addRecord<T>(name, TransferableRecord<T>(name, constructor));
  }

  static void registerEnum<T extends Enum>(String name, EnumConstructor<T> constructor) {
    registry.addEnum<T>(name, EnumRecord<T>(name, constructor));
  }


  static dynamic serialize(dynamic data) {
    switch (data) {
      case String data:
        return data;
      case num data:
        return data;
      case bool data:
        return data;
      case Enum data:
        return {'enumType': registry.enumName(data.runtimeType), 'value': data.name};
      case DateTime data:
        return {'plainType': 'DateTime', 'value': data.toIso8601String()};
      case TransferableList data:
        return {'transferableListType': data.name, 'value': data.toTransfer()};
      case TransferableMap data:
        return {'transferableMapType': data.name, 'value': data.toTransfer()};
      case TransferableSet data:
        return {'transferableSetType': data.name, 'value': data.toTransfer()};
      case Transferable data:
        return {
          'transferableType': registry.transferableName(data.runtimeType),
          'value': data.toMap(),
        };
      case Iterable<int> data:
        return {'plainListType': 'int', 'value': List.from(data)};
      case Iterable<double> data:
        return {'plainListType': 'double', 'value': List.from(data)};
      case Iterable<num> data:
        return {'plainListType': 'num', 'value': List.from(data)};
      case Iterable<String> data:
        return {'plainListType': 'String', 'value': List.from(data)};
      case Iterable<bool> data:
        return {'plainListType': 'bool', 'value': List.from(data)};
      case Iterable<DateTime> data:
        return {
          'plainListType': 'DateTime',
          'value': data.map((value) => value.toIso8601String()).toList(growable: false)
        };
      case Iterable<Transferable> data:
        return {
          'plainListType': 'Transferable',
          'value': data.map(Transferable.serialize).toList(growable: false)
        };
      case Iterable<dynamic> data:
        return {
          'plainListType': 'dynamic',
          'value': data
        };
      case Map<String, int> data:
        return {'plainMapType': 'int', 'value': data};
      case Map<String, double> data:
        return {'plainMapType': 'double', 'value': data};
      case Map<String, num> data:
        return {'plainMapType': 'num', 'value': data};
      case Map<String, String> data:
        return {'plainMapType': 'String', 'value': data};
      case Map<String, bool> data:
        return {'plainMapType': 'bool', 'value': data};
      case Map<String, DateTime> data:
        return {
          'plainMapType': 'DateTime',
          'value': data.map<String, String>((key, value) => MapEntry(key, value.toIso8601String()))
        };
      case Map<String, Transferable> data:
        return {
          'plainMapType': 'Transferable',
          'value': data.map<String, Map<String, dynamic>>((key, value) => MapEntry(key, value.toMap()))
        };
      case Map<String, dynamic> data:
        return {'plainMapType': 'dynamic', 'value': data};
    }
  }

  static dynamic materialize(dynamic data) {
    switch (data) {
      case String data:
        {
          return data;
        }
      case num data:
        {
          return data;
        }
      case bool data:
        {
          return data;
        }
      case Map<String, dynamic> data:
        {
          if (data.length != 2) return null;
          final dynamic value = data['value'];
          final String key = data.keys.first;
          final String type = data.values.first;
          switch (key) {
            case 'plainType': {
              switch (type) {
                case 'DateTime':
                  return DateTime.parse(value);
              }
            }
            case 'transferableType':
              {
                final record = registry.records[type]!;
                return record.constructor(value as Map<String, dynamic>);
              }
            case 'plainListType':
              {
                return switch (type) {
                  'String' => List<String>.from(value),
                  'int' => List<int>.from(value),
                  'double' => List<double>.from(value),
                  'num' => List<num>.from(value),
                  'bool' => List<bool>.from(value),
                  'DateTime' => List<DateTime>.from((value as List<String>).map<DateTime>(DateTime.parse)),
                  'Transferable' => List<Transferable>.from((value as List<dynamic>).map(Transferable.materialize)),
                  _ => value as List<dynamic>
                };
              }
            case 'plainMapType':
              {
                return switch (type) {
                  'String' => Map<String, String>.from(value),
                  'int' => Map<String, int>.from(value),
                  'double' => Map<String, double>.from(value),
                  'num' => Map<String, num>.from(value),
                  'bool' => Map<String, bool>.from(value),
                  'DateTime' => Map<String, DateTime>.from((value as Map<String, String>).map<String, DateTime>((key, valueData) => MapEntry(key, DateTime.parse(valueData)))),
                  'Transferable' => Map<String, Transferable>.from((value as Map<String, dynamic>).map<String, Transferable>((key, valueData) => MapEntry(key, Transferable.materialize(valueData)))),
                  _ => value as Map<String, dynamic>
                };
              }
            case 'transferableListType':
              {
                return registry.listGenerators[type]!.call(value);
              }
            case 'transferableSetType':
              {
                return registry.setGenerators[type]!.call(value);
              }
            case 'transferableMapType':
              {
                return registry.mapGenerators[type]!.call(value);
              }
            case 'enumType': {
              final enumType = registry.enums[data['enumType'] as String]!;
              return enumType.constructor(data['value'] as String);
            }
          }
        }
    }

    // final String type;
    // if (data is String || data is num || data is bool) {
    //   return data;
    // }
    // if (data is Map<String, dynamic>) {
    //   if (data.length == 2 && data.containsKey('transferableType') && data.containsKey('value')) {
    //     final type = data['transferableType'] as String;
    //     final value = data['value'];
    //     if (type == 'DateTime') {
    //       return DateTime.parse(value as String);
    //     }
    //     final record = registry.records[type]!;
    //     return record.constructor(value as Map<String, dynamic>);
    //   } else if (data.length == 2 && data.containsKey('enumType') && data.containsKey('value')) {
    //     final enumType = registry.enums[data['enumType'] as String]!;
    //     return enumType.constructor(data['value'] as String);
    //   } else if (data.length == 2 && data.containsKey('transferableListType')) {
    //     return registry.listGenerators[data['transferableListType']]?.call(data['value']);
    //   } else if (data.length == 2 && data.containsKey('transferableMapType')) {
    //     return registry.mapGenerators[data['transferableMapType']]?.call(data['value']);
    //   } else if (data.length == 2 && data.containsKey('transferableSetType')) {
    //     return registry.setGenerators[data['transferableSetType']]?.call(data['value']);
    //   } else {
    //     return Map.fromEntries(data.entries.map((entry) => MapEntry(entry.key, Transferable.materialize(entry.value))));
    //   }
    // }
    // if (data is Iterable) {
    //   return data.fold<List<dynamic>>([], (list, value) {
    //     list.add(Transferable.materialize(value));
    //     return list;
    //   });
    // }
  }

  static dynamic copy(dynamic data) {
    if (data is Enum) {
      return data;
    }
    if (data is String || data is num || data is bool || data is DateTime) {
      return data;
    }
    if (data is Map<String, dynamic>) {
      return data.map((key, value) => MapEntry(key, Transferable.copy(value) as dynamic));
    }
    if (data is Iterable<dynamic>) {
      return data.map(Transferable.copy).cast<dynamic>().toList(growable: false);
    }
    if (data is Transferable) {
      return Transferable.registry.get(registry.transferableName(data.runtimeType))(data.toMap());
    }
  }
}
