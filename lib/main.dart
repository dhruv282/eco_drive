import 'package:eco_drive/pages/trip_list_screen.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
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
