import 'dart:collection';

import 'package:depot/src/transferable.dart';
import 'package:depot/src/transferable_types/transferable_type_adapter.dart';

class TransferableQueue<T extends Transferable> extends ListQueue<T> with TransferableTypeAdapter {
  @override
  final String name;

  TransferableQueue.fromList(List<T> value) : name = TransferableRegistry().transferableName(T) {
    addAll(value);
  }

  TransferableQueue(super.initialCapacity)
      : name = TransferableRegistry().transferableName(T);

  @override
  Queue<dynamic> toTransfer() {
    return ListQueue.from(map((e) => Transferable.serialize(e)));
  }
}
