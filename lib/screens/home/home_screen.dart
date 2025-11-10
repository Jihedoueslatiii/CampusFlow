import 'package:compusflow/screens/admin/user_list_screen.dart';
import 'package:compusflow/screens/home/account_details_screen.dart';
import 'package:compusflow/screens/home/update_profile_screen.dart';
import 'package:compusflow/screens/wrapper.dart';
import 'package:compusflow/screens/club/club_list_screen.dart';
import 'package:compusflow/screens/club/create_club_screen.dart';
import 'package:compusflow/screens/club/MyClubsScreen.dart';
import 'package:compusflow/screens/admin/admin_club_approval_screen.dart';
import 'package:compusflow/screens/events/event_list_screen.dart';
import 'package:flutter/material.dart';
import 'package:compusflow/services/auth_service.dart';
import 'package:compusflow/services/club_service.dart';
import 'package:compusflow/screens/emploi_temps/choix_matieres_screen.dart';
import 'package:compusflow/screens/emploi_temps/consulter_emploi_screen.dart';
import 'package:compusflow/screens/admin/generer_emploi_screen.dart';
import 'package:compusflow/services/matiere_service.dart';
import 'package:compusflow/screens/home/projet_list_screen.dart';
import 'package:compusflow/screens/admin/admin_stats_screen.dart';
import 'package:compusflow/screens/biblio/bibliotheque_screen.dart' as biblio;
import 'package:compusflow/screens/event/event_screen.dart' as event;
import 'package:compusflow/screens/cours/cours_list_screen.dart';
import 'package:compusflow/screens/departements/departement_list_screen.dart';

// Import des nouvelles interfaces
import 'package:compusflow/screens/jihed/add_edit_examen_screen.dart';
import 'package:compusflow/screens/jihed/add_edit_salle_screen.dart';
import 'package:compusflow/screens/jihed/examen_calendar_screen.dart';
import 'package:compusflow/screens/jihed/examen_list_screen.dart';
import 'package:compusflow/screens/jihed/generate_quiz_screen.dart';
import 'package:compusflow/screens/jihed/quiz_screen.dart';
import 'package:compusflow/screens/jihed/salle_list_screen.dart';
import 'package:compusflow/screens/jihed/salle_list_screen1.dart';
import 'package:compusflow/screens/jihed/salle_map_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final AuthService _authService = AuthService();
  final ClubService _clubService = ClubService();
  bool _isDeleting = false;

  // Nouvelles couleurs selon la charte
  static const Color primaryColor = Color(0xFFF53935); // Vivid Red
  static const Color backgroundColor = Color(0xFFF5F5F5); // Light Gray
  static const Color cardBackgroundColor = Color(0xFFFFFFFF); // Pure White
  static const Color primaryTextColor = Color(0xFF212121); // Dark Gray

  Future<Map<String, dynamic>?> _getUserData() async {
    return await _authService.getCurrentUser();
  }

  void _navigateToCours() {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => const CoursListScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(1.0, 0.0),
              end: Offset.zero,
            ).animate(animation),
            child: child,
          );
        },
      ),
    );
  }

  void _navigateToDepartements() {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => const DepartementListScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(1.0, 0.0),
              end: Offset.zero,
            ).animate(animation),
            child: child,
          );
        },
      ),
    );
  }

  // =============================================
  // 🔹 NAVIGATION EMPLOI DU TEMPS (Missing from first code)
  // =============================================

  void _navigateToChoixMatieres(int userId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChoixMatieresScreen(userId: userId),
      ),
    );
  }

  void _navigateToEmploiTemps(String role, int userId) async {
    final matiereService = MatiereService();

    if (role == 'etudiant') {
      final aChoisiMatieres =
      await matiereService.etudiantAChoisiMatieres(userId);
      if (!aChoisiMatieres) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Veuillez d\'abord choisir vos matières'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            ConsulterEmploiScreen(userRole: role, userId: userId),
      ),
    );
  }

  void _navigateToGenererEmploi() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => GenererEmploiScreen()),
    );
  }

  // =============================================
  // 🔹 NAVIGATION CLUBS & ÉVÉNEMENTS (Missing from first code)
  // =============================================

  void _navigateToClubList(String role, int userId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ClubListScreen(userId: userId, userRole: role),
      ),
    );
  }

  void _navigateToCreateClub(int userId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CreateClubScreen(userId: userId),
      ),
    );
  }

  void _navigateToMyClubs(int userId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MyClubsScreen(userId: userId),
      ),
    );
  }

  void _navigateToClubApproval() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => AdminClubApprovalScreen()),
    );
  }

  void _navigateToEvents() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => EventListScreen()),
    );
  }

  // =============================================
  // 🔹 NAVIGATION EXAMENS & SALLES (Already in first code)
  // =============================================

  // Ces fonctions sont déjà dans votre premier code, on les garde
  void _navigateToExamenList() {
    Navigator.push(context,
        MaterialPageRoute(builder: (_) => const ExamenListScreen()));
  }

  void _navigateToExamenCalendar() {
    Navigator.push(context,
        MaterialPageRoute(builder: (_) => const ExamenCalendarScreen()));
  }

  void _navigateToSalleList() {
    Navigator.push(context,
        MaterialPageRoute(builder: (_) => const SalleListScreen()));
  }

  void _navigateToSalleList1() {
    Navigator.push(context,
        MaterialPageRoute(builder: (_) => const SalleListScreen1()));
  }

  void _navigateToGenerateQuiz() {
    Navigator.push(context,
        MaterialPageRoute(builder: (_) => const GenerateQuizScreen()));
  }

  void _navigateToSalleMap() {
    Navigator.push(context,
        MaterialPageRoute(builder: (_) => const SalleMapScreen()));
  }

  void _navigateToAddEditSalle() {
    Navigator.push(context,
        MaterialPageRoute(builder: (_) => const AddEditSalleScreen()));
  }

  void _navigateToAddEditExamen() {
    Navigator.push(context,
        MaterialPageRoute(builder: (_) => const AddEditExamenScreen()));
  }

  // =============================================
  // 🔹 EXISTING FUNCTIONS (From first code)
  // =============================================

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
            child: const Text('Supprimer', style: TextStyle(color: primaryColor)),
            onPressed: () async {
              Navigator.of(context).pop();
              setState(() => _isDeleting = true);
              final result = await _authService.deleteUserAccount();
              setState(() => _isDeleting = false);
              if (result != "Succès") {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(result), backgroundColor: primaryColor),
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

  // AppBar avec menu utilisateur et logo
  AppBar _buildAppBar(String userName) {
    final userInitial = userName.isNotEmpty ? userName[0].toUpperCase() : 'U';
    return AppBar(
      title: Row(
        children: [
          // Logo - version texte
          Container(
            color: Colors.red, // Your red top bar
            child: Row(
              children: [
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '🎓CampusFlow',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          )
        ],
      ),
      backgroundColor: primaryColor,
      elevation: 0,
      actions: [
        if (_isDeleting)
          const Padding(
            padding: EdgeInsets.only(right: 16),
            child: Center(child: CircularProgressIndicator(color: cardBackgroundColor)),
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
                backgroundColor: cardBackgroundColor,
                child: Text(userInitial, style: TextStyle(color: primaryColor)),
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
                    leading: Icon(Icons.delete_forever, color: primaryColor),
                    title: Text('Supprimer mon compte',
                        style: TextStyle(color: primaryColor)),
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
      color: cardBackgroundColor,
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
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: primaryTextColor,
                  )),
              const SizedBox(height: 4),
              Text(subtitle, textAlign: TextAlign.center,
                  style: TextStyle(
                      color: primaryTextColor.withOpacity(0.7),
                      fontSize: 12
                  )),
            ],
          ),
        ),
      ),
    );
  }

  // 🔹 Contenu selon rôle (UPDATED with missing buttons)
  List<Widget> _buildRoleContent(String role, int userId) {
    switch (role) {
      case 'admin':
        return [
          _buildDashboardCard(Icons.school, "Gestion des Cours", "Créez et gérez les cours", () {
            _navigateToCours();
          }),
          _buildDashboardCard(Icons.business, "Gestion des Départements", "Organisez les départements", () {
            _navigateToDepartements();
          }),
          _buildDashboardCard(Icons.group_add, "Utilisateurs", "Gérer les comptes", () {
            Navigator.push(context,
                MaterialPageRoute(builder: (_) => const UserListScreen()));
          }),
          _buildDashboardCard(Icons.assignment, "Projets Académiques", "Créer, modifier, supprimer", () {
            Navigator.push(context,
                MaterialPageRoute(builder: (_) => ProjetListScreen()));
          }),
          _buildDashboardCard(Icons.analytics, "Statistiques", "Voir les rapports", () {
            Navigator.push(context,
                MaterialPageRoute(builder: (_) => const AdminStatsScreen()));
          }),

          // 🔹 MISSING: Gestion Clubs
          _buildDashboardCard(Icons.admin_panel_settings, "Gestion Clubs", "Approbations & Suppressions",
              _navigateToClubApproval),

          // 🔹 MISSING: Générer EDT
          _buildDashboardCard(Icons.auto_awesome, "Générer EDT", "Créer l'emploi du temps",
              _navigateToGenererEmploi),

          // 🔹 MISSING: Clubs & Associations
          _buildDashboardCard(Icons.group, "Clubs & Associations", "Découvrir les clubs",
                  () => _navigateToClubList(role, userId)),

          // Nouvelles interfaces pour Admin
          _buildDashboardCard(Icons.school, "Gestion Examens", "Ajouter/modifier examens",
              _navigateToExamenList),
          _buildDashboardCard(Icons.calendar_today, "Calendrier Examens", "Voir planning",
              _navigateToExamenCalendar),
          _buildDashboardCard(Icons.meeting_room, "Gestion Salles", "Gérer les salles",
              _navigateToSalleList),
          _buildDashboardCard(Icons.quiz, "Générer Quiz", "Créer des quiz",
              _navigateToGenerateQuiz),
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
          ),
        ];

      case 'professeur':
        return [
          // 🔹 MISSING: Emploi du Temps
          _buildDashboardCard(Icons.schedule, "Mon Emploi du Temps", "Voir mes cours",
                  () => _navigateToEmploiTemps('professeur', userId)),

          _buildDashboardCard(Icons.assignment, "Projets Académiques", "Consulter les projets", () {
            Navigator.push(context,
                MaterialPageRoute(builder: (_) => ProjetListScreen()));
          }),

          // Nouvelles interfaces pour Professeur
          _buildDashboardCard(Icons.school, "Gestion Examens", "Ajouter/modifier examens",
              _navigateToExamenList),
          _buildDashboardCard(Icons.calendar_today, "Calendrier Examens", "Voir planning",
              _navigateToExamenCalendar),
          _buildDashboardCard(Icons.meeting_room, "Gestion Salles", "Gérer les salles",
              _navigateToSalleList),
          _buildDashboardCard(Icons.quiz, "Générer Quiz", "Créer des quiz",
              _navigateToGenerateQuiz),
          _buildDashboardCard(Icons.map, "Carte Campus", "Voir plan campus",
              _navigateToSalleMap),
          _buildDashboardCard(Icons.add, "Ajouter Salle", "Créer nouvelle salle",
              _navigateToAddEditSalle),
          _buildDashboardCard(Icons.add, "Ajouter Examen", "Créer nouvel examen",
              _navigateToAddEditExamen),
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
          ),
        ];

      case 'etudiant':
        return [
          // 🔹 MISSING: Choisir Matières
          _buildDashboardCard(Icons.assignment, "Choisir Matières", "Sélectionnez vos matières",
                  () => _navigateToChoixMatieres(userId)),

          // 🔹 MISSING: Emploi du Temps
          _buildDashboardCard(Icons.schedule, "Emploi du Temps", "Consulter mon planning",
                  () => _navigateToEmploiTemps('etudiant', userId)),

          // 🔹 MISSING: Mes Clubs
          _buildDashboardCard(Icons.people, "Mes Clubs", "Clubs que je gère ou rejoins",
                  () => _navigateToMyClubs(userId)),

          // 🔹 MISSING: Clubs & Associations
          _buildDashboardCard(Icons.group, "Clubs & Associations", "Découvrir les clubs",
                  () => _navigateToClubList(role, userId)),

          // 🔹 MISSING: Événements
          _buildDashboardCard(Icons.event, "Événements", "Voir tous les événements",
              _navigateToEvents),

          _buildDashboardCard(Icons.assignment, "Projets Académiques", "Consulter les projets", () {
            Navigator.push(context,
                MaterialPageRoute(builder: (_) => ProjetListScreen()));
          }),

          // Nouvelles interfaces pour Étudiant
          _buildDashboardCard(Icons.calendar_today, "Calendrier Examens", "Voir planning",
              _navigateToExamenCalendar),
          _buildDashboardCard(Icons.school, "Liste Examens", "Consulter examens",
              _navigateToExamenList),
          _buildDashboardCard(Icons.quiz, "Générer Quiz", "Créer des quiz",
              _navigateToGenerateQuiz),
          _buildDashboardCard(Icons.meeting_room, "Liste Salles", "Voir salles",
              _navigateToSalleList1),
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
          ),
        ];

      default:
        return [_buildDashboardCard(Icons.info, "Information", "Aucune option disponible", () {})];
    }
  }

  // 🔹 Helper function to get role display name
  String _getRoleDisplayName(String role) {
    switch (role) {
      case 'admin':
        return 'Administrateur';
      case 'professeur':
        return 'Professeur';
      case 'etudiant':
        return 'Étudiant';
      default:
        return 'Utilisateur';
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
                    color: backgroundColor,
                  ),
                  child: Center(
                      child: CircularProgressIndicator(color: primaryColor)
                  )
              ));
        }
        if (!snapshot.hasData || snapshot.data == null) {
          return Scaffold(
              body: Container(
                decoration: const BoxDecoration(
                  color: backgroundColor,
                ),
                child: Center(
                  child: Text("Impossible de charger vos données.",
                      style: TextStyle(color: primaryTextColor)),
                ),
              ));
        }

        final userData = snapshot.data!;
        final userName = userData['name'] ?? 'Utilisateur';
        final userRole = userData['role'] ?? 'etudiant';
        final userId = userData['id'] ?? 0; // 🔹 Added userId

        return Scaffold(
          appBar: _buildAppBar(userName),
          body: Container(
            decoration: const BoxDecoration(
              color: backgroundColor,
            ),
            child: RefreshIndicator(
              color: primaryColor,
              onRefresh: () async => setState(() {}),
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Text("Bienvenue, $userName",
                      style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: primaryTextColor)),
                  const SizedBox(height: 4),
                  Text("Rôle: ${_getRoleDisplayName(userRole)}", // 🔹 Added role display
                      style: TextStyle(
                          fontSize: 16,
                          color: primaryTextColor.withOpacity(0.7))),
                  const SizedBox(height: 20),
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    children: _buildRoleContent(userRole, userId), // 🔹 Added userId parameter
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