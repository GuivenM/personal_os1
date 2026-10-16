import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Enveloppe autour de flutter_secure_storage.
///
/// Toute la persistance locale sensible (token JWT, PIN haché, réglages de
/// verrouillage) passe par ce service, pour garder un point d'entrée unique
/// et facilement substituable dans les tests.
class StorageService {
  StorageService({FlutterSecureStorage? storage})
      : _storage = storage ??
            const FlutterSecureStorage(
              aOptions: AndroidOptions(encryptedSharedPreferences: true),
            );

  final FlutterSecureStorage _storage;

  static const _tokenKey = 'auth_token';
  static const _usernameKey = 'auth_username';

  // Verrouillage par PIN / empreinte
  static const _pinHashKey = 'lock_pin_hash';
  static const _pinSaltKey = 'lock_pin_salt';
  static const _failedAttemptsKey = 'lock_failed_attempts';
  static const _blockedUntilKey = 'lock_blocked_until_ms';
  static const _biometricKey = 'lock_biometric_enabled';
  static const _setupPromptedKey = 'lock_setup_prompted';

  Future<void> saveToken(String token) => _storage.write(key: _tokenKey, value: token);

  Future<String?> readToken() => _storage.read(key: _tokenKey);

  Future<void> deleteToken() => _storage.delete(key: _tokenKey);

  Future<void> saveUsername(String username) =>
      _storage.write(key: _usernameKey, value: username);

  Future<String?> readUsername() => _storage.read(key: _usernameKey);

  // --- PIN ---------------------------------------------------------------

  Future<String?> readPinHash() => _storage.read(key: _pinHashKey);

  Future<String?> readPinSalt() => _storage.read(key: _pinSaltKey);

  /// Stores a new PIN hash and resets the failed-attempt counters.
  Future<void> savePin({required String hash, required String salt}) async {
    await _storage.write(key: _pinHashKey, value: hash);
    await _storage.write(key: _pinSaltKey, value: salt);
    await resetFailedAttempts();
  }

  /// Removes the PIN and everything that depends on it.
  Future<void> deletePin() async {
    await _storage.delete(key: _pinHashKey);
    await _storage.delete(key: _pinSaltKey);
    await _storage.delete(key: _biometricKey);
    await resetFailedAttempts();
  }

  Future<int> readFailedAttempts() async =>
      int.tryParse(await _storage.read(key: _failedAttemptsKey) ?? '') ?? 0;

  Future<void> saveFailedAttempts(int value) =>
      _storage.write(key: _failedAttemptsKey, value: value.toString());

  Future<int?> readBlockedUntilMs() async =>
      int.tryParse(await _storage.read(key: _blockedUntilKey) ?? '');

  Future<void> saveBlockedUntilMs(int value) =>
      _storage.write(key: _blockedUntilKey, value: value.toString());

  Future<void> resetFailedAttempts() async {
    await _storage.delete(key: _failedAttemptsKey);
    await _storage.delete(key: _blockedUntilKey);
  }

  Future<bool> readBiometricEnabled() async =>
      (await _storage.read(key: _biometricKey)) == 'true';

  Future<void> saveBiometricEnabled(bool value) =>
      _storage.write(key: _biometricKey, value: value.toString());

  /// Whether the "set a PIN?" first-run screen has already been shown/skipped.
  Future<bool> readSetupPrompted() async =>
      (await _storage.read(key: _setupPromptedKey)) == 'true';

  Future<void> saveSetupPrompted(bool value) =>
      _storage.write(key: _setupPromptedKey, value: value.toString());

  /// Efface toutes les données stockées (logout complet, PIN compris).
  Future<void> clearAll() => _storage.deleteAll();
}
