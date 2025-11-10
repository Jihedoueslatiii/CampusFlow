import 'package:flutter/material.dart';
import 'package:compusflow/models/cours.dart';
import 'package:compusflow/services/ai_cours_service.dart';
import 'package:compusflow/models/cours_content.dart';

class CoursAIScreen extends StatefulWidget {
  final Cours cours;

  const CoursAIScreen({Key? key, required this.cours}) : super(key: key);

  @override
  State<CoursAIScreen> createState() => _CoursAIScreenState();
}

class _CoursAIScreenState extends State<CoursAIScreen> {
  String _aiResponse = '';
  bool _isLoading = false;
  String _selectedType = '';

  Future<void> _generateContent(String type) async {
    setState(() {
      _isLoading = true;
      _aiResponse = '';
      _selectedType = type;
    });

    try {
      CoursContent newContent;

      switch (type) {
        case 'summary':
          newContent = await AICoursService.generateSummary(widget.cours);
          break;
        case 'exercises':
          newContent = await AICoursService.generateExercises(widget.cours);
          break;
        case 'quiz':
          newContent = await AICoursService.generateQuiz(widget.cours);
          break;
        default:
          _aiResponse = 'Type non supporté';
          return;
      }

      setState(() {
        _aiResponse = newContent.content;
      });
    } catch (e) {
      setState(() {
        _aiResponse = 'Erreur: $e';
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  String _getButtonLabel(String type) {
    switch (type) {
      case 'summary':
        return 'Résumé';
      case 'exercises':
        return 'Exercices';
      case 'quiz':
        return 'Quiz';
      default:
        return '';
    }
  }

  Color _getButtonColor(String type) {
    switch (type) {
      case 'summary':
        return AppColors.primary;
      case 'exercises':
        return AppColors.accent;
      case 'quiz':
        return AppColors.success;
      default:
        return AppColors.primary;
    }
  }

  IconData _getButtonIcon(String type) {
    switch (type) {
      case 'summary':
        return Icons.summarize;
      case 'exercises':
        return Icons.assignment;
      case 'quiz':
        return Icons.quiz;
      default:
        return Icons.auto_awesome;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Assistant IA - ${widget.cours.nom}',
          style: const TextStyle(
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
            icon: const Icon(Icons.info_outline, size: 22),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('À propos de l\'Assistant IA'),
                  content: const Text(
                    'Cet assistant utilise l\'intelligence artificielle pour générer du contenu pédagogique personnalisé pour votre cours.',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Fermer'),
                    ),
                  ],
                ),
              );
            },
            tooltip: 'Informations',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Informations du cours
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppColors.backgroundSecondary.withOpacity(0.3),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.school,
                          color: AppColors.primary,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          widget.cours.nom,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    widget.cours.description,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.backgroundSecondary,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '${widget.cours.credits} crédits',
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.backgroundSecondary,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          widget.cours.semestre,
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Titre section actions
            const Text(
              'Générer du contenu',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Choisissez le type de contenu à générer',
              style: TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),

            const SizedBox(height: 16),

            // Boutons d'action
            Row(
              children: [
                Expanded(
                  child: _buildActionButton(
                    type: 'summary',
                    label: 'Résumé',
                    icon: Icons.summarize,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildActionButton(
                    type: 'exercises',
                    label: 'Exercices',
                    icon: Icons.assignment,
                    color: AppColors.accent,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildActionButton(
                    type: 'quiz',
                    label: 'Quiz',
                    icon: Icons.quiz,
                    color: AppColors.success,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Indicateur de chargement
            if (_isLoading) ...[
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.backgroundSecondary.withOpacity(0.3),
                  ),
                ),
                child: Column(
                  children: [
                    CircularProgressIndicator(color: AppColors.primary),
                    const SizedBox(height: 16),
                    Text(
                      'Génération du ${_getButtonLabel(_selectedType).toLowerCase()}...',
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'L\'IA prépare votre contenu',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],

            // Réponse IA
            Expanded(
              child: _aiResponse.isEmpty
                  ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: AppColors.backgroundSecondary,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.auto_awesome,
                        size: 48,
                        color: AppColors.textSecondary.withOpacity(0.5),
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Assistant IA Prêt',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 40),
                      child: Text(
                        'Sélectionnez un type de contenu pour commencer la génération avec l\'intelligence artificielle',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                          height: 1.4,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              )
                  : Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppColors.backgroundSecondary.withOpacity(0.5),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // En-tête du contenu généré
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: _getButtonColor(_selectedType).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: _getButtonColor(_selectedType).withOpacity(0.2),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _getButtonIcon(_selectedType),
                              size: 16,
                              color: _getButtonColor(_selectedType),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _getButtonLabel(_selectedType),
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: _getButtonColor(_selectedType),
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Text(
                              '• Généré par IA',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Contenu généré
                      Text(
                        _aiResponse,
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.textPrimary,
                          height: 1.6,
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Bouton d'action secondaire
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () => _generateContent(_selectedType),
                              icon: const Icon(Icons.refresh, size: 16),
                              label: const Text('Regénérer'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.textSecondary,
                                side: BorderSide(color: AppColors.backgroundSecondary),
                                padding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () {
                                // Action de partage à implémenter
                              },
                              icon: const Icon(Icons.share, size: 16),
                              label: const Text('Partager'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: AppColors.background,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required String type,
    required String label,
    required IconData icon,
    required Color color,
  }) {
    return ElevatedButton(
      onPressed: _isLoading ? null : () => _generateContent(type),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: AppColors.background,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        elevation: 0,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 20),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// Palette de couleurs cohérente avec le reste de l'application
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