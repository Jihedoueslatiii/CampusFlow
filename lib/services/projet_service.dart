import 'package:compusflow/services/database_service.dart';

class ProjetService {
  final DatabaseService _databaseService = DatabaseService();

  // CRUD pour Admin

  Future<int> addProjet({
    required String titre,
    required String description,
    required String dateRendu,
    required String coursAssocie,
  }) async {
    final projetData = {
      'titre': titre,
      'description': description,
      'date_rendu': dateRendu,
      'cours_associe': coursAssocie,
    };
    return await _databaseService.insertProjet(projetData);
  }

  Future<int> updateProjet({
    required int id,
    required String titre,
    required String description,
    required String dateRendu,
    required String coursAssocie,
  }) async {
    final projetData = {
      'titre': titre,
      'description': description,
      'date_rendu': dateRendu,
      'cours_associe': coursAssocie,
    };
    return await _databaseService.updateProjet(id, projetData);
  }

  Future<int> deleteProjet(int id) async {
    return await _databaseService.deleteProjet(id);
  }

  // READ pour Tous
  Future<List<Map<String, dynamic>>> getAllProjets() async {
    return await _databaseService.getProjets();
  }

  Future<Map<String, dynamic>?> getProjetById(int id) async {
    return await _databaseService.getProjetById(id);
  }
}