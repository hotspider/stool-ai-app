import 'package:flutter/material.dart';

import 'press_scale.dart';

class SecondaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool loading;
  final Widget? icon;

  const SecondaryButton({
    super.key,
    required this.label,
    this.onPressed,
    this.loading = false,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = !loading && onPressed != null;
    final child = loading
        ? const SizedBox(
            height: 18,
            width: 18,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
        : Text(label);
    final style = OutlinedButton.styleFrom(
      minimumSize: const Size.fromHeight(48),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
      ),
    );

    return PressScale(
      enabled: enabled,
      child: icon == null
          ? OutlinedButton(
              onPressed: enabled ? onPressed : null,
              style: style,
              child: child,
            )
          : OutlinedButton.icon(
              onPressed: enabled ? onPressed : null,
              style: style,
              icon: icon!,
              label: child,
            ),
    );
  }
}
