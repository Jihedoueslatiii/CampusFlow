// lib/screens/club/club_list_screen.dart

import 'package:flutter/material.dart';
import '../../services/club_service.dart';
import '../../models/club_model.dart';
import 'club_details_screen.dart';
import 'create_club_screen.dart';

class ClubListScreen extends StatefulWidget {
  final int userId;
  final String userRole;

  const ClubListScreen({Key? key, required this.userId, required this.userRole}) : super(key: key);

  @override
  _ClubListScreenState createState() => _ClubListScreenState();
}

class _ClubListScreenState extends State<ClubListScreen> {
  final ClubService _clubService = ClubService();
  List<Club> _clubs = [];

  // Color palette
  static const Color primaryAccent = Color(0xFFE53935); // Vivid Red
  static const Color background = Color(0xFFFFFFFF); // Pure White
  static const Color textPrimary = Color(0xFF212121); // Dark Gray
  static const Color backgroundSecondary = Color(0xFFF5F5F5); // Light Gray
  static const Color borderColor = Color(0xFFEEEEEE); // Very Light Gray

  @override
  void initState() {
    super.initState();
    _loadClubs();
  }

  Future<void> _loadClubs() async {
    final clubs = await _clubService.getClubs(status: 'approved');
    setState(() {
      _clubs = clubs;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundSecondary,
      appBar: AppBar(
        title: Text(
          'Clubs Approuvés',
          style: TextStyle(
            color: background,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        backgroundColor: primaryAccent,
        elevation: 0,
        iconTheme: IconThemeData(color: background),
        centerTitle: true,
        actions: [
          if (widget.userRole == 'etudiant')
            IconButton(
              icon: Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: background.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.add, color: background, size: 22),
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => CreateClubScreen(userId: widget.userId),
                  ),
                ).then((_) => _loadClubs());
              },
            ),
        ],
      ),
      body: _clubs.isEmpty
          ? Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: background,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 8,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.group_outlined,
                  size: 48,
                  color: primaryAccent,
                ),
              ),
              SizedBox(height: 24),
              Text(
                'Aucun club approuvé',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: textPrimary,
                ),
              ),
              SizedBox(height: 12),
              Text(
                'Les clubs approuvés apparaîtront ici.\nRevenez plus tard ou créez un nouveau club.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: textPrimary.withOpacity(0.6),
                  height: 1.4,
                ),
              ),
              SizedBox(height: 32),
              if (widget.userRole == 'etudiant')
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => CreateClubScreen(userId: widget.userId),
                      ),
                    ).then((_) => _loadClubs());
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryAccent,
                    foregroundColor: background,
                    padding: EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                    elevation: 2,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.add, size: 18),
                      SizedBox(width: 8),
                      Text(
                        'Créer un Club',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      )
          : RefreshIndicator(
        onRefresh: _loadClubs,
        backgroundColor: background,
        color: primaryAccent,
        child: ListView.builder(
          padding: EdgeInsets.all(16),
          itemCount: _clubs.length,
          itemBuilder: (context, index) {
            final club = _clubs[index];
            return Container(
              margin: EdgeInsets.only(bottom: 12),
              child: Material(
                color: background,
                borderRadius: BorderRadius.circular(12),
                elevation: 2,
                shadowColor: Colors.black12,
                child: InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ClubDetailsScreen(
                          clubId: club.id!,
                          userId: widget.userId,
                          userRole: widget.userRole,
                          club: club,
                        ),
                      ),
                    );
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: borderColor,
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        // Club Avatar
                        Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            color: primaryAccent.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: primaryAccent.withOpacity(0.3),
                              width: 1.5,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              club.nom.isNotEmpty ? club.nom[0].toUpperCase() : 'C',
                              style: TextStyle(
                                color: primaryAccent,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: 16),
                        // Club Info
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                club.nom,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: textPrimary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              SizedBox(height: 6),
                              Container(
                                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: primaryAccent.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  club.type.toUpperCase(),
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: primaryAccent,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                              SizedBox(height: 8),
                              if (club.description != null && club.description!.isNotEmpty)
                                Text(
                                  club.description!,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: textPrimary.withOpacity(0.7),
                                    height: 1.3,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                            ],
                          ),
                        ),
                        SizedBox(width: 12),
                        // Forward Arrow
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: backgroundSecondary,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.arrow_forward_ios_rounded,
                            color: primaryAccent,
                            size: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}