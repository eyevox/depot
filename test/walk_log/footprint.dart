import 'package:depot/depot.dart';

class Footprint extends Transferable {
  final double latitude;
  final double longitude;
  final DateTime timestamp;

  Footprint({required this.latitude, required this.longitude, required this.timestamp});

  factory Footprint.fromMap(Map<String, dynamic> data) =>
      Footprint(latitude: data['lat'], longitude: data['lon'], timestamp: DateTime.parse(data['stamp']));

  @override
  Map<String, dynamic> toMap() => {
    'lat': latitude,
    'lon': longitude,
    'stamp': timestamp.toIso8601String()
  };
}
