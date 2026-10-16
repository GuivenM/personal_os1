import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/services/lock_service.dart';
import '../../core/theme/app_theme.dart';
import 'pin_widgets.dart';

enum _Step { enter, confirm, biometric }

/// Create or change the PIN.
///
/// [isFirstRun] = true: shown by the router right after the first password
/// login (skippable). false: pushed from More → Security.
class PinSetupScreen extends ConsumerStatefulWidget {
  const PinSetupScreen({super.key, this.isFirstRun = false});

  final bool isFirstRun;

  @override
  ConsumerState<PinSetupScreen> createState() => _PinSetupScreenState();
}

class _PinSetupScreenState extends ConsumerState<PinSetupScreen> {
  _Step _step = _Step.enter;
  String _pin = '';
  String _first = '';
  bool _error = false;
  bool _saving = false;
  String? _message;

  void _onDigit(String d) {
    if (_saving || _pin.length >= kPinLength) return;
    setState(() {
      _pin += d;
      _error = false;
      _message = null;
    });
    if (_pin.length == kPinLength) _onComplete();
  }

  void _onBackspace() {
    if (_saving || _pin.isEmpty) return;
    setState(() => _pin = _pin.substring(0, _pin.length - 1));
  }

  void _onComplete() {
    if (_step == _Step.enter) {
      if (LockService.isWeakPin(_pin)) {
        setState(() {
          _pin = '';
          _error = true;
          _message = 'Too easy to guess. Pick another PIN.';
        });
        return;
      }
      setState(() {
        _first = _pin;
        _pin = '';
        _step = _Step.confirm;
      });
    } else if (_step == _Step.confirm) {
      if (_pin != _first) {
        setState(() {
          _pin = '';
          _first = '';
          _step = _Step.enter;
          _error = true;
          _message = "PINs didn't match. Start again.";
        });
        return;
      }
      if (ref.read(lockServiceProvider).biometricAvailable) {
        setState(() => _step = _Step.biometric);
      } else {
        _finish(false);
      }
    }
  }

  Future<void> _finish(bool enableBiometric) async {
    setState(() => _saving = true);
    final bio = await ref.read(lockServiceProvider.notifier).setPin(_first, enableBiometric: enableBiometric);
    if (!mounted) return;
    if (enableBiometric && !bio) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Fingerprint not enabled. You can retry in More → Security.')),
      );
    }
    // First run: the router leaves this screen by itself once the PIN exists.
    if (!widget.isFirstRun) Navigator.of(context).pop(true);
  }

  Future<void> _skip() => ref.read(lockServiceProvider.notifier).markSetupPrompted();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: widget.isFirstRun ? null : AppBar(title: const Text('PIN')),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            child: _step == _Step.biometric ? _biometricStep() : _pinStep(),
          ),
        ),
      ),
    );
  }

  Widget _pinStep() {
    final confirming = _step == _Step.confirm;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.pin_outlined, size: 40, color: AppColors.violet),
        const SizedBox(height: 12),
        Text(
          confirming ? 'Confirm your PIN' : 'Choose a $kPinLength-digit PIN',
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 6),
        const Text(
          'You will use it instead of your password.',
          style: TextStyle(color: AppColors.textSecondary),
        ),
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
        PinKeypad(onDigit: _onDigit, onBackspace: _onBackspace, enabled: !_saving),
        const SizedBox(height: 12),
        if (widget.isFirstRun)
          TextButton(onPressed: _saving ? null : _skip, child: const Text('Skip for now')),
      ],
    );
  }

  Widget _biometricStep() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Icon(Icons.fingerprint, size: 64, color: AppColors.violet),
        const SizedBox(height: 16),
        const Text(
          'Unlock with your fingerprint?',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        const Text(
          'The PIN stays available as a fallback.',
          textAlign: TextAlign.center,
          style: TextStyle(color: AppColors.textSecondary),
        ),
        const SizedBox(height: 28),
        ElevatedButton(
          onPressed: _saving ? null : () => _finish(true),
          child: const Text('Enable fingerprint'),
        ),
        const SizedBox(height: 8),
        TextButton(
          onPressed: _saving ? null : () => _finish(false),
          child: const Text('Not now'),
        ),
      ],
    );
  }
}
