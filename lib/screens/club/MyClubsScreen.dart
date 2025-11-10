// lib/screens/club/my_clubs_screen.dart
import 'package:flutter/material.dart';
import '../../services/club_service.dart';
import '../../models/club_model.dart';
import 'club_details_screen.dart'; // IMPORT AJOUTÉ
import 'deleted_clubs_screen.dart';

class MyClubsScreen extends StatefulWidget {
  final int userId;

  const MyClubsScreen({Key? key, required this.userId}) : super(key: key);

  @override
  _MyClubsScreenState createState() => _MyClubsScreenState();
}

class _MyClubsScreenState extends State<MyClubsScreen> {
  final ClubService _clubService = ClubService();
  List<Club> _myClubs = [];
  bool _isLoading = true;

  // Color palette
  static const Color primaryAccent = Color(0xFFE53935); // Vivid Red
  static const Color background = Color(0xFFFFFFFF); // Pure White
  static const Color textPrimary = Color(0xFF212121); // Dark Gray
  static const Color backgroundSecondary = Color(0xFFF5F5F5); // Light Gray

  @override
  void initState() {
    super.initState();
    _loadMyClubs();
  }

  Future<void> _loadMyClubs() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Récupérer seulement les clubs ACTIFS
      final clubs = await _clubService.getClubs(status: 'approved');

      // CORRECTION : Utiliser une boucle pour vérifier l'appartenance
      final List<Club> myClubs = [];

      for (final club in clubs) {
        if (club.responsableId == widget.userId) {
          myClubs.add(club);
        } else {
          final isMember = await _clubService.isUserMember(club.id!, widget.userId);
          if (isMember) {
            myClubs.add(club);
          }
        }
      }

      setState(() {
        _myClubs = myClubs;
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
          'Mes Clubs',
          style: TextStyle(color: background, fontWeight: FontWeight.bold),
        ),
        backgroundColor: primaryAccent,
        elevation: 0,
        iconTheme: IconThemeData(color: background),
        actions: [
          IconButton(
            icon: Icon(Icons.history, color: background),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => DeletedClubsScreen(userId: widget.userId),
                ),
              );
            },
            tooltip: 'Voir mes anciens clubs',
          ),
        ],
      ),
      body: _isLoading
          ? Center(
        child: CircularProgressIndicator(
          color: primaryAccent,
        ),
      )
          : _myClubs.isEmpty
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.group,
              size: 64,
              color: textPrimary.withOpacity(0.3),
            ),
            SizedBox(height: 16),
            Text(
              'Aucun club trouvé',
              style: TextStyle(
                fontSize: 18,
                color: textPrimary.withOpacity(0.6),
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Créez un club ou rejoignez-en un !',
              style: TextStyle(
                fontSize: 14,
                color: textPrimary.withOpacity(0.5),
              ),
            ),
          ],
        ),
      )
          : RefreshIndicator(
        onRefresh: _loadMyClubs,
        backgroundColor: background,
        color: primaryAccent,
        child: ListView.builder(
          itemCount: _myClubs.length,
          itemBuilder: (context, index) {
            final club = _myClubs[index];
            final isResponsible = club.responsableId == widget.userId;

            return Card(
              color: background,
              margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: isResponsible
                      ? primaryAccent
                      : primaryAccent.withOpacity(0.7),
                  child: Icon(
                    isResponsible
                        ? Icons.admin_panel_settings
                        : Icons.group,
                    color: background,
                    size: 20,
                  ),
                ),
                title: Text(
                  club.nom,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: textPrimary,
                  ),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      club.type,
                      style: TextStyle(
                        color: textPrimary.withOpacity(0.7),
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      isResponsible ? 'Responsable' : 'Membre',
                      style: TextStyle(
                        color: isResponsible
                            ? primaryAccent
                            : primaryAccent.withOpacity(0.7),
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
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
                      builder: (context) => ClubDetailsScreen(
                        clubId: club.id!,
                        userId: widget.userId,
                        userRole: 'etudiant', // À adapter selon votre logique
                        club: club,
                      ),
                    ),
                  ).then((_) {
                    // Recharger après retour
                    _loadMyClubs();
                  });
                },
              ),
            );
          },
        ),
      ),
    );
  }
}