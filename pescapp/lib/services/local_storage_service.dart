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
          CREATE TABLE coordinates(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            latitude REAL,
            longitude REAL,
            timestamp TEXT,
            travel_id TEXT,
            synced INTEGER DEFAULT 0
          )
        ''');

        await db.execute('''
          CREATE TABLE travels(
            travel_id TEXT PRIMARY KEY,
            timestamp TEXT,
            synced INTEGER DEFAULT 0
          )
        ''');
      },
    );
  }

  Future<void> saveTravel(String travelId, DateTime timestamp) async {
    final db = await database;
    await db.insert(
      'travels',
      {
        'travel_id': travelId,
        'timestamp': timestamp.toIso8601String(),
        'synced': 0,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Map<String, dynamic>>> getPendingTravels() async {
    final db = await database;
    return await db.query(
      'travels',
      where: 'synced = ?',
      whereArgs: [0],
    );
  }

  Future<void> markTravelAsSynced(String travelId) async {
    final db = await database;
    await db.update(
      'travels',
      {'synced': 1},
      where: 'travel_id = ?',
      whereArgs: [travelId],
    );
  }

  Future<void> saveCoordinates(
    double latitude,
    double longitude,
    DateTime timestamp,
    String travelId,
  ) async {
    final db = await database;
    await db.insert(
      'coordinates',
      {
        'latitude': latitude,
        'longitude': longitude,
        'timestamp': timestamp.toIso8601String(),
        'travel_id': travelId,
        'synced': 0,
      },
    );
  }

  Future<List<Map<String, dynamic>>> getUnsyncedCoordinates() async {
    final db = await database;
    return await db.query(
      'coordinates',
      where: 'synced = ?',
      whereArgs: [0],
    );
  }

  Future<void> markCoordinatesAsSynced(int id) async {
    final db = await database;
    await db.update(
      'coordinates',
      {'synced': 1},
      where: 'id = ?',
      whereArgs: [id],
    );
  }
} 