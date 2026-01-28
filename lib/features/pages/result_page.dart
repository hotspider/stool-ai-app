import 'dart:math';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import 'package:app/l10n/app_localizations.dart';

import '../../core/di/engine_provider.dart';
import '../services/analyzer/analyzer.dart';
import '../services/analyzer/analyzer_factory.dart';
import '../../design/tokens.dart';
import '../../design/widgets/app_scaffold.dart';
import '../../design/widgets/animated_entry.dart';
import '../../design/components/info_banner.dart';
import '../../design/components/section_header.dart';
import '../../design/components/soft_card.dart';
import '../../design/components/primary_button.dart';
import '../../design/components/secondary_button.dart';
import '../models/advice_response.dart';
import '../models/analyze_response.dart';
import '../models/record.dart';
import '../models/stool_analysis_result.dart';
import '../models/user_inputs.dart';
import '../services/pdf_export_service.dart';
import '../services/storage_service.dart';
import '../widgets/error_state_card.dart';
import '../widgets/loading_steps.dart';
import '../widgets/risk_badge.dart';

class ResultPage extends StatefulWidget {
  final AnalyzeResponse? initialAnalysis;
  final String? validationWarning;
  final AdviceResponse? initialAdvice;
  final StoolAnalysisParseResult? initialStructured;

  const ResultPage({
    super.key,
    this.initialAnalysis,
    this.validationWarning,
    this.initialAdvice,
    this.initialStructured,
  });

  @override
  State<ResultPage> createState() => _ResultPageState();
}

class _ResultPageState extends State<ResultPage> {
  final Random _random = Random();
  final TextEditingController _dietController = TextEditingController();
  final List<String> _odorOptions = [
    'none',
    'light',
    'strong',
    'sour',
    'rotten',
    'other'
  ];
  late String _odor;
  bool _painOrStrain = false;
  bool _adviceUpdated = false;
  bool _isSaving = false;
  bool _isUpdatingAdvice = false;
  bool _isExporting = false;
  bool _hasError = false;

  AnalyzeResponse? _analysis;
  AdviceResponse? _advice;
  StoolAnalysisParseResult? _structured;
  List<bool> _checks = [];
  DateTime? _analyzedAt;
  bool _isAnalyzing = false;
  List<LoadingStepItem> _steps = const [];

  @override
  void initState() {
    super.initState();
    _odor = 'none';
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _runAnalysisFlow(
        precomputed: widget.initialAnalysis,
        precomputedAdvice: widget.initialAdvice,
        precomputedStructured: widget.initialStructured,
      );
    });
  }

  @override
  void dispose() {
    _dietController.dispose();
    super.dispose();
  }

  Future<void> _runAnalysisFlow({
    AnalyzeResponse? precomputed,
    AdviceResponse? precomputedAdvice,
    StoolAnalysisParseResult? precomputedStructured,
  }) async {
    final l10n = AppLocalizations.of(context)!;
    // AnalysisContext reserved for future metadata.
    setState(() {
      _isAnalyzing = true;
      _analysis = null;
      _advice = null;
      _structured = null;
      _checks = [];
      _adviceUpdated = false;
      _hasError = false;
      _isSaving = false;
      _isUpdatingAdvice = false;
      _steps = [
        LoadingStepItem(
            label: l10n.loadingStepQuality, status: LoadingStepStatus.active),
        LoadingStepItem(
            label: l10n.loadingStepFeatures, status: LoadingStepStatus.pending),
        LoadingStepItem(
            label: l10n.loadingStepAdvice, status: LoadingStepStatus.pending),
      ];
    });

    for (int i = 0; i < 3; i++) {
      await Future.delayed(Duration(milliseconds: 600 + _random.nextInt(301)));
      if (!mounted) {
        return;
      }
      setState(() {
        _steps = List<LoadingStepItem>.generate(3, (index) {
          final status = index < i
              ? LoadingStepStatus.done
              : index == i
                  ? LoadingStepStatus.done
                  : LoadingStepStatus.pending;
          return LoadingStepItem(
            label: _steps[index].label,
            status: status,
          );
        });
        if (i + 1 < 3) {
          _steps = List<LoadingStepItem>.from(_steps);
          _steps[i + 1] = LoadingStepItem(
            label: _steps[i + 1].label,
            status: LoadingStepStatus.active,
          );
        }
      });
    }

    try {
      final analysis = precomputed;
      if (analysis != null && precomputedAdvice != null) {
        if (!mounted) {
          return;
        }
        setState(() {
          _analysis = analysis;
          _advice = precomputedAdvice;
          _structured = precomputedStructured;
          _checks =
              List<bool>.filled(precomputedAdvice.next48hActions.length, false);
          _analyzedAt = analysis.analyzedAt;
          _isAnalyzing = false;
          _steps = [
            LoadingStepItem(
                label: l10n.loadingStepQuality, status: LoadingStepStatus.done),
            LoadingStepItem(
                label: l10n.loadingStepFeatures,
                status: LoadingStepStatus.done),
            LoadingStepItem(
                label: l10n.loadingStepAdvice, status: LoadingStepStatus.done),
          ];
        });
        return;
      }

      final analyzer = AnalyzerFactory.create();
      final result = await analyzer.analyze(
        imageBytes: Uint8List(0),
        inputs: _buildInputs(),
      );
      final resolved = precomputed ?? result.analysis;
      final advice = result.advice;
      if (!mounted) {
        return;
      }
      setState(() {
        _analysis = resolved;
        _advice = advice;
        _structured = result.structured;
        _checks = List<bool>.filled(advice.next48hActions.length, false);
        _analyzedAt = resolved.analyzedAt;
        _isAnalyzing = false;
        _steps = [
          LoadingStepItem(
              label: l10n.loadingStepQuality, status: LoadingStepStatus.done),
          LoadingStepItem(
              label: l10n.loadingStepFeatures, status: LoadingStepStatus.done),
          LoadingStepItem(
              label: l10n.loadingStepAdvice, status: LoadingStepStatus.done),
        ];
      });
      if (result.structured?.missing.isNotEmpty == true) {
        debugPrint(
          '[ResultPage] structured missing: ${result.structured!.missing.join(', ')}',
        );
      }
    } on AnalyzerException catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isAnalyzing = false;
        _hasError = true;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isAnalyzing = false;
        _hasError = true;
      });
    }
  }

  Future<void> _saveRecord() async {
    if (_analysis == null || _advice == null || _isSaving) {
      return;
    }
    setState(() {
      _isSaving = true;
    });
    final record = StoolRecord(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      createdAt: DateTime.now(),
      analysis: _analysis!,
      advice: _advice ?? AdviceResponse.empty(),
      userInputs: _buildInputs(),
      checkedActions: _buildCheckedActions(_advice),
    );
    try {
      await StorageService.instance.saveRecord(record);
      if (!mounted) {
        return;
      }
      final l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.resultSaved)),
      );
      context.go('/history');
    } catch (_) {
      if (!mounted) {
        return;
      }
      final l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.resultSaveFailed)),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  Future<void> _exportPdfFromResult() async {
    if (_analysis == null || _advice == null || _isExporting) {
      return;
    }
    setState(() {
      _isExporting = true;
    });
    final l10n = AppLocalizations.of(context)!;
    final tempRecord = StoolRecord(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      createdAt: DateTime.now(),
      analysis: _analysis!,
      advice: _advice ?? AdviceResponse.empty(),
      userInputs: _buildInputs(),
      checkedActions: _buildCheckedActions(_advice),
    );
    try {
      final file =
          await PdfExportService.exportRecordToPdfFile(tempRecord, l10n);
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

  UserInputs _buildInputs() {
    return UserInputs(
      odor: _odor,
      painOrStrain: _painOrStrain,
      dietKeywords: _dietController.text.trim(),
    );
  }

  Map<String, bool> _buildCheckedActions(AdviceResponse? advice) {
    if (advice == null) {
      return const {};
    }
    final map = <String, bool>{};
    for (var i = 0; i < advice.next48hActions.length; i++) {
      map[advice.next48hActions[i]] = _checks.length > i && _checks[i];
    }
    return map;
  }

  Future<void> _submitInputs() async {
    if (_analysis == null || _isUpdatingAdvice) {
      return;
    }
    setState(() {
      _isUpdatingAdvice = true;
      _adviceUpdated = false;
    });
    try {
      final advice = await EngineProvider.engine.generateAdvice(
        analysis: _analysis!,
        inputs: _buildInputs(),
      );
      if (!mounted) {
        return;
      }
      final l10n = AppLocalizations.of(context)!;
      setState(() {
        _advice = advice;
        _checks = List<bool>.filled(advice.next48hActions.length, false);
        _adviceUpdated = true;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.resultAdviceUpdated)),
      );
    } catch (_) {
      if (!mounted) {
        return;
      }
      final l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.resultAdviceUpdateFailed)),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isUpdatingAdvice = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final analysis = _analysis;
    final advice = _advice;
    final structured = _structured?.result;
    final canUseResult = structured != null && structured.ok;
    final legacyActions = advice?.next48hActions ?? const [];
    final hasStructuredActions = structured != null &&
        (structured.actionsToday.diet.isNotEmpty ||
            structured.actionsToday.hydration.isNotEmpty ||
            structured.actionsToday.care.isNotEmpty ||
            structured.actionsToday.avoid.isNotEmpty);
    final useLegacyActions =
        structured != null && !hasStructuredActions && legacyActions.isNotEmpty;

    return AppScaffold(
      title: l10n.resultTitle,
      padding: EdgeInsets.zero,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpace.s20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_hasError)
              ErrorStateCard(
                title: l10n.resultErrorTitle,
                message: l10n.resultErrorMessage,
                primaryLabel: l10n.resultRetry,
                onPrimary: () => _runAnalysisFlow(precomputed: null),
                secondaryLabel: l10n.previewBackHome,
                onSecondary: () => context.go('/home'),
              )
            else if (_isAnalyzing || analysis == null || advice == null)
              LoadingSteps(steps: _steps)
            else if (structured == null) ...[
              SoftCard(
                child: Text(
                  l10n.resultInsufficientMessage,
                  style: AppText.body,
                ),
              ),
            ] else ...[
              AnimatedEntry(
                child: _SummaryCard(
                  riskLevel: _riskLevelFromString(structured.riskLevel),
                  riskLabel: _riskLabel(
                      l10n, _riskLevelFromString(structured.riskLevel)),
                  riskDescription: _riskDescription(structured.riskLevel),
                  riskColor: _riskColor(structured.riskLevel),
                  headline: structured.headline.isEmpty
                      ? l10n.resultInsufficientMessage
                      : structured.headline,
                  summary: structured.uiStrings.summary.isEmpty
                      ? structured.summary
                      : structured.uiStrings.summary,
                  confidence: structured.confidence,
                  uncertaintyNote: structured.uncertaintyNote,
                  warning: widget.validationWarning,
                ),
              ),
              if (!structured.ok) ...[
                const SizedBox(height: AppSpace.s12),
                SoftCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(l10n.resultInsufficientMessage,
                          style: AppText.section),
                      if (structured.uncertaintyNote.isNotEmpty) ...[
                        const SizedBox(height: AppSpace.s8),
                        Text(structured.uncertaintyNote, style: AppText.body),
                      ],
                      if (structured.followUpQuestions.isNotEmpty) ...[
                        const SizedBox(height: AppSpace.s8),
                        _BulletList(items: structured.followUpQuestions),
                      ],
                    ],
                  ),
                ),
              ],
              const SizedBox(height: AppSpace.s12),
              Wrap(
                spacing: AppSpace.s8,
                runSpacing: AppSpace.s8,
                children: [
                  _MetricChip(
                    label: l10n.resultMetricBristol,
                    value: structured.stoolFeatures.bristolType == null
                        ? l10n.resultInsufficientMessage
                        : l10n.resultBristolValue(
                            structured.stoolFeatures.bristolType!),
                  ),
                  _MetricChip(
                    label: l10n.resultMetricColor,
                    value: _featureLabelOrUnknown(
                      l10n,
                      structured.stoolFeatures.color,
                    ),
                  ),
                  _MetricChip(
                    label: l10n.resultMetricTexture,
                    value: _featureLabelOrUnknown(
                      l10n,
                      structured.stoolFeatures.texture,
                    ),
                  ),
                  _MetricChip(
                    label: l10n.resultMetricScore,
                    value: '${_resolveScore(structured)}/100',
                  ),
                  ...structured.uiStrings.tags.map(
                    (chip) => Chip(label: Text(chip, style: AppText.caption)),
                  ),
                ],
              ),
              const SizedBox(height: AppSpace.s20),
              SectionHeader(title: l10n.resultInsightsTitle),
              const SizedBox(height: AppSpace.s12),
              SoftCard(
                child: _BulletList(items: structured.reasoningBullets),
              ),
              const SizedBox(height: AppSpace.s16),
              SectionHeader(title: l10n.resultActionsTodayTitle),
              const SizedBox(height: AppSpace.s12),
              SoftCard(
                child: structured.uiStrings.sections.isNotEmpty
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: structured.uiStrings.sections
                            .map(
                              (section) => Padding(
                                padding:
                                    const EdgeInsets.only(bottom: AppSpace.s12),
                                child: _ActionSection(
                                  title: section.title,
                                  iconKey: section.iconKey,
                                  items: section.items,
                                ),
                              ),
                            )
                            .toList(),
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: useLegacyActions
                            ? [
                                _ActionSection(
                                  title: l10n.resultActionsTitle,
                                  iconKey: 'actions',
                                  items: legacyActions,
                                ),
                              ]
                            : [
                                _ActionSection(
                                  title: l10n.resultActionsDiet,
                                  iconKey: 'diet',
                                  items: structured.actionsToday.diet,
                                ),
                                const SizedBox(height: AppSpace.s12),
                                _ActionSection(
                                  title: l10n.resultActionsHydration,
                                  iconKey: 'hydration',
                                  items: structured.actionsToday.hydration,
                                ),
                                const SizedBox(height: AppSpace.s12),
                                _ActionSection(
                                  title: l10n.resultActionsCare,
                                  iconKey: 'care',
                                  items: structured.actionsToday.care,
                                ),
                                const SizedBox(height: AppSpace.s12),
                                _ActionSection(
                                  title: l10n.resultActionsAvoid,
                                  iconKey: 'avoid',
                                  items: structured.actionsToday.avoid,
                                ),
                              ],
                      ),
              ),
              const SizedBox(height: AppSpace.s16),
              SectionHeader(title: l10n.resultRedFlagsTitle),
              const SizedBox(height: AppSpace.s12),
              _WarningCard(
                title: l10n.resultRedFlagsTitle,
                items: structured.redFlags
                    .map((item) => '${item.title} ${item.detail}'.trim())
                    .toList(),
                hint: l10n.resultWarningHint,
              ),
              const SizedBox(height: AppSpace.s16),
              SectionHeader(title: l10n.resultFollowUpTitle),
              const SizedBox(height: AppSpace.s12),
              SoftCard(
                child: _BulletList(items: structured.followUpQuestions),
              ),
              const SizedBox(height: AppSpace.s16),
              SectionHeader(title: l10n.resultExtraTitle),
              const SizedBox(height: AppSpace.s12),
              SoftCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    DropdownButtonFormField<String>(
                      value: _odor,
                      decoration:
                          InputDecoration(labelText: l10n.resultOdorLabel),
                      items: _odorOptions
                          .map(
                            (value) => DropdownMenuItem<String>(
                              value: value,
                              child: Text(_odorLabel(value)),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        if (value == null) {
                          return;
                        }
                        setState(() {
                          _odor = value;
                        });
                      },
                    ),
                    const SizedBox(height: AppSpace.s12),
                    SwitchListTile(
                      value: _painOrStrain,
                      onChanged: (value) {
                        setState(() {
                          _painOrStrain = value;
                        });
                      },
                      title: Text(l10n.resultPainLabel),
                      contentPadding: EdgeInsets.zero,
                    ),
                    const SizedBox(height: AppSpace.s12),
                    TextField(
                      controller: _dietController,
                      decoration: InputDecoration(
                        labelText: l10n.resultDietLabel,
                        hintText: l10n.resultDietHint,
                      ),
                    ),
                    const SizedBox(height: AppSpace.s12),
                    OutlinedButton(
                      onPressed: _isUpdatingAdvice ? null : _submitInputs,
                      child: Text(l10n.resultSubmitUpdate),
                    ),
                    if (_adviceUpdated)
                      Padding(
                        padding: const EdgeInsets.only(top: AppSpace.s8),
                        child: Text(
                          l10n.resultAdviceUpdated,
                          style: AppText.caption.copyWith(
                            color: AppColors.riskLow,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpace.s12),
              Text(
                structured.uncertaintyNote.isEmpty
                    ? l10n.resultDisclaimersDefault
                    : structured.uncertaintyNote,
                style: AppText.caption,
              ),
            ],
          ],
        ),
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
                  onPressed:
                      _isAnalyzing || _isSaving || _isExporting || !canUseResult
                          ? null
                          : _exportPdfFromResult,
                  loading: _isExporting,
                ),
              ),
              const SizedBox(width: AppSpace.s12),
              Expanded(
                child: PrimaryButton(
                  label: l10n.resultSave,
                  onPressed: _isAnalyzing || _isSaving || !canUseResult
                      ? null
                      : _saveRecord,
                  loading: _isSaving,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _odorLabel(String value) {
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

  String _colorLabel(StoolColor color) {
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

  String _textureLabel(StoolTexture texture) {
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

  String _riskLabel(AppLocalizations l10n, RiskLevel level) {
    switch (level) {
      case RiskLevel.high:
        return l10n.riskHighLabel;
      case RiskLevel.medium:
        return l10n.riskMediumLabel;
      case RiskLevel.low:
        return l10n.riskLowLabel;
    }
  }

  RiskLevel _riskLevelFromString(String raw) {
    switch (raw.toLowerCase()) {
      case 'high':
        return RiskLevel.high;
      case 'medium':
        return RiskLevel.medium;
      default:
        return RiskLevel.low;
    }
  }

  int _resolveScore(StoolAnalysisResult structured) {
    final score = structured.score;
    if (score != null) {
      return score.clamp(0, 100);
    }
    return _fallbackScore(structured);
  }

  int _fallbackScore(StoolAnalysisResult structured) {
    var score = 85;

    final bristol = structured.stoolFeatures.bristolType;
    if (bristol != null) {
      if (bristol == 3 || bristol == 4) {
        score += 8;
      } else if (bristol == 5) {
        score += 3;
      } else if (bristol == 6) {
        score -= 8;
      } else if (bristol == 7) {
        score -= 15;
      } else if (bristol == 1 || bristol == 2) {
        score -= 12;
      }
    }

    final colorTag = (structured.stoolFeatures.color ?? '').toLowerCase();
    if (colorTag == 'black' || colorTag == 'red' || colorTag == 'white_gray') {
      score -= 35;
    } else if (colorTag == 'green') {
      score -= 6;
    }

    final findings = structured.stoolFeatures.visibleFindings
        .map((e) => e.toLowerCase())
        .toList();
    if (findings.contains('blood')) {
      score -= 40;
    }
    if (findings.contains('mucus')) {
      score -= 15;
    }

    if (_painOrStrain) {
      score -= 10;
    }

    return score.clamp(0, 100);
  }

  String _featureLabelOrUnknown(AppLocalizations l10n, String? value) {
    if (value == null) {
      return l10n.colorUnknown;
    }
    final trimmed = value.trim();
    return trimmed.isEmpty ? l10n.colorUnknown : trimmed;
  }
}

class _SummaryCard extends StatelessWidget {
  final RiskLevel riskLevel;
  final String riskLabel;
  final String riskDescription;
  final Color riskColor;
  final String headline;
  final String summary;
  final double confidence;
  final String uncertaintyNote;
  final String? warning;

  const _SummaryCard({
    required this.riskLevel,
    required this.riskLabel,
    required this.riskDescription,
    required this.riskColor,
    required this.headline,
    required this.summary,
    required this.confidence,
    required this.uncertaintyNote,
    this.warning,
  });

  @override
  Widget build(BuildContext context) {
    return SoftCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: riskColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(AppRadius.r12),
              border: Border.all(color: riskColor.withOpacity(0.4)),
            ),
            child: Icon(Icons.health_and_safety_rounded,
                color: riskColor, size: 22),
          ),
          const SizedBox(width: AppSpace.s12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(riskLabel, style: AppText.title),
                const SizedBox(height: AppSpace.s8),
                Text(headline, style: AppText.section),
                const SizedBox(height: AppSpace.s6),
                Text(summary, style: AppText.body),
                const SizedBox(height: AppSpace.s6),
                Text(
                  '置信度 ${(confidence * 100).round()}%',
                  style: AppText.caption,
                ),
                if (uncertaintyNote.isNotEmpty) ...[
                  const SizedBox(height: AppSpace.s6),
                  Text(uncertaintyNote, style: AppText.caption),
                ],
                const SizedBox(height: AppSpace.s6),
                Text(riskDescription, style: AppText.caption),
                if (warning != null) ...[
                  const SizedBox(height: AppSpace.s8),
                  Text(
                    warning!,
                    style: AppText.caption.copyWith(
                      color: AppColors.riskMedium,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: AppSpace.s8),
          RiskBadge(riskLevel: riskLevel),
        ],
      ),
    );
  }
}

class _MetricChip extends StatelessWidget {
  final String label;
  final String value;

  const _MetricChip({
    required this.label,
    required this.value,
  });

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
  final ValueChanged<bool> onChanged;

  const _ChecklistRow({
    required this.title,
    required this.checked,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => onChanged(!checked),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpace.s8),
        child: Row(
          children: [
            Checkbox(
              value: checked,
              onChanged: (value) => onChanged(value ?? false),
            ),
            const SizedBox(width: AppSpace.s8),
            Expanded(child: Text(title, style: AppText.body)),
          ],
        ),
      ),
    );
  }
}

class _BulletList extends StatelessWidget {
  final List<String> items;

  const _BulletList({required this.items});

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const SizedBox.shrink();
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: items
          .map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpace.s8),
              child: Text('• $item', style: AppText.body),
            ),
          )
          .toList(),
    );
  }
}

class _ActionSection extends StatelessWidget {
  final String title;
  final String iconKey;
  final List<String> items;

  const _ActionSection({
    required this.title,
    required this.iconKey,
    required this.items,
  });

  IconData _iconForKey(String raw) {
    switch (raw.toLowerCase()) {
      case 'diet':
        return Icons.restaurant_rounded;
      case 'hydration':
        return Icons.water_drop_rounded;
      case 'care':
        return Icons.healing_rounded;
      case 'warning':
        return Icons.warning_amber_rounded;
      case 'avoid':
        return Icons.block_rounded;
      case 'observe':
        return Icons.visibility_rounded;
      case 'actions':
        return Icons.checklist_rounded;
      default:
        return Icons.list_alt_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            if (iconKey.isNotEmpty) ...[
              Icon(_iconForKey(iconKey), size: 18, color: AppColors.primary),
              const SizedBox(width: AppSpace.s6),
            ],
            Text(title, style: AppText.section),
          ],
        ),
        const SizedBox(height: AppSpace.s6),
        _BulletList(items: items),
      ],
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
          ...items.map((item) => Padding(
                padding: const EdgeInsets.only(bottom: AppSpace.s8),
                child: Text('• $item', style: AppText.body),
              )),
          if (items.isEmpty) Text(hint, style: AppText.caption),
        ],
      ),
    );
  }
}

extension ResultPageHelpers on _ResultPageState {
  Color _riskColor(String riskLevel) {
    switch (riskLevel) {
      case 'high':
        return AppTokens.riskHigh;
      case 'medium':
        return AppTokens.riskMedium;
      case 'low':
      default:
        return AppTokens.riskLow;
    }
  }

  String _riskDescription(String riskLevel) {
    final l10n = AppLocalizations.of(context)!;
    switch (riskLevel) {
      case 'high':
        return l10n.riskHighDesc;
      case 'medium':
        return l10n.riskMediumDesc;
      case 'low':
      default:
        return l10n.riskLowDesc;
    }
  }

  String _bristolHint(int type) {
    final l10n = AppLocalizations.of(context)!;
    if (type <= 2) return l10n.bristolHintDry;
    if (type <= 4) return l10n.bristolHintIdeal;
    return l10n.bristolHintLoose;
  }
}
