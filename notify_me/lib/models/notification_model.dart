class NotificationModel {
  int? id;
  String appName;
  String packageName;
  String message;
  int hour;
  int minute;
  String days; // NOVO: Salva os dias ex: "1,2,3,4,5,6,7"

  NotificationModel({
    this.id,
    required this.appName,
    required this.packageName,
    required this.message,
    required this.hour,
    required this.minute,
    required this.days, // Adicionado aqui
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'appName': appName,
      'packageName': packageName,
      'message': message,
      'hour': hour,
      'minute': minute,
      'days': days, // Adicionado aqui
    };
  }

  factory NotificationModel.fromMap(Map<String, dynamic> map) {
    return NotificationModel(
      id: map['id'],
      appName: map['appName'],
      packageName: map['packageName'],
      message: map['message'],
      hour: map['hour'],
      minute: map['minute'],
      // Se for notificação antiga do banco que não tem 'days', assume todos os dias
      days: map['days'] ?? "1,2,3,4,5,6,7", 
    );
  }
}