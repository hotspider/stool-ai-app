import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:app/l10n/app_localizations.dart';

import '../../design/tokens.dart';
import '../../design/widgets/app_scaffold.dart';
import '../../design/components/soft_card.dart';
import '../../design/components/section_header.dart';
import '../../design/components/primary_button.dart';
import '../../design/components/secondary_button.dart';
import '../models/record.dart';
import '../models/analyze_response.dart';
import '../services/pdf_export_service.dart';
import '../services/storage_service.dart';
import '../widgets/error_state_card.dart';
import '../widgets/info_row.dart';
import '../widgets/risk_badge.dart';

class HistoryDetailPage extends StatefulWidget {
  final String recordId;

  const HistoryDetailPage({super.key, required this.recordId});

  @override
  State<HistoryDetailPage> createState() => _HistoryDetailPageState();
}

class _HistoryDetailPageState extends State<HistoryDetailPage> {
  bool _isExporting = false;

  Future<void> _exportPdf(StoolRecord record) async {
    if (_isExporting) {
      return;
    }
    final l10n = AppLocalizations.of(context)!;
    setState(() {
      _isExporting = true;
    });
    try {
      final file = await PdfExportService.exportRecordToPdfFile(record, l10n);
      await Share.shareXFiles([XFile(file.path)], text: l10n.pdfTitle);
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.exportSuccess)),
      );
    } catch (_) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.exportFailed)),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isExporting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final record = StorageService.instance.getRecord(widget.recordId);
    if (record == null) {
      return AppScaffold(
        title: l10n.detailTitle,
        body: ErrorStateCard(
          title: l10n.detailLoadFailedTitle,
          message: l10n.detailLoadFailedMessage,
          primaryLabel: l10n.detailBackHistory,
          onPrimary: () => Navigator.of(context).pop(),
        ),
      );
    }

    return AppScaffold(
      title: l10n.detailTitle,
      padding: EdgeInsets.zero,
      body: ListView(
        padding: const EdgeInsets.all(AppSpace.s20),
        children: [
          _DetailSummaryCard(record: record),
          const SizedBox(height: AppSpace.s16),
          Wrap(
            spacing: AppSpace.s8,
            runSpacing: AppSpace.s8,
            children: [
              _MetricChip(
                label: l10n.resultMetricBristol,
                value: record.analysis.bristolType == null
                    ? l10n.colorUnknown
                    : l10n.resultBristolValue(record.analysis.bristolType!),
              ),
              _MetricChip(
                label: l10n.resultMetricColor,
                value: _colorLabel(context, record.analysis.color),
              ),
              _MetricChip(
                label: l10n.resultMetricTexture,
                value: _textureLabel(context, record.analysis.texture),
              ),
              _MetricChip(
                label: l10n.resultMetricScore,
                value: '${record.analysis.qualityScore}/100',
              ),
            ],
          ),
          const SizedBox(height: AppSpace.s16),
          SectionHeader(title: l10n.detailActionsTitle),
          const SizedBox(height: AppSpace.s12),
          SoftCard(
            child: record.advice.next48hActions.isEmpty
                ? Text(l10n.detailEmptyValue, style: AppText.caption)
                : Column(
                    children: record.advice.next48hActions.map((item) {
                      final checked = record.checkedActions[item] == true;
                      return _ChecklistRow(
                        title: item,
                        checked: checked,
                      );
                    }).toList(),
                  ),
          ),
          if (_shouldShowWarning(record)) ...[
            const SizedBox(height: AppSpace.s16),
            _WarningCard(
              title: l10n.resultWarningTitle,
              items: _warningItems(record, l10n),
              hint: l10n.resultWarningHint,
            ),
          ],
          const SizedBox(height: AppSpace.s16),
          SectionHeader(title: l10n.detailInputsTitle),
          const SizedBox(height: AppSpace.s12),
          SoftCard(
            child: Column(
              children: [
                InfoRow(
                  label: l10n.resultOdorLabel,
                  value: _odorLabel(context, record.userInputs.odor),
                ),
                InfoRow(
                  label: l10n.resultPainLabel,
                  value: record.userInputs.painOrStrain
                      ? l10n.detailYes
                      : l10n.detailNo,
                ),
                InfoRow(
                  label: l10n.resultDietLabel,
                  value: record.userInputs.dietKeywords.isEmpty
                      ? l10n.detailNotProvided
                      : record.userInputs.dietKeywords,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpace.s12),
          Text(
            record.advice.disclaimers.isEmpty
                ? l10n.resultDisclaimersDefault
                : record.advice.disclaimers.join('、'),
            style: AppText.caption,
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpace.s20,
            AppSpace.s8,
            AppSpace.s20,
            AppSpace.s16,
          ),
          child: Row(
            children: [
              Expanded(
                child: SecondaryButton(
                  label: l10n.exportPdfTooltip,
                  onPressed: _isExporting ? null : () => _exportPdf(record),
                  loading: _isExporting,
                ),
              ),
              const SizedBox(width: AppSpace.s12),
              Expanded(
                child: PrimaryButton(
                  label: l10n.detailBackHistory,
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DetailSummaryCard extends StatelessWidget {
  final StoolRecord record;

  const _DetailSummaryCard({required this.record});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return SoftCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: BorderRadius.circular(AppRadius.r12),
              border: Border.all(color: AppColors.divider),
            ),
            child: const Icon(Icons.health_and_safety_rounded,
                color: AppColors.primaryDeep),
          ),
          const SizedBox(width: AppSpace.s12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.detailRiskSummaryTitle, style: AppText.section),
                const SizedBox(height: AppSpace.s8),
                RiskBadge(riskLevel: record.analysis.riskLevel),
                const SizedBox(height: AppSpace.s8),
                Text(record.analysis.summary, style: AppText.body),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricChip extends StatelessWidget {
  final String label;
  final String value;

  const _MetricChip({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text('$label · $value', style: AppText.caption),
    );
  }
}

class _ChecklistRow extends StatelessWidget {
  final String title;
  final bool checked;

  const _ChecklistRow({
    required this.title,
    required this.checked,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpace.s8),
      child: Row(
        children: [
          Icon(
            checked ? Icons.check_circle : Icons.radio_button_unchecked,
            size: 18,
            color: checked ? AppColors.primary : AppColors.textSecondary,
          ),
          const SizedBox(width: AppSpace.s8),
          Expanded(child: Text(title, style: AppText.body)),
        ],
      ),
    );
  }
}

class _WarningCard extends StatelessWidget {
  final String title;
  final List<String> items;
  final String hint;

  const _WarningCard({
    required this.title,
    required this.items,
    required this.hint,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpace.s16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.r16),
        border: Border.all(color: AppColors.riskHigh.withOpacity(0.4)),
        color: AppColors.riskHigh.withOpacity(0.06),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.warning_amber_rounded,
                  color: AppColors.riskHigh),
              const SizedBox(width: AppSpace.s8),
              Text(title, style: AppText.section),
            ],
          ),
          const SizedBox(height: AppSpace.s8),
          if (items.isEmpty)
            Text(hint, style: AppText.caption)
          else
            ...items.map((item) => Padding(
                  padding: const EdgeInsets.only(bottom: AppSpace.s8),
                  child: Text('• $item', style: AppText.body),
                )),
        ],
      ),
    );
  }
}

bool _shouldShowWarning(StoolRecord record) {
  return record.analysis.riskLevel == RiskLevel.high ||
      record.analysis.suspiciousSignals.isNotEmpty ||
      record.advice.seekCareIf.isNotEmpty;
}

List<String> _warningItems(StoolRecord record, AppLocalizations l10n) {
  final items = <String>[];
  if (record.analysis.suspiciousSignals.isNotEmpty) {
    items.addAll(record.analysis.suspiciousSignals);
  }
  if (record.advice.seekCareIf.isNotEmpty) {
    items.addAll(record.advice.seekCareIf);
  }
  if (items.isEmpty) {
    items.add(l10n.resultWarningHint);
  }
  return items;
}

String _odorLabel(BuildContext context, String value) {
  final l10n = AppLocalizations.of(context)!;
  switch (value) {
    case 'none':
      return l10n.odorNone;
    case 'light':
      return l10n.odorLight;
    case 'strong':
      return l10n.odorStrong;
    case 'sour':
      return l10n.odorSour;
    case 'rotten':
      return l10n.odorRotten;
    case 'other':
      return l10n.odorOther;
    default:
      return l10n.odorNone;
  }
}

String _colorLabel(BuildContext context, StoolColor color) {
  final l10n = AppLocalizations.of(context)!;
  switch (color) {
    case StoolColor.brown:
      return l10n.colorBrown;
    case StoolColor.yellow:
      return l10n.colorYellow;
    case StoolColor.green:
      return l10n.colorGreen;
    case StoolColor.black:
      return l10n.colorBlack;
    case StoolColor.red:
      return l10n.colorRed;
    case StoolColor.pale:
      return l10n.colorPale;
    case StoolColor.mixed:
      return l10n.colorMixed;
    case StoolColor.unknown:
      return l10n.colorUnknown;
  }
}

String _textureLabel(BuildContext context, StoolTexture texture) {
  final l10n = AppLocalizations.of(context)!;
  switch (texture) {
    case StoolTexture.watery:
      return l10n.textureWatery;
    case StoolTexture.mushy:
      return l10n.textureMushy;
    case StoolTexture.normal:
      return l10n.textureNormal;
    case StoolTexture.hard:
      return l10n.textureHard;
    case StoolTexture.oily:
      return l10n.textureOily;
    case StoolTexture.foamy:
      return l10n.textureFoamy;
    case StoolTexture.unknown:
      return l10n.textureUnknown;
  }
}
