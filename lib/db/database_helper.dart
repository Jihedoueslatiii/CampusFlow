import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/salle.dart';
import '../models/examen.dart';

class DatabaseHelper {
  DatabaseHelper._privateConstructor();
  static final DatabaseHelper instance = DatabaseHelper._privateConstructor();

  static Database? _db;

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDB('campus_flow.db');
    return _db!;
  }

  Future<Database> _initDB(String fileName) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, fileName);

    return await openDatabase(
      path,
      version: 2, // Incremented version for migration
      onConfigure: _onConfigure,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
      onOpen: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
    );
  }

  Future _onConfigure(Database db) async {
    await db.execute('PRAGMA foreign_keys = ON');
  }

  Future _onCreate(Database db, int version) async {
    // Create salle table
    await db.execute('''
      CREATE TABLE salle (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        numero TEXT NOT NULL,
        capacite INTEGER NOT NULL,
        type TEXT NOT NULL,
        batiment TEXT NOT NULL
      )
    ''');

    // Create examen table with all columns
    await db.execute('''
      CREATE TABLE examen (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        type TEXT NOT NULL,
        date TEXT NOT NULL,
        cours TEXT NOT NULL,
        dureeMinutes INTEGER NOT NULL,
        salleId INTEGER,
        status TEXT,
        notes TEXT,
        files TEXT,
        result TEXT,
        reminder1Day TEXT,
        reminder1Hour TEXT,
        FOREIGN KEY(salleId) REFERENCES salle(id) ON DELETE RESTRICT
      )
    ''');

    await db.execute('CREATE INDEX idx_examen_date ON examen(date)');
    await db.execute('CREATE INDEX idx_examen_salle ON examen(salleId)');
  }

  Future _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Migration from version 1 to 2
    if (oldVersion < 2) {
      // Get existing columns
      final columns = await db.rawQuery('PRAGMA table_info(examen)');
      final columnNames = columns.map((col) => col['name'] as String).toSet();

      // Add missing columns one by one
      if (!columnNames.contains('status')) {
        await db.execute('ALTER TABLE examen ADD COLUMN status TEXT');
      }
      if (!columnNames.contains('notes')) {
        await db.execute('ALTER TABLE examen ADD COLUMN notes TEXT');
      }
      if (!columnNames.contains('files')) {
        await db.execute('ALTER TABLE examen ADD COLUMN files TEXT');
      }
      if (!columnNames.contains('result')) {
        await db.execute('ALTER TABLE examen ADD COLUMN result TEXT');
      }
      if (!columnNames.contains('reminder1Day')) {
        await db.execute('ALTER TABLE examen ADD COLUMN reminder1Day TEXT');
      }
      if (!columnNames.contains('reminder1Hour')) {
        await db.execute('ALTER TABLE examen ADD COLUMN reminder1Hour TEXT');
      }
    }
  }

  // --- Salle CRUD ---
  Future<int> insertSalle(Salle s) async {
    try {
      final db = await database;
      return await db.insert(
        'salle',
        s.toMap(),
        conflictAlgorithm: ConflictAlgorithm.abort,
      );
    } catch (e) {
      throw Exception('Failed to insert room: $e');
    }
  }

  Future<List<Salle>> getAllSalles() async {
    try {
      final db = await database;
      final maps = await db.query(
        'salle',
        orderBy: 'batiment ASC, numero ASC',
      );
      return maps.map((m) => Salle.fromMap(m)).toList();
    } catch (e) {
      throw Exception('Failed to get rooms: $e');
    }
  }

  // Add this method to your DatabaseHelper class

  Future<Salle?> getSalleById(int id) async {
    final db = await database;
    final maps = await db.query(
      'salles',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isEmpty) return null;

    return Salle(
      id: maps.first['id'] as int?,
      numero: maps.first['numero'] as String,
      capacite: maps.first['capacite'] as int,
      type: maps.first['type'] as String,
      batiment: maps.first['batiment'] as String,
    );
  }

  Future<int> updateSalle(Salle s) async {
    try {
      final db = await database;
      return await db.update(
        'salle',
        s.toMap(),
        where: 'id = ?',
        whereArgs: [s.id],
      );
    } catch (e) {
      throw Exception('Failed to update room: $e');
    }
  }

  Future<int> deleteSalle(int id) async {
    try {
      final db = await database;
      final linked = await db.query(
        'examen',
        where: 'salleId = ?',
        whereArgs: [id],
        limit: 1,
      );

      if (linked.isNotEmpty) {
        throw Exception(
          'Cannot delete: This room is assigned to one or more exams. '
              'Please reassign or delete those exams first.',
        );
      }

      return await db.delete(
        'salle',
        where: 'id = ?',
        whereArgs: [id],
      );
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Failed to delete room: $e');
    }
  }

  // --- Examen CRUD ---
  Future<int> insertExamen(Examen e) async {
    try {
      final db = await database;

      if (e.salleId != null) {
        final available = await isSalleAvailable(
          e.salleId!,
          e.date,
          e.dureeMinutes,
        );
        if (!available) {
          throw Exception(
            'Room not available at this date/time. Please choose another room or time slot.',
          );
        }
      }

      return await db.insert(
        'examen',
        e.toMap(),
        conflictAlgorithm: ConflictAlgorithm.abort,
      );
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Failed to insert exam: $e');
    }
  }

  Future<List<Examen>> getAllExamens() async {
    try {
      final db = await database;
      final maps = await db.query(
        'examen',
        orderBy: 'date DESC',
      );
      return maps.map((m) => Examen.fromMap(m)).toList();
    } catch (e) {
      throw Exception('Failed to get exams: $e');
    }
  }

  Future<Examen?> getExamenById(int id) async {
    try {
      final db = await database;
      final maps = await db.query(
        'examen',
        where: 'id = ?',
        whereArgs: [id],
        limit: 1,
      );
      if (maps.isEmpty) return null;
      return Examen.fromMap(maps.first);
    } catch (e) {
      throw Exception('Failed to get exam: $e');
    }
  }

  Future<List<Examen>> getExamsBySalle(int salleId) async {
    try {
      final db = await database;
      final maps = await db.query(
        'examen',
        where: 'salleId = ?',
        whereArgs: [salleId],
        orderBy: 'date ASC',
      );
      return maps.map((m) => Examen.fromMap(m)).toList();
    } catch (e) {
      throw Exception('Failed to get exams for room: $e');
    }
  }

  Future<int> updateExamen(Examen e) async {
    try {
      final db = await database;

      if (e.salleId != null) {
        final available = await isSalleAvailable(
          e.salleId!,
          e.date,
          e.dureeMinutes,
          excludeExamId: e.id,
        );
        if (!available) {
          throw Exception(
            'Room not available at this date/time. Please choose another room or time slot.',
          );
        }
      }

      return await db.update(
        'examen',
        e.toMap(),
        where: 'id = ?',
        whereArgs: [e.id],
      );
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Failed to update exam: $e');
    }
  }

  Future<int> deleteExamen(int id) async {
    try {
      final db = await database;
      return await db.delete(
        'examen',
        where: 'id = ?',
        whereArgs: [id],
      );
    } catch (e) {
      throw Exception('Failed to delete exam: $e');
    }
  }

  // --- Availability check ---
  Future<bool> isSalleAvailable(
      int salleId,
      DateTime start,
      int durationMinutes, {
        int? excludeExamId,
      }) async {
    try {
      final exams = await getExamsBySalle(salleId);
      final newStart = start;
      final newEnd = start.add(Duration(minutes: durationMinutes));

      for (final ex in exams) {
        if (excludeExamId != null && ex.id == excludeExamId) continue;

        final exStart = ex.date;
        final exEnd = exStart.add(Duration(minutes: ex.dureeMinutes));

        if (newStart.isBefore(exEnd) && newEnd.isAfter(exStart)) {
          return false;
        }
      }
      return true;
    } catch (e) {
      throw Exception('Failed to check room availability: $e');
    }
  }

  Future<List<Salle>> getAvailableSalles(
      DateTime start,
      int durationMinutes,
      ) async {
    try {
      final all = await getAllSalles();
      final available = <Salle>[];

      for (final s in all) {
        if (s.id == null) continue;
        final ok = await isSalleAvailable(s.id!, start, durationMinutes);
        if (ok) available.add(s);
      }

      return available;
    } catch (e) {
      throw Exception('Failed to get available rooms: $e');
    }
  }

  Future<List<Examen>> getExamensByDateRange(
      DateTime start,
      DateTime end,
      ) async {
    try {
      final db = await database;
      final maps = await db.query(
        'examen',
        where: 'date >= ? AND date <= ?',
        whereArgs: [start.toIso8601String(), end.toIso8601String()],
        orderBy: 'date ASC',
      );
      return maps.map((m) => Examen.fromMap(m)).toList();
    } catch (e) {
      throw Exception('Failed to get exams by date range: $e');
    }
  }

  Future<List<Examen>> getUpcomingExamens() async {
    try {
      final db = await database;
      final now = DateTime.now();
      final maps = await db.query(
        'examen',
        where: 'date >= ?',
        whereArgs: [now.toIso8601String()],
        orderBy: 'date ASC',
      );
      return maps.map((m) => Examen.fromMap(m)).toList();
    } catch (e) {
      throw Exception('Failed to get upcoming exams: $e');
    }
  }

  Future<void> clearAllData() async {
    try {
      final db = await database;
      await db.delete('examen');
      await db.delete('salle');
    } catch (e) {
      throw Exception('Failed to clear data: $e');
    }
  }

  Future<void> close() async {
    if (_db != null) {
      await _db!.close();
      _db = null;
    }
  }

  Future<void> resetDatabase() async {
    try {
      final dbPath = await getDatabasesPath();
      final path = join(dbPath, 'campus_flow.db');

      await close();
      await deleteDatabase(path);

      _db = await _initDB('campus_flow.db');
    } catch (e) {
      throw Exception('Failed to reset database: $e');
    }
  }

}