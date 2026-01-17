import 'package:eco_drive/data/trip.dart';
import 'package:eco_drive/pages/drive_screen.dart';
import 'package:eco_drive/utils/trip_storage.dart';
import 'package:flutter/material.dart';

class TripListScreen extends StatefulWidget {
  const TripListScreen({super.key});

  @override
  State<TripListScreen> createState() => _TripListScreenState();
}

class _TripListScreenState extends State<TripListScreen> {
  List<Trip> trips = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    trips = await TripStorage.loadTrips();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Saved Trips')),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.play_arrow),
        label: const Text('Start Trip'),
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const DriveScreen()),
          );
          _load();
        },
      ),
      body: ListView.builder(
        itemCount: trips.length,
        itemBuilder: (c, i) {
          final t = trips[i];
          return Card(
            child: ListTile(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              title: Text('Trip ${t.start}'),
              subtitle: Text('${t.samples.length} samples'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => DriveScreen(viewTrip: t)),
                );
              },
              onLongPress:
                  () => showDialog(
                    context: context,
                    builder:
                        (c) => AlertDialog(
                          title: const Text('Delete Trip?'),
                          content: const Text(
                            'Are you sure you want to delete this trip?',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(c),
                              child: const Text('Cancel'),
                            ),
                            TextButton(
                              onPressed: () async {
                                await TripStorage.deleteTrip(t);
                                Navigator.pop(c);
                                _load();
                              },
                              child: const Text('Delete'),
                            ),
                          ],
                        ),
                  ),
            ),
          );
        },
      ),
    );
  }
}
