// lib/models/club_model.dart

class Club {
  int? id;
  String nom;
  String type; // sport, culturel
  int responsableId; // ID de l'étudiant responsable
  int? createurId;
  String? description;
  String status; // pending, approved, rejected
  DateTime dateCreation;
  String? raisonSuppression;
  String? statusSuppression; // pending, approved, rejected

  bool get isAdmin {
    // Cette logique dépend de votre implémentation
    // Vous devrez peut-être passer l'userId actuel
    return true; // À adapter
  }

  Club({
    this.id,
    required this.nom,
    required this.type,
    required this.responsableId,
    this.createurId,
    this.description,
    required this.status,
    required this.dateCreation,
    this.raisonSuppression,
    this.statusSuppression,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nom': nom,
      'type': type,
      'responsableId': responsableId,
      'createurId': createurId,
      'description': description,
      'status': status,
      'dateCreation': dateCreation.toIso8601String(),
      'raisonSuppression': raisonSuppression,
      'statusSuppression': statusSuppression,
    };
  }

  factory Club.fromMap(Map<String, dynamic> map) {
    return Club(
      id: map['id'],
      nom: map['nom'],
      type: map['type'],
      responsableId: map['responsableId'],
      description: map['description'],
      status: map['status'],
      dateCreation: DateTime.parse(map['dateCreation']),
      raisonSuppression: map['raisonSuppression'],
      statusSuppression: map['statusSuppression'],
    );
  }
}