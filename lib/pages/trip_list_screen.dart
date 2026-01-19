import 'package:eco_drive/data/trip.dart';
import 'package:eco_drive/pages/drive_screen.dart';
import 'package:eco_drive/providers/trips_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class TripListScreen extends StatefulWidget {
  const TripListScreen({super.key});

  @override
  State<TripListScreen> createState() => _TripListScreenState();
}

class _TripListScreenState extends State<TripListScreen> {
  List<Trip> trips = [];

  @override
  Widget build(BuildContext context) {
    final tripsProvider = Provider.of<TripsProvider>(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Saved Trips')),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.eco),
        label: const Text('Start Trip'),
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const DriveScreen()),
          );
        },
      ),
      body: ListView.builder(
        itemCount: tripsProvider.trips.length,
        itemBuilder: (c, i) {
          final t = tripsProvider.trips[i];
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
                                await tripsProvider.deleteTrip(t);
                                if(c.mounted) Navigator.pop(c);
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
