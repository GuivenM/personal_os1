import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:local_auth/local_auth.dart';

import 'auth_service.dart';
import 'storage_service.dart';

/// Number of digits in the PIN.
const int kPinLength = 4;

/// After this many consecutive wrong PINs the stored session is wiped and
/// the user must sign in with username + password again.
const int kMaxPinAttempts = 5;

/// The app re-locks when it returns from the background after this long.
const Duration kRelockAfter = Duration(seconds: 30);

enum PinCheck {
  /// PIN correct.
  ok,

  /// PIN wrong (counter incremented).
  wrong,

  /// Too many recent failures: temporarily blocked, nothing was checked.
  blocked,

  /// [kMaxPinAttempts] reached: caller must sign the user out.
  wiped,
}

class PinLockState {
  const PinLockState({
    this.loaded = false,
    this.hasPin = false,
    this.biometricEnabled = false,
    this.biometricAvailable = false,
    this.setupPrompted = false,
    this.failedAttempts = 0,
    this.blockedUntil,
  });

  /// False until the first read from secure storage has finished.
  final bool loaded;
  final bool hasPin;
  final bool biometricEnabled;
  final bool biometricAvailable;
  final bool setupPrompted;
  final int failedAttempts;
  final DateTime? blockedUntil;

  bool get isBlocked => blockedUntil != null && blockedUntil!.isAfter(DateTime.now());
  int get attemptsLeft => kMaxPinAttempts - failedAttempts;

  PinLockState copyWith({
    bool? loaded,
    bool? hasPin,
    bool? biometricEnabled,
    bool? biometricAvailable,
    bool? setupPrompted,
    int? failedAttempts,
    DateTime? blockedUntil,
    bool clearBlockedUntil = false,
  }) {
    return PinLockState(
      loaded: loaded ?? this.loaded,
      hasPin: hasPin ?? this.hasPin,
      biometricEnabled: biometricEnabled ?? this.biometricEnabled,
      biometricAvailable: biometricAvailable ?? this.biometricAvailable,
      setupPrompted: setupPrompted ?? this.setupPrompted,
      failedAttempts: failedAttempts ?? this.failedAttempts,
      blockedUntil: clearBlockedUntil ? null : (blockedUntil ?? this.blockedUntil),
    );
  }
}

/// Local (on-device) PIN + fingerprint gate.
///
/// The PIN never leaves the phone: it only unlocks the JWT already stored in
/// secure storage (see [AuthService.unlock], which also refreshes that token
/// so the session slides forward each time).
class LockService extends StateNotifier<PinLockState> {
  LockService(this._storage, {LocalAuthentication? localAuth})
      : _auth = localAuth ?? LocalAuthentication(),
        super(const PinLockState()) {
    load();
  }

  final StorageService _storage;
  final LocalAuthentication _auth;
  bool _prompting = false;

  /// True while the system fingerprint dialog is on screen, so the app does
  /// not treat that dialog's lifecycle blip as "came back from background".
  bool get isPrompting => _prompting;

  Future<void> load() async {
    final hasPin = (await _storage.readPinHash()) != null;
    final available = await _biometricAvailable();
    final flag = await _storage.readBiometricEnabled();
    final blockedMs = await _storage.readBlockedUntilMs();

    if (!mounted) return;
    state = PinLockState(
      loaded: true,
      hasPin: hasPin,
      biometricAvailable: available,
      biometricEnabled: hasPin && available && flag,
      setupPrompted: await _storage.readSetupPrompted(),
      failedAttempts: await _storage.readFailedAttempts(),
      blockedUntil: blockedMs == null ? null : DateTime.fromMillisecondsSinceEpoch(blockedMs),
    );
  }

  Future<bool> _biometricAvailable() async {
    try {
      if (!await _auth.isDeviceSupported()) return false;
      return (await _auth.getAvailableBiometrics()).isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  // --- PIN ---------------------------------------------------------------

  static bool isWeakPin(String pin) {
    if (pin.split('').toSet().length == 1) return true; // 0000, 1111…
    const ascending = '0123456789';
    return ascending.contains(pin) || ascending.split('').reversed.join().contains(pin);
  }

  /// Saves a new PIN. With [enableBiometric] it also asks for a fingerprint
  /// once to confirm it works. Returns whether fingerprint ended up enabled.
  /// State changes only once, at the very end.
  Future<bool> setPin(String pin, {bool enableBiometric = false}) async {
    final salt = _randomSalt();
    await _storage.savePin(hash: _hash(pin, salt), salt: salt);

    var biometric = false;
    if (enableBiometric && state.biometricAvailable) {
      biometric = await _prompt('Confirm your fingerprint to enable it');
    }
    await _storage.saveBiometricEnabled(biometric);
    await _storage.saveSetupPrompted(true);

    state = state.copyWith(
      hasPin: true,
      biometricEnabled: biometric,
      setupPrompted: true,
      failedAttempts: 0,
      clearBlockedUntil: true,
    );
    return biometric;
  }

  Future<PinCheck> verifyPin(String pin) async {
    if (state.isBlocked) return PinCheck.blocked;

    final hash = await _storage.readPinHash();
    final salt = await _storage.readPinSalt();
    if (hash == null || salt == null) return PinCheck.wrong;

    if (_constantTimeEquals(_hash(pin, salt), hash)) {
      await _storage.resetFailedAttempts();
      state = state.copyWith(failedAttempts: 0, clearBlockedUntil: true);
      return PinCheck.ok;
    }

    final failed = state.failedAttempts + 1;
    await _storage.saveFailedAttempts(failed);
    if (failed >= kMaxPinAttempts) return PinCheck.wiped;

    // 3rd failure: 30 s pause, 4th: 60 s.
    DateTime? until;
    if (failed >= 3) {
      until = DateTime.now().add(Duration(seconds: 30 * (failed - 2)));
      await _storage.saveBlockedUntilMs(until.millisecondsSinceEpoch);
    }
    state = state.copyWith(failedAttempts: failed, blockedUntil: until);
    return PinCheck.wrong;
  }

  Future<void> removePin() async {
    await _storage.deletePin();
    state = state.copyWith(
      hasPin: false,
      biometricEnabled: false,
      failedAttempts: 0,
      clearBlockedUntil: true,
    );
  }

  Future<void> markSetupPrompted() async {
    await _storage.saveSetupPrompted(true);
    state = state.copyWith(setupPrompted: true);
  }

  // --- Fingerprint -------------------------------------------------------

  Future<bool> authenticateBiometric() async {
    if (!state.biometricEnabled || state.isBlocked) return false;
    return _prompt('Unlock Personal OS');
  }

  /// Turning it on asks for one fingerprint first, so it can't be enabled
  /// on a device where it doesn't actually work.
  Future<bool> setBiometricEnabled(bool enable) async {
    if (!state.hasPin) return false;
    if (enable) {
      if (!state.biometricAvailable) return false;
      if (!await _prompt('Confirm your fingerprint to enable it')) return false;
    }
    await _storage.saveBiometricEnabled(enable);
    state = state.copyWith(biometricEnabled: enable);
    return true;
  }

  Future<bool> _prompt(String reason) async {
    _prompting = true;
    try {
      return await _auth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(biometricOnly: true, stickyAuth: true),
      );
    } catch (_) {
      return false;
    } finally {
      _prompting = false;
    }
  }

  // --- Hashing -----------------------------------------------------------

  static String _randomSalt() {
    final rnd = Random.secure();
    return base64Url.encode(List<int>.generate(16, (_) => rnd.nextInt(256)));
  }

  /// Salted, iterated SHA-256. A 4-digit PIN is always weak against an
  /// offline attack; the real protection is the Keystore-backed secure
  /// storage plus the attempt limit above.
  static String _hash(String pin, String salt) {
    final saltBytes = utf8.encode(salt);
    var digest = sha256.convert([...saltBytes, ...utf8.encode(pin)]);
    for (var i = 0; i < 20000; i++) {
      digest = sha256.convert([...digest.bytes, ...saltBytes]);
    }
    return base64Encode(digest.bytes);
  }

  static bool _constantTimeEquals(String a, String b) {
    if (a.length != b.length) return false;
    var diff = 0;
    for (var i = 0; i < a.length; i++) {
      diff |= a.codeUnitAt(i) ^ b.codeUnitAt(i);
    }
    return diff == 0;
  }
}

final lockServiceProvider = StateNotifierProvider<LockService, PinLockState>((ref) {
  final service = LockService(ref.watch(storageServiceProvider));
  // Logging out wipes secure storage; re-read so the UI doesn't keep a
  // stale "PIN is set" after that (and after login, to pick up the flags).
  ref.listen<AuthState>(authServiceProvider, (previous, next) {
    if (previous?.status != next.status &&
        (next.status == AuthStatus.unauthenticated || next.status == AuthStatus.authenticated)) {
      service.load();
    }
  });
  return service;
});
