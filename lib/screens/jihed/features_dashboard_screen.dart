// screens/features_dashboard_screen.dart
import 'package:compusflow/models/feature.dart';
import 'package:flutter/material.dart';
import 'examen_calendar_screen.dart'; // We'll create this new screen

class FeaturesDashboardScreen extends StatefulWidget {
  const FeaturesDashboardScreen({super.key});

  @override
  State<FeaturesDashboardScreen> createState() => _FeaturesDashboardScreenState();
}

class _FeaturesDashboardScreenState extends State<FeaturesDashboardScreen> {
  final List<AppFeature> _features = [
    AppFeature(
      id: 'rooms',
      title: 'Gestion des Salles',
      description: 'Gérez les salles de classe et laboratoires',
      icon: Icons.meeting_room_rounded,
      route: '/rooms',
      priority: FeaturePriority.critical,
      implemented: true,
    ),
    AppFeature(
      id: 'exams',
      title: 'Gestion des Examens',
      description: 'Planifiez et organisez vos examens',
      icon: Icons.assignment_rounded,
      route: '/exams',
      priority: FeaturePriority.critical,
      implemented: true,
    ),
    AppFeature(
      id: 'campus_map',
      title: 'Carte du Campus',
      description: 'Vue interactive des bâtiments et salles',
      icon: Icons.map_rounded,
      route: '/map',
      priority: FeaturePriority.high,
      implemented: true,
    ),
    AppFeature(
      id: 'calendar',
      title: 'Calendrier des Examens',
      description: 'Vue calendrier et timeline de vos examens',
      icon: Icons.calendar_today_rounded,
      route: '/calendar',
      priority: FeaturePriority.high,
      implemented: true, // Changed to true since we'll implement it
    ),
    AppFeature(
      id: 'notifications',
      title: 'Rappels Intelligents',
      description: 'Notifications personnalisées avant les examens',
      icon: Icons.notifications_active_rounded,
      route: '/notifications',
      priority: FeaturePriority.medium,
      implemented: false,
    ),
    AppFeature(
      id: 'study_plan',
      title: 'Planification d\'Étude',
      description: 'Créez votre emploi du temps de révision',
      icon: Icons.schedule_rounded,
      route: '/study-plan',
      priority: FeaturePriority.medium,
      implemented: false,
    ),
    AppFeature(
      id: 'grades',
      title: 'Calculateur de Notes',
      description: 'Suivez votre moyenne et progression',
      icon: Icons.calculate_rounded,
      route: '/grades',
      priority: FeaturePriority.medium,
      implemented: false,
    ),
    AppFeature(
      id: 'analytics',
      title: 'Analyses de Performance',
      description: 'Statistiques détaillées de vos résultats',
      icon: Icons.analytics_rounded,
      route: '/analytics',
      priority: FeaturePriority.low,
      implemented: false,
    ),
  ];

  String _currentFilter = 'all';

  @override
  Widget build(BuildContext context) {
    final filteredFeatures = _filterFeatures(_features, _currentFilter);

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text(
          'Fonctionnalités Campus Flow',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.teal.shade600,
        foregroundColor: Colors.white,
        elevation: 0,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(20),
          ),
        ),
      ),
      body: Column(
        children: [
          // Header Stats
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.teal.shade600,
                  Colors.teal.shade400,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(20),
              ),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    _buildStatItem(
                      'Fonctionnalités Actives',
                      _features.where((f) => f.implemented).length,
                      _features.length,
                      Colors.white,
                    ),
                    const SizedBox(width: 20),
                    _buildStatItem(
                      'En Développement',
                      _features.where((f) => !f.implemented).length,
                      _features.length,
                      Colors.white,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  'Explorez toutes les fonctionnalités de Campus Flow',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.9),
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),

          // Filter Chips
          Container(
            padding: const EdgeInsets.all(16),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFilterChip('Toutes', 'all'),
                  const SizedBox(width: 8),
                  _buildFilterChip('Actives', 'implemented'),
                  const SizedBox(width: 8),
                  _buildFilterChip('À venir', 'upcoming'),
                  const SizedBox(width: 8),
                  _buildFilterChip('Priorité Haute', 'high'),
                ],
              ),
            ),
          ),

          Expanded(
            child: filteredFeatures.isEmpty
                ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.search_off_rounded,
                    size: 64,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Aucune fonctionnalité trouvée',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Essayez avec un autre filtre',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade500,
                    ),
                  ),
                ],
              ),
            )
                : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: filteredFeatures.length,
              itemBuilder: (context, index) {
                final feature = filteredFeatures[index];
                return _buildFeatureCard(feature);
              },
            ),
          ),
        ],
      ),
    );
  }

  List<AppFeature> _filterFeatures(List<AppFeature> features, String filter) {
    switch (filter) {
      case 'implemented':
        return features.where((f) => f.implemented).toList();
      case 'upcoming':
        return features.where((f) => !f.implemented).toList();
      case 'high':
        return features.where((f) => f.priority == FeaturePriority.high || f.priority == FeaturePriority.critical).toList();
      default:
        return features;
    }
  }

  Widget _buildStatItem(String label, int count, int total, Color color) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$count',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color.withOpacity(0.9),
            ),
          ),
          const SizedBox(height: 4),
          Container(
            height: 4,
            decoration: BoxDecoration(
              color: color.withOpacity(0.3),
              borderRadius: BorderRadius.circular(2),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: count / total,
              child: Container(
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _currentFilter == value;
    return GestureDetector(
      onTap: () {
        setState(() {
          _currentFilter = value;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.teal.shade600 : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? Colors.teal.shade600 : Colors.grey.shade300,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.w500,
            color: isSelected ? Colors.white : Colors.teal.shade600,
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureCard(AppFeature feature) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            _navigateToFeature(feature);
          },
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                // Feature Icon
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: _getPriorityColor(feature.priority).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _getPriorityColor(feature.priority).withOpacity(0.3),
                    ),
                  ),
                  child: Icon(
                    feature.icon,
                    color: _getPriorityColor(feature.priority),
                    size: 24,
                  ),
                ),

                const SizedBox(width: 16),

                // Feature Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        feature.title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        feature.description,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Status and Priority
                      Row(
                        children: [
                          _buildStatusChip(feature.implemented),
                          const SizedBox(width: 8),
                          _buildPriorityChip(feature.priority),
                        ],
                      ),
                    ],
                  ),
                ),

                // Navigation Arrow
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.arrow_forward_ios_rounded,
                    color: Colors.grey.shade600,
                    size: 14,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _getPriorityColor(FeaturePriority priority) {
    switch (priority) {
      case FeaturePriority.critical:
        return Colors.red.shade600;
      case FeaturePriority.high:
        return Colors.orange.shade600;
      case FeaturePriority.medium:
        return Colors.blue.shade600;
      case FeaturePriority.low:
        return Colors.green.shade600;
    }
  }

  Widget _buildStatusChip(bool implemented) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: implemented ? Colors.green.shade50 : Colors.orange.shade50,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: implemented ? Colors.green.shade200 : Colors.orange.shade200,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            implemented ? Icons.check_circle_rounded : Icons.schedule_rounded,
            size: 12,
            color: implemented ? Colors.green.shade600 : Colors.orange.shade600,
          ),
          const SizedBox(width: 4),
          Text(
            implemented ? 'Active' : 'À venir',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: implemented ? Colors.green.shade600 : Colors.orange.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriorityChip(FeaturePriority priority) {
    final colors = {
      FeaturePriority.critical: Colors.red.shade600,
      FeaturePriority.high: Colors.orange.shade600,
      FeaturePriority.medium: Colors.blue.shade600,
      FeaturePriority.low: Colors.green.shade600,
    };

    final labels = {
      FeaturePriority.critical: 'Critique',
      FeaturePriority.high: 'Haute',
      FeaturePriority.medium: 'Moyenne',
      FeaturePriority.low: 'Basse',
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: colors[priority]!.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: colors[priority]!.withOpacity(0.3),
        ),
      ),
      child: Text(
        labels[priority]!,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: colors[priority],
        ),
      ),
    );
  }

  void _navigateToFeature(AppFeature feature) {
    if (!feature.implemented) {
      _showComingSoonDialog(feature);
      return;
    }

    // Navigate to existing features
    switch (feature.id) {
      case 'rooms':
        Navigator.pushNamed(context, '/rooms');
        break;
      case 'exams':
        Navigator.pushNamed(context, '/exams');
        break;
      case 'campus_map':
        Navigator.pushNamed(context, '/map');
        break;
      case 'calendar':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const ExamenCalendarScreen()),
        );
        break;
      default:
        _showFeatureDetails(feature);
    }
  }

  void _showComingSoonDialog(AppFeature feature) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.orange.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(feature.icon, color: Colors.orange.shade600),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                '${feature.title} - Bientôt disponible',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: Text(
          'Cette fonctionnalité est en cours de développement et sera disponible dans une prochaine mise à jour de Campus Flow.',
          style: TextStyle(color: Colors.grey.shade600),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }

  void _showFeatureDetails(AppFeature feature) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.teal.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(feature.icon, color: Colors.teal.shade600),
            ),
            const SizedBox(width: 12),
            Text(feature.title),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              feature.description,
              style: TextStyle(color: Colors.grey.shade700),
            ),
            const SizedBox(height: 16),
            const Text(
              'Fonctionnalités inclues:',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            _buildFeatureList(feature.id),
          ],
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fermer'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _navigateToFeature(feature);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.teal.shade600,
              foregroundColor: Colors.white,
            ),
            child: const Text('Explorer'),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureList(String featureId) {
    final features = {
      'rooms': [
        'Gestion complète des salles',
        'Capacité et type de salle',
        'Recherche et filtres avancés',
        'Vue par bâtiment'
      ],
      'exams': [
        'Planification des examens',
        'Gestion des horaires',
        'Assignation des salles',
        'Suivi des résultats'
      ],
      'campus_map': [
        'Vue interactive du campus',
        'Localisation des bâtiments',
        'Navigation entre salles',
        'Statistiques par bâtiment'
      ],
      'calendar': [
        'Vue mensuelle des examens',
        'Timeline chronologique',
        'Détails des examens en un coup d\'œil',
        'Filtres par cours et type'
      ],
    };

    final list = features[featureId] ?? ['Détails à venir...'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: list.map((item) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Icon(Icons.check_circle_rounded, size: 16, color: Colors.teal.shade600),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                item,
                style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
              ),
            ),
          ],
        ),
      )).toList(),
    );
  }
}