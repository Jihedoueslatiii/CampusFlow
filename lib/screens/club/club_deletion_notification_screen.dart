import 'package:flutter/material.dart';
import '../../services/club_service.dart';
import '../../models/club_model.dart';

class ClubDeletionNotificationScreen extends StatefulWidget {
  final int clubId;

  const ClubDeletionNotificationScreen({Key? key, required this.clubId}) : super(key: key);

  @override
  _ClubDeletionNotificationScreenState createState() => _ClubDeletionNotificationScreenState();
}

class _ClubDeletionNotificationScreenState extends State<ClubDeletionNotificationScreen> {
  final ClubService _clubService = ClubService();
  Club? _club;

  // Color palette
  static const Color primaryAccent = Color(0xFFE53935); // Vivid Red
  static const Color background = Color(0xFFFFFFFF); // Pure White
  static const Color textPrimary = Color(0xFF212121); // Dark Gray
  static const Color backgroundSecondary = Color(0xFFF5F5F5); // Light Gray

  @override
  void initState() {
    super.initState();
    _loadClubData();
  }

  Future<void> _loadClubData() async {
    final club = await _clubService.getClubById(widget.clubId);
    setState(() {
      _club = club;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundSecondary,
      appBar: AppBar(
        title: Text(
          'Club Supprimé',
          style: TextStyle(color: background, fontWeight: FontWeight.bold),
        ),
        backgroundColor: primaryAccent,
        elevation: 0,
        iconTheme: IconThemeData(color: background),
      ),
      body: _club == null
          ? Center(
        child: CircularProgressIndicator(
          color: primaryAccent,
        ),
      )
          : Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(
              Icons.delete_forever,
              size: 80,
              color: primaryAccent,
            ),
            SizedBox(height: 20),
            Text(
              'Club Supprimé',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: primaryAccent,
              ),
            ),
            SizedBox(height: 16),
            Card(
              color: primaryAccent.withOpacity(0.1),
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Ancien club: ${_club!.nom}',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: textPrimary,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Type: ${_club!.type}',
                      style: TextStyle(color: textPrimary.withOpacity(0.7)),
                    ),
                    SizedBox(height: 16),
                    if (_club!.raisonSuppression != null && _club!.raisonSuppression!.isNotEmpty)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Raison de la suppression:',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: primaryAccent,
                            ),
                          ),
                          SizedBox(height: 8),
                          Container(
                            padding: EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: background,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: primaryAccent),
                            ),
                            child: Text(
                              _club!.raisonSuppression!,
                              style: TextStyle(
                                fontSize: 14,
                                color: textPrimary,
                              ),
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 20),
            Text(
              'Ce club a été supprimé par l\'administration.\n'
                  'Tous les membres et le responsable ont été notifiés.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: textPrimary.withOpacity(0.7),
              ),
            ),
            Spacer(),
            Container(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryAccent,
                  foregroundColor: background,
                  padding: EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'Retour à la liste des clubs',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}