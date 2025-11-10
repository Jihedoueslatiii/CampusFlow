// lib/screens/club/club_details_screen.dart

import 'package:flutter/material.dart';
import '../../services/club_service.dart';
import '../../services/auth_service.dart';
import '../../models/club_model.dart';
import '../../models/club_member_model.dart';
import '../events/create_event_screen.dart';
import 'club_deletion_notification_screen.dart';

class ClubDetailsScreen extends StatefulWidget {
  final int clubId;
  final int userId;
  final String userRole;
  final Club club;

  const ClubDetailsScreen({
    Key? key,
    required this.clubId,
    required this.userId,
    required this.userRole,
    required this.club
  }) : super(key: key);

  @override
  _ClubDetailsScreenState createState() => _ClubDetailsScreenState();
}

class _ClubDetailsScreenState extends State<ClubDetailsScreen> {
  final ClubService _clubService = ClubService();
  final AuthService _authService = AuthService();

  Club? _club;
  List<ClubMember> _members = [];
  List<ClubMember> _pendingRequests = [];
  bool _isResponsable = false;
  bool _isMember = false;
  bool _hasPendingRequest = false;
  bool _isLoading = true;

  // Color palette
  static const Color primaryAccent = Color(0xFFE53935); // Vivid Red
  static const Color background = Color(0xFFFFFFFF); // Pure White
  static const Color textPrimary = Color(0xFF212121); // Dark Gray
  static const Color backgroundSecondary = Color(0xFFF5F5F5); // Light Gray

  bool get _isCurrentUserResponsable {
    if (_members.isEmpty) return false;

    // Find the current user in members list and check their role
    final currentUserMembership = _members.firstWhere(
          (member) => member.userId == widget.userId,
      orElse: () => ClubMember(
        id: -1,
        userId: -1,
        clubId: -1,
        role: '',
        status: '',
        dateAdhesion: DateTime.now(), // ← ADD THIS REQUIRED PARAMETER
        canApproveResponsables: false,
      ),
    );

    return currentUserMembership.role == 'responsable';
  }

  @override
  void initState() {
    super.initState();
    _loadClubData();
  }

  Future<void> _loadClubData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final club = await _clubService.getClubById(widget.clubId);
      final members = await _clubService.getClubMembers(widget.clubId, status: 'approved');
      final pendingRequests = await _clubService.getClubMembers(widget.clubId, status: 'pending');
      final isResponsable = await _clubService.isUserResponsable(widget.clubId, widget.userId);
      final isMember = await _clubService.isUserMember(widget.clubId, widget.userId);
      final hasPendingRequest = await _clubService.hasUserPendingRequest(widget.clubId, widget.userId);

      setState(() {
        _club = club;
        _members = members;
        _pendingRequests = pendingRequests;
        _isResponsable = isResponsable;
        _isMember = isMember;
        _hasPendingRequest = hasPendingRequest;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur de chargement: $e'),
          backgroundColor: primaryAccent,
        ),
      );
    }
  }

  Future<void> _joinClub() async {
    try {
      await _clubService.joinClub(widget.clubId, widget.userId);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Demande d\'adhésion envoyée!'),
          backgroundColor: primaryAccent,
        ),
      );
      await _loadClubData();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur: $e'),
          backgroundColor: primaryAccent,
        ),
      );
    }
  }

  Future<void> _requestResponsableRole() async {
    try {
      await _clubService.requestResponsableRole(widget.clubId, widget.userId);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Demande envoyée pour devenir responsable'),
          backgroundColor: primaryAccent,
        ),
      );
      await _loadClubData();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur: $e'),
          backgroundColor: primaryAccent,
        ),
      );
    }
  }

  Future<void> _approveResponsableCandidate(int candidateId) async {
    try {
      await _clubService.approveResponsableCandidate(candidateId, widget.userId);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Candidat approuvé comme responsable'),
          backgroundColor: primaryAccent,
        ),
      );
      await _loadClubData();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur: $e - Vous n\'avez pas la permission'),
          backgroundColor: primaryAccent,
        ),
      );
    }
  }

  Future<void> _grantApprovalPermissions(int memberId) async {
    try {
      await _clubService.grantApprovalPermissions(memberId, widget.userId);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Permissions d\'approbation données'),
          backgroundColor: primaryAccent,
        ),
      );
      await _loadClubData();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur: $e'),
          backgroundColor: primaryAccent,
        ),
      );
    }
  }

  // Méthode pour construire la section des candidats responsables
  Widget _buildResponsableCandidatesSection() {
    return FutureBuilder<List<ClubMember>>(
      future: _clubService.getResponsableCandidates(widget.clubId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator(color: primaryAccent));
        }

        if (snapshot.hasData && snapshot.data!.isNotEmpty) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 16),
              Text(
                'Candidats Responsables',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textPrimary),
              ),
              SizedBox(height: 8),
              ...snapshot.data!.map((candidate) => Card(
                color: background,
                margin: EdgeInsets.symmetric(vertical: 4),
                elevation: 1,
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: primaryAccent,
                    child: Icon(Icons.person_add, color: background, size: 20),
                  ),
                  title: Text(
                    'Utilisateur #${candidate.userId}',
                    style: TextStyle(color: textPrimary),
                  ),
                  subtitle: Text(
                    'Demande en attente',
                    style: TextStyle(color: textPrimary.withOpacity(0.7)),
                  ),
                  trailing: IconButton(
                    icon: Icon(Icons.check, color: primaryAccent),
                    onPressed: () => _approveResponsableCandidate(candidate.id!),
                    tooltip: 'Approuver comme responsable',
                  ),
                ),
              )).toList(),
            ],
          );
        }
        return SizedBox.shrink();
      },
    );
  }

  Future<void> _updateClubName() async {
    final TextEditingController controller = TextEditingController(text: _club?.nom ?? '');

    final newName = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: background,
        title: Text(
          'Modifier le nom du club',
          style: TextStyle(color: textPrimary),
        ),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: 'Nouveau nom du club',
            border: OutlineInputBorder(),
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(color: primaryAccent),
            ),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Annuler',
              style: TextStyle(color: textPrimary),
            ),
          ),
          TextButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                Navigator.pop(context, controller.text.trim());
              }
            },
            child: Text(
              'Modifier',
              style: TextStyle(color: primaryAccent),
            ),
          ),
        ],
      ),
    );

    if (newName != null && newName.isNotEmpty && newName != _club?.nom) {
      try {
        final updatedClub = Club(
          id: _club!.id,
          nom: newName,
          type: _club!.type,
          responsableId: _club!.responsableId,
          description: _club!.description,
          status: _club!.status,
          dateCreation: _club!.dateCreation,
          raisonSuppression: _club!.raisonSuppression,
          statusSuppression: _club!.statusSuppression,
        );

        await _clubService.updateClub(updatedClub);
        await _loadClubData();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Nom du club modifié avec succès!'),
            backgroundColor: primaryAccent,
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de la modification: $e'),
            backgroundColor: primaryAccent,
          ),
        );
      }
    }
  }

  Future<void> _requestDeletion() async {
    final TextEditingController controller = TextEditingController();

    final raison = await showDialog<String>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            backgroundColor: background,
            title: Text(
              'Demande de suppression',
              style: TextStyle(color: textPrimary),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Veuillez expliquer la raison de la suppression :',
                  style: TextStyle(color: textPrimary),
                ),
                SizedBox(height: 16),
                TextField(
                  controller: controller,
                  decoration: InputDecoration(
                    hintText: 'Raison de la suppression...',
                    border: OutlineInputBorder(),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: primaryAccent),
                    ),
                    errorText: controller.text.isEmpty ? 'Ce champ est obligatoire' : null,
                  ),
                  maxLines: 3,
                  autofocus: true,
                  onChanged: (value) {
                    setDialogState(() {});
                  },
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'Annuler',
                  style: TextStyle(color: textPrimary),
                ),
              ),
              TextButton(
                onPressed: controller.text.trim().isEmpty
                    ? null
                    : () => Navigator.pop(context, controller.text.trim()),
                child: Text(
                  'Envoyer',
                  style: TextStyle(color: primaryAccent),
                ),
              ),
            ],
          );
        },
      ),
    );

    if (raison != null && raison.isNotEmpty) {
      try {
        await _clubService.requestClubDeletion(widget.clubId, raison);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Demande de suppression envoyée à l\'administrateur'),
            backgroundColor: primaryAccent,
          ),
        );

        await _loadClubData();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de l\'envoi: $e'),
            backgroundColor: primaryAccent,
          ),
        );
      }
    }
  }

  Future<void> _approveMember(int memberId) async {
    await _clubService.approveMemberRequest(memberId);
    await _loadClubData();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Membre approuvé'),
        backgroundColor: primaryAccent,
      ),
    );
  }

  Future<void> _adminDeleteClub() async {
    final TextEditingController controller = TextEditingController();

    final raison = await showDialog<String>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            backgroundColor: background,
            title: Text(
              'Suppression administrative',
              style: TextStyle(color: textPrimary),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Vous allez supprimer le club "${_club!.nom}"',
                  style: TextStyle(color: textPrimary),
                ),
                SizedBox(height: 16),
                Text(
                  'Veuillez indiquer la raison de la suppression :',
                  style: TextStyle(color: textPrimary),
                ),
                SizedBox(height: 8),
                TextField(
                  controller: controller,
                  decoration: InputDecoration(
                    hintText: 'Raison administrative...',
                    border: OutlineInputBorder(),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: primaryAccent),
                    ),
                    errorText: controller.text.isEmpty ? 'Ce champ est obligatoire' : null,
                  ),
                  maxLines: 3,
                  autofocus: true,
                  onChanged: (value) {
                    setDialogState(() {});
                  },
                ),
                SizedBox(height: 8),
                Text(
                  'Une notification sera enregistrée pour le responsable et les membres.',
                  style: TextStyle(fontSize: 12, color: textPrimary.withOpacity(0.6)),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'Annuler',
                  style: TextStyle(color: textPrimary),
                ),
              ),
              TextButton(
                onPressed: controller.text.trim().isEmpty
                    ? null
                    : () => Navigator.pop(context, controller.text.trim()),
                child: Text(
                  'Supprimer',
                  style: TextStyle(color: primaryAccent),
                ),
              ),
            ],
          );
        },
      ),
    );

    if (raison != null && raison.isNotEmpty) {
      try {
        await _clubService.adminDeleteClub(widget.clubId, "Raison administrative: $raison");

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Club supprimé avec succès'),
            backgroundColor: primaryAccent,
          ),
        );

        // Retour à l'écran précédent
        Navigator.pop(context);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de la suppression: $e'),
            backgroundColor: primaryAccent,
          ),
        );
      }
    }
  }

  Future<void> _rejectMember(int memberId) async {
    await _clubService.rejectMemberRequest(memberId);
    await _loadClubData();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Demande rejetée'),
        backgroundColor: primaryAccent,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: backgroundSecondary,
        appBar: AppBar(
          title: Text('Chargement...'),
          backgroundColor: primaryAccent,
        ),
        body: Center(
          child: CircularProgressIndicator(color: primaryAccent),
        ),
      );
    }

    if (_club == null) {
      return Scaffold(
        backgroundColor: backgroundSecondary,
        appBar: AppBar(
          title: Text('Erreur'),
          backgroundColor: primaryAccent,
        ),
        body: Center(child: Text('Club non trouvé')),
      );
    }

    return Scaffold(
      backgroundColor: backgroundSecondary,
      appBar: AppBar(
        title: Text(
          _club!.nom,
          style: TextStyle(color: background, fontWeight: FontWeight.bold),
        ),
        backgroundColor: primaryAccent,
        elevation: 0,
        iconTheme: IconThemeData(color: background),
        actions: [
          if (_isResponsable)
            PopupMenuButton<String>(
              onSelected: (value) {
                switch (value) {
                  case 'edit':
                    _updateClubName();
                    break;
                  case 'delete':
                    _requestDeletion();
                    break;
                }
              },
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'edit',
                  child: Text('Modifier le nom'),
                ),
                PopupMenuItem(
                  value: 'delete',
                  child: Text(
                    'Demander la suppression',
                    style: TextStyle(color: primaryAccent),
                  ),
                ),
              ],
            ),
          if (widget.userRole == 'admin')
            IconButton(
              icon: Icon(Icons.delete_outline, color: background),
              onPressed: _adminDeleteClub,
              tooltip: 'Supprimer le club',
            ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Informations du club
            Card(
              color: background,
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _club!.nom,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: textPrimary,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Type: ${_club!.type}',
                      style: TextStyle(color: textPrimary.withOpacity(0.7)),
                    ),
                    if (_club!.description != null && _club!.description!.isNotEmpty) ...[
                      SizedBox(height: 8),
                      Text(
                        'Description: ${_club!.description}',
                        style: TextStyle(color: textPrimary.withOpacity(0.7)),
                      ),
                    ],
                    SizedBox(height: 16),
                    Row(
                      children: [
                        Icon(Icons.people, size: 16, color: primaryAccent),
                        SizedBox(width: 4),
                        Text(
                          '${_members.length} membres',
                          style: TextStyle(color: textPrimary),
                        ),
                        if (_pendingRequests.isNotEmpty) ...[
                          SizedBox(width: 16),
                          Icon(Icons.pending_actions, size: 16, color: primaryAccent),
                          SizedBox(width: 4),
                          Text(
                            '${_pendingRequests.length} demandes',
                            style: TextStyle(color: textPrimary),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),

            SizedBox(height: 16),

            // AJOUT: Bouton pour demander à devenir responsable
            if (widget.userRole == 'etudiant' && !_isResponsable && !_hasPendingRequest)
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: _requestResponsableRole,
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: primaryAccent),
                    foregroundColor: primaryAccent,
                  ),
                  child: Text('Devenir responsable du club'),
                ),
              ),

            // Bouton rejoindre le club - SEULEMENT pour les étudiants
            if (widget.userRole == 'etudiant') ...[
              if (!_isMember && !_isResponsable && !_hasPendingRequest)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _joinClub,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryAccent,
                      foregroundColor: background,
                    ),
                    child: Text('Rejoindre le club'),
                  ),
                ),

              if (_hasPendingRequest)
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: null,
                    child: Text('Demande en attente d\'approbation'),
                  ),
                ),
            ],

            // Message pour les non-étudiants
            if (widget.userRole != 'etudiant')
              SizedBox(
                width: double.infinity,
                child: Card(
                  color: background,
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Row(
                      children: [
                        Icon(
                          widget.userRole == 'admin' ? Icons.admin_panel_settings : Icons.school,
                          color: primaryAccent,
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            widget.userRole == 'admin'
                                ? 'Administrateur - Consultation seulement'
                                : 'Professeur - Consultation seulement',
                            style: TextStyle(color: textPrimary),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

            SizedBox(height: 16),

            // AJOUT: Section gestion des candidats responsables (pour ceux qui ont les permissions)
            if (_isResponsable)
              FutureBuilder<bool>(
                future: _clubService.canApproveResponsables(widget.clubId, widget.userId),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return SizedBox.shrink();
                  }
                  if (snapshot.hasData && snapshot.data == true) {
                    return _buildResponsableCandidatesSection();
                  }
                  return SizedBox.shrink();
                },
              ),

            if (_isResponsable) ...[
              SizedBox(height: 20),
              Container(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => CreateEventScreen(club: widget.club),
                      ),
                    ).then((refresh) {
                      if (refresh == true) {
                        _loadClubData(); // Recharger les données si nécessaire
                      }
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryAccent,
                    foregroundColor: background,
                  ),
                  icon: Icon(Icons.event),
                  label: Text('Créer un événement'),
                ),
              ),
            ],

            // Section responsable
            if (_isResponsable) ...[
              SizedBox(height: 20),
              Text(
                'Gestion du club',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textPrimary),
              ),
              SizedBox(height: 8),

              // Demandes d'adhésion en attente
              if (_pendingRequests.isNotEmpty) ...[
                Text(
                  'Demandes d\'adhésion en attente:',
                  style: TextStyle(fontWeight: FontWeight.bold, color: textPrimary),
                ),
                SizedBox(height: 8),
                ..._pendingRequests.map((request) => Card(
                  color: background,
                  margin: EdgeInsets.symmetric(vertical: 4),
                  elevation: 1,
                  child: ListTile(
                    title: Text(
                      'Utilisateur #${request.userId}',
                      style: TextStyle(color: textPrimary),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: Icon(Icons.check, color: primaryAccent),
                          onPressed: () => _approveMember(request.id!),
                          tooltip: 'Approuver',
                        ),
                        IconButton(
                          icon: Icon(Icons.close, color: primaryAccent.withOpacity(0.7)),
                          onPressed: () => _rejectMember(request.id!),
                          tooltip: 'Rejeter',
                        ),
                      ],
                    ),
                  ),
                )).toList(),
                SizedBox(height: 16),
              ],
            ],

            // Liste des membres
            Text(
              'Membres (${_members.length})',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textPrimary),
            ),
            SizedBox(height: 8),
            Expanded(
              child: _members.isEmpty
                  ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.people_outline,
                      size: 64,
                      color: textPrimary.withOpacity(0.3),
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Aucun membre pour le moment',
                      style: TextStyle(
                        fontSize: 16,
                        color: textPrimary.withOpacity(0.6),
                      ),
                    ),
                  ],
                ),
              )
                  : ListView.builder(
                itemCount: _members.length,
                itemBuilder: (context, index) {
                  final member = _members[index];
                  final isResponsable = member.role == 'responsable';

                  return Card(
                    color: background,
                    margin: EdgeInsets.symmetric(vertical: 4),
                    elevation: 1,
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: isResponsable
                            ? primaryAccent
                            : primaryAccent.withOpacity(0.7),
                        child: Text(
                          isResponsable ? 'R' : 'M',
                          style: TextStyle(color: background),
                        ),
                      ),
                      title: Text(
                        'Utilisateur #${member.userId}',
                        style: TextStyle(color: textPrimary),
                      ),
                      subtitle: Text(
                        isResponsable ? 'Responsable' : 'Membre',
                        style: TextStyle(color: textPrimary.withOpacity(0.7)),
                      ),
                      trailing: isResponsable
                          ? Chip(
                        label: Text(
                          'Responsable',
                          style: TextStyle(fontSize: 12, color: background),
                        ),
                        backgroundColor: primaryAccent,
                      )
                          : null,
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}