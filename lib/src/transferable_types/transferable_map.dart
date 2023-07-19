import 'dart:collection';

import 'package:depot/src/transferable.dart';
import 'package:depot/src/transferable_types/transferable_type_adapter.dart';

class TransferableMap<T extends Transferable> extends MapBase<String, T> with TransferableTypeAdapter {
  @override
  final String name;
  final Map<String, T> _internal;

  TransferableMap([Map<String, T>? value])
      : name = TransferableRegistry().transferableName(T),
        _internal = value ?? <String, T>{};

  @override
  T? operator [](Object? key) => _internal[key];

  @override
  void operator []=(String key, T value) => _internal[key] = value;

  @override
  void clear() => _internal.clear();

  @override
  Iterable<String> get keys => _internal.keys;

  @override
  T? remove(Object? key) => _internal.remove(key);
  
  @override
  Map<String, dynamic> toTransfer() {
    // return Map.fromEntries(_internal.entries.map((e) => MapEntry(e.key, Transferable.serialize(e.value))));
    return Map.fromEntries(_internal.entries.map((e) => MapEntry(e.key, e.value.toMap())));
  }
}
