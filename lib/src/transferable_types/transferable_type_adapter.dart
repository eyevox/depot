import 'package:depot/src/transferable_types/transferable_list.dart';

abstract class TransferableTypeAdapter {
  abstract final String name;
  dynamic toTransfer();
}
