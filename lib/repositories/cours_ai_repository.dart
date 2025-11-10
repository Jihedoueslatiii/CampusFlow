import 'package:sqflite/sqflite.dart';
import '../services/database_service.dart';
import '../models/cours_content.dart';
import '../models/cours_metadata.dart';

class CoursAIRepository {
  final DatabaseService _databaseService = DatabaseService();

  // Contenu IA
  Future<int> insertCoursContent(CoursContent content) async {
    final db = await _databaseService.database;
    return await db.insert('cours_content', content.toMap());
  }

  Future<List<CoursContent>> getCoursContent(int coursId, {String? contentType}) async {
    final db = await _databaseService.database;
    String where = 'cours_id = ?';
    List<dynamic> whereArgs = [coursId];

    if (contentType != null) {
      where += ' AND content_type = ?';
      whereArgs.add(contentType);
    }

    final List<Map<String, dynamic>> maps = await db.query(
      'cours_content',
      where: where,
      whereArgs: whereArgs,
      orderBy: 'created_at DESC',
    );

    return maps.map((map) => CoursContent.fromMap(map)).toList();
  }

  // Métadonnées IA
  Future<int> insertCoursMetadata(CoursMetadata metadata) async {
    final db = await _databaseService.database;
    return await db.insert('cours_metadata', metadata.toMap());
  }

  Future<CoursMetadata?> getCoursMetadata(int coursId) async {
    final db = await _databaseService.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'cours_metadata',
      where: 'cours_id = ?',
      whereArgs: [coursId],
    );

    if (maps.isNotEmpty) {
      return CoursMetadata.fromMap(maps.first);
    }
    return null;
  }

  Future<int> updateCoursMetadata(CoursMetadata metadata) async {
    final db = await _databaseService.database;
    return await db.update(
      'cours_metadata',
      metadata.toMap(),
      where: 'cours_id = ?',
      whereArgs: [metadata.coursId],
    );
  }
}