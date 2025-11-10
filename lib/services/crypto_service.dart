// lib/services/crypto_service.dart
import 'package:encrypt/encrypt.dart';
import 'dart:convert';
import 'package:crypto/crypto.dart';

class CryptoService {
  static final CryptoService _instance = CryptoService._internal();
  factory CryptoService() => _instance;
  CryptoService._internal() {
    _initialize();
  }

  // Clé de chiffrement 32 caractères pour AES-256
  static const String _encryptionKey = 'CompusFlowSecureKey2024@123456789';
  // IV 16 caractères pour AES CBC
  static const String _encryptionIV = 'CompusFlowIV1234';

  late final Encrypter _encrypter;
  late final IV _iv;
  bool _isInitialized = false;

  /// Initialise le service de cryptage
  void _initialize() {
    if (_isInitialized) return;

    try {
      // Vérifier et ajuster la longueur de la clé
      String adjustedKey = _adjustKeyLength(_encryptionKey);
      final key = Key.fromUtf8(adjustedKey);
      _iv = IV.fromUtf8(_encryptionIV);
      _encrypter = Encrypter(AES(key, mode: AESMode.cbc));
      _isInitialized = true;
    } catch (e) {
      throw Exception('Erreur d\'initialisation du cryptage: $e');
    }
  }

  /// Ajuste la longueur de la clé pour AES (16, 24 ou 32 caractères)
  String _adjustKeyLength(String key) {
    if (key.length == 16 || key.length == 24 || key.length == 32) {
      return key;
    }

    // Si la clé est trop courte, la compléter
    if (key.length < 32) {
      final padding = '0' * (32 - key.length);
      return key + padding;
    }

    // Si la clé est trop longue, la tronquer
    return key.substring(0, 32);
  }

  /// Méthode publique pour forcer la réinitialisation si nécessaire
  void initialize() {
    _initialize();
  }

  /// Crypte un texte en clair
  String encrypt(String plainText) {
    if (!_isInitialized) {
      _initialize();
    }
    try {
      final encrypted = _encrypter.encrypt(plainText, iv: _iv);
      return encrypted.base64;
    } catch (e) {
      throw Exception('Erreur de cryptage: $e');
    }
  }

  /// Décrypte un texte crypté
  String decrypt(String encryptedText) {
    if (!_isInitialized) {
      _initialize();
    }
    try {
      final encrypted = Encrypted.fromBase64(encryptedText);
      final decrypted = _encrypter.decrypt(encrypted, iv: _iv);
      return decrypted;
    } catch (e) {
      throw Exception('Erreur de décryptage: $e');
    }
  }

  /// Hash un mot de passe (crypte pour stockage)
  String hashPassword(String password) {
    return encrypt(password);
  }

  /// Vérifie si un mot de passe en clair correspond au hash stocké
  bool verifyPassword(String plainPassword, String hashedPassword) {
    try {
      final decrypted = decrypt(hashedPassword);
      return decrypted == plainPassword;
    } catch (e) {
      print('Erreur de vérification du mot de passe: $e');
      return false;
    }
  }

  /// Vérifie si un texte est crypté (valide base64 et décryptable)
  bool isEncrypted(String text) {
    try {
      // Vérifie si c'est du base64 valide
      final encrypted = Encrypted.fromBase64(text);
      // Tente de décrypter
      decrypt(text);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Migre un mot de passe non crypté vers un format crypté
  String migratePassword(String plainPassword) {
    return hashPassword(plainPassword);
  }

  /// Méthode alternative utilisant SHA-256 (plus sécurisée pour les mots de passe)
  String hashPasswordSHA256(String password) {
    try {
      final bytes = utf8.encode(password + _encryptionKey);
      final digest = sha256.convert(bytes);
      return digest.toString();
    } catch (e) {
      throw Exception('Erreur de hashage SHA-256: $e');
    }
  }

  /// Vérification avec SHA-256
  bool verifyPasswordSHA256(String plainPassword, String hashedPassword) {
    try {
      final newHash = hashPasswordSHA256(plainPassword);
      return newHash == hashedPassword;
    } catch (e) {
      print('Erreur de vérification du mot de passe SHA-256: $e');
      return false;
    }
  }
}