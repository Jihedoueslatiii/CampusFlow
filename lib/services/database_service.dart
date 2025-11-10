// lib/services/database_service.dart

import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/salle.dart';
import '../models/examen.dart';
import './crypto_service.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  final CryptoService _cryptoService = CryptoService();
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
      version: 9, // Increased to 9 for new tables
      onConfigure: _onConfigure,
      onCreate: _createDatabase,
      onUpgrade: _onUpgrade,
      onOpen: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
    );
  }

  Future _onConfigure(Database db) async {
    await db.execute('PRAGMA foreign_keys = ON');
  }

  Future<void> _createDatabase(Database db, int version) async {
    // Users table
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

    // Sessions table
    await db.execute('''
      CREATE TABLE sessions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        token TEXT NOT NULL,
        created_at TEXT NOT NULL,
        FOREIGN KEY (user_id) REFERENCES users (id)
      )
    ''');

    // ========== NEW MISSING TABLES ==========
    await db.execute('''
      CREATE TABLE departements(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nom TEXT NOT NULL,
        chef_departement TEXT NOT NULL,
        created_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE cours(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nom TEXT NOT NULL,
        description TEXT,
        semestre TEXT NOT NULL,
        credits INTEGER NOT NULL,
        departement_id INTEGER,
        pdf_path TEXT,
        pdf_name TEXT,
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

    // ========== EXISTING TABLES ==========
    // Clubs tables
    await db.execute('''
      CREATE TABLE clubs (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nom TEXT NOT NULL,
        type TEXT NOT NULL,
        responsableId INTEGER NOT NULL,
        createurId INTEGER NOT NULL,
        description TEXT,
        status TEXT NOT NULL,
        dateCreation TEXT NOT NULL,
        raisonSuppression TEXT,
        statusSuppression TEXT,
        FOREIGN KEY (responsableId) REFERENCES users (id)
      )
    ''');

    await db.execute('''
      CREATE TABLE club_members (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        clubId INTEGER NOT NULL,
        userId INTEGER NOT NULL,
        role TEXT NOT NULL,
        status TEXT NOT NULL,
        dateAdhesion TEXT NOT NULL,
        canApproveResponsables INTEGER DEFAULT 0,
        FOREIGN KEY (clubId) REFERENCES clubs (id),
        FOREIGN KEY (userId) REFERENCES users (id)
      )
    ''');

    // Club events (plural)
    await db.execute('''
      CREATE TABLE events (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        description TEXT NOT NULL,
        startDate INTEGER NOT NULL,
        endDate INTEGER NOT NULL,
        reminderDate INTEGER,
        clubId INTEGER NOT NULL,
        clubName TEXT NOT NULL,
        location TEXT,
        maxParticipants INTEGER,
        currentParticipants INTEGER DEFAULT 0,
        createdAt INTEGER NOT NULL,
        isActive INTEGER NOT NULL DEFAULT 1,
        isCanceled INTEGER NOT NULL DEFAULT 0,
        isArchived INTEGER NOT NULL DEFAULT 0,
        cancelReason TEXT,
        FOREIGN KEY (clubId) REFERENCES clubs (id)
      )
    ''');

    await db.execute('''
      CREATE TABLE event_participants (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        eventId INTEGER NOT NULL,
        userId INTEGER NOT NULL,
        userName TEXT NOT NULL,
        userEmail TEXT NOT NULL,
        registeredAt INTEGER NOT NULL,
        hasReceivedReminder INTEGER NOT NULL DEFAULT 0,
        FOREIGN KEY (eventId) REFERENCES events (id),
        UNIQUE(eventId, userId)
      )
    ''');

    // Academic tables
    await db.execute('''
      CREATE TABLE matieres (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nom TEXT NOT NULL,
        description TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE etudiant_matieres (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        etudiant_id INTEGER NOT NULL,
        matiere_id INTEGER NOT NULL,
        FOREIGN KEY (etudiant_id) REFERENCES users (id),
        FOREIGN KEY (matiere_id) REFERENCES matieres (id),
        UNIQUE(etudiant_id, matiere_id)
      )
    ''');

    await db.execute('''
      CREATE TABLE emploi_temps (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        matiereId INTEGER NOT NULL,
        matiereNom TEXT NOT NULL,
        jour TEXT NOT NULL,
        heureDebut TEXT NOT NULL,
        heureFin TEXT NOT NULL,
        salle TEXT NOT NULL,
        professeurId INTEGER NOT NULL,
        professeurNom TEXT NOT NULL,
        semaineNum INTEGER NOT NULL,
        FOREIGN KEY (matiereId) REFERENCES matieres (id)
      )
    ''');

    // Salle and exam tables
    await db.execute('''
      CREATE TABLE salle (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        numero TEXT NOT NULL,
        capacite INTEGER NOT NULL,
        type TEXT NOT NULL,
        batiment TEXT NOT NULL
      )
    ''');

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

    await db.execute('''
      CREATE TABLE projets_academiques (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        titre TEXT NOT NULL,
        description TEXT,
        date_rendu TEXT,
        cours_associe TEXT,
        difficulte INTEGER DEFAULT 3
      )
    ''');

    // Bibliotheque tables
    await db.execute('''
      CREATE TABLE bibliotheques (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        description TEXT NOT NULL,
        location TEXT NOT NULL,
        contact_info TEXT NOT NULL,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    // Bibliotheque events (singular)
    await db.execute('''
      CREATE TABLE event (
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

    await db.execute('''
      CREATE TABLE event_participant (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        event_id INTEGER NOT NULL,
        user_id INTEGER NOT NULL,
        participation_date DATETIME DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (event_id) REFERENCES event (id) ON DELETE CASCADE,
        UNIQUE(event_id, user_id)
      )
    ''');

    // Indexes
    await db.execute('CREATE INDEX IF NOT EXISTS idx_examen_date ON examen(date)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_examen_salle ON examen(salleId)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_users_email ON users(email)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_event_date ON event(date_time)');

    // Initial data
    await _insertInitialData(db);
    print('✅ Database created successfully (version $version)');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    for (int version = oldVersion + 1; version <= newVersion; version++) {
      switch (version) {
        case 2:
          await _upgradeToVersion2(db);
          break;
        case 3:
          await _upgradeToVersion3(db);
          break;
        case 4:
          await _upgradeToVersion4(db);
          break;
        case 5:
          await _upgradeToVersion5(db);
          break;
        case 6:
          await _upgradeToVersion6(db);
          break;
        case 7:
          await _upgradeToVersion7(db);
          break;
        case 8:
          await _upgradeToVersion8(db);
          break;
        case 9:
          await _upgradeToVersion9(db);
          break;
      }
    }
  }

  Future<void> _upgradeToVersion2(Database db) async {
    await _createProjetsTable(db);
    await _createSalleTableIfNotExists(db);
    await _createExamenTableIfNotExists(db);
  }

  Future<void> _upgradeToVersion3(Database db) async {
    await _createSalleTableIfNotExists(db);
    await _createExamenTableIfNotExists(db);
    await _addExamenColumnsIfNotExist(db);
  }

  Future<void> _upgradeToVersion4(Database db) async {
    await _createSalleTableIfNotExists(db);
    await _createExamenTableWithAllColumnsIfNotExists(db);
    await _insertDefaultSallesIfEmpty(db);
  }

  Future<void> _upgradeToVersion5(Database db) async {
    await _migratePasswordsToEncrypted(db);
  }

  Future<void> _upgradeToVersion6(Database db) async {
    await _recreatePasswordsWithFixedCrypto(db);
  }

  Future<void> _upgradeToVersion7(Database db) async {
    try {
      await _createSalleTableIfNotExists(db);
      await _createExamenTableWithAllColumnsIfNotExists(db);
      await _createProjetsTable(db);
      await _insertDefaultSallesIfEmpty(db);
      print('✅ Upgraded to version 7 - salle, examen, projets_academiques tables added');
    } catch (e) {
      print('Error upgrading to v7: $e');
    }
  }

  Future<void> _upgradeToVersion8(Database db) async {
    try {
      await _createBibliothequesTableIfNotExists(db);
      await _createEventTableIfNotExists(db);
      await _createEventParticipantTableIfNotExists(db);
      await _insertDefaultBibliothequesIfEmpty(db);
      print('✅ Upgraded to version 8 - bibliotheques, event, event_participant tables added');
    } catch (e) {
      print('Error upgrading to v8: $e');
    }
  }

  Future<void> _upgradeToVersion9(Database db) async {
    try {
      await _createDepartementsTableIfNotExists(db);
      await _createCoursTableIfNotExists(db);
      await _createCoursContentTableIfNotExists(db);
      await _createCoursMetadataTableIfNotExists(db);
      await _insertDefaultDepartementsIfEmpty(db);
      print('✅ Upgraded to version 9 - departements, cours, cours_content, cours_metadata tables added');
    } catch (e) {
      print('Error upgrading to v9: $e');
    }
  }

  Future<void> _migratePasswordsToEncrypted(Database db) async {
    try {
      final users = await db.query('users');
      for (final user in users) {
        final currentPassword = user['password'] as String;
        if (!_cryptoService.isEncrypted(currentPassword)) {
          final encryptedPassword = _cryptoService.migratePassword(currentPassword);
          await db.update(
            'users',
            {'password': encryptedPassword},
            where: 'id = ?',
            whereArgs: [user['id']],
          );
        }
      }
    } catch (e) {
      print('Error migrating passwords: $e');
    }
  }

  Future<void> _recreatePasswordsWithFixedCrypto(Database db) async {
    try {
      final defaultPassword = _cryptoService.hashPassword('admin123');
      await db.update(
        'users',
        {'password': defaultPassword},
        where: 'email = ?',
        whereArgs: ['admin@compusflow.com'],
      );
      print('Passwords migrated with fixed crypto');
    } catch (e) {
      print('Error migrating passwords with fixed crypto: $e');
    }
  }

  Future<void> _createSalleTableIfNotExists(Database db) async {
    final tables = await db.rawQuery("SELECT name FROM sqlite_master WHERE type='table' AND name='salle'");
    if (tables.isEmpty) {
      await db.execute('''
        CREATE TABLE salle (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          numero TEXT NOT NULL,
          capacite INTEGER NOT NULL,
          type TEXT NOT NULL,
          batiment TEXT NOT NULL
        )
      ''');
    }
  }

  Future<void> _createExamenTableIfNotExists(Database db) async {
    final tables = await db.rawQuery("SELECT name FROM sqlite_master WHERE type='table' AND name='examen'");
    if (tables.isEmpty) {
      await db.execute('''
        CREATE TABLE examen (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          type TEXT NOT NULL,
          date TEXT NOT NULL,
          cours TEXT NOT NULL,
          dureeMinutes INTEGER NOT NULL,
          salleId INTEGER,
          FOREIGN KEY(salleId) REFERENCES salle(id) ON DELETE RESTRICT
        )
      ''');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_examen_date ON examen(date)');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_examen_salle ON examen(salleId)');
    }
  }

  Future<void> _createExamenTableWithAllColumnsIfNotExists(Database db) async {
    final tables = await db.rawQuery("SELECT name FROM sqlite_master WHERE type='table' AND name='examen'");
    if (tables.isEmpty) {
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
      await db.execute('CREATE INDEX IF NOT EXISTS idx_examen_date ON examen(date)');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_examen_salle ON examen(salleId)');
    } else {
      await _addExamenColumnsIfNotExist(db);
    }
  }

  Future<void> _addExamenColumnsIfNotExist(Database db) async {
    try {
      final columns = await db.rawQuery('PRAGMA table_info(examen)');
      final columnNames = columns.map((col) => col['name'] as String).toSet();

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
    } catch (e) {
      await db.execute('DROP TABLE IF EXISTS examen');
      await _createExamenTableWithAllColumnsIfNotExists(db);
    }
  }

  Future<void> _insertDefaultSallesIfEmpty(Database db) async {
    final count = Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM salle'));
    if (count == 0) {
      await _insertDefaultSalles(db);
    }
  }

  Future<void> _insertDefaultSalles(Database db) async {
    final defaultSalles = [
      {'numero': '101', 'capacite': 30, 'type': 'Cours magistral', 'batiment': 'A'},
      {'numero': '102', 'capacite': 25, 'type': 'Cours magistral', 'batiment': 'A'},
      {'numero': '201', 'capacite': 20, 'type': 'TP', 'batiment': 'B'},
      {'numero': '202', 'capacite': 15, 'type': 'TP', 'batiment': 'B'},
      {'numero': '301', 'capacite': 18, 'type': 'TD', 'batiment': 'C'},
      {'numero': '302', 'capacite': 22, 'type': 'TD', 'batiment': 'C'},
    ];

    for (final salle in defaultSalles) {
      await db.insert('salle', salle);
    }
  }

  Future<void> _createProjetsTable(Database db) async {
    final tables = await db.rawQuery("SELECT name FROM sqlite_master WHERE type='table' AND name='projets_academiques'");
    if (tables.isEmpty) {
      await db.execute('''
        CREATE TABLE projets_academiques (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          titre TEXT NOT NULL,
          description TEXT,
          date_rendu TEXT,
          cours_associe TEXT,
          difficulte INTEGER DEFAULT 3
        )
      ''');
    }
  }

  Future<void> _createBibliothequesTableIfNotExists(Database db) async {
    final tables = await db.rawQuery("SELECT name FROM sqlite_master WHERE type='table' AND name='bibliotheques'");
    if (tables.isEmpty) {
      await db.execute('''
        CREATE TABLE bibliotheques (
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
  }

  Future<void> _createEventTableIfNotExists(Database db) async {
    final tables = await db.rawQuery("SELECT name FROM sqlite_master WHERE type='table' AND name='event'");
    if (tables.isEmpty) {
      await db.execute('''
        CREATE TABLE event (
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
  }

  Future<void> _createEventParticipantTableIfNotExists(Database db) async {
    final tables = await db.rawQuery("SELECT name FROM sqlite_master WHERE type='table' AND name='event_participant'");
    if (tables.isEmpty) {
      await db.execute('''
        CREATE TABLE event_participant (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          event_id INTEGER NOT NULL,
          user_id INTEGER NOT NULL,
          participation_date DATETIME DEFAULT CURRENT_TIMESTAMP,
          FOREIGN KEY (event_id) REFERENCES event (id) ON DELETE CASCADE,
          UNIQUE(event_id, user_id)
        )
      ''');
    }
  }

  Future<void> _insertDefaultBibliothequesIfEmpty(Database db) async {
    final count = Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM bibliotheques'));
    if (count == 0) {
      await _insertDefaultBibliotheques(db);
    }
  }

  Future<void> _insertDefaultBibliotheques(Database db) async {
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

    await db.insert('event', {
      'title': 'Atelier de Recherche',
      'description': 'Apprendre les techniques de recherche documentaire',
      'date_time': DateTime.now().add(Duration(days: 2)).toIso8601String(),
      'location': 'Salle de formation',
      'max_participants': 25,
      'bibliotheque_id': bibliotheque1Id,
      'created_at': DateTime.now().toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    });

    await db.insert('event', {
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

  // NEW METHODS FOR MISSING TABLES
  Future<void> _createDepartementsTableIfNotExists(Database db) async {
    final tables = await db.rawQuery("SELECT name FROM sqlite_master WHERE type='table' AND name='departements'");
    if (tables.isEmpty) {
      await db.execute('''
        CREATE TABLE departements(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          nom TEXT NOT NULL,
          chef_departement TEXT NOT NULL,
          created_at TEXT NOT NULL
        )
      ''');
    }
  }

  Future<void> _createCoursTableIfNotExists(Database db) async {
    final tables = await db.rawQuery("SELECT name FROM sqlite_master WHERE type='table' AND name='cours'");
    if (tables.isEmpty) {
      await db.execute('''
        CREATE TABLE cours(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          nom TEXT NOT NULL,
          description TEXT,
          semestre TEXT NOT NULL,
          credits INTEGER NOT NULL,
          departement_id INTEGER,
          pdf_path TEXT,
          pdf_name TEXT,
          created_at TEXT NOT NULL,
          FOREIGN KEY (departement_id) REFERENCES departements(id)
        )
      ''');
    }
  }

  Future<void> _createCoursContentTableIfNotExists(Database db) async {
    final tables = await db.rawQuery("SELECT name FROM sqlite_master WHERE type='table' AND name='cours_content'");
    if (tables.isEmpty) {
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
    }
  }

  Future<void> _createCoursMetadataTableIfNotExists(Database db) async {
    final tables = await db.rawQuery("SELECT name FROM sqlite_master WHERE type='table' AND name='cours_metadata'");
    if (tables.isEmpty) {
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
    }
  }

  Future<void> _insertDefaultDepartementsIfEmpty(Database db) async {
    final count = Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM departements'));
    if (count == 0) {
      await _insertDefaultDepartements(db);
    }
  }

  Future<void> _insertDefaultDepartements(Database db) async {
    final defaultDepartements = [
      {
        'nom': 'Informatique',
        'chef_departement': 'Dr. Ahmed Benali',
        'created_at': DateTime.now().toIso8601String(),
      },
      {
        'nom': 'Mathématiques',
        'chef_departement': 'Prof. Marie Dupont',
        'created_at': DateTime.now().toIso8601String(),
      },
    ];

    for (final departement in defaultDepartements) {
      await db.insert('departements', departement);
    }
  }

  Future<void> _insertInitialData(Database db) async {
    try {
      final encryptedAdminPassword = _cryptoService.hashPassword('admin123');

      await db.insert('users', {
        'email': 'admin@compusflow.com',
        'name': 'Administrateur',
        'password': encryptedAdminPassword,
        'role': 'admin',
        'created_at': DateTime.now().toIso8601String(),
      });

      await db.insert('projets_academiques', {
        'titre': 'Projet Application Mobile',
        'description': 'Développement d\'une application de gestion académique.',
        'date_rendu': DateTime.now().add(const Duration(days: 90)).toIso8601String(),
        'cours_associe': 'Développement Mobile Avancé',
        'difficulte': 3,
      });

      await _insertDefaultSalles(db);
      await _insertDefaultBibliotheques(db);
      await _insertDefaultDepartements(db); // ADDED

      print('✅ Initial data inserted successfully');
    } catch (e) {
      print('Error inserting initial data: $e');
    }
  }

  // =============================================
  // CRUD OPERATIONS FOR ALL TABLES
  // =============================================

  // Salle CRUD
  Future<int> insertSalle(Salle s) async {
    try {
      final db = await database;
      return await db.insert('salle', s.toMap(), conflictAlgorithm: ConflictAlgorithm.abort);
    } catch (e) {
      throw Exception('Failed to insert room: $e');
    }
  }

  Future<List<Salle>> getAllSalles() async {
    try {
      final db = await database;
      final maps = await db.query('salle', orderBy: 'batiment ASC, numero ASC');
      return maps.map((m) => Salle.fromMap(m)).toList();
    } catch (e) {
      throw Exception('Failed to get rooms: $e');
    }
  }

  Future<Salle?> getSalleById(int id) async {
    final db = await database;
    final maps = await db.query('salle', where: 'id = ?', whereArgs: [id]);
    if (maps.isEmpty) return null;
    return Salle.fromMap(maps.first);
  }

  Future<int> updateSalle(Salle s) async {
    try {
      final db = await database;
      return await db.update('salle', s.toMap(), where: 'id = ?', whereArgs: [s.id]);
    } catch (e) {
      throw Exception('Failed to update room: $e');
    }
  }

  Future<int> deleteSalle(int id) async {
    try {
      final db = await database;
      final linked = await db.query('examen', where: 'salleId = ?', whereArgs: [id], limit: 1);
      if (linked.isNotEmpty) {
        throw Exception('Cannot delete: This room is assigned to one or more exams.');
      }
      return await db.delete('salle', where: 'id = ?', whereArgs: [id]);
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Failed to delete room: $e');
    }
  }

  // Examen CRUD
  Future<int> insertExamen(Examen e) async {
    try {
      final db = await database;
      if (e.salleId != null) {
        final available = await isSalleAvailable(e.salleId!, e.date, e.dureeMinutes);
        if (!available) {
          throw Exception('Room not available at this date/time.');
        }
      }
      return await db.insert('examen', e.toMap(), conflictAlgorithm: ConflictAlgorithm.abort);
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Failed to insert exam: $e');
    }
  }

  Future<List<Examen>> getAllExamens() async {
    try {
      final db = await database;
      final maps = await db.query('examen', orderBy: 'date DESC');
      return maps.map((m) => Examen.fromMap(m)).toList();
    } catch (e) {
      throw Exception('Failed to get exams: $e');
    }
  }

  Future<Examen?> getExamenById(int id) async {
    try {
      final db = await database;
      final maps = await db.query('examen', where: 'id = ?', whereArgs: [id], limit: 1);
      if (maps.isEmpty) return null;
      return Examen.fromMap(maps.first);
    } catch (e) {
      throw Exception('Failed to get exam: $e');
    }
  }

  Future<List<Examen>> getExamsBySalle(int salleId) async {
    try {
      final db = await database;
      final maps = await db.query('examen', where: 'salleId = ?', whereArgs: [salleId], orderBy: 'date ASC');
      return maps.map((m) => Examen.fromMap(m)).toList();
    } catch (e) {
      throw Exception('Failed to get exams for room: $e');
    }
  }

  Future<int> updateExamen(Examen e) async {
    try {
      final db = await database;
      if (e.salleId != null) {
        final available = await isSalleAvailable(e.salleId!, e.date, e.dureeMinutes, excludeExamId: e.id);
        if (!available) {
          throw Exception('Room not available at this date/time.');
        }
      }
      return await db.update('examen', e.toMap(), where: 'id = ?', whereArgs: [e.id]);
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Failed to update exam: $e');
    }
  }

  Future<int> deleteExamen(int id) async {
    try {
      final db = await database;
      return await db.delete('examen', where: 'id = ?', whereArgs: [id]);
    } catch (e) {
      throw Exception('Failed to delete exam: $e');
    }
  }

  // Projets CRUD
  Future<int> insertProjet(Map<String, dynamic> projet) async {
    final db = await database;
    return await db.insert('projets_academiques', projet);
  }

  Future<List<Map<String, dynamic>>> getProjets() async {
    final db = await database;
    return await db.query('projets_academiques', orderBy: 'date_rendu ASC');
  }

  Future<Map<String, dynamic>?> getProjetById(int id) async {
    final db = await database;
    final results = await db.query('projets_academiques', where: 'id = ?', whereArgs: [id]);
    return results.isNotEmpty ? results.first : null;
  }

  Future<int> updateProjet(int id, Map<String, dynamic> projet) async {
    final db = await database;
    return await db.update('projets_academiques', projet, where: 'id = ?', whereArgs: [id]);
  }

  Future<int> deleteProjet(int id) async {
    final db = await database;
    return await db.delete('projets_academiques', where: 'id = ?', whereArgs: [id]);
  }

  // Bibliotheques CRUD
  Future<int> insertBibliotheque(Map<String, dynamic> bibliotheque) async {
    final db = await database;
    return await db.insert('bibliotheques', bibliotheque);
  }

  Future<List<Map<String, dynamic>>> getBibliotheques() async {
    final db = await database;
    return await db.query('bibliotheques', orderBy: 'name ASC');
  }

  Future<Map<String, dynamic>?> getBibliothequeById(int id) async {
    final db = await database;
    final results = await db.query('bibliotheques', where: 'id = ?', whereArgs: [id]);
    return results.isNotEmpty ? results.first : null;
  }

  Future<int> updateBibliotheque(int id, Map<String, dynamic> bibliotheque) async {
    final db = await database;
    return await db.update('bibliotheques', bibliotheque, where: 'id = ?', whereArgs: [id]);
  }

  Future<int> deleteBibliotheque(int id) async {
    final db = await database;
    return await db.delete('bibliotheques', where: 'id = ?', whereArgs: [id]);
  }

  // Event (Bibliotheque) CRUD
  Future<int> insertEvent(Map<String, dynamic> event) async {
    final db = await database;
    return await db.insert('event', event);
  }

  Future<List<Map<String, dynamic>>> getEvents() async {
    final db = await database;
    return await db.query('event', orderBy: 'date_time ASC');
  }

  Future<List<Map<String, dynamic>>> getEventsByBibliotheque(int bibliothequeId) async {
    final db = await database;
    return await db.query('event', where: 'bibliotheque_id = ?', whereArgs: [bibliothequeId], orderBy: 'date_time ASC');
  }

  Future<Map<String, dynamic>?> getEventById(int id) async {
    final db = await database;
    final results = await db.query('event', where: 'id = ?', whereArgs: [id]);
    return results.isNotEmpty ? results.first : null;
  }

  Future<int> updateEvent(int id, Map<String, dynamic> event) async {
    final db = await database;
    return await db.update('event', event, where: 'id = ?', whereArgs: [id]);
  }

  Future<int> deleteEvent(int id) async {
    final db = await database;
    return await db.delete('event', where: 'id = ?', whereArgs: [id]);
  }

  // Event Participant CRUD
  Future<int> insertEventParticipant(Map<String, dynamic> participant) async {
    final db = await database;
    return await db.insert('event_participant', participant);
  }

  Future<List<Map<String, dynamic>>> getEventParticipants(int eventId) async {
    final db = await database;
    return await db.query('event_participant', where: 'event_id = ?', whereArgs: [eventId]);
  }

  Future<bool> isUserRegisteredForEvent(int eventId, int userId) async {
    final db = await database;
    final results = await db.query('event_participant', where: 'event_id = ? AND user_id = ?', whereArgs: [eventId, userId]);
    return results.isNotEmpty;
  }

  Future<int> deleteEventParticipant(int eventId, int userId) async {
    final db = await database;
    return await db.delete('event_participant', where: 'event_id = ? AND user_id = ?', whereArgs: [eventId, userId]);
  }

  // NEW CRUD FOR MISSING TABLES
  Future<int> insertDepartement(Map<String, dynamic> departement) async {
    final db = await database;
    return await db.insert('departements', departement);
  }

  Future<List<Map<String, dynamic>>> getDepartements() async {
    final db = await database;
    return await db.query('departements', orderBy: 'nom ASC');
  }

  Future<int> insertCours(Map<String, dynamic> cours) async {
    final db = await database;
    return await db.insert('cours', cours);
  }

  Future<List<Map<String, dynamic>>> getCours() async {
    final db = await database;
    return await db.query('cours', orderBy: 'nom ASC');
  }

  // Utility functions
  Future<bool> isSalleAvailable(int salleId, DateTime start, int durationMinutes, {int? excludeExamId}) async {
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

  Future<List<Salle>> getAvailableSalles(DateTime start, int durationMinutes) async {
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

  Future<List<Examen>> getExamensByDateRange(DateTime start, DateTime end) async {
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

  // Database management
  Future<void> clearAllData() async {
    try {
      final db = await database;
      await db.delete('examen');
      await db.delete('salle');
      await db.delete('projets_academiques');
      await db.delete('event_participant');
      await db.delete('event');
      await db.delete('bibliotheques');
      await db.delete('sessions');
      await db.delete('users');
      await db.delete('departements');
      await db.delete('cours');
      await db.delete('cours_content');
      await db.delete('cours_metadata');
      await _insertInitialData(db);
    } catch (e) {
      throw Exception('Failed to clear data: $e');
    }
  }

  Future<void> close() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
  }

  Future<void> resetDatabase() async {
    try {
      final dbPath = await getDatabasesPath();
      final path = join(dbPath, 'compusflow.db');
      await close();
      await deleteDatabase(path);
      _database = await _initDatabase();
      print('🧹 Database reset successfully.');
    } catch (e) {
      throw Exception('Failed to reset database: $e');
    }
  }
}