import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Enveloppe autour de flutter_secure_storage.
///
/// Toute la persistance locale sensible (token JWT pour l'instant) passe
/// par ce service, pour garder un point d'entrée unique et facilement
/// substituable dans les tests.
class StorageService {
  StorageService({FlutterSecureStorage? storage})
      : _storage = storage ??
            const FlutterSecureStorage(
              aOptions: AndroidOptions(encryptedSharedPreferences: true),
            );

  final FlutterSecureStorage _storage;

  static const _tokenKey = 'auth_token';
  static const _usernameKey = 'auth_username';

  Future<void> saveToken(String token) => _storage.write(key: _tokenKey, value: token);

  Future<String?> readToken() => _storage.read(key: _tokenKey);

  Future<void> deleteToken() => _storage.delete(key: _tokenKey);

  Future<void> saveUsername(String username) =>
      _storage.write(key: _usernameKey, value: username);

  Future<String?> readUsername() => _storage.read(key: _usernameKey);

  /// Efface toutes les données stockées (logout complet).
  Future<void> clearAll() => _storage.deleteAll();
}
