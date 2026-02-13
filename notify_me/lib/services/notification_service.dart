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
      // Na versão 3.0.0, isso DEVE retornar uma String.
      // Se por acaso retornar algo diferente, o catch pega e usa o padrão.
      final String timeZoneName = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(timeZoneName));
    } catch (e) {
      print("⚠️ Erro ao obter Timezone: $e");
      // Fallback seguro: usa o horário de São Paulo se der ruim
      tz.setLocalLocation(tz.getLocation('America/Sao_Paulo'));
    }

    // 2. Configurações Android
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
    );

    // 3. Inicializar
    await flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        print("Payload: ${response.payload}");
      },
    );
    
    await _requestPermissions();
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

        // CONFIGURAÇÃO TURBINADA V3 🚀
        const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
          'canal_lembretes_v3',   // <--- MUDAMOS PARA V3 (Isso reseta as configs no Android)
          'Lembretes Importantes', // Nome que aparece nas configs do Android
          channelDescription: 'Canal para notificações de apps',
          importance: Importance.max, // Importância Máxima (Faz barulho e aparece pop-up)
          priority: Priority.high,    // Prioridade Alta
          
          // Configurações de Som e Vibração
          playSound: true,
          enableVibration: true,
          
          // Garante que apareça na tela de bloqueio
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