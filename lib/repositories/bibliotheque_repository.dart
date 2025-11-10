// repositories/bibliotheque_repository.dart
import 'package:sqflite/sqflite.dart';
import '../models/bibliotheque_model.dart';
import '../services/database_service.dart';

class BibliothequeRepository {
  final DatabaseService databaseService;

  BibliothequeRepository(this.databaseService);

  Future<void> createTables() async {
    final db = await databaseService.database;
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

  Future<int> createBibliotheque(Bibliotheque bibliotheque) async {
    final db = await databaseService.database;
    return await db.insert('bibliotheques', bibliotheque.toMap());
  }

  Future<List<Bibliotheque>> getBibliotheques() async {
    final db = await databaseService.database;
    final List<Map<String, dynamic>> maps = await db.query('bibliotheques');
    return List.generate(maps.length, (i) => Bibliotheque.fromMap(maps[i]));
  }

  Future<Bibliotheque?> getBibliothequeById(int id) async {
    final db = await databaseService.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'bibliotheques',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) {
      return Bibliotheque.fromMap(maps.first);
    }
    return null;
  }

  Future<int> updateBibliotheque(Bibliotheque bibliotheque) async {
    final db = await databaseService.database;
    return await db.update(
      'bibliotheques',
      bibliotheque.toMap(),
      where: 'id = ?',
      whereArgs: [bibliotheque.id],
    );
  }

  Future<int> deleteBibliotheque(int id) async {
    final db = await databaseService.database;
    return await db.delete(
      'bibliotheques',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}