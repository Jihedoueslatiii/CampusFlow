import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'compusflow.db');
    return await openDatabase(
      path,
      version: 3, // Version 3 with event_participants table
      onCreate: _createDatabase,
      onUpgrade: (db, oldVersion, newVersion) async {
        // Handle upgrades from any version to version 3
        for (int version = oldVersion + 1; version <= newVersion; version++) {
          switch (version) {
            case 2:
              await _createBibliothequeTable(db);
              await _createEventTable(db);
              await _insertDefaultData(db);
              break;
            case 3:
              await _createEventParticipantsTable(db);
              break;
          }
        }
      },
    );
  }

  Future<void> _createDatabase(Database db, int version) async {
    // Table des utilisateurs (for reference, but we're using SharedPreferences)
    await db.execute('''
      CREATE TABLE IF NOT EXISTS users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        email TEXT UNIQUE NOT NULL,
        name TEXT NOT NULL,
        password TEXT NOT NULL,
        role TEXT NOT NULL DEFAULT 'etudiant',
        created_at TEXT NOT NULL
      )
    ''');

    // Table des sessions (for reference)
    await db.execute('''
      CREATE TABLE IF NOT EXISTS sessions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        token TEXT NOT NULL,
        created_at TEXT NOT NULL,
        FOREIGN KEY (user_id) REFERENCES users (id)
      )
    ''');

    // Other tables
    await _createBibliothequeTable(db);
    await _createEventTable(db);
    await _createEventParticipantsTable(db);

    // Insert default data for bibliotheques and events
    await _insertDefaultData(db);
  }

  // Create bibliotheque table
  Future<void> _createBibliothequeTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS bibliotheques (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        description TEXT NOT NULL,
        location TEXT NOT NULL,
        contact_info TEXT NOT NULL,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');
  }

  // Create event table
  Future<void> _createEventTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS events (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        description TEXT NOT NULL,
        date_time TEXT NOT NULL,
        location TEXT NOT NULL,
        max_participants INTEGER NOT NULL DEFAULT 50,
        bibliotheque_id INTEGER NOT NULL,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        FOREIGN KEY (bibliotheque_id) REFERENCES bibliotheques (id)
      )
    ''');
  }

  // Create event_participants table (without foreign key to users)
  Future<void> _createEventParticipantsTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS event_participants (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        event_id INTEGER NOT NULL,
        user_id INTEGER NOT NULL,
        participation_date DATETIME DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (event_id) REFERENCES events (id) ON DELETE CASCADE,
        UNIQUE(event_id, user_id)
      )
    ''');
  }

  // Insert default data
  Future<void> _insertDefaultData(Database db) async {
    // Insert default bibliotheques
    final bibliotheque1Id = await db.insert('bibliotheques', {
      'name': 'Bibliothèque Centrale',
      'description': 'Bibliothèque principale du campus',
      'location': 'Bâtiment A, Rez-de-chaussée',
      'contact_info': 'biblio@compusflow.com - 0123456789',
      'created_at': DateTime.now().toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    });

    final bibliotheque2Id = await db.insert('bibliotheques', {
      'name': 'Bibliothèque des Sciences',
      'description': 'Spécialisée en sciences et technologies',
      'location': 'Bâtiment B, 1er étage',
      'contact_info': 'sciences@compusflow.com - 0123456790',
      'created_at': DateTime.now().toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    });

    // Insert default events
    await db.insert('events', {
      'title': 'Atelier de Recherche',
      'description': 'Apprendre les techniques de recherche documentaire',
      'date_time': DateTime.now().add(Duration(days: 2)).toIso8601String(),
      'location': 'Salle de formation',
      'max_participants': 25,
      'bibliotheque_id': bibliotheque1Id,
      'created_at': DateTime.now().toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    });

    await db.insert('events', {
      'title': 'Club de Lecture',
      'description': 'Discussion autour des dernières publications',
      'date_time': DateTime.now().add(Duration(days: 5)).toIso8601String(),
      'location': 'Espace détente',
      'max_participants': 15,
      'bibliotheque_id': bibliotheque2Id,
      'created_at': DateTime.now().toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    });
  }

  // Method to check if table exists
  Future<bool> tableExists(String tableName) async {
    final db = await database;
    final List<Map<String, dynamic>> result = await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type='table' AND name=?",
      [tableName],
    );
    return result.isNotEmpty;
  }

  // Method to reset database (use this during development if needed)
  Future<void> resetDatabase() async {
    final db = await database;
    await db.close();
    final String path = join(await getDatabasesPath(), 'compusflow.db');
    await deleteDatabase(path);
    _database = null;
    await database; // Reinitialize
  }

  Future<void> close() async {
    if (_database != null) {
      await _database!.close();
    }
  }
}