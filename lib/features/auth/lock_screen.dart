import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/services/auth_service.dart';
import '../../core/services/lock_service.dart';
import '../../core/theme/app_theme.dart';
import 'pin_widgets.dart';

/// Shown when a session token exists and a PIN is set: PIN or fingerprint
/// instead of username + password.
class LockScreen extends ConsumerStatefulWidget {
  const LockScreen({super.key});

  @override
  ConsumerState<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends ConsumerState<LockScreen> {
  String _pin = '';
  bool _error = false;
  bool _busy = false;
  bool _autoPrompted = false;
  String? _message;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _autoBiometric());
  }

  /// Opens the fingerprint prompt once, as soon as lock settings are loaded.
  Future<void> _autoBiometric() async {
    if (!mounted || _autoPrompted) return;
    final lock = ref.read(lockServiceProvider);
    if (!lock.loaded) return; // retried from build() once loaded
    _autoPrompted = true;
    if (!lock.biometricEnabled) return;
    await _useBiometric();
  }

  Future<void> _useBiometric() async {
    if (_busy) return;
    final ok = await ref.read(lockServiceProvider.notifier).authenticateBiometric();
    if (ok && mounted) {
      setState(() => _busy = true);
      await ref.read(authServiceProvider.notifier).unlock();
    }
  }

  void _onDigit(String d) {
    if (_busy || _pin.length >= kPinLength) return;
    setState(() {
      _pin += d;
      _error = false;
      _message = null;
    });
    if (_pin.length == kPinLength) _submit();
  }

  void _onBackspace() {
    if (_busy || _pin.isEmpty) return;
    setState(() => _pin = _pin.substring(0, _pin.length - 1));
  }

  int _secondsLeft() {
    final until = ref.read(lockServiceProvider).blockedUntil;
    if (until == null) return 0;
    return until.difference(DateTime.now()).inSeconds + 1;
  }

  Future<void> _submit() async {
    setState(() => _busy = true);
    final result = await ref.read(lockServiceProvider.notifier).verifyPin(_pin);
    if (!mounted) return;

    switch (result) {
      case PinCheck.ok:
        await ref.read(authServiceProvider.notifier).unlock();
        return; // the router leaves this screen
      case PinCheck.wiped:
        // Too many failures: forget the session, password required again.
        await ref.read(authServiceProvider.notifier).logout();
        return;
      case PinCheck.blocked:
        setState(() {
          _message = 'Too many attempts. Try again in ${_secondsLeft()}s.';
          _pin = '';
          _error = true;
          _busy = false;
        });
      case PinCheck.wrong:
        final lock = ref.read(lockServiceProvider);
        setState(() {
          _message = lock.isBlocked
              ? 'Wrong PIN. Try again in ${_secondsLeft()}s.'
              : 'Wrong PIN. ${lock.attemptsLeft} attempt(s) left.';
          _pin = '';
          _error = true;
          _busy = false;
        });
    }
  }

  Future<void> _forgot() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign in with password?'),
        content: const Text('This removes the PIN from this device. You can set a new one after signing in.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Continue')),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      await ref.read(authServiceProvider.notifier).logout();
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<PinLockState>(lockServiceProvider, (previous, next) {
      if (previous?.loaded != true && next.loaded) _autoBiometric();
    });
    final lock = ref.watch(lockServiceProvider);

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.lock_outline, size: 40, color: AppColors.violet),
                const SizedBox(height: 12),
                const Text('Personal OS', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
                const SizedBox(height: 6),
                const Text('Enter your PIN', style: TextStyle(color: AppColors.textSecondary)),
                const SizedBox(height: 26),
                PinDots(length: kPinLength, filled: _pin.length, error: _error),
                SizedBox(
                  height: 40,
                  child: Center(
                    child: Text(
                      _message ?? '',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: AppColors.rouge, fontSize: 13),
                    ),
                  ),
                ),
                PinKeypad(
                  onDigit: _onDigit,
                  onBackspace: _onBackspace,
                  enabled: !_busy,
                  leading: lock.biometricEnabled
                      ? IconButton(
                          iconSize: 34,
                          color: AppColors.violet,
                          icon: const Icon(Icons.fingerprint),
                          onPressed: _useBiometric,
                        )
                      : null,
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: _busy ? null : _forgot,
                  child: const Text('Forgot PIN? Sign in with password'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
