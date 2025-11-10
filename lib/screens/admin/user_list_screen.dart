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

  // --- DÉBUT DES AMÉLIORATIONS ---

  // Définir des couleurs pour une meilleure maintenance et cohérence
  static const Color primaryColor = Color(0xFF2575FC);
  static const Color accentColor = Color(0xFF6A11CB);

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
        return Colors.amber.shade700;
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
              child: const Text('Annuler')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Supprimer', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final result = await _authService.deleteUserByAdmin(id: id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(result),
          backgroundColor: result.contains("succès") ? Colors.green : Colors.red,
        ));
        _loadUsers(); // Recharger la liste
      }
    }
  }

  // NOUVEAU WIDGET : Pour un état vide plus engageant
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.people_outline, size: 80, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          const Text('Aucun utilisateur trouvé',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(
            'Appuyez sur le bouton + pour ajouter le premier utilisateur.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  // NOUVEAU WIDGET : Pour construire une carte utilisateur améliorée
  Widget _buildUserCard(Map<String, dynamic> user) {
    final String role = user['role'] ?? 'N/A';
    final String name = user['name'] ?? 'Utilisateur inconnu';
    final String initial = name.isNotEmpty ? name[0].toUpperCase() : '?';
    final int userId = user['id'];

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: _getColorForRole(role).withOpacity(0.2),
          child: Text(
            initial,
            style: TextStyle(
                fontWeight: FontWeight.bold, color: _getColorForRole(role)),
          ),
        ),
        title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 2),
            Text(user['email'] ?? 'Email non fourni'),
            const SizedBox(height: 5),
            Chip(
              label: Text(
                role[0].toUpperCase() + role.substring(1),
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold),
              ),
              backgroundColor: _getColorForRole(role),
              padding: const EdgeInsets.symmetric(horizontal: 4),
              labelPadding: const EdgeInsets.symmetric(horizontal: 6),
              visualDensity: VisualDensity.compact,
            ),
          ],
        ),
        trailing: _currentUser != null && userId == _currentUser!['id']
            ? const Chip(
          label: Text('Vous'),
          backgroundColor: accentColor,
          labelStyle: TextStyle(color: Colors.white),
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
                  leading: Icon(Icons.edit), title: Text('Modifier')),
            ),
            PopupMenuItem<String>(
              value: 'delete',
              child: ListTile(
                  leading: Icon(Icons.delete, color: Colors.red.shade700),
                  title: Text('Supprimer',
                      style: TextStyle(color: Colors.red.shade700))),
            ),
          ],
        ),
      ),
    );
  }

  // --- FIN DES AMÉLIORATIONS ---

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestion des Utilisateurs'),
        backgroundColor: primaryColor,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadUsers,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AddUserScreen()),
        ).then((_) => _loadUsers()), // Recharger après ajout
        label: const Text('Ajouter'),
        icon: const Icon(Icons.add),
        backgroundColor: accentColor,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: primaryColor))
          : _users.isEmpty
          ? _buildEmptyState()
          : RefreshIndicator(
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