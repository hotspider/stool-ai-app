import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:app/l10n/app_localizations.dart';

import '../../design/widgets/app_scaffold.dart';
import '../../design/tokens.dart';
import '../services/storage_service.dart';
import '../widgets/section_card.dart';

class PrivacyPage extends StatefulWidget {
  const PrivacyPage({super.key});

  @override
  State<PrivacyPage> createState() => _PrivacyPageState();
}

class _PrivacyPageState extends State<PrivacyPage> {
  bool _isClearing = false;

  Future<void> _clearAll(BuildContext context) async {
    if (_isClearing) {
      return;
    }
    final l10n = AppLocalizations.of(context)!;
    final shouldClear = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.privacyClearTitle),
        content: Text(l10n.settingsClearDialogMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.previewCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.settingsClearConfirm),
          ),
        ],
      ),
    );
    if (shouldClear == true) {
      setState(() => _isClearing = true);
      await StorageService.instance.clearAll();
      if (!context.mounted) {
        return;
      }
      setState(() => _isClearing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.privacyCleared)),
      );
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AppScaffold(
      title: l10n.privacyTitle,
      padding: EdgeInsets.zero,
      body: ListView(
        padding: const EdgeInsets.all(AppTokens.s20),
        children: [
          SectionCard(
            title: l10n.privacyLocalTitle,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.privacyLocalLine1),
                const SizedBox(height: 8),
                Text(l10n.privacyLocalLine2),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SectionCard(
            title: l10n.privacyExportTitle,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.privacyExportLine1),
                const SizedBox(height: 8),
                Text(l10n.privacyExportLine2),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SectionCard(
            title: l10n.privacyClearTitle,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(l10n.privacyClearLine),
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: _isClearing ? null : () => _clearAll(context),
                  icon: const Icon(Icons.delete_forever_outlined),
                  label: Text(l10n.privacyClearButton),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
