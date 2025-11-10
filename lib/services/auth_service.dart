import 'package:shared_preferences/shared_preferences.dart';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';
import 'dart:convert'; // Ajouté pour l'encodage/décodage JSON si nécessaire, bien que vous utilisiez déjà un format pipe |

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  static const String _userKey = 'current_user';
  static const String _isLoggedInKey = 'is_logged_in';
  static const String _usersListKey = 'users_list';

  // Utilisateur admin par défaut
  final Map<String, dynamic> _defaultAdmin = {
    'id': 1,
    'email': 'admin@compusflow.com',
    'name': 'Administrateur',
    'password': 'admin123',
    'role': 'admin',
    'created_at': '2024-01-01T00:00:00.000Z',
  };

  // ----------- AUTHENTIFICATION -----------

  Future<Map<String, dynamic>?> getCurrentUser() async {
    final prefs = await SharedPreferences.getInstance();
    final isLoggedIn = prefs.getBool(_isLoggedInKey) ?? false;
    if (!isLoggedIn) return null;

    final userJson = prefs.getString(_userKey);
    if (userJson != null) {
      return _parseUserData(userJson);
    }
    return null;
  }

  Future<Map<String, dynamic>?> signIn({
    required String email,
    required String password,
  }) async {
    try {
      // Vérification admin par défaut
      if (email == _defaultAdmin['email'] && password == _defaultAdmin['password']) {
        await _saveUserToPrefs(_defaultAdmin);
        return _defaultAdmin;
      }

      final users = await _getAllUsersFromPrefs();
      for (var user in users) {
        if (user['email'] == email && user['password'] == password) {
          await _saveUserToPrefs(user);
          return user;
        }
      }

      return null;
    } catch (e) {
      print('Erreur signIn: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>?> signUp({
    required String name,
    required String email,
    required String password,
    required String role,
  }) async {
    try {
      final users = await _getAllUsersFromPrefs();
      final existingUser = users.firstWhere(
            (user) => user['email'] == email,
        orElse: () => {},
      );

      if (existingUser.isNotEmpty) {
        return null; // Email déjà utilisé
      }

      final newUser = {
        'id': DateTime.now().millisecondsSinceEpoch,
        'email': email,
        'name': name,
        'password': password,
        'role': role,
        'created_at': DateTime.now().toIso8601String(),
      };

      users.add(newUser);
      await _saveAllUsersToPrefs(users);
      await _saveUserToPrefs(newUser);

      return newUser;
    } catch (e) {
      print('Erreur signUp: $e');
      return null;
    }
  }

  Future<void> signOut() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_isLoggedInKey, false);
    await prefs.remove(_userKey);
  }

  // ----------- GESTION UTILISATEUR -----------

  Future<String> updateUserData({
    String? name,
    String? password,
  }) async {
    try {
      final currentUser = await getCurrentUser();
      if (currentUser == null) return "Utilisateur non connecté";

      final users = await _getAllUsersFromPrefs();
      final userIndex = users.indexWhere((u) => u['id'] == currentUser['id']);
      if (userIndex == -1) return "Utilisateur non trouvé";

      if (name != null && name.isNotEmpty) {
        users[userIndex]['name'] = name;
      }
      if (password != null && password.isNotEmpty) {
        users[userIndex]['password'] = password;
      }

      await _saveAllUsersToPrefs(users);
      await _saveUserToPrefs(users[userIndex]);
      return "Succès";
    } catch (e) {
      return "Erreur: $e";
    }
  }

  Future<String> deleteUserAccount() async {
    final currentUser = await getCurrentUser();
    if (currentUser == null) return "Utilisateur non connecté";

    final users = await _getAllUsersFromPrefs();
    users.removeWhere((u) => u['id'] == currentUser['id']);
    await _saveAllUsersToPrefs(users);
    await signOut();
    return "Succès";
  }

  Future<String> deleteUserByAdmin({required int id}) async {
    final currentUser = await getCurrentUser();
    if (currentUser?['id'] == id) {
      return "Vous ne pouvez pas supprimer votre propre compte";
    }

    final users = await _getAllUsersFromPrefs();
    final initialLength = users.length;
    users.removeWhere((u) => u['id'] == id);

    if (users.length == initialLength) {
      return "Utilisateur non trouvé";
    }

    await _saveAllUsersToPrefs(users);
    return "Utilisateur supprimé avec succès";
  }

  Future<List<Map<String, dynamic>>> getAllUsers() async {
    return await _getAllUsersFromPrefs();
  }

  // ----------- STATISTIQUES -----------

  /// Retourne le nombre total d'utilisateurs enregistrés.
  Future<int> getTotalUserCount() async {
    final users = await _getAllUsersFromPrefs();
    return users.length;
  }

  /// Retourne la répartition des utilisateurs par rôle (ex: {'admin': 1, 'professeur': 5, 'etudiant': 10}).
  Future<Map<String, int>> getRoleDistribution() async {
    final users = await _getAllUsersFromPrefs();
    final Map<String, int> roleCounts = {};

    for (var user in users) {
      final role = user['role'] ?? 'inconnu';
      // Assurez-vous que le rôle est en minuscules pour la cohérence des clés
      roleCounts[role.toLowerCase()] = (roleCounts[role.toLowerCase()] ?? 0) + 1;
    }
    return roleCounts;
  }

  // ----------- RÉINITIALISATION MOT DE PASSE -----------

  Future<String> sendPasswordResetCode({required String email}) async {
    try {
      final users = await _getAllUsersFromPrefs();
      final user = users.firstWhere((u) => u['email'] == email, orElse: () => {});
      if (user.isEmpty) return "Aucun compte associé à cet email";

      final code = (100000 + (DateTime.now().millisecondsSinceEpoch % 900000)).toString();
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('reset_code_$email', code);

      // ✅ CORRECT : smtp.gmail.com
      String username = 'ribd1920@gmail.com';
      String password = 'otpd ybir gpwb avzp'; // mot de passe d'application Gmail

      final smtpServer = SmtpServer(
        'smtp.gmail.com',
        port: 587,
        username: username,
        password: password,
      );

      final message = Message()
        ..from = Address(username, 'CompusFlow Support')
        ..recipients.add(email)
        ..subject = 'Code de réinitialisation du mot de passe'
        ..text = 'Bonjour ${user['name']},\n\n'
            'Votre code de vérification est : $code\n'
            'Ce code est valable pendant 10 minutes.\n\n'
            'Merci,\nL’équipe CompusFlow.';

      await send(message, smtpServer);

      return "Succès : un code a été envoyé à votre adresse email.";
    } on MailerException catch (e) {
      print("Erreur mailer: $e");
      return "Erreur d’envoi : vérifie ta connexion Internet et les identifiants Gmail.";
    } catch (e) {
      return "Erreur: $e";
    }
  }

  Future<String> verifyCodeAndResetPassword({
    required String email,
    required String code,
    required String newPassword,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final savedCode = prefs.getString('reset_code_$email');

    if (savedCode == null) return "Aucun code trouvé pour cet email";
    if (savedCode != code) return "Code invalide";

    final users = await _getAllUsersFromPrefs();
    final index = users.indexWhere((u) => u['email'] == email);
    if (index == -1) return "Utilisateur non trouvé";

    users[index]['password'] = newPassword;
    await _saveAllUsersToPrefs(users);
    await prefs.remove('reset_code_$email');

    return "Mot de passe réinitialisé avec succès";
  }

  // ----------- FONCTIONS INTERNES -----------

  Future<void> _saveUserToPrefs(Map<String, dynamic> user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_isLoggedInKey, true);
    await prefs.setString(_userKey, _userToJsonString(user));
  }

  String _userToJsonString(Map<String, dynamic> user) {
    return '${user['id']}|${user['email']}|${user['name']}|${user['password']}|${user['role']}|${user['created_at']}';
  }

  Map<String, dynamic> _parseUserData(String userJson) {
    final parts = userJson.split('|');
    return {
      'id': int.tryParse(parts[0]) ?? 0,
      'email': parts[1],
      'name': parts[2],
      'password': parts[3],
      'role': parts[4],
      'created_at': parts[5],
    };
  }

  Future<List<Map<String, dynamic>>> _getAllUsersFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final usersJson = prefs.getStringList(_usersListKey) ?? [];

    final users = usersJson.map((json) => _parseUserData(json)).toList();
    final adminExists = users.any((user) => user['email'] == _defaultAdmin['email']);
    if (!adminExists) users.add(_defaultAdmin);
    return users;
  }

  Future<void> _saveAllUsersToPrefs(List<Map<String, dynamic>> users) async {
    final prefs = await SharedPreferences.getInstance();
    // Filtre pour ne pas sauvegarder l'admin par défaut s'il est déjà implicitement géré
    final usersToSave = users.where((user) => user['id'] != _defaultAdmin['id']).toList();
    final usersJson = usersToSave.map((user) => _userToJsonString(user)).toList();
    await prefs.setStringList(_usersListKey, usersJson);
  }

  Future<bool> isCurrentUserAdmin() async {
    final currentUser = await getCurrentUser();
    return currentUser?['role'] == 'admin';
  }

  Stream<Map<String, dynamic>?> get authStateChanges async* {
    while (true) {
      yield await getCurrentUser();
      await Future.delayed(const Duration(seconds: 2));
    }
  }
}