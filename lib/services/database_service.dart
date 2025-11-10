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

    // ⚠️ DÉCOMMENTEZ TEMPORAIREMENT POUR SUPPRIMER L'ANCIENNE BASE
    // await deleteDatabase(path);

    return await openDatabase(
      path,
      version: 4, // ⭐ AUGMENTÉ À 4 pour inclure les PDF
      onCreate: _createDatabase,
      onUpgrade: _upgradeDatabase,
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

    // Table des départements
    await db.execute('''
      CREATE TABLE departements(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nom TEXT NOT NULL,
        chef_departement TEXT NOT NULL,
        created_at TEXT NOT NULL
      )
    ''');

    // ⭐ TABLE COURS AVEC COLONNES PDF
    await db.execute('''
  CREATE TABLE cours(
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    nom TEXT NOT NULL,
    description TEXT,
    semestre TEXT NOT NULL,
    credits INTEGER NOT NULL,
    departement_id INTEGER,
    pdf_path TEXT, -- Nouveau: Chemin du fichier PDF
    pdf_name TEXT, -- Nouveau: Nom du fichier PDF
    created_at TEXT NOT NULL,
    FOREIGN KEY (departement_id) REFERENCES departements(id)
  )
''');
    await db.execute('''
  CREATE TABLE cours_content (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    cours_id INTEGER NOT NULL,
    content TEXT NOT NULL,
    content_type TEXT NOT NULL,
    ai_confidence REAL DEFAULT 1.0,
    generated_by TEXT DEFAULT 'ai_generated',
    created_at TEXT NOT NULL,
    FOREIGN KEY (cours_id) REFERENCES cours (id) ON DELETE CASCADE
  )
''');

    await db.execute('''
  CREATE TABLE cours_metadata (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    cours_id INTEGER UNIQUE NOT NULL,
    difficulty_level REAL NOT NULL,
    estimated_study_hours REAL NOT NULL,
    key_topics TEXT NOT NULL,
    prerequisites TEXT NOT NULL,
    related_skills TEXT NOT NULL,
    ai_analysis TEXT NOT NULL,
    last_analyzed TEXT NOT NULL,
    FOREIGN KEY (cours_id) REFERENCES cours (id) ON DELETE CASCADE
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

    // Départements par défaut
    await db.insert('departements', {
      'nom': 'Informatique',
      'chef_departement': 'Dr. Ahmed Benali',
      'created_at': DateTime.now().toIso8601String(),
    });

    await db.insert('departements', {
      'nom': 'Mathématiques',
      'chef_departement': 'Prof. Marie Dupont',
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  Future<void> _upgradeDatabase(Database db, int oldVersion, int newVersion) async {
    print('🔄 Mise à jour base de données: v$oldVersion -> v$newVersion');

    if (oldVersion < 2) {
      try {
        await db.execute('''
          ALTER TABLE cours ADD COLUMN created_at TEXT NOT NULL DEFAULT '${DateTime.now().toIso8601String()}'
        ''');
        print('✅ Version 2: Colonne created_at ajoutée à cours');
      } catch (e) {
        print('ℹ️ Cours created_at déjà existant: $e');
      }
    }

    if (oldVersion < 3) {
      try {
        final columns = await db.rawQuery("PRAGMA table_info(departements)");
        bool hasCreatedAt = columns.any((col) => col['name'] == 'created_at');

        if (!hasCreatedAt) {
          await db.execute('''
            ALTER TABLE departements ADD COLUMN created_at TEXT NOT NULL DEFAULT '${DateTime.now().toIso8601String()}'
          ''');
          print('✅ Version 3: Colonne created_at ajoutée à departements');
        } else {
          print('ℹ️ Departements created_at déjà existant');
        }
      } catch (e) {
        print('❌ Erreur mise à jour departements: $e');
        await _recreateDepartementsTable(db);
      }
    }

    // ⭐⭐ VERSION 4 - COLONNES PDF ⭐⭐
    if (oldVersion < 4) {
      try {
        // Vérifier si les colonnes PDF existent déjà
        final columns = await db.rawQuery("PRAGMA table_info(cours)");
        bool hasPdfPath = columns.any((col) => col['name'] == 'pdf_path');
        bool hasPdfName = columns.any((col) => col['name'] == 'pdf_name');

        if (!hasPdfPath) {
          await db.execute('ALTER TABLE cours ADD COLUMN pdf_path TEXT');
          print('✅ Version 4: Colonne pdf_path ajoutée à cours');
        } else {
          print('ℹ️ pdf_path déjà existant');
        }

        if (!hasPdfName) {
          await db.execute('ALTER TABLE cours ADD COLUMN pdf_name TEXT');
          print('✅ Version 4: Colonne pdf_name ajoutée à cours');
        } else {
          print('ℹ️ pdf_name déjà existant');
        }
      } catch (e) {
        print('❌ Erreur ajout colonnes PDF: $e');
      }
    }
  }

  Future<void> _recreateDepartementsTable(Database db) async {
    try {
      final oldData = await db.query('departements');
      await db.execute('DROP TABLE IF EXISTS departements');

      await db.execute('''
        CREATE TABLE departements(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          nom TEXT NOT NULL,
          chef_departement TEXT NOT NULL,
          created_at TEXT NOT NULL
        )
      ''');

      for (var data in oldData) {
        await db.insert('departements', {
          'id': data['id'],
          'nom': data['nom'],
          'chef_departement': data['chef_departement'],
          'created_at': data['created_at'] ?? DateTime.now().toIso8601String(),
        });
      }

      print('✅ Table departements recréée avec succès');
    } catch (e) {
      print('❌ Erreur recréation table departements: $e');
    }
  }

  Future<void> close() async {
    if (_database != null) {
      await _database!.close();
    }
  }
}