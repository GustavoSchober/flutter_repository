import 'package:flutter/material.dart';
import 'package:notify_me/screens/home_screen.dart';
import 'package:notify_me/services/notification_service.dart';
import 'package:notify_me/services/app_cache_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NotificationService().init();

  // Pré-carrega os apps instalados no cache (só roda 1 vez)
  AppCacheService().loadApps();

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Quando o app volta do background, recarrega o cache de apps
      // Isso captura installs/uninstalls que aconteceram enquanto o app estava minimizado
      AppCacheService().refresh();
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Notify Me',
      theme: ThemeData(
        scaffoldBackgroundColor: const Color.fromARGB(255, 0, 0, 0),
        useMaterial3: true,
      ),
      home: const NotificationHomeScreen(),
    );
  }
}
