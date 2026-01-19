import 'package:eco_drive/pages/trip_list_screen.dart';
import 'package:eco_drive/providers/trips_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [ChangeNotifierProvider(create: (_) => TripsProvider())],
      child: MaterialAppWidget(),
    );
  }
}

class MaterialAppWidget extends StatelessWidget {
  const MaterialAppWidget({super.key});

  @override
  Widget build(BuildContext context) {
    generateTheme(Brightness b) => ThemeData(
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: Colors.transparent,
      ),
      colorScheme: ColorScheme.fromSeed(
        seedColor: Colors.lightGreen,
        brightness: b,
      ),
      useMaterial3: true,
    );
    return MaterialApp(
      title: 'EcoDrive',
      theme: generateTheme(Brightness.light),
      darkTheme: generateTheme(Brightness.dark),
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.system,
      home: const TripListScreen(),
    );
  }
}
