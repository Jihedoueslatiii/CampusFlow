import 'package:flutter/material.dart';
import 'package:compusflow/services/auth_service.dart';

class AddUserScreen extends StatefulWidget {
  const AddUserScreen({Key? key}) : super(key: key);

  @override
  State<AddUserScreen> createState() => _AddUserScreenState();
}

class _AddUserScreenState extends State<AddUserScreen> {
  // Clé pour identifier le formulaire et valider les champs
  final _formKey = GlobalKey<FormState>();
  final AuthService _authService = AuthService();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  String _role = 'etudiant';
  bool _isLoading = false;

  // Nouvelles couleurs selon la charte
  static const Color primaryColor = Color(0xFFF53935); // Vivid Red
  static const Color backgroundColor = Color(0xFFF5F5F5); // Light Gray
  static const Color cardBackgroundColor = Color(0xFFFFFFFF); // Pure White
  static const Color primaryTextColor = Color(0xFF212121); // Dark Gray

  // Expression régulière simple pour la validation de l'email
  final RegExp _emailRegex = RegExp(
    r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
    caseSensitive: false,
    multiLine: false,
  );

  void _addUser() async {
    // Valider tous les champs du formulaire
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      // Utiliser signUp pour créer un nouvel utilisateur (comme un admin)
      final result = await _authService.signUp(
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
        role: _role,
      );

      setState(() => _isLoading = false);

      if (result != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text("Utilisateur créé avec succès ✅"),
            backgroundColor: primaryColor,
          ),
        );
        Navigator.pop(context); // Retour à la liste des utilisateurs
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text("Erreur : Email déjà utilisé ou autre problème"),
            backgroundColor: primaryColor,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const Text(
          "Ajouter un utilisateur",
          style: TextStyle(color: cardBackgroundColor),
        ),
        backgroundColor: primaryColor,
        elevation: 0,
        iconTheme: const IconThemeData(color: cardBackgroundColor),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        // Utiliser Form pour la validation
        child: Form(
          key: _formKey, // Associer la clé au formulaire
          child: SingleChildScrollView(
            child: Column(
              children: [
                // TextFormField pour la validation du Nom
                TextFormField(
                  controller: _nameController,
                  style: TextStyle(color: primaryTextColor),
                  decoration: InputDecoration(
                    labelText: "Nom",
                    labelStyle: TextStyle(color: primaryTextColor.withOpacity(0.7)),
                    prefixIcon: Icon(Icons.person_outline, color: primaryColor),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: primaryTextColor.withOpacity(0.3)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: primaryColor),
                    ),
                    filled: true,
                    fillColor: cardBackgroundColor,
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Veuillez entrer le nom.';
                    }
                    if (value.length < 3) {
                      return 'Le nom doit contenir au moins 3 caractères.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                // TextFormField pour la validation de l'Email
                TextFormField(
                  controller: _emailController,
                  style: TextStyle(color: primaryTextColor),
                  decoration: InputDecoration(
                    labelText: "Email",
                    labelStyle: TextStyle(color: primaryTextColor.withOpacity(0.7)),
                    prefixIcon: Icon(Icons.email_outlined, color: primaryColor),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: primaryTextColor.withOpacity(0.3)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: primaryColor),
                    ),
                    filled: true,
                    fillColor: cardBackgroundColor,
                  ),
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Veuillez entrer une adresse email.';
                    }
                    if (!_emailRegex.hasMatch(value.trim())) {
                      return 'Veuillez entrer une adresse email valide.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                // TextFormField pour la validation du Mot de passe
                TextFormField(
                  controller: _passwordController,
                  style: TextStyle(color: primaryTextColor),
                  decoration: InputDecoration(
                    labelText: "Mot de passe",
                    labelStyle: TextStyle(color: primaryTextColor.withOpacity(0.7)),
                    prefixIcon: Icon(Icons.lock_outline, color: primaryColor),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: primaryTextColor.withOpacity(0.3)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: primaryColor),
                    ),
                    filled: true,
                    fillColor: cardBackgroundColor,
                  ),
                  obscureText: true,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Veuillez entrer un mot de passe.';
                    }
                    if (value.length < 6) {
                      return 'Le mot de passe doit contenir au moins 6 caractères.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                // DropdownButtonFormField pour le rôle
                DropdownButtonFormField<String>(
                  value: _role,
                  style: TextStyle(color: primaryTextColor),
                  dropdownColor: cardBackgroundColor,
                  decoration: InputDecoration(
                    labelText: "Rôle",
                    labelStyle: TextStyle(color: primaryTextColor.withOpacity(0.7)),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: primaryTextColor.withOpacity(0.3)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: primaryColor),
                    ),
                    prefixIcon: Icon(Icons.admin_panel_settings, color: primaryColor),
                    filled: true,
                    fillColor: cardBackgroundColor,
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: 'admin',
                      child: Text('Admin'),
                    ),
                    DropdownMenuItem(
                      value: 'professeur',
                      child: Text('Professeur'),
                    ),
                    DropdownMenuItem(
                      value: 'etudiant',
                      child: Text('Etudiant'),
                    ),
                  ],
                  onChanged: (val) => setState(() => _role = val!),
                ),
                const SizedBox(height: 30),
                _isLoading
                    ? CircularProgressIndicator(color: primaryColor)
                    : ElevatedButton(
                  onPressed: _addUser,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: cardBackgroundColor,
                    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 40),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 3,
                    shadowColor: primaryColor.withOpacity(0.3),
                  ),
                  child: const Text(
                    "Ajouter",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    "Annuler",
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