import 'dart:collection';

import 'package:depot/src/transferable.dart';
import 'package:depot/src/transferable_types/transferable_type_adapter.dart';

class TransferableSet<T extends Transferable> extends SetBase<T> with TransferableTypeAdapter {
  @override
  final String name;
  final Set<T> _internal;

  TransferableSet([Set<T>? value])
    : name = TransferableRegistry().transferableName(T),
      _internal = value ?? <T>{};

  @override
  bool add(T value) =>
    _internal.add(value);

  @override
  bool contains(Object? element) => _internal.contains(element);

  @override
  T? lookup(Object? element) => _internal.lookup(element);

  @override
  bool remove(Object? value) => _internal.remove(value);

  @override
  Set<T> toSet() => _internal.toSet();

  @override
  Iterator<T> get iterator => _internal.iterator;

  @override
  int get length => _internal.length;
  
  @override
  Set<dynamic> toTransfer() {
    return _internal.map((e) => Transferable.serialize(e)).toSet();
  }
}
