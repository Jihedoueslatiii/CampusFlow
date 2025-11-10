// lib/screens/club/deleted_clubs_screen.dart

import 'package:flutter/material.dart';
import '../../services/club_service.dart';
import '../../models/club_model.dart';
import 'club_deletion_notification_screen.dart';

class DeletedClubsScreen extends StatefulWidget {
  final int userId;

  const DeletedClubsScreen({Key? key, required this.userId}) : super(key: key);

  @override
  _DeletedClubsScreenState createState() => _DeletedClubsScreenState();
}

class _DeletedClubsScreenState extends State<DeletedClubsScreen> {
  final ClubService _clubService = ClubService();
  List<Club> _deletedClubs = [];
  bool _isLoading = true; // DÉCLARATION AJOUTÉE

  // Color palette
  static const Color primaryAccent = Color(0xFFE53935); // Vivid Red
  static const Color background = Color(0xFFFFFFFF); // Pure White
  static const Color textPrimary = Color(0xFF212121); // Dark Gray
  static const Color backgroundSecondary = Color(0xFFF5F5F5); // Light Gray

  @override
  void initState() {
    super.initState();
    _loadDeletedClubs();
  }

  Future<void> _loadDeletedClubs() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final allClubs = await _clubService.getAllClubsIncludingDeleted();

      // CORRECTION : Utiliser une boucle pour vérifier l'appartenance
      final List<Club> deletedClubs = [];

      for (final club in allClubs) {
        if (club.status == 'deleted') {
          if (club.responsableId == widget.userId) {
            deletedClubs.add(club);
          } else {
            final isMember = await _clubService.isUserMember(club.id!, widget.userId);
            if (isMember) {
              deletedClubs.add(club);
            }
          }
        }
      }

      setState(() {
        _deletedClubs = deletedClubs;
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundSecondary,
      appBar: AppBar(
        title: Text(
          'Mes Anciens Clubs',
          style: TextStyle(color: background, fontWeight: FontWeight.bold),
        ),
        backgroundColor: primaryAccent,
        elevation: 0,
        iconTheme: IconThemeData(color: background),
      ),
      body: _isLoading
          ? Center(
        child: CircularProgressIndicator(
          color: primaryAccent,
        ),
      )
          : _deletedClubs.isEmpty
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.delete_outline,
              size: 64,
              color: textPrimary.withOpacity(0.3),
            ),
            SizedBox(height: 16),
            Text(
              'Aucun ancien club',
              style: TextStyle(
                fontSize: 16,
                color: textPrimary.withOpacity(0.6),
              ),
            ),
          ],
        ),
      )
          : ListView.builder(
        itemCount: _deletedClubs.length,
        itemBuilder: (context, index) {
          final club = _deletedClubs[index];
          return Card(
            margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: primaryAccent.withOpacity(0.05),
            elevation: 1,
            child: ListTile(
              leading: Icon(
                Icons.delete_outline,
                color: primaryAccent,
              ),
              title: Text(
                club.nom,
                style: TextStyle(
                  decoration: TextDecoration.lineThrough,
                  color: textPrimary.withOpacity(0.6),
                  fontWeight: FontWeight.w500,
                ),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Type: ${club.type}',
                    style: TextStyle(
                      color: textPrimary.withOpacity(0.5),
                    ),
                  ),
                  if (club.raisonSuppression != null && club.raisonSuppression!.isNotEmpty)
                    Padding(
                      padding: EdgeInsets.only(top: 4),
                      child: Text(
                        'Raison: ${club.raisonSuppression!}',
                        style: TextStyle(
                          fontSize: 12,
                          color: primaryAccent,
                          fontStyle: FontStyle.italic,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                ],
              ),
              trailing: Icon(
                Icons.arrow_forward_ios,
                color: primaryAccent,
                size: 16,
              ),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ClubDeletionNotificationScreen(clubId: club.id!),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}