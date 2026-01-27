import 'package:flutter/material.dart';

import '../../design/widgets/primary_button.dart' as design;

class PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool loading;
  final Widget? icon;

  const PrimaryButton({
    super.key,
    required this.label,
    this.onPressed,
    this.loading = false,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return design.PrimaryButton(
      label: label,
      onPressed: onPressed,
      loading: loading,
      icon: icon,
    );
  }
}
