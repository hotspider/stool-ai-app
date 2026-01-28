import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:app/l10n/app_localizations.dart';

import '../../core/image/image_source_service.dart';
import '../../design/tokens.dart';
import '../../design/widgets/animated_entry.dart';
import '../../design/widgets/app_scaffold.dart';
import '../../design/components/soft_card.dart';
import '../models/record.dart';
import '../services/storage_service.dart';
import '../widgets/empty_state.dart';
import '../widgets/risk_badge.dart';

class HistoryPage extends StatelessWidget {
  const HistoryPage({super.key});

  Future<void> _confirmClearAll(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    final shouldClear = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.settingsClearTitle),
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
      await StorageService.instance.clearAll();
    }
  }

  Future<bool> _confirmDelete(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.historyDeleteTitle),
        content: Text(l10n.historyDeleteMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.previewCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.historyDeleteAction),
          ),
        ],
      ),
    );
    return shouldDelete == true;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AppScaffold(
      title: l10n.historyTitle,
      padding: EdgeInsets.zero,
      body: ValueListenableBuilder(
        valueListenable: StorageService.instance.listenable(),
        builder: (context, _, child) {
          final records = StorageService.instance.getAllRecords();
          if (records.isEmpty) {
            return EmptyState(
              title: l10n.historyEmptyTitle,
              message: l10n.historyEmptyMessage,
              actionLabel: l10n.historyEmptyAction,
              onAction: () => _pickFromCamera(context),
            );
          }
          return AnimatedEntry(
            child: ListView.builder(
              padding: const EdgeInsets.all(AppSpace.s16),
              itemCount: records.length,
              itemBuilder: (context, index) {
                final record = records[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: AppSpace.s12),
                  child: Dismissible(
                    key: ValueKey(record.id),
                    direction: DismissDirection.endToStart,
                    confirmDismiss: (_) => _confirmDelete(context),
                    onDismissed: (_) async {
                      await StorageService.instance.deleteRecord(record.id);
                      if (!context.mounted) {
                        return;
                      }
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(l10n.historyDeletedUndo),
                          action: SnackBarAction(
                            label: l10n.historyUndoAction,
                            onPressed: () {
                              StorageService.instance.saveRecord(record);
                            },
                          ),
                        ),
                      );
                    },
                    background: Container(
                      padding:
                          const EdgeInsets.symmetric(horizontal: AppSpace.s16),
                      alignment: Alignment.centerRight,
                      decoration: BoxDecoration(
                        color: AppColors.riskHigh.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(AppRadius.r16),
                        border: Border.all(color: AppColors.divider),
                      ),
                      child: Text(
                        l10n.historyDeleteAction,
                        style:
                            AppText.body.copyWith(color: AppColors.riskHigh),
                      ),
                    ),
                    child: _HistoryItem(
                      record: record,
                      onTap: () => context.push('/history/${record.id}'),
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  Future<void> _pickFromCamera(BuildContext context) async {
    try {
      final bytes = await ImageSourceService.instance.pickFromCamera();
      if (bytes == null) {
        if (context.mounted) {
          final l10n = AppLocalizations.of(context)!;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.previewCanceled)),
          );
        }
        return;
      }
      if (!context.mounted) {
        return;
      }
      context.push(
        '/preview',
        extra: ImageSelection(bytes: bytes, source: ImageSourceType.camera),
      );
    } on ImageSourceFailure catch (_) {
      if (!context.mounted) {
        return;
      }
      _showPermissionSheet(context);
    } catch (_) {
      if (!context.mounted) {
        return;
      }
      final l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.previewPickFailed)),
      );
    }
  }

  void _showPermissionSheet(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    showModalBottomSheet<void>(
      context: context,
      builder: (context) => Padding(
        padding: const EdgeInsets.all(AppTokens.s20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l10n.permissionCameraTitle,
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: AppTokens.s8),
            Text(l10n.permissionCameraMessage,
                style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: AppTokens.s16),
            FilledButton(
              onPressed: () {
                openAppSettings();
                Navigator.of(context).pop();
              },
              child: Text(l10n.permissionGoSettings),
            ),
            const SizedBox(height: AppTokens.s8),
            OutlinedButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(l10n.previewCancel),
            ),
          ],
        ),
      ),
    );
  }
}

class _HistoryItem extends StatelessWidget {
  final StoolRecord record;
  final VoidCallback onTap;

  const _HistoryItem({
    required this.record,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final dateText = DateFormat('yyyy/MM/dd HH:mm').format(record.createdAt);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.r16),
      child: SoftCard(
        padding: const EdgeInsets.all(AppSpace.s16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Transform.scale(
              scale: 0.9,
              alignment: Alignment.topLeft,
              child: RiskBadge(riskLevel: record.analysis.riskLevel),
            ),
            const SizedBox(width: AppSpace.s12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    dateText,
                    style: AppText.body.copyWith(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: AppSpace.s8),
                  Text(
                    record.analysis.summary,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.body,
                  ),
                  const SizedBox(height: AppSpace.s8),
                  Text(
                    l10n.historyItemMeta(
                      record.analysis.bristolType ?? l10n.colorUnknown,
                      record.analysis.qualityScore,
                    ),
                    style: AppText.caption,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
