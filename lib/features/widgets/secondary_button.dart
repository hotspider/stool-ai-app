import 'package:flutter/material.dart';

import '../../design/widgets/secondary_button.dart' as design;

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
    return design.SecondaryButton(
      label: label,
      onPressed: onPressed,
      loading: loading,
      icon: icon,
    );
  }
}
