import 'dart:convert';
import 'dart:io';

import 'package:eco_drive/data/trip.dart';
import 'package:path_provider/path_provider.dart';

class TripStorage {
  static Future<Directory> _dir() async {
    final base = await getApplicationDocumentsDirectory();
    final dir = Directory('${base.path}/trips');
    if (!dir.existsSync()) dir.createSync(recursive: true);
    return dir;
  }

  static Future<void> saveTrip(Trip trip) async {
    final dir = await _dir();
    final file = File('${dir.path}/${trip.id}.json');
    await file.writeAsString(jsonEncode(trip.toJson()));
  }

  static Future<List<Trip>> loadTrips() async {
    final dir = await _dir();
    final files = dir.listSync().whereType<File>();
    final trips = <Trip>[];

    for (final f in files) {
      final json = jsonDecode(await f.readAsString());
      trips.add(Trip.fromJson(json));
    }

    trips.sort((a, b) => b.start.compareTo(a.start));
    return trips;
  }

  static Future<void> deleteTrip(Trip trip) async {
    final dir = await _dir();
    final file = File('${dir.path}/${trip.id}.json');
    if (file.existsSync()) {
      await file.delete();
    }
  }
}
