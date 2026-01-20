import 'package:eco_drive/data/trip_aggregates.dart';
import 'package:eco_drive/pages/drive_screen.dart';
import 'package:eco_drive/providers/trips_provider.dart';
import 'package:eco_drive/widgets/summary_card.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class TripListScreen extends StatefulWidget {
  const TripListScreen({super.key});

  @override
  State<TripListScreen> createState() => _TripListScreenState();
}

class _TripListScreenState extends State<TripListScreen> {
  bool isLoading = true;
  double totalDistanceKm = 0;
  double avgSpeed = 0;
  double ecoScore = 0;

  _initializeTrips(BuildContext context) async {
    Provider.of<TripsProvider>(context, listen: false).loadTrips().whenComplete(
      () => setState(() {
        isLoading = false;
      }),
    );
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeTrips(context);
    });
  }

  @override
  Widget build(BuildContext context) {
    final tripsProvider = Provider.of<TripsProvider>(context);
    final aggregates = TripAggregates.computeAggregates(tripsProvider.trips);
    return isLoading
        ? const Center(child: CircularProgressIndicator())
        : Scaffold(
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
          body:
              tripsProvider.trips.isEmpty
                  ? Center(
                    child: Text(
                      'No trips recorded yet.\nStart a new trip!',
                      textAlign: TextAlign.center,
                      style: Theme.of(
                        context,
                      ).textTheme.headlineMedium?.copyWith(
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withAlpha(125),
                      ),
                    ),
                  )
                  : Column(
                    children: [
                      SummaryCard(
                        tripCount: tripsProvider.trips.length,
                        totalDistanceMeters: aggregates.totalDistanceMeters,
                        avgSpeedMps: aggregates.avgSpeedMps,
                        ecoScore: aggregates.ecoScore,
                      ),
                      Expanded(
                        child: ListView.builder(
                          itemCount: tripsProvider.trips.length,
                          itemBuilder: (c, i) {
                            final t = tripsProvider.trips[i];
                            return Card(
                              child: ListTile(
                                title: Text('Trip ${t.start}'),
                                subtitle: Text('${t.samples.length} samples'),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => DriveScreen(viewTrip: t),
                                    ),
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
                                                onPressed:
                                                    () => Navigator.pop(c),
                                                child: const Text('Cancel'),
                                              ),
                                              TextButton(
                                                onPressed: () async {
                                                  await tripsProvider
                                                      .deleteTrip(t);
                                                  if (c.mounted)
                                                    Navigator.pop(c);
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
                      ),
                    ],
                  ),
        );
  }
}
