// lib/services/auth_service.dart
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';
import './crypto_service.dart';
import './database_service.dart'; // 🔥 AJOUT IMPORT

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final CryptoService _cryptoService = CryptoService();

  static const String _userKey = 'current_user';
  static const String _isLoggedInKey = 'is_logged_in';
  static const String _usersListKey = 'users_list';

  // Utilisateur admin par défaut avec mot de passe crypté
  final Map<String, dynamic> _defaultAdmin = {
    'id': 1,
    'email': 'admin@compusflow.com',
    'name': 'Administrateur',
    'password': 'encrypted_admin_password',
    'role': 'admin',
    'created_at': '2024-01-01T00:00:00.000Z',
  };

  // Initialiser l'admin avec mot de passe crypté
  Map<String, dynamic> get defaultAdmin {
    if (_defaultAdmin['password'] == 'encrypted_admin_password') {
      try {
        _defaultAdmin['password'] = _cryptoService.hashPassword('admin123');
      } catch (e) {
        print('Erreur lors du hash du mot de passe admin: $e');
        // Fallback en cas d'erreur
        _defaultAdmin['password'] = 'admin123'; // Non sécurisé, mais fonctionnel
      }
    }
    return _defaultAdmin;
  }

  // ----------- AUTHENTIFICATION AVEC CRYPTAGE -----------

  Future<Map<String, dynamic>?> signIn({
    required String email,
    required String password,
  }) async {
    try {
      // Vérification admin par défaut avec cryptage
      if (email == defaultAdmin['email']) {
        if (_cryptoService.verifyPassword(password, defaultAdmin['password'])) {
          await _saveUserToPrefs(defaultAdmin);
          await _syncUserToSQLite(defaultAdmin); // 🔥 AJOUT SYNCHRO
          return defaultAdmin;
        }
      }

      final users = await _getAllUsersFromPrefs();
      for (var user in users) {
        if (user['email'] == email) {
          // Vérifier le mot de passe crypté
          if (_cryptoService.verifyPassword(password, user['password'])) {
            await _saveUserToPrefs(user);
            await _syncUserToSQLite(user); // 🔥 AJOUT SYNCHRO
            return user;
          }
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

      // Crypter le mot de passe avant stockage
      final encryptedPassword = _cryptoService.hashPassword(password);

      final newUser = {
        'id': DateTime.now().millisecondsSinceEpoch,
        'email': email,
        'name': name,
        'password': encryptedPassword,
        'role': role,
        'created_at': DateTime.now().toIso8601String(),
      };

      users.add(newUser);
      await _saveAllUsersToPrefs(users);
      await _saveUserToPrefs(newUser);
      await _syncUserToSQLite(newUser, plainPassword: password); // 🔥 AJOUT SYNCHRO

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
      if (currentUser == null) return "Utilisateur non connecte";

      final users = await _getAllUsersFromPrefs();
      final userIndex = users.indexWhere((u) => u['id'] == currentUser['id']);
      if (userIndex == -1) return "Utilisateur non trouve";

      if (name != null && name.isNotEmpty) {
        users[userIndex]['name'] = name;
      }
      if (password != null && password.isNotEmpty) {
        // Crypter le nouveau mot de passe
        users[userIndex]['password'] = _cryptoService.hashPassword(password);
      }

      await _saveAllUsersToPrefs(users);
      await _saveUserToPrefs(users[userIndex]);
      await _syncUserToSQLite(users[userIndex]); // 🔥 AJOUT SYNCHRO

      return "Succes";
    } catch (e) {
      return "Erreur: $e";
    }
  }

  Future<String> deleteUserAccount() async {
    final currentUser = await getCurrentUser();
    if (currentUser == null) return "Utilisateur non connecte";

    final users = await _getAllUsersFromPrefs();
    users.removeWhere((u) => u['id'] == currentUser['id']);
    await _saveAllUsersToPrefs(users);
    await signOut();

    await _deleteUserFromSQLite(currentUser['id']); // 🔥 AJOUT SYNCHRO

    return "Succes";
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
      return "Utilisateur non trouve";
    }

    await _saveAllUsersToPrefs(users);
    await _deleteUserFromSQLite(id); // 🔥 AJOUT SYNCHRO

    return "Utilisateur supprime avec succes";
  }

  Future<List<Map<String, dynamic>>> getAllUsers() async {
    return await _getAllUsersFromPrefs();
  }

  // ----------- STATISTIQUES -----------

  Future<int> getTotalUserCount() async {
    final users = await _getAllUsersFromPrefs();
    return users.length;
  }

  Future<Map<String, int>> getRoleDistribution() async {
    final users = await _getAllUsersFromPrefs();
    final Map<String, int> roleCounts = {};

    for (var user in users) {
      final role = user['role'] ?? 'inconnu';
      roleCounts[role.toLowerCase()] = (roleCounts[role.toLowerCase()] ?? 0) + 1;
    }
    return roleCounts;
  }

  // ----------- REINITIALISATION MOT DE PASSE -----------

  Future<String> sendPasswordResetCode({required String email}) async {
    try {
      final users = await _getAllUsersFromPrefs();
      final user = users.firstWhere((u) => u['email'] == email, orElse: () => {});
      if (user.isEmpty) return "Aucun compte associe a cet email";

      final code = (100000 + (DateTime.now().millisecondsSinceEpoch % 900000)).toString();
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('reset_code_$email', code);

      String username = 'ribd1920@gmail.com';
      String password = 'otpd ybir gpwb avzp';

      final smtpServer = SmtpServer(
        'smtp.gmail.com',
        port: 587,
        username: username,
        password: password,
      );

      final message = Message()
        ..from = Address(username, 'CompusFlow Support')
        ..recipients.add(email)
        ..subject = 'Code de reinitialisation du mot de passe'
        ..text = 'Bonjour ${user['name']},\n\n'
            'Votre code de verification est : $code\n'
            'Ce code est valable pendant 10 minutes.\n\n'
            'Merci,\nL equipe CompusFlow.';

      await send(message, smtpServer);

      return "Succes : un code a ete envoye a votre adresse email.";
    } on MailerException catch (e) {
      print("Erreur mailer: $e");
      return "Erreur d envoi : verifie ta connexion Internet et les identifiants Gmail.";
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

    if (savedCode == null) return "Aucun code trouve pour cet email";
    if (savedCode != code) return "Code invalide";

    final users = await _getAllUsersFromPrefs();
    final index = users.indexWhere((u) => u['email'] == email);
    if (index == -1) return "Utilisateur non trouve";

    // Crypter le nouveau mot de passe
    users[index]['password'] = _cryptoService.hashPassword(newPassword);
    await _saveAllUsersToPrefs(users);
    await prefs.remove('reset_code_$email');

    await _syncUserToSQLite(users[index]); // 🔥 AJOUT SYNCHRO

    return "Mot de passe reinitialise avec succes";
  }

  // ----------- FONCTIONS INTERNES -----------

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
    final adminExists = users.any((user) => user['email'] == defaultAdmin['email']);
    if (!adminExists) users.add(defaultAdmin);
    return users;
  }

  Future<void> _saveAllUsersToPrefs(List<Map<String, dynamic>> users) async {
    final prefs = await SharedPreferences.getInstance();
    final usersToSave = users.where((user) => user['id'] != defaultAdmin['id']).toList();
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

  // Méthode pour réinitialiser l'authentification en cas de problème
  Future<void> resetAuth() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_userKey);
    await prefs.remove(_isLoggedInKey);
    await prefs.remove(_usersListKey);
  }

  // ========== 🔥 AJOUT SYNCHRONISATION SQLITE ==========

  /// Synchronise un utilisateur avec la base SQLite
  Future<void> _syncUserToSQLite(Map<String, dynamic> user, {String? plainPassword}) async {
    try {
      final dbService = DatabaseService();
      final db = await dbService.database;

      // Vérifier si l'utilisateur existe déjà dans SQLite
      final existingUser = await db.query(
        'users',
        where: 'id = ?',
        whereArgs: [user['id']],
      );

      // Pour SQLite, utiliser le mot de passe en clair ou essayer de décrypter
      final passwordForSQLite = plainPassword ?? _decryptPasswordForSQLite(user['password']);

      if (existingUser.isEmpty) {
        // Créer l'utilisateur dans SQLite
        await db.insert('users', {
          'id': user['id'],
          'email': user['email'],
          'name': user['name'],
          'password': passwordForSQLite,
          'role': user['role'],
          'created_at': user['created_at'],
        });
        print('✅ Utilisateur synchronisé avec SQLite: ${user['email']}');
      } else {
        // Mettre à jour l'utilisateur dans SQLite
        await db.update(
          'users',
          {
            'email': user['email'],
            'name': user['name'],
            'password': passwordForSQLite,
            'role': user['role'],
          },
          where: 'id = ?',
          whereArgs: [user['id']],
        );
        print('✅ Utilisateur mis à jour dans SQLite: ${user['email']}');
      }
    } catch (e) {
      print('❌ Erreur synchronisation SQLite: $e');
    }
  }

  /// Décrypte le mot de passe pour SQLite (ou utilise un mot de passe par défaut)
  String _decryptPasswordForSQLite(String encryptedPassword) {
    try {
      // Essayer de décrypter
      return _cryptoService.decrypt(encryptedPassword);
    } catch (e) {
      // Si le décryptage échoue, utiliser un mot de passe par défaut
      print('⚠️ Impossible de décrypter, utilisation mot de passe par défaut');
      return 'default_sqlite_password';
    }
  }

  /// Supprime un utilisateur de SQLite
  Future<void> _deleteUserFromSQLite(int userId) async {
    try {
      final dbService = DatabaseService();
      final db = await dbService.database;

      await db.delete(
        'users',
        where: 'id = ?',
        whereArgs: [userId],
      );

      print('✅ Utilisateur supprimé de SQLite: $userId');
    } catch (e) {
      print('❌ Erreur suppression SQLite: $e');
    }
  }

  /// Synchronise tous les utilisateurs avec SQLite (pour migration)
  Future<void> syncAllUsersToSQLite() async {
    try {
      final users = await _getAllUsersFromPrefs();
      final dbService = DatabaseService();
      final db = await dbService.database;

      int syncedCount = 0;

      for (final user in users) {
        final existingUser = await db.query(
          'users',
          where: 'id = ?',
          whereArgs: [user['id']],
        );

        if (existingUser.isEmpty) {
          final passwordForSQLite = _decryptPasswordForSQLite(user['password']);
          await db.insert('users', {
            'id': user['id'],
            'email': user['email'],
            'name': user['name'],
            'password': passwordForSQLite,
            'role': user['role'],
            'created_at': user['created_at'],
          });
          syncedCount++;
        }
      }

      print('🎉 Synchronisation terminée: $syncedCount utilisateurs synchronisés');
    } catch (e) {
      print('❌ Erreur synchronisation globale: $e');
    }
  }

  /// Vérifie si un utilisateur existe dans SQLite
  Future<bool> isUserInSQLite(int userId) async {
    try {
      final dbService = DatabaseService();
      final db = await dbService.database;

      final user = await db.query(
        'users',
        where: 'id = ?',
        whereArgs: [userId],
        limit: 1,
      );

      return user.isNotEmpty;
    } catch (e) {
      print('❌ Erreur vérification SQLite: $e');
      return false;
    }
  }
}