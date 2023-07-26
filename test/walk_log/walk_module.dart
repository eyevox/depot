import 'package:depot/depot.dart';

import 'footprint.dart';

class WalkFacade extends Facade {

  Future<List<Footprint>> combine(List<List<Footprint>> list);
  Future<List<Footprint>> fromPoints(List<Footprint> list);

  WalkFacade(super.mode, super.tram, super.returnerConstructor);
  static String get name => 'WalkFacade';
}

class WalkModule extends Module implements WalkFacade {

  WalkModule() {
    addRequest(#combine, combine);
    addRequest(#fromPoints, fromPoints);
  }

  @override
  Future<TransferableList<Footprint>> combine(List<List<Footprint>> list) async {
    final result = list.fold(TransferableList<Footprint>(), (current, segment) => current..addAll(segment));
    return result;
  }

  @override
  Future<List<Footprint>> fromPoints(List<Footprint> list) async {
    // final result = TransferableList(list);
    final result = list.fold<TransferableList<Footprint>>(TransferableList<Footprint>(), (current, point) => current..add(point));
    return result;
  }

}
