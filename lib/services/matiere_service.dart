import 'package:sqflite/sqflite.dart';
import '../models/matiere_model.dart';
import 'database_service.dart';

class MatiereService {
  final DatabaseService _databaseService = DatabaseService();

  // Initialiser les 10 matières prédéfinies
  Future<void> initializeMatieres() async {
    final db = await _databaseService.database;

    final matieres = [
      Matiere(nom: 'Mathématiques', description: 'Algèbre et analyse'),
      Matiere(nom: 'Physique', description: 'Mécanique et électricité'),
      Matiere(nom: 'Chimie', description: 'Chimie organique et inorganique'),
      Matiere(nom: 'Informatique', description: 'Programmation et algorithmes'),
      Matiere(nom: 'Français', description: 'Littérature et grammaire'),
      Matiere(nom: 'Anglais', description: 'Langue anglaise'),
      Matiere(nom: 'Histoire-Géographie', description: 'Histoire et géographie mondiale'),
      Matiere(nom: 'SVT', description: 'Sciences de la Vie et de la Terre'),
      Matiere(nom: 'Philosophie', description: 'Pensée philosophique'),
      Matiere(nom: 'Économie', description: 'Principes économiques'),
    ];

    for (final matiere in matieres) {
      await db.insert(
        'matieres',
        matiere.toMap(),
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );
    }
  }

  // Récupérer toutes les matières
  Future<List<Matiere>> getMatieres() async {
    final db = await _databaseService.database;

    // VÉRIFIER SI BESOIN D'INITIALISER
    final count = Sqflite.firstIntValue(
        await db.rawQuery('SELECT COUNT(*) FROM matieres')
    );

    if (count == 0) {
      print('🔄 Initialisation des matières...');
      await initializeMatieres();
    }

    final List<Map<String, dynamic>> maps = await db.query('matieres', distinct: true);
    return List.generate(maps.length, (i) => Matiere.fromMap(maps[i]));
  }

  // Vider et réinitialiser les matières
  Future<void> reinitialiserMatieres() async {
    final db = await _databaseService.database;

    // Vider la table
    await db.delete('matieres');

    // Réinitialiser l'auto-increment (SQLite)
    await db.rawDelete('DELETE FROM sqlite_sequence WHERE name="matieres"');

    // Recréer les matières
    await initializeMatieres();

    print('✅ Matières réinitialisées');
  }

  // Inscrire un étudiant à des matières
  Future<void> inscrireEtudiantMatieres(int etudiantId, List<int> matiereIds) async {
    final db = await _databaseService.database;

    // Supprimer les anciennes inscriptions
    await db.delete(
      'etudiant_matieres',
      where: 'etudiant_id = ?',
      whereArgs: [etudiantId],
    );

    // Ajouter les nouvelles inscriptions
    for (final matiereId in matiereIds) {
      await db.insert('etudiant_matieres', {
        'etudiant_id': etudiantId,
        'matiere_id': matiereId,
      });
    }
  }

  // Récupérer les matières d'un étudiant
  Future<List<Matiere>> getMatieresEtudiant(int etudiantId) async {
    final db = await _databaseService.database;
    final List<Map<String, dynamic>> maps = await db.rawQuery('''
      SELECT m.* FROM matieres m
      INNER JOIN etudiant_matieres em ON m.id = em.matiere_id
      WHERE em.etudiant_id = ?
    ''', [etudiantId]);

    return List.generate(maps.length, (i) => Matiere.fromMap(maps[i]));
  }

  // Vérifier si un étudiant a choisi ses matières
  Future<bool> etudiantAChoisiMatieres(int etudiantId) async {
    final db = await _databaseService.database;
    final List<Map<String, dynamic>> maps = await db.rawQuery('''
      SELECT COUNT(*) as count FROM etudiant_matieres 
      WHERE etudiant_id = ?
    ''', [etudiantId]);

    return maps.first['count'] > 0;
  }
}