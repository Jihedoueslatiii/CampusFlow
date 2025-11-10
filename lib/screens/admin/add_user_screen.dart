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
          const SnackBar(content: Text("Utilisateur créé avec succès ✅")),
        );
        Navigator.pop(context); // Retour à la liste des utilisateurs
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Erreur : Email déjà utilisé ou autre problème")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Ajouter un utilisateur"),
        backgroundColor: const Color(0xFF2575FC),
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
                  decoration: InputDecoration(
                    labelText: "Nom",
                    prefixIcon: const Icon(Icons.person_outline),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
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
                  decoration: InputDecoration(
                    labelText: "Email",
                    prefixIcon: const Icon(Icons.email_outlined),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
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
                  decoration: InputDecoration(
                    labelText: "Mot de passe",
                    prefixIcon: const Icon(Icons.lock_outline),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
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
                // Le DropdownButtonFormField n'a pas besoin d'une validation aussi stricte
                // si la valeur par défaut est toujours définie.
                DropdownButtonFormField<String>(
                  value: _role,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    prefixIcon: const Icon(Icons.admin_panel_settings),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'admin', child: Text('Admin')),
                    DropdownMenuItem(value: 'professeur', child: Text('Professeur')),
                    DropdownMenuItem(value: 'etudiant', child: Text('Etudiant')),
                  ],
                  onChanged: (val) => setState(() => _role = val!),
                ),
                const SizedBox(height: 20),
                _isLoading
                    ? const CircularProgressIndicator()
                    : ElevatedButton(
                  onPressed: _addUser,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2575FC),
                    padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 40),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text("Ajouter", style: TextStyle(fontSize: 16, color: Colors.white)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}