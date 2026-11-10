import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'services/movement_sensor_service.dart';
import 'services/gps_tracking_service.dart';
import 'ui/screens/home_tracker_screen.dart';
import 'ui/theme/health_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: HealthTheme.background,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => MovementSensorService()),
        ChangeNotifierProvider(create: (_) => GpsTrackingService()),
      ],
      child: const SmartHealthTrackerApp(),
    ),
  );
}

class SmartHealthTrackerApp extends StatelessWidget {
  const SmartHealthTrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Health Step Pulse',
      debugShowCheckedModeBanner: false,
      theme: HealthTheme.darkTheme,
      home: const HomeTrackerScreen(),
    );
  }
}
