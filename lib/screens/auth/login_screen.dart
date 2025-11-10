import 'package:compusflow/screens/auth/forgot_password_screen.dart';
import 'package:compusflow/screens/auth/signup_screen.dart';
import 'package:compusflow/services/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:compusflow/screens/wrapper.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final AuthService _authService = AuthService();
  // Clé pour gérer l'état du formulaire et la validation
  final _formKey = GlobalKey<FormState>();

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  // Nouvelles couleurs selon la charte
  static const Color primaryColor = Color(0xFFF53935); // Vivid Red
  static const Color backgroundColor = Color(0xFFF5F5F5); // Light Gray
  static const Color cardBackgroundColor = Color(0xFFFFFFFF); // Pure White
  static const Color primaryTextColor = Color(0xFF212121); // Dark Gray

  // Regex pour la validation de l'email
  final RegExp _emailRegex = RegExp(
    r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
  );

  void _login() async {
    // 1. Déclencher la validation des champs
    if (!_formKey.currentState!.validate()) {
      setState(() => _errorMessage = null); // Effacer l'erreur de connexion précédente si les erreurs de validation sont présentes
      return;
    }

    // Si la validation du formulaire est OK, on tente la connexion
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final userCredential = await _authService.signIn(
      email: _emailController.text.trim(),
      password: _passwordController.text.trim(),
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (userCredential == null) {
      // 2. Afficher l'erreur si l'authentification échoue
      setState(() => _errorMessage = 'Email ou mot de passe incorrect');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Email ou mot de passe incorrect.'),
          backgroundColor: primaryColor,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Connexion réussie !'),
          backgroundColor: primaryColor,
        ),
      );
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const Wrapper()),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    // Rediriger si déjà connecté
    _authService.getCurrentUser().then((user) {
      if (user != null && mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const Wrapper()),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form( // Ajout du widget Form
            key: _formKey, // Association de la clé
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: cardBackgroundColor,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: primaryTextColor.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Logo CampusFlow
                  Column(
                    children: [
                      Image.asset(
                        'assets/images/logo.png',
                        height: 200,
                        width: 200,
                        errorBuilder: (context, error, stackTrace) {
                          // Fallback si l'image n'est pas trouvée
                          return Column(
                            children: [
                              Text(
                                "CampusFlow",
                                style: TextStyle(
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold,
                                  color: primaryColor,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                "UNIVERSITY APP",
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: primaryTextColor.withOpacity(0.7),
                                  letterSpacing: 1.5,
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "UNIVERSITY APP",
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: primaryTextColor.withOpacity(0.7),
                          letterSpacing: 1.5,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Text(
                    "Connexion",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: primaryTextColor,
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Champ Email avec validation
                  TextFormField(
                    controller: _emailController,
                    style: TextStyle(color: primaryTextColor),
                    decoration: _inputDecoration('Email', Icons.email_outlined),
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Veuillez entrer votre email.';
                      }
                      if (!_emailRegex.hasMatch(value.trim())) {
                        return 'Veuillez entrer une adresse email valide.';
                      }
                      return null;
                    },
                    onChanged: (_) => setState(() => _errorMessage = null),
                  ),
                  const SizedBox(height: 16),
                  // Champ Mot de passe avec validation
                  TextFormField(
                    controller: _passwordController,
                    style: TextStyle(color: primaryTextColor),
                    decoration: _inputDecoration('Mot de passe', Icons.lock_outline),
                    obscureText: true,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Veuillez entrer votre mot de passe.';
                      }
                      return null;
                    },
                    onChanged: (_) => setState(() => _errorMessage = null),
                    onFieldSubmitted: (_) => _login(),
                  ),
                  if (_errorMessage != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      _errorMessage!,
                      style: TextStyle(color: primaryColor, fontSize: 14),
                      textAlign: TextAlign.center,
                    ),
                  ],
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const ForgotPasswordScreen()),
                      ),
                      child: Text(
                        'Mot de passe oublié ?',
                        style: TextStyle(color: primaryColor),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _isLoading
                      ? Center(child: CircularProgressIndicator(color: primaryColor))
                      : ElevatedButton(
                    onPressed: _login,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      foregroundColor: cardBackgroundColor,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      elevation: 3,
                      shadowColor: primaryColor.withOpacity(0.3),
                    ),
                    child: const Text(
                      'Se connecter',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () => Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (_) => const SignUpScreen()),
                    ),
                    child: Text(
                      "Pas encore de compte ? S'inscrire",
                      style: TextStyle(color: primaryTextColor.withOpacity(0.7)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Fonction utilitaire pour l'InputDecoration (pour uniformiser le style)
  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      prefixIcon: Icon(icon, color: primaryColor),
      labelText: label,
      labelStyle: TextStyle(color: primaryTextColor.withOpacity(0.7)),
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
      fillColor: cardBackgroundColor,
    );
  }
}