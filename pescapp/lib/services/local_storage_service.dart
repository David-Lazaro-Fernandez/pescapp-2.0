import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class LocalStorageService {
  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'coordinates.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: (Database db, int version) async {
        await db.execute('''
          CREATE TABLE pending_coordinates(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            travel_id INTEGER,
            latitude REAL,
            longitude REAL,
            timestamp INTEGER,
            synced INTEGER DEFAULT 0
          )
        ''');
      },
    );
  }

  Future<void> saveCoordinates(int travelId, double latitude, double longitude) async {
    final db = await database;
    await db.insert('pending_coordinates', {
      'travel_id': travelId,
      'latitude': latitude,
      'longitude': longitude,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
      'synced': 0,
    });
  }

  Future<List<Map<String, dynamic>>> getPendingCoordinates() async {
    final db = await database;
    return await db.query('pending_coordinates', where: 'synced = ?', whereArgs: [0]);
  }

  Future<void> markCoordinatesAsSynced(List<int> ids) async {
    final db = await database;
    await db.update(
      'pending_coordinates',
      {'synced': 1},
      where: 'id IN (${List.filled(ids.length, '?').join(',')})',
      whereArgs: ids,
    );
  }
} 