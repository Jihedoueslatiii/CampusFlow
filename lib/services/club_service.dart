// lib/services/club_service.dart

import 'package:sqflite/sqflite.dart';
import '../models/club_model.dart';
import '../models/club_member_model.dart';
import '../models/events_model.dart';
import 'database_service.dart';

class ClubService {
  final DatabaseService _databaseService = DatabaseService();

  // CRUD pour Club
  Future<int> createClub(Club club) async {
    final db = await _databaseService.database;
    return await db.insert('clubs', club.toMap());
  }

  Future<Club?> getClubById(int id) async {
    final db = await _databaseService.database;
    List<Map<String, dynamic>> maps = await db.query(
      'clubs',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) {
      return Club.fromMap(maps.first);
    }
    return null;
  }

  Future<int> updateClub(Club club) async {
    final db = await _databaseService.database;
    return await db.update(
      'clubs',
      club.toMap(),
      where: 'id = ?',
      whereArgs: [club.id],
    );
  }

  // Dans services/club_service.dart - Ajoutez cette méthode
  Future<Club?> getClub(int clubId) async {
    try {
      final db = await _databaseService.database;
      final List<Map<String, dynamic>> maps = await db.query(
        'clubs',
        where: 'id = ?',
        whereArgs: [clubId],
      );

      if (maps.isNotEmpty) {
        final map = maps[0];
        return Club(
          id: map['id'],
          nom: map['nom'],
          type: map['type'],
          responsableId: map['responsableId'],
          createurId: map['createurId'] ?? map['responsableId'], // Fallback
          description: map['description'],
          status: map['status'],
          dateCreation: DateTime.parse(map['dateCreation']),
          raisonSuppression: map['raisonSuppression'],
          statusSuppression: map['statusSuppression'],
        );
      }
      return null;
    } catch (e) {
      print('Erreur getClub: $e');
      return null;
    }
  }

  // Dans services/club_service.dart - Ajoutez cette méthode
  Future<List<Club>> getClubsByAdmin(int adminId) async {
    final db = await _databaseService.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'clubs',
      where: 'adminId = ? AND isActive = ?',
      whereArgs: [adminId, 1],
    );
    return List.generate(maps.length, (i) => Club.fromMap(maps[i]));
  }

  Future<int> deleteClub(int id) async {
    final db = await _databaseService.database;
    // Supprimer d'abord les membres et événements associés
    await db.delete('club_members', where: 'clubId = ?', whereArgs: [id]);
    await db.delete('events', where: 'clubId = ?', whereArgs: [id]);
    // Puis supprimer le club
    return await db.delete('clubs', where: 'id = ?', whereArgs: [id]);
  }

  // Gestion des membres
  Future<int> addClubMember(ClubMember member) async {
    final db = await _databaseService.database;
    return await db.insert('club_members', member.toMap());
  }

  Future<List<ClubMember>> getClubMembers(int clubId, {String? status}) async {
    final db = await _databaseService.database;
    List<Map<String, dynamic>> maps;

    if (status != null) {
      maps = await db.query(
        'club_members',
        where: 'clubId = ? AND status = ?',
        whereArgs: [clubId, status],
      );
    } else {
      maps = await db.query(
        'club_members',
        where: 'clubId = ?',
        whereArgs: [clubId],
      );
    }

    return List.generate(maps.length, (i) => ClubMember.fromMap(maps[i]));
  }

  Future<ClubMember?> getClubMember(int clubId, int userId) async {
    final db = await _databaseService.database;
    List<Map<String, dynamic>> maps = await db.query(
      'club_members',
      where: 'clubId = ? AND userId = ?',
      whereArgs: [clubId, userId],
    );
    if (maps.isNotEmpty) {
      return ClubMember.fromMap(maps.first);
    }
    return null;
  }

  Future<int> updateClubMemberStatus(int memberId, String status) async {
    final db = await _databaseService.database;
    return await db.update(
      'club_members',
      {'status': status},
      where: 'id = ?',
      whereArgs: [memberId],
    );
  }

  Future<int> updateClubMemberRole(int memberId, String role) async {
    final db = await _databaseService.database;
    return await db.update(
      'club_members',
      {'role': role},
      where: 'id = ?',
      whereArgs: [memberId],
    );
  }

  Future<int> removeClubMember(int clubId, int userId) async {
    final db = await _databaseService.database;
    return await db.delete(
      'club_members',
      where: 'clubId = ? AND userId = ?',
      whereArgs: [clubId, userId],
    );
  }

  // Gestion des événements
  Future<int> createEvent(Event event) async {
    final db = await _databaseService.database;
    return await db.insert('events', event.toMap());
  }

  Future<List<Event>> getClubEvents(int clubId) async {
    final db = await _databaseService.database;
    List<Map<String, dynamic>> maps = await db.query(
      'events',
      where: 'clubId = ?',
      whereArgs: [clubId],
      orderBy: 'dateDebut DESC',
    );
    return List.generate(maps.length, (i) => Event.fromMap(maps[i]));
  }

  // Méthodes métier améliorées
  Future<bool> isUserResponsable(int clubId, int userId) async {
    final member = await getClubMember(clubId, userId);
    return member != null && member.role == 'responsable' && member.status == 'approved';
  }

  Future<bool> isUserMember(int clubId, int userId) async {
    final member = await getClubMember(clubId, userId);
    return member != null && member.status == 'approved';
  }

  Future<bool> hasUserPendingRequest(int clubId, int userId) async {
    final member = await getClubMember(clubId, userId);
    return member != null && member.status == 'pending';
  }

  Future<List<Club>> getClubsByResponsable(int userId) async {
    final db = await _databaseService.database;
    List<Map<String, dynamic>> maps = await db.query(
      'clubs',
      where: 'responsableId = ? AND status = ?',
      whereArgs: [userId, 'approved'],
    );
    return List.generate(maps.length, (i) => Club.fromMap(maps[i]));
  }

  Future<List<Club>> getPendingClubs() async {
    final db = await _databaseService.database;
    List<Map<String, dynamic>> maps = await db.query(
      'clubs',
      where: 'status = ?',
      whereArgs: ['pending'],
    );
    return List.generate(maps.length, (i) => Club.fromMap(maps[i]));
  }

  // Méthodes pour rejoindre un club
  Future<int> joinClub(int clubId, int userId) async {
    final existingMember = await getClubMember(clubId, userId);

    if (existingMember != null) {
      // Si déjà membre, retourner l'ID existant
      return existingMember.id!;
    } else {
      // Créer une nouvelle demande d'adhésion
      final newMember = ClubMember(
        clubId: clubId,
        userId: userId,
        role: 'membre',
        status: 'pending',
        dateAdhesion: DateTime.now(),
      );
      return await addClubMember(newMember);
    }
  }

  // Méthodes pour approuver/rejeter les demandes d'adhésion
  Future<int> approveMemberRequest(int memberId) async {
    return await updateClubMemberStatus(memberId, 'approved');
  }

  Future<int> rejectMemberRequest(int memberId) async {
    return await updateClubMemberStatus(memberId, 'rejected');
  }

  // Méthodes pour les demandes de suppression
  Future<int> requestClubDeletion(int clubId, String raison) async {
    final db = await _databaseService.database;
    return await db.update(
      'clubs',
      {
        'raisonSuppression': raison,
        'statusSuppression': 'pending',
      },
      where: 'id = ?',
      whereArgs: [clubId],
    );
  }

  // Dans ClubService
  Future<List<Club>> getPendingDeletionRequests() async {
    final db = await _databaseService.database;
    List<Map<String, dynamic>> maps = await db.query(
      'clubs',
      where: 'statusSuppression = ? AND status = ?',
      whereArgs: ['pending', 'approved'],
    );
    return List.generate(maps.length, (i) => Club.fromMap(maps[i]));
  }

  Future<int> approveClubDeletion(int clubId) async {
    final db = await _databaseService.database;
    return await db.update(
      'clubs',
      {
        'statusSuppression': 'approved',
        'status': 'deleted',
      },
      where: 'id = ?',
      whereArgs: [clubId],
    );
  }

  Future<int> rejectClubDeletion(int clubId) async {
    final db = await _databaseService.database;
    return await db.update(
      'clubs',
      {
        'raisonSuppression': null,
        'statusSuppression': 'rejected',
      },
      where: 'id = ?',
      whereArgs: [clubId],
    );
  }

  // Méthodes d'approbation admin
  Future<int> approveClub(int clubId) async {
    final db = await _databaseService.database;
    return await db.update(
      'clubs',
      {'status': 'approved'},
      where: 'id = ?',
      whereArgs: [clubId],
    );
  }

  Future<int> rejectClub(int clubId) async {
    final db = await _databaseService.database;
    return await db.update(
      'clubs',
      {'status': 'rejected'},
      where: 'id = ?',
      whereArgs: [clubId],
    );
  }

  // Méthodes statistiques
  Future<int> getMembersCount(int clubId) async {
    final db = await _databaseService.database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM club_members WHERE clubId = ? AND status = ?',
      [clubId, 'approved'],
    );
    return result.first['count'] as int;
  }

  Future<int> getPendingRequestsCount(int clubId) async {
    final db = await _databaseService.database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM club_members WHERE clubId = ? AND status = ?',
      [clubId, 'pending'],
    );
    return result.first['count'] as int;
  }


  // Méthode pour récupérer tous les clubs (y compris supprimés)
  Future<List<Club>> getAllClubsIncludingDeleted() async {
    final db = await _databaseService.database;
    List<Map<String, dynamic>> maps = await db.query('clubs');
    return List.generate(maps.length, (i) => Club.fromMap(maps[i]));
  }

// Modifier adminDeleteClub pour marquer comme supprimé au lieu de supprimer
  Future<int> adminDeleteClub(int clubId, String raison) async {
    final db = await _databaseService.database;

    return await db.update(
      'clubs',
      {
        'raisonSuppression': raison,
        'statusSuppression': 'admin_deleted',
        'status': 'deleted',
      },
      where: 'id = ?',
      whereArgs: [clubId],
    );
  }

// Modifier getClubs pour exclure les supprimés
  Future<List<Club>> getClubs({String? status}) async {
    final db = await _databaseService.database;
    List<Map<String, dynamic>> maps;

    if (status != null) {
      maps = await db.query(
          'clubs',
          where: 'status = ? AND status != ?',
          whereArgs: [status, 'deleted']
      );
    } else {
      maps = await db.query(
          'clubs',
          where: 'status != ?',
          whereArgs: ['deleted']
      );
    }

    return List.generate(maps.length, (i) => Club.fromMap(maps[i]));
  }


  // Dans lib/services/club_service.dart

// Vérifier si un utilisateur peut approuver des responsables
  Future<bool> canApproveResponsables(int clubId, int userId) async {
    final member = await getClubMember(clubId, userId);
    return member != null &&
        member.role == 'responsable' &&
        member.status == 'approved' &&
        member.canApproveResponsables;
  }

// Demander à devenir responsable
  Future<int> requestResponsableRole(int clubId, int userId) async {
    final existingMember = await getClubMember(clubId, userId);

    if (existingMember != null) {
      // Mettre à jour le rôle existant
      return await updateClubMemberRole(existingMember.id!, 'candidat_responsable');
    } else {
      // Créer un nouveau membre avec le rôle candidat
      final newMember = ClubMember(
        clubId: clubId,
        userId: userId,
        role: 'candidat_responsable',
        status: 'pending',
        dateAdhesion: DateTime.now(),
        canApproveResponsables: false,
      );
      return await addClubMember(newMember);
    }
  }

// Récupérer les candidats responsables
  Future<List<ClubMember>> getResponsableCandidates(int clubId) async {
    final db = await _databaseService.database;
    List<Map<String, dynamic>> maps = await db.query(
      'club_members',
      where: 'clubId = ? AND role = ? AND status = ?',
      whereArgs: [clubId, 'candidat_responsable', 'pending'],
    );
    return List.generate(maps.length, (i) => ClubMember.fromMap(maps[i]));
  }

// Approuver un candidat responsable
  Future<int> approveResponsableCandidate(int candidateId, int approverUserId) async {
    final db = await _databaseService.database;

    // Récupérer le candidat
    final candidate = await getClubMemberById(candidateId);
    if (candidate == null) throw Exception('Candidat non trouvé');

    // Vérifier que l'approbateur a les permissions
    final canApprove = await canApproveResponsables(candidate.clubId, approverUserId);
    if (!canApprove) throw Exception('Vous n\'avez pas la permission d\'approuver des responsables');

    // Mettre à jour le candidat en responsable
    return await db.update(
      'club_members',
      {
        'role': 'responsable',
        'status': 'approved',
        'canApproveResponsables': 0, // Nouveaux responsables n'ont pas les permissions par défaut
      },
      where: 'id = ?',
      whereArgs: [candidateId],
    );
  }

// Donner les permissions d'approbation à un responsable
  Future<int> grantApprovalPermissions(int memberId, int granterUserId) async {
    final db = await _databaseService.database;

    // Récupérer le membre
    final member = await getClubMemberById(memberId);
    if (member == null) throw Exception('Membre non trouvé');

    // Vérifier que celui qui donne les permissions a lui-même les permissions
    final canGrant = await canApproveResponsables(member.clubId, granterUserId);
    if (!canGrant) throw Exception('Vous n\'avez pas la permission de donner ces permissions');

    // Donner les permissions
    return await db.update(
      'club_members',
      {
        'canApproveResponsables': 1,
      },
      where: 'id = ?',
      whereArgs: [memberId],
    );
  }

// Récupérer un membre par son ID
  Future<ClubMember?> getClubMemberById(int memberId) async {
    final db = await _databaseService.database;
    List<Map<String, dynamic>> maps = await db.query(
      'club_members',
      where: 'id = ?',
      whereArgs: [memberId],
    );
    if (maps.isNotEmpty) {
      return ClubMember.fromMap(maps.first);
    }
    return null;
  }


}