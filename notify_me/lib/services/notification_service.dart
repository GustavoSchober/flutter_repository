import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'dart:io'; // Para verificar se é Android

class NotificationService {
  // Singleton
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  // Inicialização
  Future<void> init() async {
    // 1. Configuração do Fuso Horário
    tz.initializeTimeZones();
    final String timeZoneName = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(timeZoneName));

    // 2. Configuração do Android (Ícone da notificação)
    // O ícone precisa estar na pasta: android/app/src/main/res/drawable/
    // Se não tiver um ícone customizado, usamos o @mipmap/ic_launcher padrão
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    // 3. Configuração Geral
    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
    );

    // 4. Inicia o plugin
    await flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) async {
        // AQUI É ONDE VAMOS CONFIGURAR O CLIQUE NA NOTIFICAÇÃO DEPOIS
        print("Notificação clicada! Payload: ${response.payload}");
      },
    );
    
    // 5. Pedir permissão no Android 13+
    await _requestPermissions();
  }
  
  // Função para pedir permissão (Android 13+)
  Future<void> _requestPermissions() async {
    if (Platform.isAndroid) {
      final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
          flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();

      await androidImplementation?.requestNotificationsPermission();
    }
  }

  // --- AGENDAR NOTIFICAÇÃO ---
  Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required int hour,
    required int minute,
    required String payload, // O pacote do app para abrir depois
  }) async {
    
    // Calcula o horário de hoje
    final now = tz.TZDateTime.now(tz.local);
    var scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );

    // Se o horário já passou hoje, agenda para amanhã
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    // Detalhes visuais da notificação
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'notify_me_channel', // ID do canal
      'Lembretes de Apps', // Nome visível pro usuário nas configs
      channelDescription: 'Canal para notificações agendadas',
      importance: Importance.max,
      priority: Priority.high,
      showWhen: true,
    );

    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
    );

    // O Agendamento em si
    await flutterLocalNotificationsPlugin.zonedSchedule(
      id,
      title,
      body,
      scheduledDate,
      notificationDetails,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle, // Garante precisão mesmo com economia de bateria
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time, // REPETE DIARIAMENTE NESSE HORÁRIO!
      payload: payload,
    );
    
    print("Notificação agendada para: $scheduledDate");
  }

  // Cancelar Notificação
  Future<void> cancelNotification(int id) async {
    await flutterLocalNotificationsPlugin.cancel(id);
  }
}