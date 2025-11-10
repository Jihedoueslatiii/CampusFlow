import 'package:compusflow/screens/admin/add_user_screen.dart';
import 'package:compusflow/services/auth_service.dart';
import 'package:flutter/material.dart';

class UserListScreen extends StatefulWidget {
  const UserListScreen({Key? key}) : super(key: key);

  @override
  State<UserListScreen> createState() => _UserListScreenState();
}

class _UserListScreenState extends State<UserListScreen> {
  final AuthService _authService = AuthService();
  List<Map<String, dynamic>> _users = [];
  Map<String, dynamic>? _currentUser;
  bool _isLoading = true;

  // Nouvelles couleurs selon la charte
  static const Color primaryColor = Color(0xFFF53935); // Vivid Red
  static const Color backgroundColor = Color(0xFFF5F5F5); // Light Gray
  static const Color cardBackgroundColor = Color(0xFFFFFFFF); // Pure White
  static const Color primaryTextColor = Color(0xFF212121); // Dark Gray

  @override
  void initState() {
    super.initState();
    _loadUsers();
    _loadCurrentUser();
  }

  Future<void> _loadUsers() async {
    setState(() => _isLoading = true);
    final users = await _authService.getAllUsers();
    setState(() {
      _users = users;
      _isLoading = false;
    });
  }

  Future<void> _loadCurrentUser() async {
    final currentUser = await _authService.getCurrentUser();
    setState(() {
      _currentUser = currentUser;
    });
  }

  // Méthode pour obtenir une couleur en fonction du rôle de l'utilisateur
  Color _getColorForRole(String role) {
    switch (role.toLowerCase()) {
      case 'admin':
        return primaryColor; // Rouge vif pour admin
      case 'professeur':
        return Colors.blue.shade700;
      case 'etudiant':
        return Colors.green.shade700;
      default:
        return Colors.grey.shade700;
    }
  }

  // La boîte de dialogue de confirmation
  Future<void> _deleteUser(int id, String name) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmer la suppression'),
        content: Text(
            'Êtes-vous sûr de vouloir supprimer l\'utilisateur "$name" ? Cette action est irréversible.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Annuler',
              style: TextStyle(color: primaryTextColor),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              'Supprimer',
              style: TextStyle(color: primaryColor),
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final result = await _authService.deleteUserByAdmin(id: id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(result),
          backgroundColor: primaryColor,
        ));
        _loadUsers(); // Recharger la liste
      }
    }
  }

  // WIDGET : Pour un état vide plus engageant
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.people_outline, size: 80, color: primaryTextColor.withOpacity(0.4)),
          const SizedBox(height: 16),
          Text(
            'Aucun utilisateur trouvé',
            style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: primaryTextColor
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Appuyez sur le bouton + pour ajouter le premier utilisateur.',
            textAlign: TextAlign.center,
            style: TextStyle(
                fontSize: 16,
                color: primaryTextColor.withOpacity(0.6)
            ),
          ),
        ],
      ),
    );
  }

  // WIDGET : Pour construire une carte utilisateur améliorée
  Widget _buildUserCard(Map<String, dynamic> user) {
    final String role = user['role'] ?? 'N/A';
    final String name = user['name'] ?? 'Utilisateur inconnu';
    final String initial = name.isNotEmpty ? name[0].toUpperCase() : '?';
    final int userId = user['id'];

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      elevation: 3,
      color: cardBackgroundColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: _getColorForRole(role).withOpacity(0.2),
          child: Text(
            initial,
            style: TextStyle(
                fontWeight: FontWeight.bold,
                color: _getColorForRole(role)
            ),
          ),
        ),
        title: Text(
            name,
            style: TextStyle(
                fontWeight: FontWeight.bold,
                color: primaryTextColor
            )
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 2),
            Text(
              user['email'] ?? 'Email non fourni',
              style: TextStyle(color: primaryTextColor.withOpacity(0.7)),
            ),
            const SizedBox(height: 5),
            Chip(
              label: Text(
                role[0].toUpperCase() + role.substring(1),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
              backgroundColor: _getColorForRole(role),
              padding: const EdgeInsets.symmetric(horizontal: 4),
              labelPadding: const EdgeInsets.symmetric(horizontal: 6),
              visualDensity: VisualDensity.compact,
            ),
          ],
        ),
        trailing: _currentUser != null && userId == _currentUser!['id']
            ? Chip(
          label: const Text(
            'Vous',
            style: TextStyle(color: Colors.white),
          ),
          backgroundColor: primaryColor,
        )
            : PopupMenuButton<String>(
          onSelected: (value) {
            if (value == 'delete') {
              _deleteUser(userId, name);
            }
            // Vous pouvez ajouter d'autres cas ici (ex: 'edit')
          },
          itemBuilder: (context) => [
            const PopupMenuItem<String>(
              value: 'edit',
              child: ListTile(
                leading: Icon(Icons.edit),
                title: Text('Modifier'),
              ),
            ),
            PopupMenuItem<String>(
              value: 'delete',
              child: ListTile(
                leading: Icon(Icons.delete, color: primaryColor),
                title: Text(
                  'Supprimer',
                  style: TextStyle(color: primaryColor),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const Text(
          'Gestion des Utilisateurs',
          style: TextStyle(color: cardBackgroundColor),
        ),
        backgroundColor: primaryColor,
        iconTheme: const IconThemeData(color: cardBackgroundColor),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: cardBackgroundColor),
            onPressed: _loadUsers,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AddUserScreen()),
        ).then((_) => _loadUsers()), // Recharger après ajout
        label: const Text(
          'Ajouter',
          style: TextStyle(color: cardBackgroundColor),
        ),
        icon: const Icon(Icons.add, color: cardBackgroundColor),
        backgroundColor: primaryColor,
      ),
      body: _isLoading
          ? Center(
        child: CircularProgressIndicator(color: primaryColor),
      )
          : _users.isEmpty
          ? _buildEmptyState()
          : RefreshIndicator(
        color: primaryColor,
        onRefresh: _loadUsers,
        child: ListView.builder(
          padding: const EdgeInsets.only(top: 8, bottom: 80),
          itemCount: _users.length,
          itemBuilder: (context, index) {
            final user = _users[index];
            return _buildUserCard(user);
          },
        ),
      ),
    );
  }
}