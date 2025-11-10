import 'package:compusflow/screens/auth/login_screen.dart';
import 'package:compusflow/screens/home/home_screen.dart';
import 'package:compusflow/services/auth_service.dart';
import 'package:flutter/material.dart';

class Wrapper extends StatelessWidget {
  const Wrapper({Key? key}) : super(key: key);

  Future<Map<String, dynamic>?> _getCurrentUser() async {
    try {
      final authService = AuthService();
      return await authService.getCurrentUser();
    } catch (e) {
      print('Erreur Wrapper: $e');
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>?>(
      future: _getCurrentUser(),
      builder: (context, snapshot) {
        // État de chargement
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Chargement...'),
                ],
              ),
            ),
          );
        }

        // Erreur
        if (snapshot.hasError) {
          print('Erreur dans Wrapper: ${snapshot.error}');
          return Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  const Text(
                    'Erreur de chargement',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${snapshot.error}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (context) => const Wrapper()),
                      );
                    },
                    child: const Text('Réessayer'),
                  ),
                ],
              ),
            ),
          );
        }

        // Vérification de l'utilisateur
        final user = snapshot.data;

        // DEBUG - Affichez l'utilisateur dans la console
        print('🔐 Wrapper - Utilisateur actuel: $user');

        if (user != null && user.isNotEmpty) {
          print('🚀 Redirection vers HomeScreen');
          return const HomeScreen();
        } else {
          print('🔑 Redirection vers LoginScreen');
          return const LoginScreen();
        }
      },
    );
  }
}