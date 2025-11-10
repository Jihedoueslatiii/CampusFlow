import 'package:compusflow/services/auth_service.dart';
import 'package:flutter/material.dart';

class AccountDetailsScreen extends StatelessWidget {
  const AccountDetailsScreen({Key? key}) : super(key: key);

  // Nouvelles couleurs selon la charte
  static const Color primaryColor = Color(0xFFF53935); // Vivid Red
  static const Color backgroundColor = Color(0xFFF5F5F5); // Light Gray
  static const Color cardBackgroundColor = Color(0xFFFFFFFF); // Pure White
  static const Color primaryTextColor = Color(0xFF212121); // Dark Gray

  @override
  Widget build(BuildContext context) {
    final AuthService authService = AuthService();

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const Text(
          "Détails du Compte",
          style: TextStyle(color: cardBackgroundColor),
        ),
        backgroundColor: primaryColor,
        iconTheme: const IconThemeData(color: cardBackgroundColor),
        elevation: 0,
      ),
      body: FutureBuilder<Map<String, dynamic>?>(
        future: authService.getCurrentUser(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: CircularProgressIndicator(color: primaryColor),
            );
          }
          if (!snapshot.hasData || snapshot.data == null) {
            return Center(
              child: Text(
                "Impossible de charger les données.",
                style: TextStyle(color: primaryTextColor),
              ),
            );
          }

          final userData = snapshot.data!;

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              color: cardBackgroundColor,
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildDetailRow(context, Icons.person, "Nom complet", userData['name'] ?? 'Non défini'),
                    const Divider(height: 30),
                    _buildDetailRow(context, Icons.email, "Email", userData['email'] ?? 'Non défini'),
                    const Divider(height: 30),
                    _buildDetailRow(context, Icons.badge, "Rôle", _formatRole(userData['role'] ?? 'Non défini')),
                    const Divider(height: 30),
                    _buildDetailRow(context, Icons.vpn_key, "User ID", userData['id']?.toString() ?? 'Non défini'),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  String _formatRole(dynamic role) {
    if (role == null) return 'Non défini';
    final roleString = role.toString();
    return roleString[0].toUpperCase() + roleString.substring(1);
  }

  Widget _buildDetailRow(BuildContext context, IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: primaryColor, size: 28),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  color: primaryTextColor.withOpacity(0.6),
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: primaryTextColor,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}