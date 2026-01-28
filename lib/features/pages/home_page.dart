import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:app/l10n/app_localizations.dart';

import '../../core/image/image_source_service.dart';
import '../../design/tokens.dart';
import '../../design/widgets/animated_entry.dart';
import '../../design/widgets/app_scaffold.dart';
import '../../design/components/info_banner.dart';
import '../../design/components/section_header.dart';
import '../../design/components/soft_card.dart';
import '../../design/components/primary_button.dart';
import '../../design/components/secondary_button.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';
import '../widgets/empty_state.dart';
import '../widgets/risk_badge.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool _bannerVisible = true;
  bool _isAnalyzing = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return AppScaffold(
      title: l10n.homeTitle,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _HeroHeader(
              title: l10n.appTitle,
              subtitle: l10n.homeHeroSubtitle,
            ),
            const SizedBox(height: AppSpace.s16),
            _ActionCard(
              title: l10n.homePrimaryAction,
              description: l10n.homePrimaryDesc,
              icon: Icons.photo_camera_rounded,
              isPrimary: true,
              onTap: () => _pickImage(context, ImageSourceType.camera),
            ),
            const SizedBox(height: AppSpace.s12),
            _ActionCard(
              title: l10n.homeSecondaryAction,
              description: l10n.homeSecondaryDesc,
              icon: Icons.photo_library_rounded,
              isPrimary: false,
              onTap: () => _pickImage(context, ImageSourceType.gallery),
            ),
            const SizedBox(height: AppSpace.s24),
            SectionHeader(title: l10n.homeRecentTitle),
            const SizedBox(height: AppSpace.s12),
            ValueListenableBuilder(
              valueListenable: StorageService.instance.listenable(),
              builder: (context, _, __) {
                final records = StorageService.instance.getAllRecords();
                if (records.isEmpty) {
                  return EmptyState(
                    title: l10n.homeRecentEmptyTitle,
                    message: l10n.homeRecentEmptyMessage,
                    actionLabel: l10n.homeRecentAction,
                    onAction: () => _startAnalyze(context),
                  );
                }
                final latest = records.first;
                final timeText =
                    DateFormat('yyyy/MM/dd HH:mm').format(latest.createdAt);
                return InkWell(
                  onTap: () => context.push('/history/${latest.id}'),
                  borderRadius: BorderRadius.circular(AppRadius.r16),
                  child: SoftCard(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(timeText, style: AppText.caption),
                              const SizedBox(height: AppSpace.s8),
                              RiskBadge(riskLevel: latest.analysis.riskLevel),
                              const SizedBox(height: AppSpace.s8),
                              Text(
                                latest.analysis.summary,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: AppText.body,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: AppSpace.s12),
                        const Icon(Icons.chevron_right_rounded,
                            color: AppColors.textSecondary),
                      ],
                    ),
                  ),
                );
              },
            ),
            if (_bannerVisible) ...[
              const SizedBox(height: AppSpace.s24),
              InfoBanner(
                message: l10n.homeDisclaimer,
                onClose: () => setState(() => _bannerVisible = false),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _pickImage(BuildContext context, ImageSourceType source) async {
    try {
      final bytes = source == ImageSourceType.camera
          ? await ImageSourceService.instance.pickFromCamera()
          : await ImageSourceService.instance.pickFromGallery();
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
        extra: ImageSelection(bytes: bytes, source: source),
      );
    } on ImageSourceFailure catch (_) {
      if (!context.mounted) {
        return;
      }
      _showPermissionSheet(context, source);
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

  Future<void> _startAnalyze(BuildContext context) async {
    if (_isAnalyzing) {
      return;
    }
    setState(() => _isAnalyzing = true);
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
      _showLoadingDialog(context);
      final payload = await ApiService.analyzeImage(imageBytes: bytes);
      if (!context.mounted) {
        return;
      }
      Navigator.of(context, rootNavigator: true).pop();
      context.push('/result', extra: payload);
    } on ImageSourceFailure {
      if (!context.mounted) {
        return;
      }
      _showPermissionSheet(context, ImageSourceType.camera);
    } catch (_) {
      if (!context.mounted) {
        return;
      }
      Navigator.of(context, rootNavigator: true).maybePop();
      final l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.resultErrorMessage)),
      );
    } finally {
      if (mounted) {
        setState(() => _isAnalyzing = false);
      }
    }
  }

  void _showLoadingDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );
  }

  void _showPermissionSheet(BuildContext context, ImageSourceType source) {
    final l10n = AppLocalizations.of(context)!;
    final title = source == ImageSourceType.camera
        ? l10n.permissionCameraTitle
        : l10n.permissionGalleryTitle;
    final message = source == ImageSourceType.camera
        ? l10n.permissionCameraMessage
        : l10n.permissionGalleryMessage;
    showModalBottomSheet<void>(
      context: context,
      builder: (context) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(message, style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () {
                openAppSettings();
                Navigator.of(context).pop();
              },
              child: Text(l10n.permissionGoSettings),
            ),
            const SizedBox(height: 8),
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

class _HeroHeader extends StatelessWidget {
  final String title;
  final String subtitle;

  const _HeroHeader({
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return SoftCard(
      padding: const EdgeInsets.all(AppSpace.s20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppText.title),
          const SizedBox(height: AppSpace.s8),
          Text(subtitle, style: AppText.body.copyWith(color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final bool isPrimary;
  final VoidCallback onTap;

  const _ActionCard({
    required this.title,
    required this.description,
    required this.icon,
    required this.isPrimary,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final borderColor = isPrimary ? AppColors.primary : AppColors.divider;
    final iconColor = isPrimary ? AppColors.primary : AppColors.textSecondary;
    final bgColor = isPrimary ? AppColors.primaryLight : AppColors.card;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.r16),
      child: Container(
        constraints: const BoxConstraints(minHeight: 96),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(AppRadius.r16),
          border: Border.all(color: borderColor),
          boxShadow: AppShadow.soft,
        ),
        padding: const EdgeInsets.all(AppSpace.s16),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(AppRadius.r12),
                border: Border.all(color: AppColors.divider),
              ),
              child: Icon(icon, color: iconColor),
            ),
            const SizedBox(width: AppSpace.s12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppText.section),
                  const SizedBox(height: AppSpace.s8),
                  Text(description, style: AppText.caption),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }
}
