import 'package:eco_drive/data/trip.dart';
import 'package:eco_drive/utils/trip_storage.dart';
import 'package:flutter/material.dart';

class TripsProvider extends ChangeNotifier {
  List<Trip> _trips = [];

  List<Trip> get trips => _trips;

  Future loadTrips() async {
    return TripStorage.loadTrips().then((t) {
      _trips = t;
    }).whenComplete(() => notifyListeners());
  }

  Future deleteTrip(Trip trip) async {
    return TripStorage.deleteTrip(trip).then((_) {
      _trips.removeWhere((t) => t.id == trip.id);
    }).whenComplete(() => notifyListeners());
  }

  Future saveTrip(Trip trip) async {
    return TripStorage.saveTrip(trip).then((_) {
      _trips.add(trip);
    }).whenComplete(() => notifyListeners());
  }
}
