import 'package:compusflow/screens/admin/user_list_screen.dart';
import 'package:compusflow/screens/home/account_details_screen.dart';
import 'package:compusflow/screens/home/update_profile_screen.dart';
import 'package:compusflow/screens/wrapper.dart';
import 'package:flutter/material.dart';
import 'package:compusflow/services/auth_service.dart';
import 'package:compusflow/screens/home/projet_list_screen.dart';
import 'package:compusflow/screens/admin/admin_stats_screen.dart'; // 👈 NOUVEL IMPORT

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final AuthService _authService = AuthService();
  bool _isDeleting = false;

  // Couleurs
  static const Color primaryColor = Color(0xFF2575FC);
  static const Color secondaryColor = Color(0xFF6A11CB);

  Future<Map<String, dynamic>?> _getUserData() async {
    return await _authService.getCurrentUser();
  }

  // Confirmer suppression du compte
  Future<void> _showDeleteConfirmationDialog() async {
    return showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmer la suppression'),
        content: const Text(
            'Êtes-vous sûr de vouloir supprimer votre compte ? Cette action est irréversible.'),
        actions: [
          TextButton(
            child: const Text('Annuler'),
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
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
      backgroundColor: primaryColor,
      elevation: 0,
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
            child: Padding(
              padding: const EdgeInsets.only(right: 16),
              child: CircleAvatar(
                backgroundColor: secondaryColor,
                child: Text(userInitial, style: const TextStyle(color: Colors.white)),
              ),
            ),
            itemBuilder: (_) => <PopupMenuEntry<String>>[
              const PopupMenuItem(
                  value: 'details',
                  child: ListTile(
                    leading: Icon(Icons.person_outline),
                    title: Text('Détails du compte'),
                  )),
              const PopupMenuItem(
                  value: 'update',
                  child: ListTile(
                    leading: Icon(Icons.edit_outlined),
                    title: Text('Mettre à jour'),
                  )),
              const PopupMenuDivider(),
              const PopupMenuItem(
                  value: 'logout',
                  child: ListTile(
                    leading: Icon(Icons.logout),
                    title: Text('Se déconnecter'),
                  )),
              const PopupMenuDivider(),
              const PopupMenuItem(
                  value: 'delete',
                  child: ListTile(
                    leading: Icon(Icons.delete_forever, color: Colors.red),
                    title: Text('Supprimer mon compte',
                        style: TextStyle(color: Colors.red)),
                  )),
            ],
          ),
      ],
    );
  }

  // Carte dashboard
  Widget _buildDashboardCard(
      IconData icon, String title, String subtitle, VoidCallback onTap) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 5,
      shadowColor: Colors.black.withOpacity(0.2),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: primaryColor, size: 48),
              const SizedBox(height: 8),
              Text(title, textAlign: TextAlign.center,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 4),
              Text(subtitle, textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
            ],
          ),
        ),
      ),
    );
  }

  // Contenu selon rôle
  List<Widget> _buildRoleContent(String role) {
    switch (role) {
      case 'admin':
        return [
          _buildDashboardCard(Icons.group_add, "Utilisateurs", "Gérer les comptes", () {
            Navigator.push(context,
                MaterialPageRoute(builder: (_) => const UserListScreen()));
          }),
          // 💡 Carte Admin (CRUD)
          _buildDashboardCard(Icons.assignment, "Projets Académiques", "Créer, modifier, supprimer", () {
            Navigator.push(context,
                MaterialPageRoute(builder: (_) => ProjetListScreen()));
          }),
          _buildDashboardCard(Icons.analytics, "Statistiques", "Voir les rapports", () {
            // 🚀 Navigation vers le nouvel écran de statistiques
            Navigator.push(context,
                MaterialPageRoute(builder: (_) => const AdminStatsScreen()));
          }),
        ];
      case 'professeur':
        return [
          _buildDashboardCard(Icons.school, "Mes Cours", "Gérer vos matières", () {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                content: Text('Fonctionnalité Cours à implémenter')));
          }),
          // 💡 Carte Professeur (Read only)
          _buildDashboardCard(Icons.assignment, "Projets Académiques", "Consulter les projets", () {
            Navigator.push(context,
                MaterialPageRoute(builder: (_) => ProjetListScreen()));
          }),
        ];
      case 'etudiant':
        return [
          _buildDashboardCard(Icons.calendar_today, "Emploi du Temps", "Consulter vos cours", () {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                content: Text('Fonctionnalité Emploi du Temps à implémenter')));
          }),
          // 💡 Carte Étudiant (Read only)
          _buildDashboardCard(Icons.assignment, "Projets Académiques", "Consulter les projets", () {
            Navigator.push(context,
                MaterialPageRoute(builder: (_) => ProjetListScreen()));
          }),
        ];
      default:
        return [_buildDashboardCard(Icons.info, "Information", "Aucune option disponible", () {})];
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>?>(
      future: _getUserData(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
              body: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [secondaryColor, primaryColor],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: const Center(child: CircularProgressIndicator(color: Colors.white))
              ));
        }
        if (!snapshot.hasData || snapshot.data == null) {
          return Scaffold(
              body: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [secondaryColor, primaryColor],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: const Center(
                  child: Text("Impossible de charger vos données.",
                      style: TextStyle(color: Colors.white)),
                ),
              ));
        }

        final userData = snapshot.data!;
        final userName = userData['name'] ?? 'Utilisateur';
        final userRole = userData['role'] ?? 'etudiant';

        return Scaffold(
          appBar: _buildAppBar(userName),
          body: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [secondaryColor, primaryColor],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: RefreshIndicator(
              onRefresh: () async => setState(() {}),
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Text("Bienvenue, $userName",
                      style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.white)),
                  const SizedBox(height: 20),
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
          ),
        );
      },
    );
  }
}