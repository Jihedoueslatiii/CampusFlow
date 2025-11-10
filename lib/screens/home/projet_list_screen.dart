//
import 'package:flutter/material.dart';
import 'package:compusflow/services/auth_service.dart';
import 'package:compusflow/services/projet_service.dart';
import 'package:compusflow/screens/home/projet_details_screen.dart';
import 'package:compusflow/screens/admin/projet_form_screen.dart';
import 'package:intl/intl.dart';

class ProjetListScreen extends StatefulWidget {
  const ProjetListScreen({Key? key}) : super(key: key);

  @override
  State<ProjetListScreen> createState() => _ProjetListScreenState();
}

class _ProjetListScreenState extends State<ProjetListScreen> {
  final ProjetService _projetService = ProjetService();
  final AuthService _authService = AuthService();

  // 💡 Initialisé dans initState, pas de 'late' simple sans valeur initiale.
  late Future<List<Map<String, dynamic>>> _projetsFuture;

  bool _isAdmin = false;

  // Couleurs
  static const Color primaryColor = Color(0xFF2575FC);
  static const Color accentColor = Color(0xFFFFA500);

  @override
  void initState() {
    super.initState();
    // 💡 CORRECTION : Initialiser _projetsFuture ici en appelant la fonction qui le définit.
    // On appelle aussi la mise à jour du rôle.
    _initializeData();
  }

  // Initialise _projetsFuture et charge les données asynchrones
  Future<void> _initializeData() async {
    // 1. Initialiser _projetsFuture pour éviter l'erreur LateInitializationError dans build.
    setState(() {
      _projetsFuture = _projetService.getAllProjets();
    });

    // 2. Charger le rôle de l'utilisateur de manière asynchrone.
    await _loadUserRole();
  }

  // Charge uniquement le rôle de l'utilisateur
  Future<void> _loadUserRole() async {
    final userData = await _authService.getCurrentUser();
    final role = userData?['role'] ?? 'etudiant';
    if (mounted) {
      setState(() {
        _isAdmin = role == 'admin';
      });
    }
  }

  // Rafraîchit la liste des projets (appelé par RefreshIndicator et après form)
  Future<void> _refreshProjets() async {
    // On n'appelle pas setState ici pour ne pas provoquer un build
    // avant que l'opération ne soit terminée.
    final projets = _projetService.getAllProjets();
    final userData = await _authService.getCurrentUser();
    final role = userData?['role'] ?? 'etudiant';

    if (mounted) {
      setState(() {
        _isAdmin = role == 'admin';
        _projetsFuture = projets;
      });
    }
  }


  // Navigue vers l'écran de formulaire d'ajout/édition
  void _navigateProjetForm([Map<String, dynamic>? projet]) async {
    if (!_isAdmin) return;

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ProjetFormScreen(projet: projet),
      ),
    );
    // Rafraîchir la liste après le retour du formulaire
    _refreshProjets();
  }

  // Confirmer et supprimer un projet
  Future<void> _deleteProjet(int id) async {
    if (!_isAdmin) return;

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmer la suppression'),
        content: const Text('Êtes-vous sûr de vouloir supprimer ce projet ?'),
        actions: [
          TextButton(
            child: const Text('Annuler'),
            onPressed: () => Navigator.of(context).pop(false),
          ),
          TextButton(
            child: const Text('Supprimer', style: TextStyle(color: Colors.red)),
            onPressed: () => Navigator.of(context).pop(true),
          ),
        ],
      ),
    );

    if (result == true) {
      final rowsAffected = await _projetService.deleteProjet(id);
      if (rowsAffected > 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Projet supprimé avec succès!')),
        );
        _refreshProjets(); // Rafraîchir la liste
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Échec de la suppression du projet.'), backgroundColor: Colors.red),
        );
      }
    }
  }


  // Affiche un item de projet dans la liste
  Widget _buildProjetItem(Map<String, dynamic> projet) {
    final id = projet['id'] as int;
    final titre = projet['titre'] as String;
    final coursAssocie = projet['cours_associe'] as String? ?? 'Non spécifié';
    final dateRenduString = projet['date_rendu'] as String?;
    DateTime? dateRendu;
    String formattedDate = 'Non spécifiée';

    try {
      if (dateRenduString != null) {
        dateRendu = DateTime.tryParse(dateRenduString);
        if (dateRendu != null) {
          formattedDate = DateFormat('dd MMM yyyy').format(dateRendu);
        }
      }
    } catch (_) {
      // Ignorer l'erreur de parsing si la date n'est pas au bon format ISO
    }

    // Calculer le délai avant la date de rendu
    Duration? remaining;
    String deadlineText = '';
    Color deadlineColor = Colors.grey;
    if (dateRendu != null) {
      remaining = dateRendu.difference(DateTime.now());
      if (remaining.isNegative) {
        deadlineText = 'Rendu dépassé!';
        deadlineColor = Colors.red.shade700;
      } else if (remaining.inDays == 0) {
        deadlineText = 'Rendu aujourd\'hui!';
        deadlineColor = Colors.red.shade700;
      } else if (remaining.inDays < 7) {
        deadlineText = 'Reste ${remaining.inDays} jours (Urgent!)';
        deadlineColor = Colors.orange.shade700;
      } else {
        deadlineText = 'Reste ${remaining.inDays} jours';
        deadlineColor = Colors.green.shade700;
      }
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: CircleAvatar(
          backgroundColor: primaryColor,
          child: Text(coursAssocie[0].toUpperCase(), style: const TextStyle(color: Colors.white)),
        ),
        title: Text(titre,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text('Cours: $coursAssocie', style: TextStyle(color: Colors.grey[700])),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.date_range, size: 16, color: Colors.blueGrey),
                const SizedBox(width: 4),
                Text('Rendu: $formattedDate', style: TextStyle(color: Colors.blueGrey)),
              ],
            ),
            const SizedBox(height: 4),
            // Affichage du statut
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: deadlineColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(5),
              ),
              child: Text(deadlineText, style: TextStyle(color: deadlineColor, fontWeight: FontWeight.bold, fontSize: 12)),
            ),
          ],
        ),
        trailing: _isAdmin
            ? PopupMenuButton<String>(
          onSelected: (value) {
            if (value == 'edit') {
              _navigateProjetForm(projet);
            } else if (value == 'delete') {
              _deleteProjet(id);
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'edit',
              child: Row(
                children: [
                  Icon(Icons.edit, color: primaryColor),
                  SizedBox(width: 8),
                  Text('Modifier'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete, color: Colors.red),
                  SizedBox(width: 8),
                  Text('Supprimer'),
                ],
              ),
            ),
          ],
        )
            : const Icon(Icons.chevron_right, color: primaryColor), // Flèche pour les non-admins

        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ProjetDetailsScreen(projetId: id),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Projets Académiques',
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: primaryColor,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [primaryColor, Color(0xFF6A11CB)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Text(
                "Liste des Projets",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: _refreshProjets, // Utiliser la nouvelle fonction de rafraîchissement
                child: FutureBuilder<List<Map<String, dynamic>>>(
                  future: _projetsFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator(color: Colors.white));
                    }
                    if (snapshot.hasError) {
                      return Center(
                          child: Text('Erreur: ${snapshot.error}',
                              style: const TextStyle(color: Colors.white)));
                    }
                    if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return Center(
                          child: Padding(
                            padding: const EdgeInsets.all(32.0),
                            child: Text(
                                _isAdmin
                                    ? 'Aucun projet trouvé. Appuyez sur "+" pour ajouter un nouveau projet.'
                                    : 'Aucun projet académique n\'est disponible pour le moment.',
                                textAlign: TextAlign.center,
                                style: const TextStyle(color: Colors.white, fontSize: 16)),
                          ));
                    }

                    final projets = snapshot.data!;
                    return ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: projets.length,
                      itemBuilder: (context, index) {
                        return _buildProjetItem(projets[index]);
                      },
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
      // Bouton flottant pour l'ajout (Admin uniquement)
      floatingActionButton: _isAdmin
          ? FloatingActionButton(
        onPressed: () => _navigateProjetForm(),
        backgroundColor: accentColor,
        child: const Icon(Icons.add, color: Colors.white),
      )
          : null,
    );
  }
}