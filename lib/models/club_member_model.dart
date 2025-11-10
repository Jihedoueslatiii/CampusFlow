// Dans lib/models/club_member_model.dart, ajoutez un champ :
class ClubMember {
  int? id;
  int clubId;
  int userId;
  String role; // responsable, membre, candidat_responsable
  String status; // pending, approved, rejected
  DateTime dateAdhesion;
  bool canApproveResponsables; // AJOUT: Si ce responsable peut approuver d'autres responsables

  ClubMember({
    this.id,
    required this.clubId,
    required this.userId,
    required this.role,
    required this.status,
    required this.dateAdhesion,
    this.canApproveResponsables = false, // Par défaut false
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'clubId': clubId,
      'userId': userId,
      'role': role,
      'status': status,
      'dateAdhesion': dateAdhesion.toIso8601String(),
      'canApproveResponsables': canApproveResponsables ? 1 : 0, // Stocké comme integer
    };
  }

  factory ClubMember.fromMap(Map<String, dynamic> map) {
    return ClubMember(
      id: map['id'],
      clubId: map['clubId'],
      userId: map['userId'],
      role: map['role'],
      status: map['status'],
      dateAdhesion: DateTime.parse(map['dateAdhesion']),
      canApproveResponsables: map['canApproveResponsables'] == 1, // Convertir depuis integer
    );
  }
}