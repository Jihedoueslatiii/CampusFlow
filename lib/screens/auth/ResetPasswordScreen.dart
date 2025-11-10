import 'package:flutter/material.dart';
import 'package:compusflow/services/auth_service.dart';
import 'package:compusflow/screens/auth/login_screen.dart';

class ResetPasswordScreen extends StatefulWidget {
  final String email;
  const ResetPasswordScreen({Key? key, required this.email}) : super(key: key);

  @override
  _ResetPasswordScreenState createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _codeController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authService = AuthService();
  bool _isLoading = false;
  String? _message;

  void _verifyAndReset() async {
    setState(() {
      _isLoading = true;
      _message = null;
    });

    final result = await _authService.verifyCodeAndResetPassword(
      email: widget.email,
      code: _codeController.text.trim(),
      newPassword: _passwordController.text.trim(),
    );

    setState(() {
      _isLoading = false;
      _message = result;
    });

    if (result == "Mot de passe reinitialise avec succes") {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Mot de passe réinitialisé !")),
      );

      // Redirection vers le LoginScreen et suppression de la pile
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
            (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Vérification du code")),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            Text("Un code de vérification a été envoyé à ${widget.email}"),
            const SizedBox(height: 16),
            TextField(
              controller: _codeController,
              decoration: const InputDecoration(
                labelText: "Code de vérification",
                prefixIcon: Icon(Icons.verified),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _passwordController,
              decoration: const InputDecoration(
                labelText: "Nouveau mot de passe",
                prefixIcon: Icon(Icons.lock_outline),
              ),
              obscureText: true,
            ),
            const SizedBox(height: 20),
            _isLoading
                ? const CircularProgressIndicator()
                : ElevatedButton(
              onPressed: _verifyAndReset,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2575FC),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text("Valider et réinitialiser",
                  style: TextStyle(fontSize: 16, color: Colors.white)),
            ),
            if (_message != null) ...[
              const SizedBox(height: 16),
              Text(
                _message!,
                style: TextStyle(
                  color: _message == "Mot de passe réinitialisé avec succès"
                      ? Colors.green
                      : Colors.red,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
