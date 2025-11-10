import 'package:flutter/material.dart';
import 'package:compusflow/models/cours.dart';
import 'package:compusflow/repositories/cours_repository.dart';
import 'package:compusflow/screens/cours/add_edit_cours_screen.dart';
import 'package:compusflow/screens/cours/cours_ai_screen.dart';

class AppColors {
  static const Color primary = Color(0xFFE53935);      // Vivid Red - Main brand color
  static const Color background = Color(0xFFFFFFFF);   // Pure White - Card backgrounds
  static const Color textPrimary = Color(0xFF212121);  // Dark Gray - Main text content
  static const Color backgroundSecondary = Color(0xFFF5F5F5); // Light Gray - Screen background
  static const Color textSecondary = Color(0xFF757575); // Medium Gray - Secondary text
  static const Color accent = Color(0xFF1976D2);       // Blue accent for secondary actions
  static const Color success = Color(0xFF4CAF50);      // Green for positive states
  static const Color warning = Color(0xFFFF9800);      // Orange for warnings
  static const Color surface = Color(0xFFFAFAFA);      // Surface color for cards
}

class CoursListScreen extends StatefulWidget {
  const CoursListScreen({Key? key}) : super(key: key);

  @override
  State<CoursListScreen> createState() => _CoursListScreenState();
}

class _CoursListScreenState extends State<CoursListScreen> {
  final CoursRepository _coursRepository = CoursRepository();
  List<Cours> _coursList = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCours();
  }

  Future<void> _loadCours() async {
    setState(() => _isLoading = true);
    try {
      final cours = await _coursRepository.getAllCours();
      setState(() {
        _coursList = cours;
        _isLoading = false;
      });
    } catch (e) {
      print('Erreur chargement cours: $e');
      setState(() => _isLoading = false);
    }
  }

  void _deleteCours(int id, String nom) async {
    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          'Confirmer la suppression',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        content: Text('Êtes-vous sûr de vouloir supprimer le cours "$nom" ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(
              'Annuler',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Supprimer',
              style: TextStyle(color: AppColors.primary),
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _coursRepository.deleteCours(id);
        _loadCours();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Cours "$nom" supprimé avec succès'),
              backgroundColor: AppColors.success,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erreur lors de la suppression: $e'),
              backgroundColor: AppColors.primary,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          );
        }
      }
    }
  }

  void _openAIAssistant(Cours cours) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CoursAIScreen(cours: cours),
      ),
    );
  }

  Widget _buildCoursCard(Cours cours) {
    return Card(
      elevation: 1,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppColors.backgroundSecondary.withOpacity(0.5),
            width: 1,
          ),
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          leading: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.primary.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: Icon(Icons.school, color: AppColors.primary, size: 22),
          ),
          title: Text(
            cours.nom,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 16,
              color: AppColors.textPrimary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 6),
              Text(
                cours.description,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                  height: 1.3,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: [
                  // Badge crédits
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.accent.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: AppColors.accent.withOpacity(0.2),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      '${cours.credits} crédits',
                      style: TextStyle(
                        color: AppColors.accent,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  // Badge semestre
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.success.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: AppColors.success.withOpacity(0.2),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      cours.semestre,
                      style: TextStyle(
                        color: AppColors.success,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  // Badge département
                  if (cours.departementNom != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.warning.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: AppColors.warning.withOpacity(0.2),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        cours.departementNom!,
                        style: TextStyle(
                          color: AppColors.warning,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  if (cours.departementNom == null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.textSecondary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: AppColors.textSecondary.withOpacity(0.2),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        'Aucun département',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  // Badge IA
                  GestureDetector(
                    onTap: () => _openAIAssistant(cours),
                    child: MouseRegion(
                      cursor: SystemMouseCursors.click,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: AppColors.primary.withOpacity(0.2),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.auto_awesome, size: 12, color: AppColors.primary),
                            const SizedBox(width: 4),
                            Text(
                              'Assistant IA',
                              style: TextStyle(
                                color: AppColors.primary,
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          trailing: PopupMenuButton<String>(
            icon: Icon(Icons.more_vert, color: AppColors.textSecondary, size: 20),
            onSelected: (value) {
              if (value == 'edit') {
                _editCours(cours);
              } else if (value == 'delete') {
                _deleteCours(cours.id!, cours.nom);
              } else if (value == 'ai_assistant') {
                _openAIAssistant(cours);
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'edit',
                child: Row(
                  children: [
                    Icon(Icons.edit, color: AppColors.accent, size: 18),
                    const SizedBox(width: 8),
                    const Text('Modifier'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'ai_assistant',
                child: Row(
                  children: [
                    Icon(Icons.auto_awesome, color: AppColors.primary, size: 18),
                    const SizedBox(width: 8),
                    const Text('Assistant IA'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete, color: AppColors.primary, size: 18),
                    const SizedBox(width: 8),
                    const Text('Supprimer'),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundSecondary,
      appBar: AppBar(
        title: const Text(
          'Gestion des Cours',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: AppColors.background,
            fontSize: 18,
          ),
        ),
        backgroundColor: AppColors.primary,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: AppColors.background),
        actions: [
          IconButton(
            icon: const Icon(Icons.auto_awesome, size: 22),
            onPressed: _coursList.isNotEmpty
                ? () => _openAIAssistant(_coursList.first)
                : null,
            tooltip: 'Tester IA',
            color: AppColors.background,
          ),
          IconButton(
            icon: const Icon(Icons.refresh, size: 22),
            onPressed: _loadCours,
            tooltip: 'Actualiser',
            color: AppColors.background,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: AppColors.primary),
            SizedBox(height: 16),
            Text(
              'Chargement des cours...',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ],
        ),
      )
          : _coursList.isEmpty
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.school,
              size: 80,
              color: AppColors.textSecondary.withOpacity(0.3),
            ),
            const SizedBox(height: 24),
            const Text(
              'Aucun cours trouvé',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Text(
                'Commencez par créer votre premier cours en utilisant le bouton +',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 32),
            // Message IA
            Container(
              width: 280,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppColors.backgroundSecondary.withOpacity(0.8),
                  width: 1,
                ),
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.auto_awesome,
                      size: 32,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Assistant IA Disponible',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Créez un cours pour accéder à l\'assistant IA de génération de contenu',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                      height: 1.4,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ],
        ),
      )
          : RefreshIndicator(
        onRefresh: _loadCours,
        backgroundColor: AppColors.background,
        color: AppColors.primary,
        child: Column(
          children: [
            // Bannière IA
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.primary.withOpacity(0.1),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.auto_awesome,
                      color: AppColors.primary,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Assistant IA Actif',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Utilisez le badge "Assistant IA" ou le menu pour générer du contenu',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // Statistiques rapides
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: AppColors.backgroundSecondary.withOpacity(0.5),
                      ),
                    ),
                    child: Text(
                      '${_coursList.length} cours',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: AppColors.backgroundSecondary.withOpacity(0.5),
                      ),
                    ),
                    child: Text(
                      '${_coursList.map((c) => c.credits).reduce((a, b) => a + b)} crédits totaux',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.only(bottom: 80),
                itemCount: _coursList.length,
                itemBuilder: (context, index) {
                  final cours = _coursList[index];
                  return _buildCoursCard(cours);
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          // Bouton IA rapide
          if (_coursList.isNotEmpty)
            FloatingActionButton.small(
              onPressed: () => _openAIAssistant(_coursList.first),
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.background,
              heroTag: 'ai_button',
              child: const Icon(Icons.auto_awesome, size: 20),
            ),
          const SizedBox(height: 12),
          FloatingActionButton(
            onPressed: _addCours,
            backgroundColor: AppColors.primary,
            foregroundColor: AppColors.background,
            elevation: 2,
            child: const Icon(Icons.add, size: 24),
          ),
        ],
      ),
    );
  }

  void _addCours() async {
    await Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => const AddEditCoursScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0.0, 1.0),
              end: Offset.zero,
            ).animate(animation),
            child: child,
          );
        },
      ),
    );
    _loadCours();
  }

  void _editCours(Cours cours) async {
    await Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => AddEditCoursScreen(cours: cours),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0.0, 1.0),
              end: Offset.zero,
            ).animate(animation),
            child: child,
          );
        },
      ),
    );
    _loadCours();
  }
}