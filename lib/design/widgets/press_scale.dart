import 'package:flutter/material.dart';

class PressScale extends StatefulWidget {
  final Widget child;
  final bool enabled;

  const PressScale({
    super.key,
    required this.child,
    this.enabled = true,
  });

  @override
  State<PressScale> createState() => _PressScaleState();
}

class _PressScaleState extends State<PressScale> {
  double _scale = 1;

  void _setScale(double value) {
    if (!widget.enabled) {
      return;
    }
    setState(() {
      _scale = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (_) => _setScale(0.98),
      onPointerUp: (_) => _setScale(1),
      onPointerCancel: (_) => _setScale(1),
      child: AnimatedScale(
        scale: _scale,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: widget.child,
      ),
    );
  }
}
