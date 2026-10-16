import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

/// Row of dots showing how many digits have been typed.
class PinDots extends StatelessWidget {
  const PinDots({super.key, required this.length, required this.filled, this.error = false});

  final int length;
  final int filled;
  final bool error;

  @override
  Widget build(BuildContext context) {
    final color = error ? AppColors.rouge : AppColors.violet;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(length, (i) {
        final on = i < filled;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          margin: const EdgeInsets.symmetric(horizontal: 9),
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: on ? color : Colors.transparent,
            border: Border.all(color: on || error ? color : AppColors.textMuted, width: 1.6),
          ),
        );
      }),
    );
  }
}

/// 3×4 numeric keypad. [leading] fills the bottom-left slot (e.g. the
/// fingerprint button).
class PinKeypad extends StatelessWidget {
  const PinKeypad({
    super.key,
    required this.onDigit,
    required this.onBackspace,
    this.leading,
    this.enabled = true,
  });

  final ValueChanged<String> onDigit;
  final VoidCallback onBackspace;
  final Widget? leading;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    Widget digit(String d) => _Key(
          onTap: enabled ? () => onDigit(d) : null,
          child: Text(d, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w600)),
        );

    Widget row(List<Widget> keys) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: keys),
        );

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        row([digit('1'), digit('2'), digit('3')]),
        row([digit('4'), digit('5'), digit('6')]),
        row([digit('7'), digit('8'), digit('9')]),
        row([
          _Key(child: leading ?? const SizedBox.shrink(), onTap: null, passthrough: leading != null),
          digit('0'),
          _Key(
            onTap: enabled ? onBackspace : null,
            child: const Icon(Icons.backspace_outlined, color: AppColors.textSecondary),
          ),
        ]),
      ],
    );
  }
}

class _Key extends StatelessWidget {
  const _Key({required this.child, required this.onTap, this.passthrough = false});

  final Widget child;
  final VoidCallback? onTap;

  /// When true the child handles its own taps (used for the leading slot).
  final bool passthrough;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: SizedBox(
        width: 72,
        height: 72,
        child: passthrough
            ? Center(child: child)
            : Material(
                color: Colors.transparent,
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: onTap,
                  child: Center(child: child),
                ),
              ),
      ),
    );
  }
}
