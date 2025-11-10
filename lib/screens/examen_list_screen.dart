import 'package:campusflow/screens/examen_calendar_screen.dart';
import 'package:campusflow/screens/generate_quiz_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../db/database_helper.dart';
import '../models/examen.dart';
import '../models/salle.dart';
import 'add_edit_examen_screen.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';

// App Color Scheme
class AppColors {
  static const Color primaryRed = Color(0xFFE53935);
  static const Color lightGray = Color(0xFFF5F5F5);
  static const Color darkGray = Color(0xFF212121);
  static const Color white = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFF757575);
  static const Color border = Color(0xFFE0E0E0);
  static const Color redLight = Color(0xFFFFEBEE);
  static const Color divider = Color(0xFFEEEEEE);
}

class ExamenListScreen extends StatefulWidget {
  const ExamenListScreen({super.key});

  @override
  State<ExamenListScreen> createState() => _ExamenListScreenState();
}

class _ExamenListScreenState extends State<ExamenListScreen> {
  final db = DatabaseHelper.instance;
  late Future<List<Examen>> _future;
  String _filter = 'all'; // 'all', 'upcoming', 'completed', 'cancelled'
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  void _refresh() {
    setState(() {
      _future = db.getAllExamens();
    });
  }

  Future<void> _delete(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmer la suppression'),
        content: const Text('Voulez-vous vraiment supprimer cet examen ?'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryRed,
              foregroundColor: AppColors.white,
            ),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await db.deleteExamen(id);
      _refresh();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Examen supprimé avec succès'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<Salle?> _getSalleForExam(Examen e) async {
    if (e.salleId == null) return null;
    final salles = await db.getAllSalles();
    try {
      return salles.firstWhere((s) => s.id == e.salleId);
    } catch (_) {
      return null;
    }
  }

  Color _statusColor(String? status) {
    switch (status) {
      case 'Scheduled':
        return Colors.blue.shade600;
      case 'In Progress':
        return Colors.orange.shade600;
      case 'Completed':
        return Colors.green.shade600;
      case 'Cancelled':
        return AppColors.primaryRed;
      default:
        return AppColors.textSecondary;
    }
  }

  IconData _statusIcon(String? status) {
    switch (status) {
      case 'Scheduled':
        return Icons.schedule_rounded;
      case 'In Progress':
        return Icons.play_circle_fill_rounded;
      case 'Completed':
        return Icons.check_circle_rounded;
      case 'Cancelled':
        return Icons.cancel_rounded;
      default:
        return Icons.help_rounded;
    }
  }

  IconData _examTypeIcon(String type) {
    switch (type.toLowerCase()) {
      case 'partiel':
        return Icons.assignment_rounded;
      case 'final':
        return Icons.school_rounded;
      default:
        return Icons.description_rounded;
    }
  }

  Future<void> _openFile(String filePath) async {
    try {
      final uri = Uri.file(filePath);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('❌ Impossible d\'ouvrir le fichier'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Erreur: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = dateTime.difference(now);

    if (difference.inDays == 0) {
      return 'Aujourd\'hui à ${DateFormat('HH:mm').format(dateTime)}';
    } else if (difference.inDays == 1) {
      return 'Demain à ${DateFormat('HH:mm').format(dateTime)}';
    } else if (difference.inDays == -1) {
      return 'Hier à ${DateFormat('HH:mm').format(dateTime)}';
    } else {
      return DateFormat('dd MMM yyyy à HH:mm', 'fr_FR').format(dateTime);
    }
  }

  List<Examen> _filterExams(List<Examen> exams) {
    final now = DateTime.now();
    switch (_filter) {
      case 'upcoming':
        return exams.where((e) => e.date.isAfter(now)).toList();
      case 'completed':
        return exams.where((e) => e.status == 'Completed').toList();
      case 'cancelled':
        return exams.where((e) => e.status == 'Cancelled').toList();
      default:
        return exams;
    }
  }

  // 🎮 Study Streak & Gamification
  Widget _buildStreakHeader() {
    return FutureBuilder<List<Examen>>(
      future: _future,
      builder: (context, snapshot) {
        final exams = snapshot.data ?? [];
        final streak = _calculateStudyStreak(exams);
        final points = _calculateStudyPoints(exams);

        return Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.redLight,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.local_fire_department,
                  color: AppColors.primaryRed,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$streak jours de suite!',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.darkGray,
                      ),
                    ),
                    Text(
                      '$points points gagnés',
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              Stack(
                alignment: Alignment.center,
                children: [
                  CircularProgressIndicator(
                    value: streak / 7,
                    backgroundColor: AppColors.divider,
                    valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primaryRed),
                    strokeWidth: 4,
                  ),
                  Text(
                    '${((streak / 7) * 100).toInt()}%',
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  int _calculateStudyStreak(List<Examen> exams) {
    final completedExams = exams.where((e) => e.status == 'Completed').toList();
    if (completedExams.isEmpty) return 0;

    completedExams.sort((a, b) => b.date.compareTo(a.date));
    int streak = 1;
    DateTime currentDate = completedExams.first.date;

    for (int i = 1; i < completedExams.length; i++) {
      final previousDate = completedExams[i].date;
      final difference = currentDate.difference(previousDate).inDays;

      if (difference == 1) {
        streak++;
        currentDate = previousDate;
      } else if (difference > 1) {
        break;
      }
    }
    return streak;
  }

  int _calculateStudyPoints(List<Examen> exams) {
    return exams.fold(0, (points, exam) {
      if (exam.status == 'Completed') points += 100;
      if (exam.result != null && double.tryParse(exam.result!) != null) {
        points += (double.parse(exam.result!) * 10).toInt();
      }
      return points;
    });
  }

  // 🏆 Achievement System
  Widget _buildAchievementsSection() {
    return FutureBuilder<List<Examen>>(
      future: _future,
      builder: (context, snapshot) {
        final exams = snapshot.data ?? [];
        final achievements = _checkAchievements(exams);

        if (achievements.isEmpty) return const SizedBox();

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(16),
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
              const Text(
                '🏆 Succès Débloqués',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.darkGray,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: achievements.map((achievement) {
                  return Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: achievement.color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(achievement.icon, color: achievement.color, size: 16),
                        const SizedBox(width: 6),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              achievement.title,
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: achievement.color,
                                fontSize: 12,
                              ),
                            ),
                            Text(
                              achievement.description,
                              style: const TextStyle(
                                fontSize: 10,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        );
      },
    );
  }

  List<Achievement> _checkAchievements(List<Examen> exams) {
    final List<Achievement> unlocked = [];

    if (exams.any((e) => e.date.hour >= 20 && e.status == 'Completed')) {
      unlocked.add(Achievement(
        title: 'Night Owl',
        description: 'Examen après 20h',
        icon: Icons.nightlight_round,
        color: Colors.purple,
      ));
    }

    if (exams.any((e) => e.result == '100' || e.result == '20/20' || e.result == 'A+')) {
      unlocked.add(Achievement(
        title: 'Parfait!',
        description: 'Score parfait',
        icon: Icons.emoji_events,
        color: Colors.amber,
      ));
    }

    if (exams.any((e) => e.date.hour < 10)) {
      unlocked.add(Achievement(
        title: 'Early Bird',
        description: 'Examen avant 10h',
        icon: Icons.wb_sunny,
        color: Colors.orange,
      ));
    }

    if (exams.any((e) => e.dureeMinutes >= 180)) {
      unlocked.add(Achievement(
        title: 'Marathon',
        description: 'Examen 3h+',
        icon: Icons.directions_run,
        color: Colors.red,
      ));
    }

    final types = exams.map((e) => e.type).toSet();
    if (types.length >= 2) {
      unlocked.add(Achievement(
        title: 'Stratège',
        description: 'Types variés',
        icon: Icons.psychology,
        color: Colors.blue,
      ));
    }

    return unlocked;
  }

  // 📊 Visual Statistics
  Widget _buildStatsSection() {
    return FutureBuilder<List<Examen>>(
      future: _future,
      builder: (context, snapshot) {
        final exams = snapshot.data ?? [];
        final stats = _calculateStatistics(exams);

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              const Text(
                '📈 Statistiques',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.darkGray,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatItem('Moyenne', stats['average'] ?? 'N/A', Icons.trending_up),
                  _buildStatItem('Réussite', '${stats['successRate']}%', Icons.flag),
                  _buildStatItem('Heures', stats['studyHours'] ?? '0', Icons.access_time),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: AppColors.primaryRed, size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: AppColors.darkGray,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Map<String, dynamic> _calculateStatistics(List<Examen> exams) {
    final completedExams = exams.where((e) => e.status == 'Completed').toList();
    final gradedExams = completedExams.where((e) => e.result != null && _tryParseGrade(e.result!) != null).toList();

    double average = 0;
    if (gradedExams.isNotEmpty) {
      final total = gradedExams.fold(0.0, (sum, exam) => sum + _tryParseGrade(exam.result!)!);
      average = total / gradedExams.length;
    }

    final successRate = completedExams.isEmpty ? 0 : (completedExams.length / exams.length * 100).toInt();
    final totalStudyHours = exams.fold(0, (sum, exam) => sum + exam.dureeMinutes) ~/ 60;

    return {
      'average': average > 0 ? average.toStringAsFixed(1) : 'N/A',
      'successRate': successRate,
      'studyHours': totalStudyHours.toString(),
    };
  }

  double? _tryParseGrade(String grade) {
    if (grade.contains('/')) {
      final parts = grade.split('/');
      if (parts.length == 2) {
        final numerator = double.tryParse(parts[0]);
        final denominator = double.tryParse(parts[1]);
        if (numerator != null && denominator != null && denominator > 0) {
          return (numerator / denominator) * 20;
        }
      }
    } else if (grade.contains('%')) {
      final percent = double.tryParse(grade.replaceAll('%', ''));
      if (percent != null) return (percent / 100) * 20;
    } else {
      return double.tryParse(grade);
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightGray,
      appBar: AppBar(
        title: const Text(
          'Mes Examens',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 20,
            color: AppColors.white,
          ),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: AppColors.primaryRed,
        systemOverlayStyle: SystemUiOverlayStyle.light,
      ),
      body: Column(
        children: [
          // Header with stats
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: const BoxDecoration(
              color: AppColors.primaryRed,
            ),
            child: FutureBuilder<List<Examen>>(
              future: _future,
              builder: (context, snapshot) {
                final exams = snapshot.data ?? [];
                final upcoming = exams.where((e) => e.date.isAfter(DateTime.now())).length;
                final completed = exams.where((e) => e.status == 'Completed').length;

                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildHeaderStatItem(upcoming, 'À venir', Icons.upcoming_rounded),
                    _buildHeaderStatItem(completed, 'Terminés', Icons.check_circle_rounded),
                    _buildHeaderStatItem(exams.length, 'Total', Icons.event_note_rounded),
                  ],
                );
              },
            ),
          ),

          // Enhanced Sections
          _buildStreakHeader(),
          _buildStatsSection(),
          _buildAchievementsSection(),

          // Filter Chips
          Container(
            padding: const EdgeInsets.all(16),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFilterChip('Tous', 'all', Icons.all_inclusive_rounded),
                  const SizedBox(width: 8),
                  _buildFilterChip('À venir', 'upcoming', Icons.upcoming_rounded),
                  const SizedBox(width: 8),
                  _buildFilterChip('Terminés', 'completed', Icons.check_circle_rounded),
                  const SizedBox(width: 8),
                  _buildFilterChip('Annulés', 'cancelled', Icons.cancel_rounded),
                ],
              ),
            ),
          ),

          // Exams List
          Expanded(
            child: FutureBuilder<List<Examen>>(
              future: _future,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return _buildLoadingState();
                }

                if (snapshot.hasError) {
                  return _buildErrorState();
                }

                final exams = snapshot.data ?? [];
                final filteredExams = _filterExams(exams);

                if (filteredExams.isEmpty) {
                  return _buildEmptyState(exams.isEmpty);
                }

                return RefreshIndicator(
                  onRefresh: () async => _refresh(),
                  backgroundColor: AppColors.white,
                  color: AppColors.primaryRed,
                  child: ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    itemCount: filteredExams.length,
                    itemBuilder: (context, index) {
                      final exam = filteredExams[index];
                      return _buildExamCard(exam);
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          // Timeline/Calendar Button
          FloatingActionButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ExamenCalendarScreen()),
              );
            },
            heroTag: "timeline_button",
            backgroundColor: Colors.blue.shade600, // You can use Colors.blue.shade600 or define AppColors.blue
            child: const Icon(Icons.calendar_today, color: AppColors.white),
          ),
          const SizedBox(height: 16),
          // Quiz Generation Button
          FloatingActionButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const GenerateQuizScreen()),
              );
            },
            heroTag: "quiz_button",
            backgroundColor: AppColors.darkGray,
            child: const Icon(Icons.quiz, color: AppColors.white),
          ),
          const SizedBox(height: 16),
          // Add Exam Button
          FloatingActionButton(
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AddEditExamenScreen()),
              );
              _refresh();
            },
            heroTag: "add_exam_button",
            backgroundColor: AppColors.primaryRed,
            child: const Icon(Icons.add, color: AppColors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderStatItem(int count, String label, IconData icon) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: AppColors.white, size: 18),
        ),
        const SizedBox(height: 8),
        Text(
          count.toString(),
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppColors.white,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: AppColors.white.withOpacity(0.9),
          ),
        ),
      ],
    );
  }

  Widget _buildFilterChip(String label, String value, IconData icon) {
    final isSelected = _filter == value;
    return GestureDetector(
      onTap: () => setState(() => _filter = value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryRed : AppColors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppColors.primaryRed : AppColors.border,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected ? AppColors.white : AppColors.primaryRed,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: isSelected ? AppColors.white : AppColors.primaryRed,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExamCard(Examen e) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primaryRed,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    _examTypeIcon(e.type),
                    color: AppColors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        e.cours,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.darkGray,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.redLight,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          e.type.toUpperCase(),
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primaryRed,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                if (e.status != null) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _statusColor(e.status).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _statusIcon(e.status),
                          size: 12,
                          color: _statusColor(e.status),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          e.status!,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: _statusColor(e.status),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),

            const SizedBox(height: 12),

            // Date and time
            _buildInfoRow(
              icon: Icons.access_time_rounded,
              color: AppColors.primaryRed,
              title: _formatDateTime(e.date),
              subtitle: 'Durée: ${e.dureeMinutes} minutes',
            ),

            const SizedBox(height: 8),

            // Room information
            FutureBuilder<Salle?>(
              future: _getSalleForExam(e),
              builder: (context, snapshot) {
                final salle = snapshot.data;
                return _buildInfoRow(
                  icon: Icons.location_on_rounded,
                  color: Colors.green.shade600,
                  title: salle == null ? 'Salle non définie' : 'Salle ${salle.numero} - ${salle.batiment}',
                  subtitle: salle == null ? null : '${salle.capacite} places • ${salle.type}',
                );
              },
            ),

            // Notes
            if (e.notes != null && e.notes!.isNotEmpty) ...[
              const SizedBox(height: 8),
              _buildInfoSection(
                icon: Icons.note_rounded,
                color: Colors.orange.shade600,
                child: Text(
                  e.notes!,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.darkGray,
                  ),
                ),
              ),
            ],

            // Files
            if (e.files != null && e.files!.isNotEmpty) ...[
              const SizedBox(height: 8),
              _buildInfoSection(
                icon: Icons.attach_file_rounded,
                color: Colors.purple.shade600,
                child: Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: e.files!.map((f) {
                    final fileName = f.split('/').last;
                    return GestureDetector(
                      onTap: () => _openFile(f),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.purple.shade50,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          fileName,
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.purple.shade600,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],

            // Result
            if (e.result != null && e.result!.isNotEmpty) ...[
              const SizedBox(height: 8),
              _buildInfoSection(
                icon: Icons.grade_rounded,
                color: Colors.green.shade600,
                child: Text(
                  'Résultat: ${e.result!}',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.green.shade600,
                  ),
                ),
              ),
            ],

            // Actions
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => AddEditExamenScreen(examen: e),
                        ),
                      );
                      _refresh();
                    },
                    icon: const Icon(Icons.edit_rounded, size: 16),
                    label: const Text('Modifier'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primaryRed,
                      side: const BorderSide(color: AppColors.primaryRed),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _delete(e.id!),
                    icon: const Icon(Icons.delete_rounded, size: 16),
                    label: const Text('Supprimer'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryRed,
                      foregroundColor: AppColors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required Color color,
    required String title,
    String? subtitle,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(icon, color: color, size: 16),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: AppColors.darkGray,
                ),
              ),
              if (subtitle != null)
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInfoSection({
    required IconData icon,
    required Color color,
    required Widget child,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(icon, color: color, size: 16),
        ),
        const SizedBox(width: 10),
        Expanded(child: child),
      ],
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: CircularProgressIndicator(
        valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryRed),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline_rounded,
            size: 64,
            color: AppColors.textSecondary,
          ),
          const SizedBox(height: 16),
          const Text(
            'Une erreur est survenue',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: AppColors.darkGray,
            ),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: _refresh,
            child: const Text(
              'Réessayer',
              style: TextStyle(color: AppColors.primaryRed),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(bool isCompletelyEmpty) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isCompletelyEmpty ? Icons.event_busy_rounded : Icons.filter_list_off_rounded,
            size: 80,
            color: AppColors.textSecondary.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            isCompletelyEmpty ? 'Aucun examen' : 'Aucun examen trouvé',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.darkGray,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            isCompletelyEmpty
                ? 'Commencez par ajouter votre premier examen'
                : 'Essayez un autre filtre',
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
          if (isCompletelyEmpty) ...[
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AddEditExamenScreen()),
                );
                _refresh();
              },
              icon: const Icon(Icons.add),
              label: const Text('Ajouter un examen'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryRed,
                foregroundColor: AppColors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// Achievement Model
class Achievement {
  final String title;
  final String description;
  final IconData icon;
  final Color color;

  Achievement({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
  });
}