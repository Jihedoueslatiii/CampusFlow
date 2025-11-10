// screens/admin/admin_stats_screen.dart

import 'package:flutter/material.dart';
import 'package:compusflow/services/auth_service.dart';

// ====================================================================
// 1. WIDGET CUSTOM PAINTER POUR LE DIAGRAMME CIRCULAIRE (PIE CHART)
// ====================================================================
class PieChartPainter extends CustomPainter {
  final List<Map<String, dynamic>> segments;
  final double total;
  final Animation<double> animation;
  final double strokeWidth = 5.0; // Épaisseur des bordures

  PieChartPainter({required this.segments, required this.total, required this.animation})
      : super(repaint: animation);

  @override
  void paint(Canvas canvas, Size size) {
    if (total == 0) return;

    final double radius = size.width / 2 - strokeWidth / 2;
    final center = Offset(size.width / 2, size.height / 2);
    final rect = Rect.fromCircle(center: center, radius: radius);

    double startAngle = -90.0 * (3.1415926535 / 180.0); // Commencer par le haut
    double animatedSweep = animation.value;

    for (var segment in segments) {
      final double sweepAngle = (segment['percentage'] * 360.0) * (3.1415926535 / 180.0);
      double actualSweep = sweepAngle * animatedSweep;

      // Peinture du segment (remplissage)
      final Paint fillPaint = Paint()
        ..color = segment['color']
        ..style = PaintingStyle.fill;

      canvas.drawArc(
        rect,
        startAngle,
        actualSweep,
        true, // Centré pour Pie Chart
        fillPaint,
      );

      // Peinture de la bordure
      final Paint strokePaint = Paint()
        ..color = Colors.white.withOpacity(0.9) // Bordure blanche pour la séparation
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth;

      canvas.drawArc(
        rect,
        startAngle,
        actualSweep,
        false, // Non centré pour Stroke
        strokePaint,
      );

      startAngle += sweepAngle;
    }
  }

  @override
  bool shouldRepaint(covariant PieChartPainter oldDelegate) =>
      oldDelegate.animation.value != animation.value || oldDelegate.segments != segments;
}

// ====================================================================
// 2. ÉTAT DE L'ÉCRAN
// ====================================================================
class AdminStatsScreen extends StatefulWidget {
  const AdminStatsScreen({Key? key}) : super(key: key);

  @override
  State<AdminStatsScreen> createState() => _AdminStatsScreenState();
}

class _AdminStatsScreenState extends State<AdminStatsScreen> with SingleTickerProviderStateMixin {
  final AuthService _authService = AuthService();

  // Nouvelles couleurs selon la charte
  static const Color primaryColor = Color(0xFFF53935); // Vivid Red
  static const Color backgroundColor = Color(0xFFF5F5F5); // Light Gray
  static const Color cardBackgroundColor = Color(0xFFFFFFFF); // Pure White
  static const Color primaryTextColor = Color(0xFF212121); // Dark Gray

  late Future<Map<String, dynamic>> _statsFuture;

  // Contrôleur pour l'animation du Pie Chart
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    );
    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );
    _statsFuture = _fetchStats().then((data) {
      _animationController.forward(from: 0.0); // Démarre l'animation après le chargement
      return data;
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  // Récupère toutes les statistiques
  Future<Map<String, dynamic>> _fetchStats() async {
    final totalUsers = await _authService.getTotalUserCount();
    final roleDistribution = await _authService.getRoleDistribution();

    const activeProjects = 1;
    final Map<String, int> monthlySignups = {
      'Oct': 8,
      'Nov': 12,
      'Dec': 15,
    };

    return {
      'totalUsers': totalUsers,
      'roleDistribution': roleDistribution,
      'activeProjects': activeProjects,
      'monthlySignups': monthlySignups,
    };
  }

  // Méthode pour obtenir une couleur cohérente pour un rôle
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

  // 3. WIDGET AMÉLIORÉ : Carte de Statistique
  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      decoration: BoxDecoration(
        color: cardBackgroundColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: primaryTextColor.withOpacity(0.1),
            spreadRadius: 2,
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(icon, size: 36, color: color),
          const Spacer(),
          Text(
            value,
            style: TextStyle(
              fontSize: 34,
              fontWeight: FontWeight.w900,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
                fontSize: 14,
                color: primaryTextColor.withOpacity(0.7),
                fontWeight: FontWeight.w600
            ),
          ),
        ],
      ),
    );
  }

  // 4. WIDGET GRAPHE CIRCULAIRE (Pie Chart RÉEL)
  Widget _buildRolePieChart(Map<String, int> distribution, int total) {
    if (total == 0) {
      return Center(
        child: Text(
          "Aucun utilisateur à afficher.",
          style: TextStyle(color: primaryTextColor),
        ),
      );
    }

    final List<Map<String, dynamic>> segments = distribution.entries.map((entry) {
      final percentage = (entry.value / total);
      return {
        'role': entry.key,
        'count': entry.value,
        'percentage': percentage,
        'color': _getColorForRole(entry.key),
      };
    }).toList();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBackgroundColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: primaryTextColor.withOpacity(0.05), blurRadius: 10)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
              "Répartition des Rôles",
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: primaryTextColor
              )
          ),
          Divider(thickness: 1, color: primaryTextColor.withOpacity(0.3)),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Zone du Pie Chart (CustomPaint)
              Expanded(
                child: SizedBox(
                  width: 150,
                  height: 150,
                  child: CustomPaint(
                    painter: PieChartPainter(
                      segments: segments,
                      total: total.toDouble(),
                      animation: _animation,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              // Légende (à droite)
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: segments.map((s) {
                    final percentage = (s['percentage'] * 100).toStringAsFixed(1);
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: Row(
                        children: [
                          Container(width: 10, height: 10, color: s['color']),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              '${s['role'][0].toUpperCase()}${s['role'].substring(1)}: $percentage%',
                              style: TextStyle(
                                  fontSize: 14,
                                  color: primaryTextColor.withOpacity(0.8)
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // 5. WIDGET GRAPHE À BARRES (Bar Chart Simulé)
  Widget _buildMonthlyBarChart(Map<String, int> monthlySignups) {
    if (monthlySignups.isEmpty) {
      return Center(
        child: Text(
          "Aucune donnée d'inscription récente.",
          style: TextStyle(color: primaryTextColor),
        ),
      );
    }

    final maxCount = monthlySignups.values.reduce((a, b) => a > b ? a : b);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBackgroundColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: primaryTextColor.withOpacity(0.05), blurRadius: 10)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
              "Inscriptions Mensuelles",
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: primaryTextColor
              )
          ),
          Divider(thickness: 1, color: primaryTextColor.withOpacity(0.3)),
          const SizedBox(height: 16),
          SizedBox(
            height: 150,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: monthlySignups.entries.map((entry) {
                final normalizedHeight = (entry.value / maxCount) * 100;
                return Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                        entry.value.toString(),
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: primaryTextColor
                        )
                    ),
                    const SizedBox(height: 4),
                    Container(
                      height: normalizedHeight,
                      width: 40,
                      decoration: BoxDecoration(
                        color: primaryColor,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                        entry.key,
                        style: TextStyle(
                            fontSize: 14,
                            color: primaryTextColor.withOpacity(0.7)
                        )
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const Text(
          'Tableau de Bord Admin 📈',
          style: TextStyle(color: cardBackgroundColor),
        ),
        backgroundColor: primaryColor,
        elevation: 0,
        iconTheme: const IconThemeData(color: cardBackgroundColor),
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _statsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: CircularProgressIndicator(color: primaryColor),
            );
          }
          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Erreur de chargement: ${snapshot.error}',
                style: TextStyle(color: primaryTextColor),
              ),
            );
          }
          if (!snapshot.hasData || snapshot.data == null) {
            return Center(
              child: Text(
                'Aucune donnée de statistique trouvée.',
                style: TextStyle(color: primaryTextColor),
              ),
            );
          }

          final data = snapshot.data!;
          final int totalUsers = data['totalUsers'] as int;
          final Map<String, int> roleDistribution = data['roleDistribution'] as Map<String, int>;
          final int activeProjects = data['activeProjects'] as int;
          final Map<String, int> monthlySignups = data['monthlySignups'] as Map<String, int>;

          return RefreshIndicator(
            color: primaryColor,
            onRefresh: () async {
              setState(() {
                // Redémarrer l'animation après le rafraîchissement des données
                _statsFuture = _fetchStats().then((data) {
                  _animationController.forward(from: 0.0);
                  return data;
                });
              });
            },
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // --- Aperçu Global ---
                  Text(
                    "Aperçu Global",
                    style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: primaryTextColor
                    ),
                  ),
                  const SizedBox(height: 16),

                  GridView.count(
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    children: [
                      _buildStatCard(
                        "Total Utilisateurs",
                        totalUsers.toString(),
                        Icons.people_alt_outlined,
                        primaryColor, // Rouge vif pour le total
                      ),
                      _buildStatCard(
                        "Projets Actifs",
                        activeProjects.toString(),
                        Icons.folder_special_outlined,
                        Colors.green.shade700,
                      ),
                      _buildStatCard(
                        "Rôles Professeur",
                        (roleDistribution['professeur'] ?? 0).toString(),
                        Icons.school_outlined,
                        Colors.orange.shade700,
                      ),
                      _buildStatCard(
                        "Total Administrateurs",
                        (roleDistribution['admin'] ?? 0).toString(),
                        Icons.admin_panel_settings_outlined,
                        primaryColor, // Rouge vif pour admin
                      ),
                    ],
                  ),
                  const SizedBox(height: 30),

                  // --- Graphique des Rôles (Pie Chart RÉEL) ---
                  _buildRolePieChart(roleDistribution, totalUsers),
                  const SizedBox(height: 30),

                  // --- Graphique des Inscriptions (Bar Chart Simulé) ---
                  _buildMonthlyBarChart(monthlySignups),
                  const SizedBox(height: 50),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}