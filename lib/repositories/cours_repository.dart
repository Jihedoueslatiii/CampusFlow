import 'package:sqflite/sqflite.dart';
import '../models/cours.dart';
import '../services/database_service.dart';

class CoursRepository {
  final DatabaseService _databaseService = DatabaseService();

  Future<int> insertCours(Cours cours) async {
    final db = await _databaseService.database;
    return await db.insert('cours', cours.toMap());
  }

  Future<List<Cours>> getAllCours() async {
    final db = await _databaseService.database;
    final List<Map<String, dynamic>> maps = await db.rawQuery('''
      SELECT c.*, d.nom as departement_nom 
      FROM cours c 
      LEFT JOIN departements d ON c.departement_id = d.id
      ORDER BY c.created_at DESC
    ''');

    return List.generate(maps.length, (i) {
      return Cours(
        id: maps[i]['id'],
        nom: maps[i]['nom'],
        description: maps[i]['description'],
        semestre: maps[i]['semestre'],
        credits: maps[i]['credits'],
        departementId: maps[i]['departement_id'],
        departementNom: maps[i]['departement_nom'],
        pdfPath: maps[i]['pdf_path'],
        pdfName: maps[i]['pdf_name'],
        createdAt: maps[i]['created_at'],
      );
    });
  }

  Future<List<Cours>> getCoursByDepartement(int departementId) async {
    final db = await _databaseService.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'cours',
      where: 'departement_id = ?',
      whereArgs: [departementId],
    );
    return List.generate(maps.length, (i) => Cours.fromMap(maps[i]));
  }

  Future<int> updateCours(Cours cours) async {
    final db = await _databaseService.database;
    return await db.update(
      'cours',
      cours.toMap(),
      where: 'id = ?',
      whereArgs: [cours.id],
    );
  }

  Future<int> deleteCours(int id) async {
    final db = await _databaseService.database;
    return await db.delete(
      'cours',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}