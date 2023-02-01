import 'package:depot/src/depot_exceptions.dart';
import 'package:depot/src/transferable_types/transferable_set.dart';
import 'package:depot/src/transferable_types/transferable_list.dart';
import 'package:depot/src/transferable_types/transferable_map.dart';
import 'package:depot/src/transferable_types/transferable_queue.dart';
import 'package:depot/src/transferable_types/transferable_type_adapter.dart';

typedef TransferableConstructor<T extends Transferable> = T Function(
    Map<String, dynamic> data);
typedef EnumConstructor<E extends Enum> = E Function(String data);
typedef CollectionGenerator<C extends TransferableTypeAdapter> = C Function(
    dynamic data);

class TransferableRecord<T extends Transferable> {
  static final records = TransferableRegistry().records;
  Type type = T;
  TransferableConstructor<T> constructor;

  TransferableRecord.internal(this.constructor);

  factory TransferableRecord(
      String name, TransferableConstructor<T> constructor) {
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
  Map<String, CollectionGenerator<TransferableQueue>> queueGenerators = {};
  // Map<Type, EnumRecord> enumsByType = {};

  TransferableRegistry.internal();

  static final _self = TransferableRegistry.internal();

  factory TransferableRegistry() => _self;

  void add<T extends Transferable>(
          String name, TransferableConstructor<T> constructor) =>
      records[name] = TransferableRecord<T>.internal(constructor);

  void addRecord<T extends Transferable>(
      String name, TransferableRecord<T> record) {
    records[name] = record;
    listGenerators[name] = (data) {
      final value =
          (data as Iterable).map(Transferable.materialize).toList().cast<T>();
      return TransferableList<T>(value);
    };
    mapGenerators[name] = (data) {
      final value = Map<String, T>.fromEntries((data as Map<String, dynamic>)
          .entries
          .map((e) => MapEntry(e.key, Transferable.materialize(e.value) as T)));
      return TransferableMap<T>(value);
    };
    setGenerators[name] =(data) {
      final set = (data as Set<dynamic>).map(Transferable.materialize).toSet().cast<T>();
      return TransferableSet<T>(Set<T>.from(set));
    };
    queueGenerators[name] =(data) {
      throw UnsupportedError('queue is not supporting current time');
    };
  }

  void addEnum<E extends Enum>(String name, EnumRecord<E> record) =>
      enums[name] = record;

  TransferableConstructor get(String name) => records[name]!.constructor;

  String enumName(Type type) =>
      enums.keys.firstWhere((key) => enums[key]!.type == type,
          orElse: () => throw TypeNotFoundException(type));

  String transferableName(Type type) =>
      records.keys.firstWhere((key) => records[key]!.type == type,
          orElse: () => throw TypeNotFoundException(type));
}

abstract class Transferable {
  static TransferableRegistry registry = TransferableRegistry();

  Map<String, dynamic> toMap();

  Transferable();

  factory Transferable.fromMap(Map<String, dynamic> data) {
    throw UnimplementedError(data.toString());
  }

  static void register<T extends Transferable>(
      String name, TransferableConstructor<T> constructor) {
    registry.addRecord<T>(name, TransferableRecord<T>(name, constructor));
  }

  static void registerEnum<T extends Enum>(
      String name, EnumConstructor<T> constructor) {
    registry.addEnum<T>(name, EnumRecord<T>(name, constructor));
  }

  static dynamic serialize(dynamic data) {
    if (data is String || data is num || data is bool) {
      return data;
    }
    if (data is Enum) {
      return {
        'enumType': registry.enumName(data.runtimeType),
        'value': data.name,
      };
    }
    if (data is DateTime) {
      return {'transferableType': 'DateTime', 'value': data.toIso8601String()};
    }
    if (data is TransferableList) {
      return {
        'transferableListType': data.name,
        'value': data.toTransfer(),
      };
    }
    if (data is TransferableMap) {
      final result = {
        'transferableMapType': data.name,
        'value': data.toTransfer(),
      };
      return result;
    }
    if (data is TransferableSet) {
      return {
        'transferableSetType': data.name,
        'value': data.toTransfer(),
      };
    }
    if (data is TransferableQueue) {
      return {
        'transferableQueueType': data.name,
        'value': data.toTransfer(),
      };
    }
    if (data is Iterable) {
      return data.fold<List<dynamic>>(<dynamic>[], (list, value) {
        list.add(Transferable.serialize(value));
        return list;
      });
    }
    if (data is Transferable) {
      return {
        'transferableType': registry.transferableName(data.runtimeType),
        'value': data.toMap(),
      };
    }
  }

  static dynamic materialize(dynamic data) {
    // final String type;
    if (data is String || data is num || data is bool) {
      return data;
    }
    if (data is Map<String, dynamic>) {
      if (data.length == 2 &&
          data.containsKey('transferableType') &&
          data.containsKey('value')) {
        final type = data['transferableType'] as String;
        final value = data['value'];
        if (type == 'DateTime') {
          return DateTime.parse(value as String);
        }
        final record = registry.records[type]!;
        return record.constructor(value as Map<String, dynamic>);
      } else if (data.length == 2 &&
          data.containsKey('enumType') &&
          data.containsKey('value')) {
        final enumType = registry.enums[data['enumType'] as String]!;
        return enumType.constructor(data['value'] as String);
      } else if (data.length == 2 && data.containsKey('transferableListType')) {
        return registry.listGenerators[data['transferableListType']]
            ?.call(data['value']);
      } else if (data.length == 2 && data.containsKey('transferableMapType')) {
        // final name = data['transferableMapType'] as String;
        // final value = data['value'];
        return registry.mapGenerators[data['transferableMapType']]
            ?.call(data['value']);
      } else if (data.length == 2 && data.containsKey('transferableSetType')) {
        return registry.setGenerators[data['transferableSetType']]
            ?.call(data['value']);
      } else if (data.length == 2 && data.containsKey('transferableQueueType')) {
        return registry.queueGenerators[data['transferableSetType']]
            ?.call(data['value']);
      } else {
        return Map.fromEntries(data.entries.map((entry) =>
            MapEntry(entry.key, Transferable.materialize(entry.value))));
      }
    }
    if (data is Iterable) {
      return data.fold<List<dynamic>>([], (list, value) {
        list.add(Transferable.materialize(value));
        return list;
      });
    }
  }

  static dynamic copy(dynamic data) {
    if(data is Enum) {
      return data;
    }
    if (data is String || data is num || data is bool || data is DateTime) {
      return data;
    }
    if (data is Map<String, dynamic>) {
      return data.map(
          (key, value) => MapEntry(key, Transferable.copy(value) as dynamic));
    }
    if (data is Iterable<dynamic>) {
      return data
          .map(Transferable.copy)
          .cast<dynamic>()
          .toList(growable: false);
    }
    if (data is Transferable) {
      return Transferable.registry
          .get(registry.transferableName(data.runtimeType))(data.toMap());
    }
  }
}
