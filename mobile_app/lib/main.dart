import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'services/api_service.dart';
import 'providers/sensor_provider.dart';
import 'theme/app_theme.dart';
import 'screens/main_shell_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MosquitoGuardApp());
}

class MosquitoGuardApp extends StatelessWidget {
  const MosquitoGuardApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => SensorProvider()..checkAndFetchData(isInitialLoad: true),
        ),
        Provider(create: (_) => ApiService()),
      ],
      child: MaterialApp(
        title: 'Mosquito Guard',
        theme: AppTheme.darkTheme,
        themeMode: ThemeMode.dark,
        home: const AppHome(),
        debugShowCheckedModeBanner: false,
        builder: (context, child) {
          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 430),
              child: child!,
            ),
          );
        },
      ),
    );
  }
}

class AppHome extends StatelessWidget {
  const AppHome({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Open directly to the main dashboard shell with 0 delay and zero loading screen
    return const MainShellScreen();
  }
}
