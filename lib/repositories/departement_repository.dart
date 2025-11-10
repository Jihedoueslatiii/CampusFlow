import 'package:sqflite/sqflite.dart';
import '../models/departement.dart';
import '../services/database_service.dart';

class DepartementRepository {
  final DatabaseService _databaseService = DatabaseService();

  Future<int> insertDepartement(Departement departement) async {
    try {
      final db = await _databaseService.database;

      // ⭐ LOG POUR DÉBOGUAGE
      print('🔄 Insertion département dans table: departements');
      print('📦 Données: ${departement.toMap()}');

      final result = await db.insert('departements', departement.toMap());
      print('✅ Département inséré avec ID: $result');
      return result;
    } catch (e) {
      print('❌ Erreur insertion département: $e');
      rethrow;
    }
  }

  Future<List<Departement>> getAllDepartements() async {
    try {
      final db = await _databaseService.database;
      final List<Map<String, dynamic>> maps = await db.query('departements');
      print('📊 ${maps.length} départements récupérés');
      return List.generate(maps.length, (i) => Departement.fromMap(maps[i]));
    } catch (e) {
      print('❌ Erreur récupération départements: $e');
      return [];
    }
  }

  Future<Departement?> getDepartementById(int id) async {
    final db = await _databaseService.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'departements',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) {
      return Departement.fromMap(maps.first);
    }
    return null;
  }

  Future<int> updateDepartement(Departement departement) async {
    final db = await _databaseService.database;
    return await db.update(
      'departements',
      departement.toMap(),
      where: 'id = ?',
      whereArgs: [departement.id],
    );
  }

  Future<int> deleteDepartement(int id) async {
    final db = await _databaseService.database;
    return await db.delete(
      'departements',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> getDepartementCount() async {
    final db = await _databaseService.database;
    final count = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM departements'),
    );
    return count ?? 0;
  }
}