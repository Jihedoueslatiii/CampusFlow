// lib/screens/auth/signup_screen.dart

import 'package:compusflow/screens/auth/login_screen.dart';
import 'package:flutter/material.dart';
import 'package:compusflow/services/auth_service.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({Key? key}) : super(key: key);

  @override
  _SignUpScreenState createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final AuthService _authService = AuthService();
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  String _selectedRole = 'etudiant'; // <-- Rôle par défaut
  bool _isLoading = false;

  void _signUp() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      final userCredential = await _authService.signUp(
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
        role: _selectedRole,
      );
      if (!mounted) return;
      setState(() => _isLoading = false);
      if (userCredential == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              "L'inscription a échoué. L'email est peut-être déjà utilisé.",
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Inscription réussie ✅")),
        );
        // Optionnel : Naviguer vers l'écran de connexion après une inscription réussie
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF3A7BD5), Color(0xFF00D2FF)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              child: Card(
                elevation: 10,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Padding(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 24, vertical: 30),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          "Créer un compte",
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF3A7BD5),
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          "Rejoignez la communauté CompusFlow 🎓",
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.black54,
                          ),
                        ),
                        const SizedBox(height: 30),

                        // Champ nom
                        TextFormField(
                          controller: _nameController,
                          decoration: _inputDecoration("Nom complet", Icons.person),
                          validator: (value) =>
                          value!.isEmpty ? 'Veuillez entrer un nom' : null,
                        ),
                        const SizedBox(height: 16),

                        // Champ email
                        TextFormField(
                          controller: _emailController,
                          decoration: _inputDecoration("Email", Icons.email),
                          keyboardType: TextInputType.emailAddress,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Veuillez entrer un email';
                            }
                            if (!RegExp(r'\S+@\S+\.\S+').hasMatch(value)) {
                              return 'Veuillez entrer un email valide';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        // Champ mot de passe
                        TextFormField(
                          controller: _passwordController,
                          decoration:
                          _inputDecoration("Mot de passe", Icons.lock),
                          obscureText: true,
                          validator: (value) => value!.length < 6
                              ? 'Le mot de passe doit faire 6+ caractères'
                              : null,
                        ),
                        const SizedBox(height: 16),

                        // Sélecteur de rôle
                        DropdownButtonFormField<String>(
                          value: _selectedRole,
                          decoration: _inputDecoration("Je suis un...", Icons.people),
                          onChanged: (String? newValue) {
                            setState(() => _selectedRole = newValue!);
                          },
                          items: <String>['etudiant']
                              .map<DropdownMenuItem<String>>((String value) {
                            return DropdownMenuItem<String>(
                              value: value,
                              child: Text(
                                value[0].toUpperCase() + value.substring(1),
                              ),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 30),

                        // Bouton
                        _isLoading
                            ? const CircularProgressIndicator()
                            : ElevatedButton(
                          onPressed: _signUp,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF3A7BD5),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            minimumSize: const Size(double.infinity, 50),
                          ),
                          child: const Text(
                            "Créer mon compte",
                            style: TextStyle(
                                fontSize: 16, color: Colors.white),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Lien connexion
                        TextButton(
                          onPressed: () => Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const LoginScreen()),
                          ),
                          child: const Text(
                            "Déjà un compte ? Se connecter",
                            style: TextStyle(
                                color: Color(0xFF3A7BD5),
                                fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: const Color(0xFF3A7BD5)),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      focusedBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: Color(0xFF3A7BD5), width: 2),
        borderRadius: BorderRadius.circular(12),
      ),
      contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
    );
  }
}