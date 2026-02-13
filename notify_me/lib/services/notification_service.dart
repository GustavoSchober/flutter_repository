import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'dart:io';
import 'package:device_apps/device_apps.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    // 1. Configurar Timezone
    tz.initializeTimeZones();
    
    try {
      final String timeZoneName = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(timeZoneName));
    } catch (e) {
      print("⚠️ Erro ao obter Timezone: $e");
      tz.setLocalLocation(tz.getLocation('America/Sao_Paulo'));
    }

    // 2. Configurações Android
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
    );

    // 3. Inicializar e Configurar o Clique (Para quando o app JÁ ESTÁ ABERTO/MINIMIZADO)
    await flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        _openTargetApp(response.payload);
      },
    );

    // 4. VERIFICAÇÃO DE COLD START (Para quando o app ESTAVA FECHADO)
    // O app pergunta: "Fui lançado por uma notificação?"
    final NotificationAppLaunchDetails? notificationAppLaunchDetails =
        await flutterLocalNotificationsPlugin.getNotificationAppLaunchDetails();

    // Se sim, e se tiver payload, executa a abertura
    if (notificationAppLaunchDetails?.didNotificationLaunchApp ?? false) {
      final payload = notificationAppLaunchDetails!.notificationResponse?.payload;
      print("🚀 App reiniciado via notificação! Payload: $payload");
      _openTargetApp(payload);
    }
    
    await _requestPermissions();
  }
  
  // --- FUNÇÃO AUXILIAR PARA ABRIR O APP (DRY - Don't Repeat Yourself) ---
  Future<void> _openTargetApp(String? payload) async {
    if (payload != null && payload.isNotEmpty) {
      print("🚀 Tentando abrir pacote: $payload");
      bool isOpened = await DeviceApps.openApp(payload);
      
      if (!isOpened) {
        print("❌ Falha ao abrir o app. Talvez ele tenha sido desinstalado?");
      }
    }
  }

  Future<void> _requestPermissions() async {
    if (Platform.isAndroid) {
      final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
          flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();

      await androidImplementation?.requestNotificationsPermission();
    }
  }

  // --- AGENDAR ---
  Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required int hour,
    required int minute,
    required String payload,
  }) async {
    
    final now = tz.TZDateTime.now(tz.local);
    var scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );

    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    print("🕒 AGORA:     $now");
    print("⏰ AGENDADO:  $scheduledDate");

    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'canal_lembretes_v3', 
      'Lembretes Importantes', 
      channelDescription: 'Canal para notificações de apps',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
      visibility: NotificationVisibility.public,
    );

    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
    );

    await flutterLocalNotificationsPlugin.zonedSchedule(
      id,
      title,
      body,
      scheduledDate,
      notificationDetails,
      androidAllowWhileIdle: true,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
      payload: payload,
    );
  }

  Future<void> cancelNotification(int id) async {
    await flutterLocalNotificationsPlugin.cancel(id);
  }
}