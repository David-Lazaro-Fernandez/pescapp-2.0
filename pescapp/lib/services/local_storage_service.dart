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
      version: 3,
      onCreate: (Database db, int version) async {
        await db.execute('''
          CREATE TABLE coordinates(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            latitude REAL,
            longitude REAL,
            timestamp TEXT,
            travel_id TEXT,
            coord_type TEXT,
            accuracy REAL,
            altitude REAL,
            speed REAL,
            synced INTEGER DEFAULT 0
          )
        ''');

        await db.execute('''
          CREATE TABLE travels(
            travel_id TEXT PRIMARY KEY,
            timestamp TEXT,
            user_id TEXT,
            status TEXT DEFAULT 'active',
            start_latitude REAL,
            start_longitude REAL,
            end_latitude REAL,
            end_longitude REAL,
            end_timestamp TEXT,
            synced INTEGER DEFAULT 0
          )
        ''');
      },
      onUpgrade: (Database db, int oldVersion, int newVersion) async {
        if (oldVersion < 2) {
          await db.execute('ALTER TABLE travels ADD COLUMN user_id TEXT');
        }
        if (oldVersion < 3) {
          // Agregar nuevas columnas a la tabla coordinates
          await db.execute('ALTER TABLE coordinates ADD COLUMN coord_type TEXT');
          await db.execute('ALTER TABLE coordinates ADD COLUMN accuracy REAL');
          await db.execute('ALTER TABLE coordinates ADD COLUMN altitude REAL');
          await db.execute('ALTER TABLE coordinates ADD COLUMN speed REAL');
          
          // Agregar nuevas columnas a la tabla travels
          await db.execute('ALTER TABLE travels ADD COLUMN status TEXT DEFAULT "active"');
          await db.execute('ALTER TABLE travels ADD COLUMN start_latitude REAL');
          await db.execute('ALTER TABLE travels ADD COLUMN start_longitude REAL');
          await db.execute('ALTER TABLE travels ADD COLUMN end_latitude REAL');
          await db.execute('ALTER TABLE travels ADD COLUMN end_longitude REAL');
          await db.execute('ALTER TABLE travels ADD COLUMN end_timestamp TEXT');
        }
      },
    );
  }

  Future<void> saveTravel(String travelId, DateTime timestamp, String userId, double startLat, double startLon) async {
    final db = await database;
    await db.insert(
      'travels',
      {
        'travel_id': travelId,
        'timestamp': timestamp.toIso8601String(),
        'user_id': userId,
        'status': 'active',
        'start_latitude': startLat,
        'start_longitude': startLon,
        'synced': 0,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> endTravel(String travelId, double endLat, double endLon) async {
    final db = await database;
    await db.update(
      'travels',
      {
        'status': 'completed',
        'end_latitude': endLat,
        'end_longitude': endLon,
        'end_timestamp': DateTime.now().toIso8601String(),
        'synced': 0,
      },
      where: 'travel_id = ?',
      whereArgs: [travelId],
    );
  }

  Future<Map<String, dynamic>?> getActiveTravel() async {
    final db = await database;
    final List<Map<String, dynamic>> results = await db.query(
      'travels',
      where: 'status = ?',
      whereArgs: ['active'],
      limit: 1,
    );
    return results.isNotEmpty ? results.first : null;
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
    String coordType, {
    double? accuracy,
    double? altitude,
    double? speed,
  }) async {
    final db = await database;
    await db.insert(
      'coordinates',
      {
        'latitude': latitude,
        'longitude': longitude,
        'timestamp': timestamp.toIso8601String(),
        'travel_id': travelId,
        'coord_type': coordType,
        'accuracy': accuracy,
        'altitude': altitude,
        'speed': speed,
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
      orderBy: 'timestamp ASC',
    );
  }

  Future<List<Map<String, dynamic>>> getTravelCoordinates(String travelId) async {
    final db = await database;
    return await db.query(
      'coordinates',
      where: 'travel_id = ?',
      whereArgs: [travelId],
      orderBy: 'timestamp ASC',
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

  Future<void> deleteOldSyncedData() async {
    final db = await database;
    final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30)).toIso8601String();
    
    // Eliminar coordenadas sincronizadas antiguas
    await db.delete(
      'coordinates',
      where: 'synced = 1 AND timestamp < ?',
      whereArgs: [thirtyDaysAgo],
    );

    // Eliminar viajes sincronizados antiguos
    await db.delete(
      'travels',
      where: 'synced = 1 AND timestamp < ?',
      whereArgs: [thirtyDaysAgo],
    );
  }
} 