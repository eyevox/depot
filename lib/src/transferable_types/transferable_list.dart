import 'dart:collection';

import 'package:depot/src/transferable.dart';
import 'package:depot/src/transferable_types/transferable_type_adapter.dart';

class TransferableList<T extends Transferable> extends ListBase<T> with TransferableTypeAdapter implements Transferable {
  @override
  final String name;
  final List<T> _list;

  TransferableList([List<T>? list])
    : name = TransferableRegistry().transferableName(T),
      _list = (T is TransferableList) ? (list?.toList() ?? <T>[]) : list ?? <T>[];

  factory TransferableList.fromMap(Map<String, dynamic> data) => Transferable.materialize(data);

  @override
  int get length => _list.length;

  @override
  void add(T value) {
    _list.add(value);
  }

  @override
  void addAll(Iterable<T> value) {
    _list.addAll(value);
  }

  @override
  set length(int newLength) {
    _list.length = newLength;
  }

  @override
  T operator [](int index) {
    return _list[index];
  }

  @override
  void operator []=(int index, T value) {
    _list[index] = value;
  }
  
  @override
  // List<dynamic> toTransfer() => _list.map((e) => Transferable.serialize(e)).toList();
  List<dynamic> toTransfer() => _list.map((e) => e.toMap()).toList();

  @override
  Map<String, dynamic> toMap() => Transferable.serialize(this);

}
