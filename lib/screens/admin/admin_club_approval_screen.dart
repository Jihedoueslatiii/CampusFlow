// lib/screens/admin/admin_club_approval_screen.dart

import 'package:flutter/material.dart';
import '../../services/club_service.dart';
import '../../models/club_model.dart';

class AdminClubApprovalScreen extends StatefulWidget {
  const AdminClubApprovalScreen({Key? key}) : super(key: key);

  @override
  _AdminClubApprovalScreenState createState() => _AdminClubApprovalScreenState();
}

class _AdminClubApprovalScreenState extends State<AdminClubApprovalScreen> {
  final ClubService _clubService = ClubService();
  List<Club> _pendingClubs = [];
  List<Club> _pendingDeletions = [];
  int _selectedTab = 0; // 0: Approbations, 1: Suppressions

  // Color palette
  static const Color primaryAccent = Color(0xFFE53935); // Vivid Red
  static const Color background = Color(0xFFFFFFFF); // Pure White
  static const Color textPrimary = Color(0xFF212121); // Dark Gray
  static const Color backgroundSecondary = Color(0xFFF5F5F5); // Light Gray

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final pendingClubs = await _clubService.getPendingClubs();
    final pendingDeletions = await _clubService.getPendingDeletionRequests();
    setState(() {
      _pendingClubs = pendingClubs;
      _pendingDeletions = pendingDeletions;
    });
  }

  // Méthodes pour l'approbation des clubs
  Future<void> _approveClub(int clubId) async {
    await _clubService.approveClub(clubId);
    _loadData();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Club approuvé avec succès'),
        backgroundColor: primaryAccent,
      ),
    );
  }

  Future<void> _rejectClub(int clubId) async {
    await _clubService.rejectClub(clubId);
    _loadData();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Club rejeté'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  // Méthodes pour les demandes de suppression
  Future<void> _approveDeletion(int clubId) async {
    await _clubService.approveClubDeletion(clubId);
    _loadData();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Club supprimé avec succès'),
        backgroundColor: primaryAccent,
      ),
    );
  }

  Future<void> _rejectDeletion(int clubId) async {
    await _clubService.rejectClubDeletion(clubId);
    _loadData();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Demande de suppression rejetée'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  Future<void> _adminDeleteClub(int clubId, String clubName) async {
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
                  'Vous allez supprimer le club "$clubName"',
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
                  'Le club sera marqué comme supprimé et apparaîtra dans l\'historique du responsable et des membres.',
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
        // Utiliser la méthode qui marque comme supprimé au lieu de supprimer physiquement
        await _clubService.adminDeleteClub(clubId, "Raison administrative: $raison");

        await _loadData();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Club "$clubName" marqué comme supprimé - Il apparaîtra dans l\'historique'),
            backgroundColor: primaryAccent,
          ),
        );
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

  // Widget pour l'onglet d'approbation des clubs
  Widget _buildApprovalTab() {
    return _pendingClubs.isEmpty
        ? Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.check_circle_outline, size: 64, color: textPrimary.withOpacity(0.3)),
          SizedBox(height: 16),
          Text(
            'Aucun club en attente d\'approbation',
            style: TextStyle(fontSize: 16, color: textPrimary.withOpacity(0.6)),
          ),
        ],
      ),
    )
        : ListView.builder(
      itemCount: _pendingClubs.length,
      itemBuilder: (context, index) {
        final club = _pendingClubs[index];
        return Card(
          color: background,
          margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          elevation: 2,
          child: ListTile(
            contentPadding: EdgeInsets.all(16),
            leading: CircleAvatar(
              backgroundColor: primaryAccent,
              child: Text(
                  club.nom.isNotEmpty ? club.nom[0].toUpperCase() : 'C',
                  style: TextStyle(color: background)
              ),
            ),
            title: Text(
              club.nom,
              style: TextStyle(fontWeight: FontWeight.bold, color: textPrimary),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 4),
                Text(
                  'Type: ${club.type}',
                  style: TextStyle(color: textPrimary.withOpacity(0.7)),
                ),
                if (club.description != null && club.description!.isNotEmpty)
                  Text(
                    'Description: ${club.description}',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: textPrimary.withOpacity(0.7)),
                  ),
                SizedBox(height: 8),
                Text(
                  'Créé par: Utilisateur #${club.responsableId}',
                  style: TextStyle(fontSize: 12, color: textPrimary.withOpacity(0.5)),
                ),
              ],
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: Icon(Icons.check_circle, color: primaryAccent),
                  onPressed: () => _approveClub(club.id!),
                  tooltip: 'Approuver le club',
                ),
                IconButton(
                  icon: Icon(Icons.cancel, color: Colors.orange),
                  onPressed: () => _rejectClub(club.id!),
                  tooltip: 'Rejeter le club',
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Widget pour l'onglet des demandes de suppression
  Widget _buildDeletionTab() {
    return _pendingDeletions.isEmpty
        ? Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.delete_outline, size: 64, color: textPrimary.withOpacity(0.3)),
          SizedBox(height: 16),
          Text(
            'Aucune demande de suppression',
            style: TextStyle(fontSize: 16, color: textPrimary.withOpacity(0.6)),
          ),
        ],
      ),
    )
        : ListView.builder(
      itemCount: _pendingDeletions.length,
      itemBuilder: (context, index) {
        final club = _pendingDeletions[index];
        return Card(
          margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          color: primaryAccent.withOpacity(0.1),
          elevation: 2,
          child: ListTile(
            contentPadding: EdgeInsets.all(16),
            leading: CircleAvatar(
              backgroundColor: primaryAccent,
              child: Icon(Icons.delete_outline, color: background, size: 20),
            ),
            title: Text(
              club.nom,
              style: TextStyle(fontWeight: FontWeight.bold, color: primaryAccent),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 4),
                Text(
                  'Type: ${club.type}',
                  style: TextStyle(color: textPrimary.withOpacity(0.7)),
                ),
                if (club.raisonSuppression != null && club.raisonSuppression!.isNotEmpty)
                  Container(
                    margin: EdgeInsets.only(top: 8),
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: background,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: primaryAccent.withOpacity(0.3)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Raison de suppression:',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: textPrimary),
                        ),
                        SizedBox(height: 4),
                        Text(
                          club.raisonSuppression!,
                          style: TextStyle(fontSize: 12, color: textPrimary),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: Icon(Icons.check_circle, color: primaryAccent),
                  onPressed: () => _approveDeletion(club.id!),
                  tooltip: 'Approuver la suppression',
                ),
                IconButton(
                  icon: Icon(Icons.cancel, color: Colors.orange),
                  onPressed: () => _rejectDeletion(club.id!),
                  tooltip: 'Rejeter la demande',
                ),
                PopupMenuButton<String>(
                  icon: Icon(Icons.more_vert, color: textPrimary),
                  onSelected: (value) {
                    if (value == 'delete') {
                      _adminDeleteClub(club.id!, club.nom);
                    }
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete_forever, color: primaryAccent),
                          SizedBox(width: 8),
                          Text(
                            'Supprimer avec notification',
                            style: TextStyle(color: textPrimary),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundSecondary,
      appBar: AppBar(
        title: Text(
          'Gestion des Clubs',
          style: TextStyle(color: background, fontWeight: FontWeight.bold),
        ),
        backgroundColor: primaryAccent,
        elevation: 0,
        iconTheme: IconThemeData(color: background),
      ),
      body: Column(
        children: [
          // Onglets
          Container(
            decoration: BoxDecoration(
              color: background,
              border: Border(bottom: BorderSide(color: backgroundSecondary)),
            ),
            child: Row(
              children: [
                _buildTab(0, 'Approbations', _pendingClubs.length),
                _buildTab(1, 'Suppressions', _pendingDeletions.length),
              ],
            ),
          ),
          // Contenu
          Expanded(
            child: _selectedTab == 0 ? _buildApprovalTab() : _buildDeletionTab(),
          ),
        ],
      ),
    );
  }

  Widget _buildTab(int tabIndex, String title, int count) {
    final isSelected = _selectedTab == tabIndex;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _selectedTab = tabIndex),
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: isSelected ? primaryAccent : background,
            border: isSelected ? Border(bottom: BorderSide(color: primaryAccent, width: 3)) : null,
          ),
          child: Column(
            children: [
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: isSelected ? background : textPrimary,
                ),
              ),
              SizedBox(height: 4),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: isSelected ? background : backgroundSecondary,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  count.toString(),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: isSelected ? primaryAccent : textPrimary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}