import 'package:compusflow/screens/auth/ResetPasswordScreen.dart';
import 'package:flutter/material.dart';
import 'package:compusflow/services/auth_service.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({Key? key}) : super(key: key);

  @override
  _ForgotPasswordScreenState createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final AuthService _authService = AuthService();
  final _emailController = TextEditingController();
  bool _isLoading = false;
  String? _message;

  // Nouvelles couleurs selon la charte
  static const Color primaryColor = Color(0xFFF53935); // Vivid Red
  static const Color backgroundColor = Color(0xFFF5F5F5); // Light Gray
  static const Color cardBackgroundColor = Color(0xFFFFFFFF); // Pure White
  static const Color primaryTextColor = Color(0xFF212121); // Dark Gray

  void _sendCode() async {
    setState(() {
      _isLoading = true;
      _message = null;
    });

    final result = await _authService.sendPasswordResetCode(
        email: _emailController.text.trim());

    setState(() {
      _isLoading = false;
      _message = result;
    });

    if (result.startsWith("Succes")) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ResetPasswordScreen(email: _emailController.text.trim()),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: cardBackgroundColor,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                    color: primaryTextColor.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 5)
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Icon(Icons.lock_reset, size: 70, color: primaryColor),
                const SizedBox(height: 16),
                Text(
                  "Mot de passe oublié",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: primaryTextColor
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  "Entrez votre email pour recevoir un code de vérification.",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: primaryTextColor.withOpacity(0.7)),
                ),
                const SizedBox(height: 24),
                TextField(
                  controller: _emailController,
                  style: TextStyle(color: primaryTextColor),
                  decoration: InputDecoration(
                    prefixIcon: Icon(Icons.email_outlined, color: primaryColor),
                    labelText: 'Email',
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
                    filled: true,
                    fillColor: cardBackgroundColor,
                  ),
                ),
                const SizedBox(height: 24),
                _isLoading
                    ? Center(child: CircularProgressIndicator(color: primaryColor))
                    : ElevatedButton(
                  onPressed: _sendCode,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: cardBackgroundColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    elevation: 3,
                    shadowColor: primaryColor.withOpacity(0.3),
                  ),
                  child: const Text(
                    "Envoyer le code",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
                if (_message != null) ...[
                  const SizedBox(height: 16),
                  Text(
                    _message!,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: _message!.startsWith("Erreur") ? primaryColor : primaryColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    "Retour à la connexion",
                    style: TextStyle(
                      color: primaryTextColor.withOpacity(0.7),
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}