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
    // Version 2 pour inclure la table des projets
    return await openDatabase(
      path,
      version: 2,
      onCreate: _createDatabase,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _createDatabase(Database db, int version) async {
    // Table des utilisateurs
    await db.execute('''
      CREATE TABLE users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        email TEXT UNIQUE NOT NULL,
        name TEXT NOT NULL,
        password TEXT NOT NULL,
        role TEXT NOT NULL DEFAULT 'etudiant',
        created_at TEXT NOT NULL
      )
    ''');

    // Table des sessions
    await db.execute('''
      CREATE TABLE sessions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        token TEXT NOT NULL,
        created_at TEXT NOT NULL,
        FOREIGN KEY (user_id) REFERENCES users (id)
      )
    ''');

    // Insérer un utilisateur admin par défaut
    await db.insert('users', {
      'email': 'admin@compusflow.com',
      'name': 'Administrateur',
      'password': 'admin123',
      'role': 'admin',
      'created_at': DateTime.now().toIso8601String(),
    });

    // Si on crée directement la v2, on crée la table projets
    if (version >= 2) {
      await _createProjetsTable(db);
    }
  }

  // Gérer la mise à niveau de la base de données
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await _createProjetsTable(db);
    }
  }

  // Méthode pour créer la nouvelle table des projets
  Future<void> _createProjetsTable(Database db) async {
    await db.execute('''
      CREATE TABLE projets_academiques (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        titre TEXT NOT NULL,
        description TEXT,
        date_rendu TEXT,
        cours_associe TEXT
      )
    ''');
    // Insérer un projet initial
    await db.insert('projets_academiques', {
      'titre': 'Projet Application Mobile',
      'description': 'Développement d\'une application de gestion académique.',
      'date_rendu': DateTime.now().add(const Duration(days: 90)).toIso8601String(),
      'cours_associe': 'Développement Mobile Avancé',
    });
  }

  // Fonctions CRUD pour ProjetAcadémique

  // CREATE
  Future<int> insertProjet(Map<String, dynamic> projet) async {
    final db = await database;
    return await db.insert('projets_academiques', projet);
  }

  // READ (Tous)
  Future<List<Map<String, dynamic>>> getProjets() async {
    final db = await database;
    // Tri par date de rendu
    return await db.query('projets_academiques', orderBy: 'date_rendu ASC');
  }

  // READ (Un)
  Future<Map<String, dynamic>?> getProjetById(int id) async {
    final db = await database;
    final results = await db.query(
      'projets_academiques',
      where: 'id = ?',
      whereArgs: [id],
    );
    return results.isNotEmpty ? results.first : null;
  }

  // UPDATE
  Future<int> updateProjet(int id, Map<String, dynamic> projet) async {
    final db = await database;
    return await db.update(
      'projets_academiques',
      projet,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // DELETE
  Future<int> deleteProjet(int id) async {
    final db = await database;
    return await db.delete(
      'projets_academiques',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> close() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
  }
}