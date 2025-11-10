import 'package:compusflow/services/auth_service.dart';
import 'package:flutter/material.dart';

class UpdateProfileScreen extends StatefulWidget {
  const UpdateProfileScreen({Key? key}) : super(key: key);

  @override
  _UpdateProfileScreenState createState() => _UpdateProfileScreenState();
}

class _UpdateProfileScreenState extends State<UpdateProfileScreen> {
  final AuthService _authService = AuthService();
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  // Nouvelles couleurs selon la charte
  static const Color primaryColor = Color(0xFFF53935); // Vivid Red
  static const Color backgroundColor = Color(0xFFF5F5F5); // Light Gray
  static const Color cardBackgroundColor = Color(0xFFFFFFFF); // Pure White
  static const Color primaryTextColor = Color(0xFF212121); // Dark Gray

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    final user = await _authService.getCurrentUser();
    if (user != null) {
      // S'assurer que le nom est chargé pour la modification
      setState(() {
        _nameController.text = user['name'] ?? '';
      });
    }
  }

  Future<void> _updateProfile() async {
    // Vérifie la validité de l'intégralité du formulaire
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      final result = await _authService.updateUserData(
        name: _nameController.text.trim(),
        // Le service gère l'envoi du mot de passe uniquement s'il est non vide
        password: _passwordController.text.trim(),
      );

      if (mounted) {
        setState(() => _isLoading = false);

        final isSuccess = result == "Succès";

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isSuccess ? "Profil mis à jour avec succès ! ✅" : result),
            backgroundColor: primaryColor,
          ),
        );

        if (isSuccess) {
          Navigator.pop(context);
        }
      }
    }
  }

  // Fonction pour basculer la visibilité du mot de passe
  void _togglePasswordVisibility(bool isConfirmField) {
    setState(() {
      if (isConfirmField) {
        _obscureConfirmPassword = !_obscureConfirmPassword;
      } else {
        _obscurePassword = !_obscurePassword;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const Text(
          "Mettre à jour le profil",
          style: TextStyle(color: cardBackgroundColor),
        ),
        backgroundColor: primaryColor,
        iconTheme: const IconThemeData(color: cardBackgroundColor),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // --- Champ Nom (Validation obligatoire) ---
                TextFormField(
                  controller: _nameController,
                  style: TextStyle(color: primaryTextColor),
                  decoration: _inputDecoration(
                    'Nom complet',
                    Icons.person,
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Veuillez entrer un nom.';
                    }
                    if (value.length < 3) {
                      return 'Le nom doit contenir au moins 3 caractères.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),

                // --- Section Changement de mot de passe ---
                Text(
                  "Changer le mot de passe",
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: primaryTextColor
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "Laissez les champs vides si vous ne souhaitez pas modifier le mot de passe.",
                  style: TextStyle(color: primaryTextColor.withOpacity(0.6)),
                ),
                const SizedBox(height: 16),

                // --- Champ Nouveau Mot de passe (Validation de longueur si rempli) ---
                TextFormField(
                  controller: _passwordController,
                  style: TextStyle(color: primaryTextColor),
                  obscureText: _obscurePassword,
                  decoration: _inputDecoration(
                    'Nouveau mot de passe',
                    Icons.lock,
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword ? Icons.visibility_off : Icons.visibility,
                        color: primaryTextColor.withOpacity(0.6),
                      ),
                      onPressed: () => _togglePasswordVisibility(false),
                    ),
                  ),
                  validator: (value) {
                    // Valider uniquement si le champ n'est pas vide (l'utilisateur veut changer le mot de passe)
                    if (value != null && value.isNotEmpty && value.length < 6) {
                      return 'Le mot de passe doit faire au moins 6 caractères';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // --- Champ Confirmer Mot de passe (Validation de correspondance si le nouveau mot de passe est rempli) ---
                TextFormField(
                  controller: _confirmPasswordController,
                  style: TextStyle(color: primaryTextColor),
                  obscureText: _obscureConfirmPassword,
                  decoration: _inputDecoration(
                    'Confirmer le mot de passe',
                    Icons.lock_outline,
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureConfirmPassword ? Icons.visibility_off : Icons.visibility,
                        color: primaryTextColor.withOpacity(0.6),
                      ),
                      onPressed: () => _togglePasswordVisibility(true),
                    ),
                  ),
                  validator: (value) {
                    final newPassword = _passwordController.text;

                    // Si le champ du nouveau mot de passe est rempli, la confirmation est obligatoire
                    if (newPassword.isNotEmpty && (value == null || value.isEmpty)) {
                      return 'Veuillez confirmer le mot de passe.';
                    }

                    // Vérifier la correspondance si les deux champs sont remplis
                    if (newPassword.isNotEmpty && value != newPassword) {
                      return 'Les mots de passe ne correspondent pas.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 32),

                // --- Bouton de soumission ---
                _isLoading
                    ? Center(child: CircularProgressIndicator(color: primaryColor))
                    : ElevatedButton(
                  onPressed: _updateProfile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: cardBackgroundColor,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    minimumSize: const Size(double.infinity, 50),
                    elevation: 3,
                    shadowColor: primaryColor.withOpacity(0.3),
                  ),
                  child: const Text(
                    'Enregistrer les modifications',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Style commun pour les champs de saisie
  InputDecoration _inputDecoration(String label, IconData icon, {Widget? suffixIcon}) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: primaryTextColor.withOpacity(0.7)),
      prefixIcon: Icon(icon, color: primaryColor),
      suffixIcon: suffixIcon,
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
      filled: true,
      fillColor: cardBackgroundColor,
      contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
    );
  }
}