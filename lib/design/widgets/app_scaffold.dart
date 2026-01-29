import 'package:flutter/material.dart';

import '../tokens.dart';

class AppScaffold extends StatelessWidget {
  final String title;
  final Widget body;
  final List<Widget>? actions;
  final EdgeInsets? padding;
  final Widget? bottomNavigationBar;
  final bool? resizeToAvoidBottomInset;

  const AppScaffold({
    super.key,
    required this.title,
    required this.body,
    this.actions,
    this.padding,
    this.bottomNavigationBar,
    this.resizeToAvoidBottomInset,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        centerTitle: true,
        actions: actions,
      ),
      resizeToAvoidBottomInset: resizeToAvoidBottomInset,
      body: SafeArea(
        child: Padding(
          padding: padding ?? const EdgeInsets.all(AppSpace.s20),
          child: body,
        ),
      ),
      bottomNavigationBar: bottomNavigationBar,
    );
  }
}
