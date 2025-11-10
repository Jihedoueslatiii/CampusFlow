import 'package:campusflow/screens/salle_map_screen.dart';
import 'package:flutter/material.dart';
import 'examen_list_screen.dart';
import 'salle_list_screen.dart';
import 'features_dashboard_screen.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text(
          "Campus Flow",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.indigo.shade600,
        foregroundColor: Colors.white,
        elevation: 0,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(20),
          ),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.indigo.shade600,
              Colors.indigo.shade100,
              Colors.white,
            ],
            stops: const [0.0, 0.1, 0.3],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Welcome Section
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.indigo.shade600,
                        Colors.indigo.shade400,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.indigo.withOpacity(0.3),
                        blurRadius: 15,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.school_rounded,
                          color: Colors.white,
                          size: 40,
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        "Welcome to Campus Flow 🎓",
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Manage your campus resources efficiently",
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white.withOpacity(0.9),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // Feature Buttons
                Expanded(
                  child: ListView(
                    children: [
                      _buildFeatureButton(
                        context,
                        title: "Manage Exams",
                        subtitle: "Schedule and organize examinations",
                        icon: Icons.assignment_rounded,
                        color: Colors.indigo,
                        screen: const ExamenListScreen(),
                      ),
                      const SizedBox(height: 12),
                      _buildFeatureButton(
                        context,
                        title: "Manage Rooms",
                        subtitle: "View and edit room details in list format",
                        icon: Icons.meeting_room_rounded,
                        color: Colors.teal,
                        screen: const SalleListScreen(),
                      ),
                      const SizedBox(height: 12),
                      _buildFeatureButton(
                        context,
                        title: "Campus Overview",
                        subtitle: "Interactive map with room locations",
                        icon: Icons.map_rounded,
                        color: Colors.orange,
                        screen: const SalleMapScreen(),
                      ),
                      const SizedBox(height: 12),
                      _buildFeatureButton(
                        context,
                        title: "Features Dashboard",
                        subtitle: "Explore all app features and roadmap",
                        icon: Icons.dashboard_rounded,
                        color: Colors.purple,
                        screen: const FeaturesDashboardScreen(),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureButton(
      BuildContext context, {
        required String title,
        required String subtitle,
        required IconData icon,
        required MaterialColor color,
        required Widget screen,
      }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => screen),
          );
        },
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                color.shade50,
                color.shade100,
              ],
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: color.withOpacity(0.3)),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: color.shade800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: color.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                color: color.shade400,
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }
}