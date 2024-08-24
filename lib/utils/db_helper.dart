import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DBHelper {
  static Database? _db;

  Future<Database> get db async {
    if (_db != null) return _db!;
    _db = await initDB();
    return _db!;
  }

  Future<Database> initDB() async {
    String path = join(await getDatabasesPath(), 'webrtc.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute(
          'CREATE TABLE users(id INTEGER PRIMARY KEY AUTOINCREMENT, mobile TEXT, name TEXT)',
        );
      },
    );
  }

  Future<int> addUser(String mobile, String name) async {
    final dbClient = await db;
    var existingUser = await getUserByMobile(mobile);
    if (existingUser != null) return 0;
    return await dbClient.insert('users', {'mobile': mobile, 'name': name});
  }

  Future<List<Map<String, dynamic>>> getUsers(String currentMobile) async {
    final dbClient = await db;
    return await dbClient.query(
      'users',
      where: 'mobile != ?',
      whereArgs: [currentMobile],
    );
  }

  Future<Map<String, dynamic>?> getUserByMobile(String mobile) async {
    final dbClient = await db;
    var res = await dbClient.query('users', where: 'mobile = ?', whereArgs: [mobile]);
    return res.isNotEmpty ? res.first : null;
  }
}
