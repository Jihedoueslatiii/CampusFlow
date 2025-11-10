import 'package:flutter/material.dart';
import 'package:compusflow/services/projet_service.dart';
import 'package:compusflow/services/ai_planning_service.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';

class ProjetDetailsScreen extends StatefulWidget {
  final int projetId;

  const ProjetDetailsScreen({Key? key, required this.projetId}) : super(key: key);

  @override
  State<ProjetDetailsScreen> createState() => _ProjetDetailsScreenState();
}

class _ProjetDetailsScreenState extends State<ProjetDetailsScreen> {
  final ProjetService _projetService = ProjetService();
  final AIPlanningService _aiPlanningService = AIPlanningService();
  late Future<Map<String, dynamic>?> _projetFuture;
  List<Map<String, dynamic>> _timeline = [];
  bool _isAILoading = false;
  String? _aiAdvice;
  bool _hasLoadedAI = false;

  // Couleurs améliorées
  static const Color primaryColor = Color(0xFF2563EB);
  static const Color secondaryColor = Color(0xFF7C3AED);
  static const Color accentColor = Color(0xFFFFD700);
  static const Color backgroundColor = Color(0xFFF8FAFC);
  static const Color cardColor = Color(0xFFFFFFFF);
  static const Color textColor = Color(0xFF1E293B);
  static const Color subtitleColor = Color(0xFF64748B);

  final DateFormat _dateFormatter = DateFormat('dd MMM', 'fr_FR');
  final DateFormat _fullDateFormatter = DateFormat('EEEE dd MMMM yyyy', 'fr_FR');

  @override
  void initState() {
    super.initState();
    Intl.defaultLocale = 'fr_FR';
    _loadProjetDetails();
  }

  void _loadProjetDetails() {
    setState(() {
      _projetFuture = _projetService.getProjetById(widget.projetId);
    });
  }

  // 🚀 Chargement de la timeline IA - CORRIGÉ
  Future<void> _loadAITimeline(Map<String, dynamic> projet) async {
    if (_hasLoadedAI) return;

    if (!mounted) return;

    setState(() {
      _isAILoading = true;
    });

    try {
      final String titre = projet['titre'] as String? ?? 'Titre Inconnu';
      final String description = projet['description'] as String? ?? '';
      final String coursAssocie = projet['cours_associe'] as String? ?? 'N/A';
      final String dateRenduString = projet['date_rendu'] as String? ?? '';
      final int difficulte = projet['difficulte'] as int? ?? 3;

      final DateTime? dateRendu = DateTime.tryParse(dateRenduString);

      if (dateRendu != null) {
        final aiTimeline = await _aiPlanningService.generateProjectTimeline(
          projetTitre: titre,
          description: description,
          coursAssocie: coursAssocie,
          dateRendu: dateRendu,
          difficulte: difficulte,
        );

        if (aiTimeline != null && mounted) {
          setState(() {
            _timeline = aiTimeline;
            _isAILoading = false;
            _hasLoadedAI = true;
          });
        } else {
          setState(() {
            _isAILoading = false;
            _hasLoadedAI = true;
          });
        }
      } else {
        setState(() {
          _isAILoading = false;
          _hasLoadedAI = true;
        });
      }
    } catch (e) {
      print('Erreur chargement timeline IA: $e');
      if (mounted) {
        setState(() {
          _isAILoading = false;
          _hasLoadedAI = true;
        });
      }
    }
  }

  // 🚀 Chargement des conseils IA - CORRIGÉ
  Future<void> _loadAIAdvice(Map<String, dynamic> projet) async {
    try {
      final String titre = projet['titre'] as String? ?? 'Titre Inconnu';
      final String description = projet['description'] as String? ?? '';
      final String coursAssocie = projet['cours_associe'] as String? ?? 'N/A';
      final int difficulte = projet['difficulte'] as int? ?? 3;

      final advice = await _aiPlanningService.getProjectAdvice(
        projetTitre: titre,
        description: description,
        coursAssocie: coursAssocie,
        difficulte: difficulte,
      );

      if (advice != null && mounted) {
        setState(() {
          _aiAdvice = advice;
        });
      }
    } catch (e) {
      print('Erreur chargement conseils IA: $e');
    }
  }

  // 🎯 WIDGET AMÉLIORÉ : Diagramme de Gantt avec données IA
  Widget _buildGanttChartTable(List<Map<String, dynamic>> timeline) {
    if (timeline.isEmpty) {
      return _buildEmptyState(
        icon: Icons.timeline,
        title: 'Timeline non disponible',
        subtitle: 'La date de rendu est trop proche pour générer un plan optimal',
      );
    }

    final DateTime overallStart = timeline.first['start'];
    final DateTime overallEnd = timeline.last['end'];
    final int totalDuration = overallEnd.difference(overallStart).inDays + 1;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: cardColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0), // Padding réduit
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // En-tête
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.auto_awesome, color: primaryColor, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Planification Intelligente',
                        style: TextStyle(
                          fontSize: 18, // Taille réduite
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                      ),
                      Text(
                        'Diagramme de Gantt optimisé par IA',
                        style: TextStyle(
                          fontSize: 13, // Taille réduite
                          color: subtitleColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Légende avec défilement horizontal si nécessaire
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: _buildGanttLegend(timeline),
            ),
            const SizedBox(height: 16),

            // Tableau Gantt avec hauteur fixe et défilement
            ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.6, // Hauteur maximale
              ),
              child: SingleChildScrollView(
                child: Table(
                  columnWidths: const {
                    0: FlexColumnWidth(3.5),
                    1: FlexColumnWidth(6.5),
                  },
                  defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                  children: [
                    // En-tête du tableau
                    TableRow(
                      decoration: BoxDecoration(
                        color: primaryColor.withOpacity(0.05),
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(12),
                          topRight: Radius.circular(12),
                        ),
                      ),
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Text(
                            'TÂCHE',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 13, // Taille réduite
                              color: primaryColor,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Text(
                            'ÉCHÉANCIER',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 13, // Taille réduite
                              color: primaryColor,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                    // Lignes des tâches
                    ...timeline.asMap().entries.map((entry) {
                      final index = entry.key;
                      final item = entry.value;
                      final bool isLast = index == timeline.length - 1;

                      return _buildGanttTableRow(item, overallStart, overallEnd, totalDuration, isLast);
                    }).toList(),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Pied de page
            _buildGanttFooter(overallStart, overallEnd, timeline),
          ],
        ),
      ),
    );
  }

  // Ligne de tableau Gantt - CORRIGÉE POUR DÉBORDEMENT
  TableRow _buildGanttTableRow(
      Map<String, dynamic> item,
      DateTime overallStart,
      DateTime overallEnd,
      int totalDuration,
      bool isLast,
      ) {
    final DateTime taskStart = item['start'];
    final DateTime taskEnd = item['end'];
    final Color color = item['color'];
    final String description = item['description'] ?? '';
    final String priority = item['priority'] ?? 'Moyenne';
    final bool isAI = item['isAI'] ?? false;

    final int taskDuration = taskEnd.difference(taskStart).inDays + 1;
    final int daysOffset = taskStart.difference(overallStart).inDays;

    final double startPercent = daysOffset / totalDuration;
    final double durationPercent = taskDuration / totalDuration;

    final DateTime now = DateTime.now();
    int daysPassed = now.isBefore(taskStart) ? 0 : now.difference(taskStart).inDays + 1;
    daysPassed = daysPassed.clamp(0, taskDuration);
    final double progressPercent = (taskDuration > 0) ? daysPassed / taskDuration : 0.0;

    return TableRow(
      decoration: BoxDecoration(
        border: Border(
          bottom: isLast
              ? BorderSide.none
              : BorderSide(color: Colors.grey.shade100, width: 1),
        ),
      ),
      children: [
        // Colonne tâche - CORRIGÉE POUR DÉBORDEMENT
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 8.0),
          child: SizedBox(
            height: 90, // Hauteur fixe pour éviter le débordement
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Titre de la tâche avec priorité
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        item['task'],
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: textColor,
                          height: 1.2,
                        ),
                        maxLines: 2, // Limiter à 2 lignes
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (isAI)
                      Padding(
                        padding: const EdgeInsets.only(left: 4.0),
                        child: _buildAIBadge(),
                      ),
                  ],
                ),
                const SizedBox(height: 6),

                // Priorité et dates sur la même ligne pour économiser l'espace
                Row(
                  children: [
                    _buildPriorityBadge(priority),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${_dateFormatter.format(taskStart)} - ${_dateFormatter.format(taskEnd)}',
                        style: TextStyle(
                          fontSize: 11,
                          color: subtitleColor,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),

                // Description réduite
                if (description.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 11,
                      color: subtitleColor,
                      height: 1.2,
                    ),
                    maxLines: 2, // Limiter à 2 lignes
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
        ),

        // Colonne barre de progression
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 8.0),
          child: SizedBox(
            height: 90, // Même hauteur que la colonne de gauche
            child: _buildGanttBar(
              item,
              startPercent,
              durationPercent,
              progressPercent,
              overallStart,
              overallEnd,
              totalDuration,
            ),
          ),
        ),
      ],
    );
  }

  // Barre Gantt - CORRIGÉE
  Widget _buildGanttBar(
      Map<String, dynamic> item,
      double startPercent,
      double durationPercent,
      double progressPercent,
      DateTime overallStart,
      DateTime overallEnd,
      int totalDuration,
      ) {
    final DateTime now = DateTime.now();
    final String progressText = progressPercent > 0.0 ? '${(progressPercent * 100).round()}%' : '0%';

    return LayoutBuilder(
      builder: (context, constraints) {
        final double availableWidth = constraints.maxWidth;
        const double barHeight = 20.0;
        const double borderRadius = barHeight / 2;

        final double taskBarWidth = (availableWidth * durationPercent).clamp(20.0, availableWidth);
        final double taskBarOffset = (availableWidth * startPercent).clamp(0.0, availableWidth);
        final double todayPosition = availableWidth *
            (now.difference(overallStart).inDays / totalDuration);

        return Stack(
          clipBehavior: Clip.none,
          children: [
            // Ligne de base
            Container(
              height: barHeight,
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(borderRadius),
              ),
            ),

            // Barre de tâche
            Positioned(
              left: taskBarOffset,
              child: Tooltip(
                message: '${item['task']}\nDurée: ${item['end'].difference(item['start']).inDays + 1} jours\nPriorité: ${item['priority']}',
                child: Container(
                  width: taskBarWidth,
                  height: barHeight,
                  decoration: BoxDecoration(
                    color: item['color'].withOpacity(0.2),
                    borderRadius: BorderRadius.circular(borderRadius),
                    border: Border.all(color: item['color'].withOpacity(0.3)),
                  ),
                  child: Stack(
                    children: [
                      // Progression
                      Container(
                        width: taskBarWidth * progressPercent,
                        height: barHeight,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              item['color'],
                              item['color'].withOpacity(0.8),
                            ],
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                          ),
                          borderRadius: BorderRadius.horizontal(
                            left: const Radius.circular(borderRadius),
                            right: Radius.circular(
                                progressPercent >= 1.0 ? borderRadius : 0),
                          ),
                        ),
                        child: progressPercent > 0.3 ? Center(
                          child: Text(
                            progressText,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              shadows: [
                                Shadow(
                                  color: Colors.black54,
                                  blurRadius: 2,
                                ),
                              ],
                            ),
                          ),
                        ) : null,
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Indicateur "Aujourd'hui"
            if (now.isAfter(overallStart.subtract(const Duration(days: 1))) &&
                now.isBefore(overallEnd.add(const Duration(days: 1))))
              Positioned(
                left: todayPosition.clamp(0.0, availableWidth) - 1,
                child: Container(
                  width: 2,
                  height: barHeight + 4,
                  color: Colors.red.shade600,
                ),
              ),
          ],
        );
      },
    );
  }

  // Widget pour la légende du Gantt - CORRIGÉ POUR DÉBORDEMENT
  Widget _buildGanttLegend(List<Map<String, dynamic>> timeline) {
    final uniqueTasks = timeline.toSet().toList();

    return Wrap(
      spacing: 12,
      runSpacing: 8,
      children: uniqueTasks.map((item) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: item['color'].withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: item['color'].withOpacity(0.3)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: item['color'],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 6),
              Text(
                _abbreviateTaskName(item['task']), // Nom abrégé
                style: TextStyle(
                  fontSize: 11,
                  color: textColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  // Abréviation des noms de tâches pour la légende
  String _abbreviateTaskName(String taskName) {
    if (taskName.length <= 20) return taskName;

    final words = taskName.split(' ');
    if (words.length <= 2) return taskName.substring(0, 17) + '...';

    return '${words[0]} ${words.length > 1 ? words[1] : ''}...';
  }

  // Widget pour le badge de priorité
  Widget _buildPriorityBadge(String priority) {
    Map<String, dynamic> priorityConfig;

    switch (priority.toLowerCase()) {
      case 'critique':
        priorityConfig = {
          'color': Colors.red.shade700,
          'bgColor': Colors.red.shade50,
        };
        break;
      case 'élevée':
        priorityConfig = {
          'color': Colors.orange.shade700,
          'bgColor': Colors.orange.shade50,
        };
        break;
      case 'moyenne':
        priorityConfig = {
          'color': Colors.blue.shade700,
          'bgColor': Colors.blue.shade50,
        };
        break;
      default:
        priorityConfig = {
          'color': Colors.grey.shade600,
          'bgColor': Colors.grey.shade50,
        };
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: priorityConfig['bgColor'],
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.flag, size: 10, color: priorityConfig['color']),
          const SizedBox(width: 2),
          Text(
            _abbreviatePriority(priority),
            style: TextStyle(
              color: priorityConfig['color'],
              fontSize: 9,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  // Abréviation des priorités
  String _abbreviatePriority(String priority) {
    switch (priority.toLowerCase()) {
      case 'critique': return 'Crit.';
      case 'élevée': return 'Élev.';
      case 'moyenne': return 'Moy.';
      case 'faible': return 'Faib.';
      default: return priority.length > 4 ? priority.substring(0, 4) : priority;
    }
  }

  // Badge IA
  Widget _buildAIBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: Colors.green.shade200),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.auto_awesome, size: 8, color: Colors.green.shade700),
          const SizedBox(width: 2),
          Text(
            'IA',
            style: TextStyle(
              color: Colors.green.shade700,
              fontSize: 8,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  // Widget pour le pied de page du Gantt
  Widget _buildGanttFooter(DateTime start, DateTime end, List<Map<String, dynamic>> timeline) {
    final totalDays = end.difference(start).inDays + 1;
    final completedTasks = timeline.where((task) {
      final now = DateTime.now();
      return now.isAfter(task['end'] as DateTime);
    }).length;

    final progressPercent = timeline.isNotEmpty ? (completedTasks / timeline.length) * 100 : 0;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: primaryColor.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Période',
                style: TextStyle(
                  color: subtitleColor,
                  fontSize: 11,
                ),
              ),
              Text(
                '$totalDays j',
                style: const TextStyle(
                  color: textColor,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                'Progression',
                style: TextStyle(
                  color: subtitleColor,
                  fontSize: 11,
                ),
              ),
              Text(
                '${progressPercent.round()}%',
                style: TextStyle(
                  color: Colors.green.shade700,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'Terminé',
                style: TextStyle(
                  color: subtitleColor,
                  fontSize: 11,
                ),
              ),
              Text(
                '$completedTasks/${timeline.length}',
                style: const TextStyle(
                  color: textColor,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Timeline Améliorée avec IA - CORRIGÉE POUR DÉBORDEMENT
  Widget _buildEnhancedTimeline(List<Map<String, dynamic>> timeline) {
    if (_isAILoading) {
      return _buildLoadingState(
        title: 'L\'IA génère une timeline optimisée...',
        subtitle: 'Analyse en cours de votre projet',
      );
    }

    if (timeline.isEmpty) {
      return _buildEmptyState(
        icon: Icons.schedule,
        title: 'Timeline non disponible',
        subtitle: 'La date de rendu est trop proche pour générer un plan optimal',
      );
    }

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: cardColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // En-tête
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: secondaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.timeline, color: secondaryColor, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Timeline Intelligente',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                      ),
                      Text(
                        'Planification optimisée par IA',
                        style: TextStyle(
                          fontSize: 13,
                          color: subtitleColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Étapes de la timeline avec hauteur limitée
            ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.5,
              ),
              child: SingleChildScrollView(
                child: Column(
                  children: timeline.asMap().entries.map((entry) {
                    final index = entry.key;
                    final item = entry.value;
                    return _buildTimelineStep(
                      task: item['task'],
                      start: item['start'],
                      end: item['end'],
                      color: item['color'],
                      description: item['description'] ?? '',
                      priority: item['priority'] ?? 'Moyenne',
                      isLast: index == timeline.length - 1,
                      isAI: item['isAI'] ?? false,
                      recommendations: item['recommendations'] ?? [],
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Étape de timeline améliorée - CORRIGÉE POUR DÉBORDEMENT
  Widget _buildTimelineStep({
    required String task,
    required DateTime start,
    required DateTime end,
    required Color color,
    required String description,
    required String priority,
    required bool isLast,
    required bool isAI,
    required List<dynamic> recommendations,
  }) {
    final int totalDays = end.difference(start).inDays + 1;
    final DateTime now = DateTime.now();
    final bool isCurrent = now.isAfter(start) && now.isBefore(end);
    final bool isCompleted = now.isAfter(end);
    final bool isUpcoming = now.isBefore(start);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isCurrent ? color.withOpacity(0.3) : Colors.grey.shade100,
          width: isCurrent ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Indicateur visuel
          Column(
            children: [
              Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  color: isCompleted
                      ? Colors.green
                      : isCurrent
                      ? color
                      : color.withOpacity(0.5),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
              ),
              if (!isLast)
                Container(
                  width: 2,
                  height: 40,
                  color: color.withOpacity(0.3),
                  margin: const EdgeInsets.symmetric(vertical: 2),
                ),
            ],
          ),
          const SizedBox(width: 12),

          // Contenu - CORRIGÉ POUR DÉBORDEMENT
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // En-tête avec titre et badges
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            task,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                              color: textColor,
                              height: 1.2,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 6),
                          Wrap(
                            spacing: 6,
                            runSpacing: 4,
                            children: [
                              _buildStatusBadge(isCompleted, isCurrent, isUpcoming),
                              _buildPriorityBadge(priority),
                              if (isAI) _buildAIBadge(),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Dates et durée
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.calendar_today, size: 12, color: color),
                      const SizedBox(width: 4),
                      Text(
                        '${_dateFormatter.format(start)} - ${_dateFormatter.format(end)} • $totalDays j',
                        style: TextStyle(
                          fontSize: 11,
                          color: color,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),

                // Description
                if (description.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 12,
                      color: subtitleColor,
                      height: 1.3,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],

                // Conseils IA
                if (recommendations.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  _buildAITips(recommendations.cast<String>()),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Widget pour le badge de statut
  Widget _buildStatusBadge(bool isCompleted, bool isCurrent, bool isUpcoming) {
    if (isCompleted) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: Colors.green.shade50,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check, size: 10, color: Colors.green.shade700),
            const SizedBox(width: 2),
            Text(
              'Terminé',
              style: TextStyle(
                color: Colors.green.shade700,
                fontSize: 9,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      );
    } else if (isCurrent) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: Colors.orange.shade50,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.play_arrow, size: 10, color: Colors.orange.shade700),
            const SizedBox(width: 2),
            Text(
              'En cours',
              style: TextStyle(
                color: Colors.orange.shade700,
                fontSize: 9,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      );
    } else {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: Colors.blue.shade50,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.schedule, size: 10, color: Colors.blue.shade700),
            const SizedBox(width: 2),
            Text(
              'À venir',
              style: TextStyle(
                color: Colors.blue.shade700,
                fontSize: 9,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      );
    }
  }

  // Widget pour les conseils IA - CORRIGÉ POUR DÉBORDEMENT
  Widget _buildAITips(List<String> recommendations) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.blue.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(Icons.lightbulb_outline, size: 12, color: Colors.orange.shade700),
              const SizedBox(width: 4),
              Text(
                'Conseils',
                style: TextStyle(
                  color: Colors.orange.shade700,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          ...recommendations.take(2).map((tip) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 1),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '• ',
                  style: TextStyle(
                    color: Colors.orange.shade700,
                    fontSize: 10,
                  ),
                ),
                Expanded(
                  child: Text(
                    tip,
                    style: TextStyle(
                      color: subtitleColor,
                      fontSize: 10,
                      height: 1.3,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          )).toList(),
        ],
      ),
    );
  }

  // Construit une carte d'information stylisée
  Widget _buildDetailCard(IconData icon, String title, String value, [Color? color]) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: cardColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: (color ?? primaryColor).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color ?? primaryColor, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: subtitleColor,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: color ?? textColor,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Calcule le statut de la date de rendu
  Map<String, dynamic> _getDeadlineStatus(DateTime? dateRendu) {
    if (dateRendu == null) {
      return {
        'text': 'Non spécifié',
        'color': Colors.grey.shade600,
        'icon': Icons.info_outline
      };
    }

    final remaining = dateRendu.difference(DateTime.now());

    if (remaining.isNegative) {
      return {
        'text': 'Rendu dépassé',
        'color': Colors.red.shade700,
        'icon': Icons.error_outline
      };
    } else if (remaining.inDays == 0) {
      return {
        'text': 'Rendu aujourd\'hui!',
        'color': Colors.red.shade700,
        'icon': Icons.notification_important
      };
    } else if (remaining.inDays < 7) {
      return {
        'text': 'Reste ${remaining.inDays} jours',
        'color': Colors.orange.shade700,
        'icon': Icons.warning_amber
      };
    } else {
      return {
        'text': 'Reste ${remaining.inDays} jours',
        'color': Colors.green.shade700,
        'icon': Icons.check_circle_outline
      };
    }
  }

  // Widget de code QR pour le partage
  Widget _buildQrCodeCard(String qrData) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: cardColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: secondaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.qr_code, color: secondaryColor, size: 20),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Partage Rapide',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: QrImageView(
                data: qrData.length > 500 ? qrData.substring(0, 500) : qrData,
                version: QrVersions.auto,
                size: 150.0,
                gapless: true,
                backgroundColor: Colors.transparent,
                foregroundColor: textColor,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Scannez pour voir les informations du projet',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: subtitleColor,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Widget pour les conseils IA du projet
  Widget _buildAIAdviceCard() {
    if (_aiAdvice == null) return const SizedBox.shrink();

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: cardColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.auto_awesome, color: Colors.orange, size: 20),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Conseils IA pour Réussir',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.orange.withOpacity(0.2)),
              ),
              child: Text(
                _aiAdvice!,
                style: const TextStyle(
                  fontSize: 14,
                  height: 1.5,
                  color: textColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Widget pour l'état de chargement
  Widget _buildLoadingState({required String title, required String subtitle}) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: cardColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          children: [
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
              strokeWidth: 3,
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: textColor,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 12,
                color: subtitleColor,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // Widget pour l'état vide
  Widget _buildEmptyState({required IconData icon, required String title, required String subtitle}) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: cardColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          children: [
            Icon(icon, size: 40, color: Colors.grey.shade400),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: textColor,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 12,
                color: subtitleColor,
              ),
              textAlign: TextAlign.center,
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
          'Détails du Projet',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
            fontSize: 16,
          ),
        ),
        backgroundColor: primaryColor,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, size: 20),
            onPressed: _loadProjetDetails,
            tooltip: 'Actualiser',
          ),
        ],
      ),
      body: FutureBuilder<Map<String, dynamic>?>(
        future: _projetFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
              ),
            );
          }

          if (!snapshot.hasData || snapshot.data == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 50, color: Colors.grey.shade400),
                  const SizedBox(height: 12),
                  Text(
                    snapshot.hasError
                        ? 'Erreur lors du chargement'
                        : 'Projet non trouvé',
                    style: const TextStyle(
                      color: textColor,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: _loadProjetDetails,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Réessayer', style: TextStyle(color: Colors.white)),
                  ),
                ],
              ),
            );
          }

          final projet = snapshot.data!;
          final String titre = projet['titre'] as String? ?? 'Titre Inconnu';
          final String coursAssocie = projet['cours_associe'] as String? ?? 'N/A';
          final String description = projet['description'] as String? ?? 'Aucune description fournie.';
          final String dateRenduString = projet['date_rendu'] as String? ?? '';
          final int difficulte = projet['difficulte'] as int? ?? 3;

          DateTime? dateRendu;
          String formattedDate = 'Non spécifiée';

          try {
            dateRendu = DateTime.tryParse(dateRenduString);
            if (dateRendu != null) {
              formattedDate = _fullDateFormatter.format(dateRendu);

              // Charger la timeline IA si pas déjà fait
              if (!_hasLoadedAI && !_isAILoading) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  _loadAITimeline(projet);
                  _loadAIAdvice(projet);
                });
              }
            }
          } catch (_) {
            // Gérer l'erreur de format
          }

          final deadlineStatus = _getDeadlineStatus(dateRendu);
          final qrData = 'Projet: $titre\nCours: $coursAssocie\nRendu: $formattedDate\nStatut: ${deadlineStatus['text']}';

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // En-tête du projet
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [primaryColor, secondaryColor],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: primaryColor.withOpacity(0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        titre,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          height: 1.2,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        coursAssocie,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white.withOpacity(0.9),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Grille d'informations
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.4,
                  children: [
                    _buildDetailCard(
                      Icons.school_outlined,
                      'Cours Associé',
                      coursAssocie,
                    ),
                    _buildDetailCard(
                      Icons.calendar_month_outlined,
                      'Date de Rendu',
                      formattedDate,
                    ),
                    _buildDetailCard(
                      Icons.assessment_outlined,
                      'Difficulté',
                      '${difficulte}/5',
                      _getDifficultyColor(difficulte),
                    ),
                    _buildDetailCard(
                      deadlineStatus['icon'] as IconData,
                      'Statut du Rendu',
                      deadlineStatus['text'] as String,
                      deadlineStatus['color'] as Color,
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Conseils IA
                _buildAIAdviceCard(),
                if (_aiAdvice != null) const SizedBox(height: 20),

                // Timeline
                _buildEnhancedTimeline(_timeline),
                const SizedBox(height: 20),

                // Diagramme de Gantt
                _buildGanttChartTable(_timeline),
                const SizedBox(height: 20),

                // Description
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    color: cardColor,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 20,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: primaryColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(Icons.description, color: primaryColor, size: 20),
                            ),
                            const SizedBox(width: 12),
                            const Text(
                              'Description Détaillée',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: textColor,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          description,
                          style: const TextStyle(
                            fontSize: 14,
                            height: 1.6,
                            color: textColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // QR Code
                _buildQrCodeCard(qrData),
                const SizedBox(height: 30),
              ],
            ),
          );
        },
      ),
    );
  }

  // Méthode utilitaire pour la couleur de difficulté
  Color _getDifficultyColor(int difficulte) {
    switch (difficulte) {
      case 1:
        return Colors.green.shade700;
      case 2:
        return Colors.lightGreen.shade700;
      case 3:
        return Colors.orange.shade700;
      case 4:
        return Colors.orange.shade800;
      case 5:
        return Colors.red.shade700;
      default:
        return Colors.grey.shade600;
    }
  }
}