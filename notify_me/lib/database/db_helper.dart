import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/notification_model.dart'; // Importando o arquivo que criamos acima

class DBHelper {
  // Padrão Singleton: Garante que só existe 1 conexão aberta por vez
  static final DBHelper _instance = DBHelper._internal();
  static Database? _database;

  factory DBHelper() {
    return _instance;
  }

  DBHelper._internal();

  // Getter do banco: Se não existir, ele cria/abre
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB();
    return _database!;
  }

  // Inicializa o banco de dados no celular
  Future<Database> _initDB() async {
    String path = join(await getDatabasesPath(), 'notify_me.db');
    return await openDatabase(
      path,
      version: 2,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  // Cria a tabela SQL
  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE notifications(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        appName TEXT,
        packageName TEXT,
        message TEXT,
        hour INTEGER,
        minute INTEGER,
        days TEXT
      )
    ''');
  }

  // Upgrade do banco para adicionar a coluna days em apps já instalados
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute("ALTER TABLE notifications ADD COLUMN days TEXT DEFAULT '1,2,3,4,5,6,7'");
    }
  }


  // --- MÉTODOS CRUD (Create, Read, Delete) ---

  // 1. Salvar Notificação
  Future<int> insertNotification(NotificationModel notification) async {
    final db = await database;
    return await db.insert('notifications', notification.toMap());
  }

  // 2. Listar Todas
  Future<List<NotificationModel>> getNotifications() async {
    final db = await database;
    // Ordena pelo ID decrescente (as mais novas aparecem primeiro)
    final List<Map<String, dynamic>> maps = await db.query('notifications', orderBy: "id DESC");

    return List.generate(maps.length, (i) {
      return NotificationModel.fromMap(maps[i]);
    });
  }

  // 3. Deletar Notificação
  Future<int> deleteNotification(int id) async {
    final db = await database;
    return await db.delete(
      'notifications',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // 4. Atualizar Notificação (NOVO)
  Future<int> updateNotification(NotificationModel notification) async {
    final db = await database;
    return await db.update(
      'notifications',
      notification.toMap(),
      where: 'id = ?',
      whereArgs: [notification.id],
    );
  }
}