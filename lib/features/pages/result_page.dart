import 'dart:math';
import 'dart:typed_data';

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

  const ResultPage({
    super.key,
    this.initialAnalysis,
    this.validationWarning,
    this.initialAdvice,
  });

  @override
  State<ResultPage> createState() => _ResultPageState();
}

class _ResultPageState extends State<ResultPage> {
  final Random _random = Random();
  final TextEditingController _dietController = TextEditingController();
  final List<String> _odorOptions = ['none', 'light', 'strong', 'sour', 'rotten', 'other'];
  late String _odor;
  bool _painOrStrain = false;
  bool _adviceUpdated = false;
  bool _isSaving = false;
  bool _isUpdatingAdvice = false;
  bool _isExporting = false;
  bool _hasError = false;

  AnalyzeResponse? _analysis;
  AdviceResponse? _advice;
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
  }) async {
    final l10n = AppLocalizations.of(context)!;
    // AnalysisContext reserved for future metadata.
    setState(() {
      _isAnalyzing = true;
      _analysis = null;
      _advice = null;
      _checks = [];
      _adviceUpdated = false;
      _hasError = false;
      _isSaving = false;
      _isUpdatingAdvice = false;
      _steps = [
        LoadingStepItem(label: l10n.loadingStepQuality, status: LoadingStepStatus.active),
        LoadingStepItem(label: l10n.loadingStepFeatures, status: LoadingStepStatus.pending),
        LoadingStepItem(label: l10n.loadingStepAdvice, status: LoadingStepStatus.pending),
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
          _checks =
              List<bool>.filled(precomputedAdvice.next48hActions.length, false);
          _analyzedAt = analysis.analyzedAt;
          _isAnalyzing = false;
          _steps = [
            LoadingStepItem(label: l10n.loadingStepQuality, status: LoadingStepStatus.done),
            LoadingStepItem(label: l10n.loadingStepFeatures, status: LoadingStepStatus.done),
            LoadingStepItem(label: l10n.loadingStepAdvice, status: LoadingStepStatus.done),
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
        _checks = List<bool>.filled(advice.next48hActions.length, false);
        _analyzedAt = resolved.analyzedAt;
        _isAnalyzing = false;
        _steps = [
          LoadingStepItem(label: l10n.loadingStepQuality, status: LoadingStepStatus.done),
          LoadingStepItem(label: l10n.loadingStepFeatures, status: LoadingStepStatus.done),
          LoadingStepItem(label: l10n.loadingStepAdvice, status: LoadingStepStatus.done),
        ];
      });
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
      final file = await PdfExportService.exportRecordToPdfFile(tempRecord, l10n);
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
            else ...[
              AnimatedEntry(
                child: _SummaryCard(
                  riskLevel: analysis.riskLevel,
                  riskLabel: _riskLabel(l10n, analysis.riskLevel),
                  riskDescription: _riskDescription(analysis.riskLevel.name),
                  riskColor: _riskColor(analysis.riskLevel.name),
                  warning: widget.validationWarning,
                ),
              ),
              const SizedBox(height: AppSpace.s12),
              Wrap(
                spacing: AppSpace.s8,
                runSpacing: AppSpace.s8,
                children: [
                  _MetricChip(
                    label: l10n.resultMetricBristol,
                    value: l10n.resultBristolValue(analysis.bristolType),
                  ),
                  _MetricChip(
                    label: l10n.resultMetricColor,
                    value: _colorLabel(analysis.color),
                  ),
                  _MetricChip(
                    label: l10n.resultMetricTexture,
                    value: _textureLabel(analysis.texture),
                  ),
                  _MetricChip(
                    label: l10n.resultMetricScore,
                    value: '${analysis.qualityScore}/100',
                  ),
                ],
              ),
              const SizedBox(height: AppSpace.s20),
              SectionHeader(title: l10n.resultActionsTitle),
              const SizedBox(height: AppSpace.s12),
              SoftCard(
                child: advice.next48hActions.isEmpty
                    ? Text(l10n.resultActionsEmpty, style: AppText.caption)
                    : Column(
                        children: List.generate(
                          advice.next48hActions.length,
                          (index) => _ChecklistRow(
                            title: advice.next48hActions[index],
                            checked: _checks[index],
                            onChanged: (value) {
                              setState(() {
                                _checks[index] = value;
                              });
                            },
                          ),
                        ),
                      ),
              ),
              if (_shouldShowWarning(analysis, advice)) ...[
                const SizedBox(height: AppSpace.s16),
                _WarningCard(
                  title: l10n.resultWarningTitle,
                  items: _warningItems(analysis, advice, l10n),
                  hint: l10n.resultWarningHint,
                ),
              ],
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
                advice.disclaimers.isEmpty
                    ? l10n.resultDisclaimersDefault
                    : advice.disclaimers.join('、'),
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
                  onPressed: _isAnalyzing || _isSaving || _isExporting
                      ? null
                      : _exportPdfFromResult,
                  loading: _isExporting,
                ),
              ),
              const SizedBox(width: AppSpace.s12),
              Expanded(
                child: PrimaryButton(
                  label: l10n.resultSave,
                  onPressed: _isAnalyzing || _isSaving ? null : _saveRecord,
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

  bool _shouldShowWarning(AnalyzeResponse analysis, AdviceResponse advice) {
    return analysis.riskLevel == RiskLevel.high ||
        advice.seekCareIf.isNotEmpty ||
        analysis.suspiciousSignals.isNotEmpty;
  }

  List<String> _warningItems(
    AnalyzeResponse analysis,
    AdviceResponse advice,
    AppLocalizations l10n,
  ) {
    final items = <String>[];
    if (analysis.suspiciousSignals.isNotEmpty) {
      items.addAll(analysis.suspiciousSignals);
    }
    if (advice.seekCareIf.isNotEmpty) {
      items.addAll(advice.seekCareIf);
    }
    if (items.isEmpty) {
      items.add(l10n.resultWarningHint);
    }
    return items;
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
}

class _SummaryCard extends StatelessWidget {
  final RiskLevel riskLevel;
  final String riskLabel;
  final String riskDescription;
  final Color riskColor;
  final String? warning;

  const _SummaryCard({
    required this.riskLevel,
    required this.riskLabel,
    required this.riskDescription,
    required this.riskColor,
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
                Text(riskDescription, style: AppText.body),
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
          if (items.isEmpty)
            Text(hint, style: AppText.caption),
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