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
        const SnackBar(content: Text('Email ou mot de passe incorrect.')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Connexion réussie !')),
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
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF6A11CB), Color(0xFF2575FC)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form( // Ajout du widget Form
              key: _formKey, // Association de la clé
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: const [
                    BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, 5)),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Icon(Icons.lock_outline, size: 70, color: Color(0xFF2575FC)),
                    const SizedBox(height: 16),
                    const Text(
                      "Connexion",
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 24),
                    // Champ Email avec validation
                    TextFormField(
                      controller: _emailController,
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
                        style: const TextStyle(color: Colors.red, fontSize: 14),
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
                        child: const Text('Mot de passe oublié ?'),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _isLoading
                        ? const Center(child: CircularProgressIndicator(color: Color(0xFF2575FC)))
                        : ElevatedButton(
                      onPressed: _login,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2575FC),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Text('Se connecter',
                          style: TextStyle(fontSize: 16, color: Colors.white)),
                    ),
                    const SizedBox(height: 16),
                    TextButton(
                      onPressed: () => Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (_) => const SignUpScreen()),
                      ),
                      child: const Text("Pas encore de compte ? S'inscrire"),
                    ),
                  ],
                ),
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
      prefixIcon: Icon(icon, color: const Color(0xFF2575FC)),
      labelText: label,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      focusedBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: Color(0xFF2575FC), width: 2),
        borderRadius: BorderRadius.circular(12),
      ),
      errorBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: Colors.red, width: 2),
        borderRadius: BorderRadius.circular(12),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: Colors.red, width: 2),
        borderRadius: BorderRadius.circular(12),
      ),
      contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
    );
  }
}