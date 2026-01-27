import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:app/l10n/app_localizations.dart';

import '../../design/tokens.dart';
import '../../design/widgets/app_scaffold.dart';
import '../../design/components/section_header.dart';
import '../../design/components/soft_card.dart';
import '../models/record.dart';
import '../services/analyzer/engine_config.dart';
import '../services/storage_service.dart';

const String kAppVersion = '1.0.0';
const int kSchemaVersion = 1;

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _isExporting = false;
  bool _isClearing = false;

  Future<void> _confirmClearAll(BuildContext context) async {
    if (_isClearing) {
      return;
    }
    final l10n = AppLocalizations.of(context)!;
    final shouldClear = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.settingsClearDialogTitle),
        content: Text(l10n.settingsClearDialogMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.previewCancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: AppTokens.riskHigh,
            ),
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
        SnackBar(content: Text(l10n.settingsCleared)),
      );
    }
  }

  Future<void> _exportRecords(BuildContext context) async {
    if (_isExporting) {
      return;
    }
    final l10n = AppLocalizations.of(context)!;
    setState(() => _isExporting = true);
    _showLoading(context, l10n.settingsExporting);
    final records = StorageService.instance.getAllRecords();
    if (records.isEmpty) {
      if (context.mounted) {
        Navigator.of(context).pop();
        setState(() => _isExporting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.settingsExportEmpty)),
        );
      }
      return;
    }
    try {
      final jsonText = _encodeRecords(records);
      await Clipboard.setData(ClipboardData(text: jsonText));
      if (!context.mounted) {
        return;
      }
      Navigator.of(context).pop();
      setState(() => _isExporting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.settingsExportSuccess(records.length))),
      );
    } catch (_) {
      if (!context.mounted) {
        return;
      }
      Navigator.of(context).pop();
      setState(() => _isExporting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.settingsExportFailed)),
      );
    }
  }

  String _encodeRecords(List<StoolRecord> records) {
    final list = records.map((record) => record.toJson()).toList();
    return const JsonEncoder.withIndent('  ').convert(list);
  }

  void _showLoading(BuildContext context, String message) {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        content: Row(
          children: [
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AppScaffold(
      title: l10n.settingsTitle,
      padding: EdgeInsets.zero,
      body: ListView(
        padding: const EdgeInsets.all(AppSpace.s20),
        children: [
          SoftCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.settingsDataTitle,
                    style: AppText.section),
                const SizedBox(height: AppSpace.s8),
                Text(l10n.settingsDataLine1,
                    style: AppText.caption),
                const SizedBox(height: AppSpace.s8),
                Text(l10n.settingsDataLine2,
                    style: AppText.caption),
              ],
            ),
          ),
          const SizedBox(height: AppSpace.s16),
          SectionHeader(title: l10n.settingsDataMgmtTitle),
          const SizedBox(height: AppSpace.s12),
          SoftCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                _SettingsItem(
                  icon: Icons.download_rounded,
                  title: l10n.settingsExportTitle,
                  subtitle: l10n.settingsExportSubtitle,
                  trailing: _isExporting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.chevron_right),
                  onTap: _isExporting ? null : () => _exportRecords(context),
                ),
                const Divider(height: 1),
                _SettingsItem(
                  icon: Icons.delete_forever_rounded,
                  title: l10n.settingsClearTitle,
                  subtitle: l10n.settingsClearSubtitle,
                  titleColor: AppTokens.riskHigh,
                  trailing: _isClearing
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.chevron_right),
                  onTap: _isClearing ? null : () => _confirmClearAll(context),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpace.s16),
          SectionHeader(title: l10n.settingsAboutTitle),
          const SizedBox(height: AppSpace.s12),
          SoftCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                _SettingsItem(
                  icon: Icons.info_outline_rounded,
                  title: l10n.settingsVersionTitle,
                  subtitle: l10n.settingsSchemaVersion(kSchemaVersion),
                  trailing: Text(
                    kAppVersion,
                    style: AppText.caption,
                  ),
                ),
                const Divider(height: 1),
                _SettingsItem(
                  icon: Icons.help_outline_rounded,
                  title: l10n.settingsUsageTitle,
                  subtitle: l10n.settingsUsageSubtitle,
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _showUsageDialog(context),
                ),
                const Divider(height: 1),
                _SettingsItem(
                  icon: Icons.privacy_tip_outlined,
                  title: l10n.settingsPrivacyTitle,
                  subtitle: l10n.settingsPrivacySubtitle,
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push('/privacy'),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpace.s16),
          SectionHeader(title: l10n.settingsAnalyzerModeTitle),
          const SizedBox(height: AppSpace.s12),
          ValueListenableBuilder(
            valueListenable: StorageService.instance.prefsListenable(),
            builder: (context, _, __) {
              final mode = StorageService.instance.getAnalyzerMode();
              return SoftCard(
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    _SettingsItem(
                      icon: Icons.memory_rounded,
                      title: l10n.settingsAnalyzerLocalTitle,
                      subtitle: l10n.settingsAnalyzerLocalSubtitle,
                      trailing: _ModeIndicator(selected: mode == AnalyzerMode.mock),
                      onTap: () =>
                          StorageService.instance.setAnalyzerMode(AnalyzerMode.mock),
                    ),
                    const Divider(height: 1),
                    _SettingsItem(
                      icon: Icons.cloud_outlined,
                      title: l10n.settingsAnalyzerRemoteTitle,
                      subtitle: l10n.settingsAnalyzerRemoteSubtitle,
                      trailing:
                          _ModeIndicator(selected: mode == AnalyzerMode.remote),
                      onTap: () =>
                          StorageService.instance.setAnalyzerMode(AnalyzerMode.remote),
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: AppSpace.s16),
          Text(
            l10n.settingsDisclaimer,
            style: AppText.caption,
          ),
        ],
      ),
    );
  }

  void _showUsageDialog(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.settingsUsageDialogTitle),
        content: Text(l10n.settingsUsageDialogMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l10n.settingsUsageDialogClose),
          ),
        ],
      ),
    );
  }
}

class _SettingsItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget trailing;
  final VoidCallback? onTap;
  final Color? titleColor;

  const _SettingsItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.trailing,
    this.onTap,
    this.titleColor,
  });

  @override
  Widget build(BuildContext context) {
    final content = Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: AppSpace.s16),
      child: Row(
        children: [
          Icon(icon, color: AppColors.textSecondary),
          const SizedBox(width: AppSpace.s12),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppText.body.copyWith(
                        color: titleColor ?? AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: AppText.caption,
                ),
              ],
            ),
          ),
          trailing,
        ],
      ),
    );

    return InkWell(
      onTap: onTap,
      child: content,
    );
  }
}

class _ModeIndicator extends StatelessWidget {
  final bool selected;

  const _ModeIndicator({required this.selected});

  @override
  Widget build(BuildContext context) {
    return Icon(
      selected ? Icons.check_circle_rounded : Icons.radio_button_unchecked,
      size: 20,
      color: selected ? AppTokens.primaryDeep : AppTokens.textSecondary,
    );
  }
}
