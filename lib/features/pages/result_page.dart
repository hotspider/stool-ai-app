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
import '../../design/widgets/app_scaffold.dart';
import '../../design/components/info_banner.dart';
import '../../design/components/soft_card.dart';
import '../../design/components/primary_button.dart';
import '../../design/components/secondary_button.dart';
import '../../design/components/section_header.dart';
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
import '../../ui/components/app_card.dart';
import '../../ui/components/bullet_list.dart';
import '../../ui/components/key_value_chips.dart';
import '../../ui/components/notice_banner.dart';
import '../../ui/components/primary_button.dart' as ui;
import '../../ui/components/section_header.dart' as ui;
import '../../ui/design_tokens.dart';
import '../../design/tokens.dart';

class ResultPage extends StatefulWidget {
  final AnalyzeResponse? initialAnalysis;
  final String? validationWarning;
  final AdviceResponse? initialAdvice;
  final StoolAnalysisParseResult? initialStructured;
  final Map<String, dynamic>? initialContext;
  final String? contextSummary;
  final Map<String, String?>? debugInfo;

  const ResultPage({
    super.key,
    this.initialAnalysis,
    this.validationWarning,
    this.initialAdvice,
    this.initialStructured,
    this.initialContext,
    this.contextSummary,
    this.debugInfo,
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
    final canUseResult = structured != null;
    final legacyActions = advice?.next48hActions ?? const [];
    final hasStructuredActions = structured != null &&
        (structured.actionsToday.diet.isNotEmpty ||
            structured.actionsToday.hydration.isNotEmpty ||
            structured.actionsToday.care.isNotEmpty ||
            structured.actionsToday.avoid.isNotEmpty ||
            structured.actionsToday.observe.isNotEmpty);
    final useLegacyActions =
        structured != null && !hasStructuredActions && legacyActions.isNotEmpty;
    final showNotice = structured != null &&
        (structured.analysisMode != 'full' ||
            structured.imageValidationStatus != 'ok');
    final noticeTitle = structured?.analysisMode == 'general_advice'
        ? '未能判断图片内容，提供通用建议'
        : '识别置信度较低，以下为参考分析';
    final noticeItems = structured == null
        ? const <String>[]
        : [
            if (structured.uncertaintyNote.isNotEmpty)
              structured.uncertaintyNote,
            ...structured.imageValidationTips,
          ].where((item) => item.trim().isNotEmpty).toList();

    return AppScaffold(
      title: l10n.resultTitle,
      padding: EdgeInsets.zero,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(UiSpacing.md),
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
              AppCard(
                child: Text(
                  l10n.resultInsufficientMessage,
                  style: UiText.body,
                ),
              ),
            ] else ...[
              if (showNotice)
                NoticeBanner(
                  title: noticeTitle,
                  items: noticeItems.isNotEmpty
                      ? noticeItems
                      : const ['建议下次拍更近更清晰'],
                  color: UiColors.riskMedium,
                ),
              if (showNotice) const SizedBox(height: UiSpacing.md),
              ..._buildDoctorReport(
                context,
                structured,
                l10n,
                useLegacyActions,
                legacyActions,
              ),
            ],
            if (kDebugMode) ...[
              const SizedBox(height: UiSpacing.lg),
              _buildDebugPanel(),
            ],
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            UiSpacing.md,
            UiSpacing.sm,
            UiSpacing.md,
            UiSpacing.md,
          ),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed:
                      _isAnalyzing || _isSaving || _isExporting || !canUseResult
                          ? null
                          : _exportPdfFromResult,
                  child: Text(
                    l10n.exportPdfTooltip,
                    style: UiText.section,
                  ),
                ),
              ),
              const SizedBox(width: UiSpacing.sm),
              Expanded(
                child: ui.PrimaryButton(
                  label: l10n.resultSave,
                  isLoading: _isSaving,
                  onPressed: _isAnalyzing || _isSaving || !canUseResult
                      ? null
                      : _saveRecord,
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

  List<Widget> _buildDoctorReport(
    BuildContext context,
    StoolAnalysisResult structured,
    AppLocalizations l10n,
    bool useLegacyActions,
    List<String> legacyActions,
  ) {
    const fallback = '未能识别，建议补拍清晰图片';
    final headline = _safeText(
      structured.doctorExplanation.oneSentenceConclusion,
      fallback: _safeText(structured.headline, fallback: '整体情况偏可观察。'),
    );
    final confidencePercent = (structured.analysisConfidence * 100).round();
    final model = widget.debugInfo?['model_used'] ??
        (structured.modelUsed.trim().isNotEmpty
            ? structured.modelUsed
            : 'unknown');
    final riskLabel = switch (structured.riskLevel) {
      'high' => '高风险',
      'medium' => '中等风险',
      'low' => '低风险',
      _ => '待评估',
    };
    final overviewLine = [
      '风险：$riskLabel',
      '置信度：$confidencePercent%',
      if (model.trim().isNotEmpty && model != 'unknown') '模型：$model',
    ].join(' · ');

    final chipLabels = <String>[
      if (structured.stoolFeatures.bristolRange.isNotEmpty)
        'Bristol ${structured.stoolFeatures.bristolRange}',
      if (structured.stoolFeatures.colorDesc.isNotEmpty)
        '颜色 ${structured.stoolFeatures.colorDesc}',
      if (structured.stoolFeatures.textureDesc.isNotEmpty)
        '质地 ${structured.stoolFeatures.textureDesc}',
      if (structured.score > 0) '评分 ${structured.score}',
    ];

    final contextText = structured.inputContext != null
        ? _buildContextSummaryFromInput(structured.inputContext!)
        : (structured.interpretation.howContextAffects.isNotEmpty
            ? structured.interpretation.howContextAffects.join('；')
            : '你未填写补充信息，本次仅基于图片进行判断。');

    final reasons = structured.reasoningBullets.isNotEmpty
        ? structured.reasoningBullets.take(5).toList()
        : structured.possibleCauses
            .map((e) =>
                '${_safeText(e.title, fallback: '常见原因')}：${_safeText(e.explanation, fallback: '与饮食或肠道通过速度相关')}'
                    .trim())
            .toList();

    final canDo = useLegacyActions
        ? legacyActions
        : [
            ...structured.actionsToday.diet,
            ...structured.actionsToday.hydration,
            ...structured.actionsToday.care,
          ];
    final avoid = structured.actionsToday.avoid;
    final observe = structured.actionsToday.observe;

    final extraFindings = <String>[];
    if (structured.stoolFeatures.wateriness != 'none') {
      extraFindings.add('水样程度：${structured.stoolFeatures.wateriness}');
    }
    if (structured.stoolFeatures.mucus != 'none') {
      extraFindings.add('黏液：${structured.stoolFeatures.mucus}');
    }
    if (structured.stoolFeatures.foam != 'none') {
      extraFindings.add('泡沫：${structured.stoolFeatures.foam}');
    }
    if (structured.stoolFeatures.blood != 'none') {
      extraFindings.add('血丝：${structured.stoolFeatures.blood}');
    }
    if (structured.stoolFeatures.undigestedFood != 'none') {
      extraFindings.add('未消化食物：${structured.stoolFeatures.undigestedFood}');
    }
    if (structured.stoolFeatures.separationLayers != 'none') {
      extraFindings.add('水样分层：${structured.stoolFeatures.separationLayers}');
    }
    if (structured.stoolFeatures.odorLevel != 'unknown') {
      extraFindings.add('气味：${structured.stoolFeatures.odorLevel}');
    }
    if (structured.stoolFeatures.visibleFindings.isNotEmpty) {
      extraFindings.add('可见物：${structured.stoolFeatures.visibleFindings.join('、')}');
    }

    final redFlags = structured.redFlags
        .map((item) => '${item.title} ${item.detail}'.trim())
        .where((item) => item.isNotEmpty)
        .toList();

    final reassure = _safeText(
      structured.uiStrings.longform.reassure,
      fallback: '如果精神好、能吃能睡、次数不多，多数可观察 24-48 小时。',
    );

    return [
      AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: UiSpacing.sm, vertical: 4),
                  decoration: BoxDecoration(
                    color: _riskColor(structured.riskLevel).withOpacity(0.12),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                        color: _riskColor(structured.riskLevel)
                            .withOpacity(0.4)),
                  ),
                  child: Text(
                    _riskDescription(structured.riskLevel),
                    style: UiText.hint.copyWith(
                      color: _riskColor(structured.riskLevel),
                    ),
                  ),
                ),
                const Spacer(),
                Text('置信度 $confidencePercent%', style: UiText.hint),
              ],
            ),
            const SizedBox(height: UiSpacing.sm),
            Text(headline, style: UiText.title),
            const SizedBox(height: UiSpacing.sm),
            Text(overviewLine, style: UiText.hint),
            const SizedBox(height: UiSpacing.sm),
            KeyValueChips(labels: chipLabels),
          ],
        ),
      ),
      const SizedBox(height: UiSpacing.lg),
      AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const ui.SectionHeader(
              icon: Icons.notes,
              title: '一句话结论',
            ),
            const SizedBox(height: UiSpacing.sm),
            Text(headline, style: UiText.body),
          ],
        ),
      ),
      const SizedBox(height: UiSpacing.lg),
      const ui.SectionHeader(icon: Icons.search, title: '具体怎么看'),
      const SizedBox(height: UiSpacing.sm),
      AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const ui.SectionHeader(icon: Icons.bakery_dining, title: '形态'),
            const SizedBox(height: UiSpacing.sm),
            Text(
              '形态：${_safeText(structured.stoolFeatures.shapeDesc, fallback: fallback)}',
              style: UiText.body,
            ),
            const SizedBox(height: UiSpacing.xs),
            Text(
              'Bristol：${_safeText(structured.stoolFeatures.bristolRange, fallback: fallback)}',
              style: UiText.hint,
            ),
            const SizedBox(height: UiSpacing.sm),
            BulletList(items: structured.interpretation.whyShape),
            const SizedBox(height: UiSpacing.sm),
            Text(
              _safeText(structured.doctorExplanation.shapeAnalysis,
                  fallback: fallback),
              style: UiText.hint,
            ),
          ],
        ),
      ),
      const SizedBox(height: UiSpacing.md),
      AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const ui.SectionHeader(icon: Icons.palette, title: '颜色'),
            const SizedBox(height: UiSpacing.sm),
            Text(
              '颜色：${_safeText(structured.stoolFeatures.colorDesc, fallback: fallback)}',
              style: UiText.body,
            ),
            const SizedBox(height: UiSpacing.sm),
            BulletList(items: structured.interpretation.whyColor),
            const SizedBox(height: UiSpacing.sm),
            Text(
              _safeText(structured.doctorExplanation.colorAnalysis,
                  fallback: fallback),
              style: UiText.hint,
            ),
          ],
        ),
      ),
      const SizedBox(height: UiSpacing.md),
      AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const ui.SectionHeader(icon: Icons.water_drop, title: '质地'),
            const SizedBox(height: UiSpacing.sm),
            Text(
              '质地：${_safeText(structured.stoolFeatures.textureDesc, fallback: fallback)}',
              style: UiText.body,
            ),
            const SizedBox(height: UiSpacing.sm),
            BulletList(items: structured.interpretation.whyTexture),
            const SizedBox(height: UiSpacing.sm),
            Text(
              _safeText(structured.doctorExplanation.textureAnalysis,
                  fallback: fallback),
              style: UiText.hint,
            ),
          ],
        ),
      ),
      if (extraFindings.isNotEmpty) ...[
        const SizedBox(height: UiSpacing.md),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const ui.SectionHeader(icon: Icons.visibility, title: '可见细节'),
              const SizedBox(height: UiSpacing.sm),
              BulletList(items: extraFindings),
            ],
          ),
        ),
      ],
      const SizedBox(height: UiSpacing.lg),
      AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const ui.SectionHeader(icon: Icons.person, title: '结合你填写的情况'),
            const SizedBox(height: UiSpacing.sm),
            Text(contextText, style: UiText.body),
          ],
        ),
      ),
      const SizedBox(height: UiSpacing.lg),
      AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const ui.SectionHeader(icon: Icons.bubble_chart, title: '可能原因'),
            const SizedBox(height: UiSpacing.sm),
            BulletList(items: reasons),
          ],
        ),
      ),
      const SizedBox(height: UiSpacing.lg),
      AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const ui.SectionHeader(icon: Icons.task_alt, title: '现在需要做什么'),
            const SizedBox(height: UiSpacing.sm),
            Text('✅ 可以做', style: UiText.section),
            const SizedBox(height: UiSpacing.xs),
            BulletList(items: canDo),
            const SizedBox(height: UiSpacing.sm),
            Text('❌ 少一点', style: UiText.section),
            const SizedBox(height: UiSpacing.xs),
            BulletList(items: avoid),
            const SizedBox(height: UiSpacing.sm),
            Text('👀 观察指标', style: UiText.section),
            const SizedBox(height: UiSpacing.xs),
            BulletList(items: observe),
          ],
        ),
      ),
      const SizedBox(height: UiSpacing.lg),
      NoticeBanner(title: '何时就医', items: redFlags),
      const SizedBox(height: UiSpacing.lg),
      AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const ui.SectionHeader(icon: Icons.favorite, title: '家长安心指标'),
            const SizedBox(height: UiSpacing.sm),
            Text(reassure, style: UiText.body),
          ],
        ),
      ),
    ];
  }

  Widget _buildDebugPanel() {
    final info = widget.debugInfo ?? const <String, String?>{};
    if (info.isEmpty) {
      return const SizedBox.shrink();
    }
    return AppCard(
      child: ExpansionTile(
        tilePadding: EdgeInsets.zero,
        title: Text('调试信息', style: UiText.section),
        children: info.entries
            .map(
              (entry) => Padding(
                padding: const EdgeInsets.only(bottom: UiSpacing.sm),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 120,
                      child: Text(entry.key, style: UiText.hint),
                    ),
                    Expanded(
                      child: Text(entry.value ?? '-', style: UiText.body),
                    ),
                  ],
                ),
              ),
            )
            .toList(),
      ),
    );
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

    final colorTag = (structured.stoolFeatures.colorLabel).toLowerCase();
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

  List<Widget> _buildNarrativeBlocks(
    BuildContext context,
    StoolAnalysisResult structured,
    AppLocalizations l10n,
    bool useLegacyActions,
    List<String> legacyActions,
  ) {
    final longform = structured.uiStrings.longform;
    final conclusion = _safeText(
      structured.doctorExplanation.oneSentenceConclusion,
      fallback: _safeText(structured.headline, fallback: '整体情况更偏向可观察。'),
    );
    final combined = _safeText(
      structured.doctorExplanation.combinedJudgement,
      fallback: _safeText(structured.interpretation.overallJudgement, fallback: ''),
    );
    final contextSummary = structured.inputContext != null
        ? _buildContextSummaryFromInput(structured.inputContext!)
        : widget.contextSummary;
    final contextBullets = contextSummary != null && contextSummary.trim().isNotEmpty
        ? [contextSummary.trim()]
        : structured.interpretation.howContextAffects.isNotEmpty
            ? structured.interpretation.howContextAffects
            : const ['你未填写补充信息，本次仅基于图片进行判断。'];
    final reassure = _safeText(
      longform.reassure,
      fallback: '如果精神好、吃得下、睡得稳、次数不多，大多属于可观察型。',
    );
    final showGuidance = structured.analysisMode != 'full' ||
        structured.imageValidationStatus != 'ok';

    final canDo = [
      ...structured.actionsToday.diet,
      ...structured.actionsToday.hydration,
      ...structured.actionsToday.care,
    ];

    final widgets = <Widget>[];

    final contextEchoCard = _buildContextEchoCard(structured.inputContext);
    if (contextEchoCard != null) {
      widgets.add(const SizedBox(height: AppSpace.s12));
      widgets.add(contextEchoCard);
    }

    if (showGuidance) {
      widgets.add(const SizedBox(height: AppSpace.s12));
      widgets.add(
        SoftCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('建议补充信息/拍摄提示', style: AppText.section),
              const SizedBox(height: AppSpace.s8),
              if (structured.uncertaintyNote.isNotEmpty)
                Text(structured.uncertaintyNote, style: AppText.body),
              const SizedBox(height: AppSpace.s8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: structured.uiStrings.sections
                    .map(
                      (section) => Padding(
                        padding: const EdgeInsets.only(bottom: AppSpace.s12),
                        child: _ActionSection(
                          title: section.title,
                          iconKey: section.iconKey,
                          items: section.items,
                        ),
                      ),
                    )
                    .toList(),
              ),
              if (structured.errorCode == 'INVALID_IMAGE') ...[
                const SizedBox(height: AppSpace.s12),
                Row(
                  children: [
                    Expanded(
                      child: PrimaryButton(
                        label: '重新裁剪/重新拍摄',
                        onPressed: () {
                          if (context.canPop()) {
                            context.pop();
                          } else {
                            context.go('/home');
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: AppSpace.s12),
                    Expanded(
                      child: SecondaryButton(
                        label: l10n.previewBackHome,
                        onPressed: () => context.go('/home'),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      );
    }

    final abnormalSigns = structured.stoolFeatures.abnormalSigns;
    final hasExplicitAbnormal = abnormalSigns.any(
      (item) => item.contains('血') || item.contains('黏') || item.contains('泡') || item.contains('分层'),
    );
    final abnormalLine = hasExplicitAbnormal
        ? '可见：${abnormalSigns.join('、')}'
        : '未看到：血丝 / 黏液 / 水样分层';

    widgets.addAll([
      const SizedBox(height: AppSpace.s12),
      SoftCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              conclusion,
              style: AppText.title.copyWith(fontSize: 22, height: 1.35),
            ),
            if (combined.isNotEmpty) ...[
              const SizedBox(height: AppSpace.s8),
              Text(combined, style: AppText.body),
            ],
            const SizedBox(height: AppSpace.s12),
            Text('你提到：', style: AppText.section),
            const SizedBox(height: AppSpace.s8),
            _BulletList(items: contextBullets),
          ],
        ),
      ),
      const SizedBox(height: AppSpace.s16),
      SectionHeader(title: '具体怎么看这个便便'),
      const SizedBox(height: AppSpace.s8),
      _FeatureCard(
        title: '形态',
        icon: Icons.bakery_dining_outlined,
        lines: [
          '形态：${_safeText(structured.stoolFeatures.shape, fallback: "偏软/糊状")}',
          '像：${_safeText(structured.stoolFeatures.shapeDesc, fallback: "稠粥/土豆泥")}',
          '布里斯托：${_safeText(structured.stoolFeatures.bristolRange, fallback: "5-6")}',
        ],
        footer: _safeText(
          structured.doctorExplanation.shapeAnalysis,
          fallback: '未能识别，建议补拍清晰图片',
        ),
      ),
      const SizedBox(height: AppSpace.s12),
      _FeatureCard(
        title: '颜色',
        icon: Icons.palette_outlined,
        lines: [
          '颜色：${_safeText(structured.stoolFeatures.colorLabel, fallback: "黄褐偏黄")}',
          _safeText(structured.stoolFeatures.colorReason, fallback: '多与饮食和肠道通过速度有关'),
        ],
        footer: _safeText(
          structured.doctorExplanation.colorAnalysis,
          fallback: '未能识别，建议补拍清晰图片',
        ),
      ),
      const SizedBox(height: AppSpace.s12),
      _FeatureCard(
        title: '质地',
        icon: Icons.grain_outlined,
        lines: [
          '质地：${_safeText(structured.stoolFeatures.textureLabel, fallback: "细腻/糊状")}',
          abnormalLine,
        ],
        footer: _safeText(
          structured.doctorExplanation.textureAnalysis,
          fallback: '未能识别，建议补拍清晰图片',
        ),
      ),
      const SizedBox(height: AppSpace.s16),
      SectionHeader(title: '可能的原因（按概率）'),
      const SizedBox(height: AppSpace.s8),
      SoftCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: structured.possibleCauses.asMap().entries.map((entry) {
            final idx = entry.key + 1;
            final item = entry.value;
            final title = _safeText(item.title, fallback: '常见原因');
            final explanation = _safeText(item.explanation, fallback: '常见原因导致的短期变化。');
            return Padding(
              padding: const EdgeInsets.only(bottom: AppSpace.s12),
              child: Text('$idx. $title：$explanation', style: AppText.body),
            );
          }).toList(),
        ),
      ),
      const SizedBox(height: AppSpace.s16),
      SectionHeader(title: '现在需要做什么'),
      const SizedBox(height: AppSpace.s8),
      SoftCard(
        child: useLegacyActions
            ? _ActionSection(
                title: l10n.resultActionsTitle,
                iconKey: 'actions',
                items: legacyActions,
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _ActionSection(
                    title: '✅ 可以做',
                    iconKey: 'care',
                    items: canDo,
                  ),
                  const SizedBox(height: AppSpace.s12),
                  _ActionSection(
                    title: '❌ 少一点',
                    iconKey: 'avoid',
                    items: structured.actionsToday.avoid,
                  ),
                  const SizedBox(height: AppSpace.s12),
                  Text('家长安心指标：$reassure', style: AppText.body),
                ],
              ),
      ),
      const SizedBox(height: AppSpace.s16),
      SectionHeader(title: '什么时候需要警惕'),
      const SizedBox(height: AppSpace.s8),
      SoftCard(
        child: ExpansionTile(
          title: const Text('红旗预警（可展开）'),
          childrenPadding: const EdgeInsets.only(bottom: AppSpace.s8),
          children: [
            _WarningCard(
              title: '需要警惕的情况',
              items: structured.redFlags
                  .map((item) => '${item.title} ${item.detail}'.trim())
                  .toList(),
              hint: '如出现以上情况，请及时咨询医生。',
            ),
          ],
        ),
      ),
    ]);

    return widgets;
  }

  String _buildHowToRead(StoolAnalysisResult structured) {
    final shapeWhy = structured.interpretation.whyShape.join('；');
    final colorWhy = structured.interpretation.whyColor.join('；');
    final textureWhy = structured.interpretation.whyTexture.join('；');
    final shape = structured.stoolFeatures.shapeDesc;
    final color = structured.stoolFeatures.colorDesc;
    final texture = structured.stoolFeatures.textureDesc;
    return [
      '形态：$shape${shapeWhy.isNotEmpty ? "（$shapeWhy）" : ""}',
      '颜色：$color${colorWhy.isNotEmpty ? "（$colorWhy）" : ""}',
      '质地：$texture${textureWhy.isNotEmpty ? "（$textureWhy）" : ""}',
    ].join('\n');
  }

  String _safeText(String? raw, {required String fallback}) {
    final value = raw?.trim() ?? '';
    if (value.isEmpty) return fallback;
    if (value.toLowerCase().contains('unknown')) return fallback;
    if (value.contains('信息不足')) return fallback;
    return value;
  }

  String _buildContextSummaryFromInput(Map<String, dynamic> ctx) {
    if (ctx.isEmpty) {
      return '你未填写补充信息，本次仅基于图片进行判断。';
    }
    final parts = <String>[];
    final foods = ctx['foods_eaten'];
    if (foods != null && foods.toString().trim().isNotEmpty) {
      parts.add('吃了什么：$foods');
    }
    final drinks = ctx['drinks_taken'];
    if (drinks != null && drinks.toString().trim().isNotEmpty) {
      parts.add('喝了什么：$drinks');
    }
    final mood = ctx['mood_state'];
    if (mood != null && mood.toString().trim().isNotEmpty) {
      parts.add('精神状态：$mood');
    }
    final notes = ctx['other_notes'];
    if (notes != null && notes.toString().trim().isNotEmpty) {
      parts.add('其他：$notes');
    }

    return parts.join('；');
  }

  Widget? _buildContextEchoCard(Map<String, dynamic>? ctx) {
    if (ctx == null || ctx.isEmpty) {
      return null;
    }
    final foods = ctx['foods_eaten']?.toString().trim();
    final drinks = ctx['drinks_taken']?.toString().trim();
    final mood = ctx['mood_state']?.toString().trim();
    final notes = ctx['other_notes']?.toString().trim();
    if ((foods ?? '').isEmpty &&
        (drinks ?? '').isEmpty &&
        (mood ?? '').isEmpty &&
        (notes ?? '').isEmpty) {
      return null;
    }
    final items = <MapEntry<String, String>>[
      MapEntry('吃了什么', foods?.isNotEmpty == true ? foods! : '未填写'),
      MapEntry('喝了什么', drinks?.isNotEmpty == true ? drinks! : '未填写'),
      MapEntry('精神状态', mood?.isNotEmpty == true ? mood! : '未填写'),
      MapEntry('其他', notes?.isNotEmpty == true ? notes! : '未填写'),
    ];
    return SoftCard(
      child: ExpansionTile(
        tilePadding: EdgeInsets.zero,
        title: Text('补充信息回显', style: AppText.section),
        children: items
            .map(
              (entry) => Padding(
                padding: const EdgeInsets.only(bottom: AppSpace.s8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 80,
                      child: Text(entry.key, style: AppText.caption),
                    ),
                    Expanded(child: Text(entry.value, style: AppText.body)),
                  ],
                ),
              ),
            )
            .toList(),
      ),
    );
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
  final String modelUsed;

  const _SummaryCard({
    required this.riskLevel,
    required this.riskLabel,
    required this.riskDescription,
    required this.riskColor,
    required this.headline,
    required this.summary,
    required this.confidence,
    required this.uncertaintyNote,
    required this.modelUsed,
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
                if (kDebugMode && modelUsed.isNotEmpty) ...[
                  const SizedBox(height: AppSpace.s8),
                  Text('model: $modelUsed', style: AppText.caption),
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

class _FeatureCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<String> lines;
  final String footer;

  const _FeatureCard({
    required this.title,
    required this.icon,
    required this.lines,
    required this.footer,
  });

  @override
  Widget build(BuildContext context) {
    return SoftCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: AppColors.primary),
              const SizedBox(width: AppSpace.s6),
              Text(title, style: AppText.section),
            ],
          ),
          const SizedBox(height: AppSpace.s8),
          ...lines.map((line) => Padding(
                padding: const EdgeInsets.only(bottom: AppSpace.s6),
                child: Text(line, style: AppText.body),
              )),
          if (footer.trim().isNotEmpty) ...[
            const SizedBox(height: AppSpace.s6),
            Text('👉 $footer', style: AppText.body),
          ],
        ],
      ),
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
