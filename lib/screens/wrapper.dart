import 'package:compusflow/screens/auth/login_screen.dart';
import 'package:compusflow/screens/home/home_screen.dart';
import 'package:compusflow/services/auth_service.dart';
import 'package:flutter/material.dart';

class Wrapper extends StatelessWidget {
  const Wrapper({Key? key}) : super(key: key);

  Future<Map<String, dynamic>?> _getCurrentUser() async {
    final authService = AuthService();
    return await authService.getCurrentUser();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>?>(
      future: _getCurrentUser(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasError) {
          return Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text('Erreur: ${snapshot.error}'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => (context as Element).reassemble(),
                    child: const Text('Réessayer'),
                  ),
                ],
              ),
            ),
          );
        }
        final user = snapshot.data;
        if (user != null && user.isNotEmpty) {
          return const HomeScreen();
        } else {
          return const LoginScreen();
        }
      },
    );
  }
}
