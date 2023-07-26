import 'package:depot/depot.dart';
import 'package:test/expect.dart';
import 'package:test/scaffolding.dart';

import 'walk_log/footprint.dart';
import 'walk_log/walk_module.dart';

void main() {
  group(
    'Complex calls testing',
    () {
      Transferable.register<Footprint>('Footprint', Footprint.fromMap);
      Depot().localRegister<WalkFacade>(
          constructor: WalkFacade.new, module: WalkModule(), name: WalkFacade.name);

      final WalkOne = TransferableList([Footprint(latitude: 50, longitude: 60, timestamp: DateTime.parse('2022-10-19T22:54:31.300Z')), Footprint(latitude: 51, longitude: 60, timestamp: DateTime.parse('2022-10-19T22:54:31.400Z'))]);
      final WalkTwo = TransferableList([Footprint(latitude: 51, longitude: 61, timestamp: DateTime.parse('2022-10-19T22:54:31.500Z')), Footprint(latitude: 50, longitude: 61, timestamp: DateTime.parse('2022-10-19T22:54:32.600Z'))]);

      test('From points', () async {
        final combinedWalk = await Depot<WalkFacade>().request<List<Footprint>>().fromPoints(TransferableList<Footprint>([WalkOne[0], WalkOne[1]]));
        expect(combinedWalk.length, equals(2));
      });

      //TODO Implement recursive lists
      // test('Combine', () async {
      //   final combinedWalk = await Depot<WalkFacade>().request<List<Footprint>>().combine(TransferableList<TransferableList<Footprint>>([WalkOne, WalkTwo]));
      //   expect(combinedWalk.length, equals(4));
      // });
    },
  );
}
