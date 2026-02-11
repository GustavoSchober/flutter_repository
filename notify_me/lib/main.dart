import 'package:flutter/material.dart';
import 'package:notify_me/screens/home_screen.dart';
import 'package:notify_me/services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NotificationService().init();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Notify Me',
      theme: ThemeData(
        scaffoldBackgroundColor: const Color.fromARGB(255, 0, 0, 0), // Space Indigo 262322
        useMaterial3: true,
      ),
      home: const NotificationHomeScreen(),
    );
  }
}
