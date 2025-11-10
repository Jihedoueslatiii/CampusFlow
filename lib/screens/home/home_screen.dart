import 'package:flutter/material.dart';
import 'package:compusflow/screens/admin/user_list_screen.dart';
import 'package:compusflow/screens/home/account_details_screen.dart';
import 'package:compusflow/screens/home/update_profile_screen.dart';
import 'package:compusflow/screens/wrapper.dart';
import 'package:compusflow/services/auth_service.dart';
import 'package:compusflow/theme/colors.dart';

import 'package:compusflow/screens/biblio/bibliotheque_screen.dart' as biblio;
import 'package:compusflow/screens/event/event_screen.dart' as event;

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final AuthService _authService = AuthService();
  bool _isDeleting = false;

  Future<Map<String, dynamic>?> _getUserData() async {
    return await _authService.getCurrentUser();
  }

  // Confirmer suppression du compte
  Future<void> _showDeleteConfirmationDialog() async {
    return showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Confirmer la suppression',
            style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text(
            'Êtes-vous sûr de vouloir supprimer votre compte ? Cette action est irréversible.'),
        actions: [
          TextButton(
            child: const Text('Annuler', style: TextStyle(color: AppColors.textLight)),
            onPressed: () => Navigator.of(context).pop(),
          ),
          TextButton(
            child: const Text('Supprimer', style: TextStyle(color: Colors.red)),
            onPressed: () async {
              Navigator.of(context).pop();
              setState(() => _isDeleting = true);
              final result = await _authService.deleteUserAccount();
              setState(() => _isDeleting = false);
              if (result != "Succès") {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(result), backgroundColor: Colors.red),
                );
              } else {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const Wrapper()),
                      (route) => false,
                );
              }
            },
          ),
        ],
      ),
    );
  }

  // AppBar avec menu utilisateur
  AppBar _buildAppBar(String userName) {
    final userInitial = userName.isNotEmpty ? userName[0].toUpperCase() : 'U';
    return AppBar(
      title: const Text("CompusFlow",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: AppColors.white,
            fontSize: 24,
          )),
      backgroundColor: AppColors.secondaryPurple,
      elevation: 0,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(20))
      ),
      actions: [
        if (_isDeleting)
          const Padding(
            padding: EdgeInsets.only(right: 16),
            child: Center(child: CircularProgressIndicator(color: Colors.white)),
          )
        else
          PopupMenuButton<String>(
            onSelected: (value) async {
              switch (value) {
                case 'details':
                  Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const AccountDetailsScreen()));
                  break;
                case 'update':
                  Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const UpdateProfileScreen()));
                  break;
                case 'delete':
                  _showDeleteConfirmationDialog();
                  break;
                case 'logout':
                  await _authService.signOut();
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (_) => const Wrapper()),
                        (route) => false,
                  );
                  break;
              }
            },
            child: Container(
              margin: const EdgeInsets.only(right: 16),
              decoration: BoxDecoration(
                color: AppColors.primaryBlue,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: CircleAvatar(
                backgroundColor: AppColors.primaryBlue,
                child: Text(userInitial,
                    style: const TextStyle(
                        color: AppColors.white,
                        fontWeight: FontWeight.bold
                    )),
              ),
            ),
            itemBuilder: (_) => <PopupMenuEntry<String>>[
              PopupMenuItem(
                  value: 'details',
                  child: ListTile(
                    leading: const Icon(Icons.person_outline, color: AppColors.secondaryPurple),
                    title: const Text('Détails du compte', style: TextStyle(color: AppColors.textDark)),
                  )),
              PopupMenuItem(
                  value: 'update',
                  child: ListTile(
                    leading: const Icon(Icons.edit_outlined, color: AppColors.secondaryPurple),
                    title: const Text('Mettre à jour', style: TextStyle(color: AppColors.textDark)),
                  )),
              const PopupMenuDivider(),
              PopupMenuItem(
                  value: 'logout',
                  child: ListTile(
                    leading: const Icon(Icons.logout, color: AppColors.secondaryPurple),
                    title: const Text('Se déconnecter', style: TextStyle(color: AppColors.textDark)),
                  )),
              const PopupMenuDivider(),
              PopupMenuItem(
                  value: 'delete',
                  child: ListTile(
                    leading: const Icon(Icons.delete_forever, color: Colors.red),
                    title: const Text('Supprimer mon compte',
                        style: TextStyle(color: Colors.red)),
                  )),
            ],
          ),
      ],
    );
  }

  // Carte dashboard moderne
  Widget _buildDashboardCard(
      IconData icon, String title, String subtitle, VoidCallback onTap, Color color) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 8,
      shadowColor: Colors.black.withOpacity(0.15),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [color.withOpacity(0.9), color],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: AppColors.white, size: 32),
                ),
                const SizedBox(height: 16),
                Text(title, textAlign: TextAlign.center,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: AppColors.white
                    )),
                const SizedBox(height: 8),
                Text(subtitle, textAlign: TextAlign.center,
                    style: TextStyle(
                        color: AppColors.white.withOpacity(0.8),
                        fontSize: 12
                    )),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Contenu selon rôle
  List<Widget> _buildRoleContent(String role) {
    List<Widget> commonCards = [
      _buildDashboardCard(
        Icons.library_books,
        "Bibliothèques",
        "Gérer les bibliothèques",
            () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const biblio.BibliothequeScreen()), // FIXED: Use alias
          );
        },
        AppColors.secondaryPurple,
      ),
      _buildDashboardCard(
        Icons.event,
        "Événements",
        "Gérer les événements",
            () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const event.EventScreen()), // FIXED: Use alias
          );
        },
        AppColors.primaryBlue,
      ),
    ];

    switch (role) {
      case 'admin':
        return [
          ...commonCards,
          _buildDashboardCard(Icons.group_add, "Utilisateurs", "Gérer les comptes", () {
            Navigator.push(context,
                MaterialPageRoute(builder: (_) => const UserListScreen()));
          }, AppColors.accentTeal),
          _buildDashboardCard(Icons.analytics, "Statistiques", "Voir les rapports", () {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                content: Text('Fonctionnalité en cours de développement')));
          }, AppColors.secondaryPurple),
        ];
      case 'professeur':
        return [
          ...commonCards,
          _buildDashboardCard(Icons.school, "Mes Cours", "Gérer vos matières", () {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                content: Text('Fonctionnalité en cours de développement')));
          }, AppColors.accentTeal),
        ];
      case 'etudiant':
        return [
          ...commonCards,
          _buildDashboardCard(Icons.calendar_today, "Emploi du Temps", "Consulter vos cours", () {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                content: Text('Fonctionnalité en cours de développement')));
          }, AppColors.accentTeal),
        ];
      default:
        return [
          ...commonCards,
          _buildDashboardCard(Icons.info, "Information", "Aucune option disponible", () {},
              AppColors.textLight),
        ];
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>?>(
      future: _getUserData(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            backgroundColor: AppColors.backgroundLight,
            body: Center(child: CircularProgressIndicator(color: AppColors.primaryBlue)),
          );
        }
        if (!snapshot.hasData || snapshot.data == null) {
          return Scaffold(
            backgroundColor: AppColors.backgroundLight,
            body: const Center(
                child: Text("Impossible de charger vos données.",
                    style: TextStyle(color: AppColors.white))),
          );
        }

        final userData = snapshot.data!;
        final userName = userData['name'] ?? 'Utilisateur';
        final userRole = userData['role'] ?? 'etudiant';

        return Scaffold(
          appBar: _buildAppBar(userName),
          backgroundColor: AppColors.backgroundLight,
          body: RefreshIndicator(
            onRefresh: () async => setState(() {}),
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                // Welcome Section
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppColors.primaryBlue.withOpacity(0.1), AppColors.secondaryPurple.withOpacity(0.1)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Bienvenue,",
                          style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w500,
                              color: AppColors.textLight)),
                      const SizedBox(height: 4),
                      Text(userName,
                          style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textDark)),
                      const SizedBox(height: 8),
                      Text(
                        "Que souhaitez-vous faire aujourd'hui ?",
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.textLight,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // Dashboard Grid
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  children: _buildRoleContent(userRole),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        );
      },
    );
  }
}