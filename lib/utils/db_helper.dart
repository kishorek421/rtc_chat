import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DBHelper {
  static Database? _db;

  Future<Database> get db async {
    if (_db != null) {
      return _db!;
    }
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
        await db.execute(
          'CREATE TABLE connections(id INTEGER PRIMARY KEY AUTOINCREMENT, userId INTEGER, targetMobile TEXT, targetName TEXT)',
        );
        await db.execute(
          'CREATE TABLE sdp(id INTEGER PRIMARY KEY AUTOINCREMENT, userId INTEGER, targetMobile TEXT, sdp TEXT, type TEXT, FOREIGN KEY(userId) REFERENCES users(id))',
        );
        await db.execute(
          'CREATE TABLE ice_candidates(id INTEGER PRIMARY KEY AUTOINCREMENT, userId INTEGER, targetMobile TEXT, candidate TEXT, FOREIGN KEY(userId) REFERENCES users(id))',
        );
      },
    );
  }

  Future<int> addUser(String mobile, String name) async {
    final dbClient = await db;

    // Check if the user already exists
    var existingUser = await getUserByMobile(mobile);
    if (existingUser != null) {
      // User already exists, return 0 or another value to indicate no insertion
      return 0;
    }

    // User does not exist, insert the new user
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

  Future<int> addConnection(int userId, String targetMobile, String targetName) async {
    final dbClient = await db;
    return await dbClient.insert('connections', {'userId': userId, 'targetMobile': targetMobile, 'targetName': targetName});
  }

  Future<List<Map<String, dynamic>>> getConnections(int userId) async {
    final dbClient = await db;
    return await dbClient.query('connections', where: 'userId = ?', whereArgs: [userId]);
  }

  Future<int> addSdp(int userId, String targetMobile, String sdp, String type) async {
    final dbClient = await db;
    return await dbClient.insert('sdp', {'userId': userId, 'targetMobile': targetMobile, 'sdp': sdp, 'type': type});
  }

  Future<List<Map<String, dynamic>>> getSdp(int userId, String targetMobile) async {
    final dbClient = await db;
    return await dbClient.query('sdp', where: 'userId = ? AND targetMobile = ?', whereArgs: [userId, targetMobile]);
  }

  Future<int> addIceCandidate(int userId, String targetMobile, String candidate) async {
    final dbClient = await db;
    return await dbClient.insert('ice_candidates', {'userId': userId, 'targetMobile': targetMobile, 'candidate': candidate});
  }

  Future<List<Map<String, dynamic>>> getIceCandidates(int userId, String targetMobile) async {
    final dbClient = await db;
    return await dbClient.query('ice_candidates', where: 'userId = ? AND targetMobile = ?', whereArgs: [userId, targetMobile]);
  }

  Future<Map<String, dynamic>?> getUserByMobile(String mobile) async {
    final dbClient = await db;
    var result = await dbClient.query('users', where: 'mobile = ?', whereArgs: [mobile]);
    if (result.isNotEmpty) {
      return result.first;
    }
    return null;
  }
}
