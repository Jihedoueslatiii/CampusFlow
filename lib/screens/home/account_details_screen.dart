import 'package:compusflow/services/auth_service.dart';
import 'package:flutter/material.dart';

class AccountDetailsScreen extends StatelessWidget {
  const AccountDetailsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final AuthService authService = AuthService();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Détails du Compte"),
      ),
      body: FutureBuilder<Map<String, dynamic>?>(
        future: authService.getCurrentUser(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data == null) {
            return const Center(child: Text("Impossible de charger les données."));
          }

          final userData = snapshot.data!;

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
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
        Icon(icon, color: Theme.of(context).primaryColor, size: 28),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(fontSize: 14, color: Colors.grey),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      ],
    );
  }
}