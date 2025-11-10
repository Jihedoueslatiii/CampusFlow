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

  // Nouvelles couleurs selon la charte
  static const Color primaryColor = Color(0xFFF53935); // Vivid Red
  static const Color backgroundColor = Color(0xFFF5F5F5); // Light Gray
  static const Color cardBackgroundColor = Color(0xFFFFFFFF); // Pure White
  static const Color primaryTextColor = Color(0xFF212121); // Dark Gray

  // Regex pour une validation d'email plus robuste
  final RegExp _emailRegex = RegExp(
    r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
  );

  void _signUp() async {
    // 💡 Déclenche la validation des champs
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
          SnackBar(
            content: const Text(
              "L'inscription a échoué. L'email est peut-être déjà utilisé ou le mot de passe est trop faible.",
            ),
            backgroundColor: primaryColor,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text("Inscription réussie ✅"),
            backgroundColor: primaryColor,
          ),
        );
        // Naviguer vers l'écran de connexion après une inscription réussie
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
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: Card(
              elevation: 10,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              color: cardBackgroundColor,
              child: Padding(
                padding:
                const EdgeInsets.symmetric(horizontal: 24, vertical: 30),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Logo et titre UNIVERSITY APP
                      Column(
                        children: [
                          // Logo - remplacez par votre image si disponible
                          Container(
                            width: 70,
                            height: 70,
                            decoration: BoxDecoration(
                              color: primaryColor,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              Icons.school,
                              color: cardBackgroundColor,
                              size: 35,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            "UNIVERSITY APP",
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: primaryTextColor.withOpacity(0.8),
                              letterSpacing: 1.2,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),

                      Text(
                        "Créer un compte",
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: primaryTextColor,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Rejoignez la communauté CompusFlow 🎓",
                        style: TextStyle(
                          fontSize: 14,
                          color: primaryTextColor.withOpacity(0.7),
                        ),
                      ),
                      const SizedBox(height: 30),

                      // Champ nom
                      TextFormField(
                        controller: _nameController,
                        style: TextStyle(color: primaryTextColor),
                        decoration: _inputDecoration("Nom complet", Icons.person),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Veuillez entrer votre nom complet.';
                          }
                          if (value.length < 3) {
                            return 'Le nom doit contenir au moins 3 caractères.';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Champ email
                      TextFormField(
                        controller: _emailController,
                        style: TextStyle(color: primaryTextColor),
                        decoration: _inputDecoration("Email", Icons.email),
                        keyboardType: TextInputType.emailAddress,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Veuillez entrer une adresse email.';
                          }
                          // Utilisation de la RegExp pour valider le format
                          if (!_emailRegex.hasMatch(value)) {
                            return 'Veuillez entrer une adresse email valide.';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Champ mot de passe
                      TextFormField(
                        controller: _passwordController,
                        style: TextStyle(color: primaryTextColor),
                        decoration:
                        _inputDecoration("Mot de passe", Icons.lock),
                        obscureText: true,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Veuillez entrer un mot de passe.';
                          }
                          if (value.length < 6) {
                            return 'Le mot de passe doit faire au moins 6 caractères.';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Sélecteur de rôle
                      DropdownButtonFormField<String>(
                        value: _selectedRole,
                        style: TextStyle(color: primaryTextColor),
                        dropdownColor: cardBackgroundColor,
                        decoration: _inputDecoration("Je suis un...", Icons.people),
                        onChanged: (String? newValue) {
                          setState(() => _selectedRole = newValue!);
                        },
                        // La liste des rôles est limitée à 'etudiant' pour l'inscription
                        items: <String>['etudiant']
                            .map<DropdownMenuItem<String>>((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(
                              value[0].toUpperCase() + value.substring(1),
                              style: TextStyle(color: primaryTextColor),
                            ),
                          );
                        }).toList(),
                        // Pas besoin de valider, car une valeur par défaut est toujours sélectionnée
                        validator: (value) => null,
                      ),
                      const SizedBox(height: 30),

                      // Bouton
                      _isLoading
                          ? CircularProgressIndicator(color: primaryColor)
                          : ElevatedButton(
                        onPressed: _signUp,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          foregroundColor: cardBackgroundColor,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          minimumSize: const Size(double.infinity, 50),
                          elevation: 3,
                          shadowColor: primaryColor.withOpacity(0.3),
                        ),
                        child: const Text(
                          "Créer mon compte",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
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
                        child: RichText(
                          text: TextSpan(
                            style: TextStyle(
                              color: primaryTextColor.withOpacity(0.7),
                              fontSize: 14,
                            ),
                            children: [
                              const TextSpan(text: "Déjà un compte ? "),
                              TextSpan(
                                text: "Se connecter",
                                style: TextStyle(
                                  color: primaryColor,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
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
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: primaryTextColor.withOpacity(0.7)),
      prefixIcon: Icon(icon, color: primaryColor),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: primaryTextColor.withOpacity(0.3)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: primaryTextColor.withOpacity(0.3)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: primaryColor, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: primaryColor, width: 2),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: primaryColor, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
      filled: true,
      fillColor: backgroundColor.withOpacity(0.5),
    );
  }
}