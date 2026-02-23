import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'dart:io';
import 'package:installed_apps/installed_apps.dart';

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
  
  // --- FUNÇÃO AUXILIAR PARA ABRIR O APP ---
  Future<void> _openTargetApp(String? payload) async {
    if (payload != null && payload.isNotEmpty) {
      print("🚀 Tentando abrir pacote: $payload");
      
      // O comando mudou ligeiramente no novo pacote
      bool isOpened = await InstalledApps.startApp(payload) ?? false;
      
      // Nota: InstalledApps.startApp retorna void ou bool dependendo da versão, 
      // mas geralmente se não der erro, abriu.
      if (isOpened == false) { 
         print("❌ Falha ao abrir o app."); 
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

  // --- FUNÇÃO AUXILIAR DE TEMPO ---
  tz.TZDateTime _nextInstanceOfWeekday(int weekday, int hour, int minute) {
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduledDate = tz.TZDateTime(
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

    while (scheduledDate.weekday != weekday) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }
    return scheduledDate;
  }

  // --- AGENDAR ---
  Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required int hour,
    required int minute,
    required String payload,
    required List<int> days, 
  }) async {
    
    // 1. CAPTURA DO ÍCONE DINÂMICO 🖼️
    // Vamos buscar a foto (ícone) do app alvo no sistema antes de agendar
    AndroidBitmap<Object>? largeIcon;
    try {
      final appInfo = await InstalledApps.getAppInfo(payload, null);
      if (appInfo != null && appInfo.icon != null) {
        // Converte o ícone do formato do app para o formato que a notificação aceita
        largeIcon = ByteArrayAndroidBitmap(appInfo.icon!);
      }
    } catch (e) {
      print("⚠️ Erro ao carregar ícone para a notificação: $e");
    }

    // 2. CONFIGURAÇÃO DO ANDROID (Agora com o Large Icon)
    AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'canal_lembretes_v3', 
      'Lembretes Importantes', 
      channelDescription: 'Canal para notificações de apps',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
      visibility: NotificationVisibility.public,
      largeIcon: largeIcon, // <--- A MÁGICA ACONTECE AQUI!
    );

    NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
    );

    // 3. O LOOP DOS DIAS (Mantido igualzinho)
    for (int day in days) {
      int uniqueId = int.parse("$id$day");
      tz.TZDateTime scheduledDate = _nextInstanceOfWeekday(day, hour, minute);

      print("⏰ Agendando ID $uniqueId para: $scheduledDate (Dia $day)");

      await flutterLocalNotificationsPlugin.zonedSchedule(
        uniqueId,
        title,
        body,
        scheduledDate,
        notificationDetails,
        androidAllowWhileIdle: true,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
        payload: payload,
      );
    }
  }

  Future<void> cancelNotification(int id) async {
    // Para cancelar, temos que cancelar todas as combinações de dias (1 a 7)
    for (int i = 1; i <= 7; i++) {
      int uniqueId = int.parse("$id$i");
      await flutterLocalNotificationsPlugin.cancel(uniqueId);
    }
    print("🗑️ Cancelados todos os alarmes do ID base $id");
  }
}