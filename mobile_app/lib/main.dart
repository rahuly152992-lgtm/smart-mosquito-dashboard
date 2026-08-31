import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'services/api_service.dart';
import 'providers/sensor_provider.dart';
import 'screens/home_screen.dart';
import 'screens/connection_screen.dart';

void main() {
  runApp(const MosquitoGuardApp());
}

class MosquitoGuardApp extends StatelessWidget {
  const MosquitoGuardApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => SensorProvider()),
        Provider(create: (_) => ApiService()),
      ],
      child: MaterialApp(
        title: 'Mosquito Guard',
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF0284c7),
            brightness: Brightness.light,
          ),
          fontFamily: 'Inter',
        ),
        home: const AppHome(),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}

class AppHome extends StatelessWidget {
  const AppHome({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<SensorProvider>(
      builder: (context, sensorProvider, _) {
        // Show connection screen if hardware not connected
        if (!sensorProvider.isConnected) {
          return const ConnectionScreen();
        }
        // Show home screen with sensor data if connected
        return const HomeScreen();
      },
    );
  }
}
