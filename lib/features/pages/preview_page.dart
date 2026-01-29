import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:app/l10n/app_localizations.dart';

import '../../core/image/image_source_service.dart';
import '../../core/validation/basic_image_validator.dart';
import '../../core/validation/image_validator.dart';
import '../../design/tokens.dart';
import '../../design/widgets/app_scaffold.dart';
import '../../design/widgets/press_scale.dart';
import '../../design/widgets/soft_card.dart';
import '../models/result_payload.dart';
import '../services/api_service.dart';
import '../widgets/error_state_card.dart';

class PreviewPage extends StatefulWidget {
  final ImageSelection? selection;

  const PreviewPage({super.key, this.selection});

  @override
  State<PreviewPage> createState() => _PreviewPageState();
}

class _PreviewPageState extends State<PreviewPage> {
  final ImageValidator _validator = BasicImageValidator();
  final Set<String> _dietTags = {};
  final Set<String> _warningSigns = {};
  String? _moodState;
  String? _appetite;
  String? _hydrationIntake;
  String? _odor;
  bool _painOrStrain = false;
  int _poopCount24h = 1;
  bool _poopCountTouched = false;
  Uint8List? _bytes;
  bool _isValidating = false;
  bool _isAnalyzing = false;
  ImageValidationResult? _validation;

  @override
  void initState() {
    super.initState();
    _bytes = widget.selection?.bytes;
    if (_bytes != null) {
      _validate();
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _validate() async {
    if (_bytes == null) {
      return;
    }
    setState(() {
      _isValidating = true;
    });
    final result = await _validator.validate(_bytes!);
    if (!mounted) {
      return;
    }
    setState(() {
      _validation = result;
      _isValidating = false;
    });
  }

  Future<void> _showInvalidSheet(
    ImageValidationReason reason,
    String message,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    final title = _errorTitle(reason);
    final description = _errorDescription(reason, message);
    await showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      isDismissible: true,
      builder: (context) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(Icons.error_outline,
                size: 36, color: AppTokens.riskMedium),
            const SizedBox(height: AppTokens.s12),
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(description, style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () {
                Navigator.of(context).pop();
                _repick(ImageSourceType.camera);
              },
              child: Text(l10n.previewRetake),
            ),
            const SizedBox(height: 8),
            OutlinedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _repick(ImageSourceType.gallery);
              },
              child: Text(l10n.previewSelectAgain),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                if (mounted) {
                  context.pop();
                }
              },
              child: Text(l10n.previewCancel),
            ),
          ],
        ),
      ),
    );
  }

  String _errorDescription(ImageValidationReason reason, String fallback) {
    final l10n = AppLocalizations.of(context)!;
    switch (reason) {
      case ImageValidationReason.notTarget:
        return l10n.previewNotTargetMessage;
      case ImageValidationReason.tooBlurry:
        return l10n.previewBlurryMessage;
      case ImageValidationReason.tooDark:
        return fallback;
      case ImageValidationReason.tooSmall:
        return fallback;
      case ImageValidationReason.unknown:
        return l10n.previewUnknownMessage;
    }
  }

  String _errorTitle(ImageValidationReason reason) {
    final l10n = AppLocalizations.of(context)!;
    switch (reason) {
      case ImageValidationReason.tooSmall:
        return '图片尺寸过小';
      case ImageValidationReason.tooDark:
        return '图片太暗';
      case ImageValidationReason.tooBlurry:
        return '图片不清晰';
      case ImageValidationReason.notTarget:
        return l10n.previewNotTargetTitle;
      case ImageValidationReason.unknown:
        return '图片无法识别';
    }
  }

  bool _shouldShowSheet(ImageValidationResult result) {
    if (result.ok) {
      return false;
    }
    return result.reason == ImageValidationReason.tooDark ||
        result.reason == ImageValidationReason.tooBlurry ||
        result.reason == ImageValidationReason.tooSmall;
  }

  Future<void> _repick(ImageSourceType source) async {
    try {
      final bytes = source == ImageSourceType.camera
          ? await ImageSourceService.instance.pickFromCamera()
          : await ImageSourceService.instance.pickFromGallery();
      if (bytes == null) {
        if (mounted) {
          final l10n = AppLocalizations.of(context)!;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.previewCanceled)),
          );
        }
        return;
      }
      if (!mounted) {
        return;
      }
      setState(() {
        _bytes = bytes;
        _validation = null;
      });
      _validate();
    } on ImageSourceFailure catch (_) {
      if (!mounted) {
        return;
      }
      _showPermissionSheet(source);
    } catch (_) {
      if (!mounted) {
        return;
      }
      final l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.previewPickFailed)),
      );
    }
  }

  void _showPermissionSheet(ImageSourceType source) {
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

  Future<void> _startAnalyze() async {
    if (_bytes == null || _isAnalyzing) {
      return;
    }
    debugPrint(
      'Preview analyze: bytes=${_bytes?.length ?? 0}, validation=${_validation?.reason}, url=${ApiService.baseUrl}/analyze',
    );
    setState(() {
      _isAnalyzing = true;
    });
    try {
      final context = _buildContextInput();
      final result = await ApiService.analyzeImage(
        imageBytes: _bytes!,
        odor: _odor ?? 'none',
        painOrStrain: _painOrStrain,
        context: context,
      );
      if (!mounted) {
        return;
      }
      final l10n = AppLocalizations.of(context)!;
      final payload = ResultPayload(
        analysis: result.analysis,
        advice: result.advice,
        structured: result.structured,
        contextInput: context,
        contextSummary: _buildContextSummary(context),
        validationWarning:
            _validation?.weakPass == true ? l10n.previewWeakPass : null,
      );
      context.push('/result', extra: payload);
    } on ApiServiceException catch (e) {
      if (!mounted) {
        return;
      }
      final l10n = AppLocalizations.of(context)!;
      final message = e.code == ApiServiceErrorCode.notTarget
          ? '未识别到目标，请换更清晰或包含尿不湿/便便的图片'
          : (e.message ?? l10n.resultErrorMessage);
      final details =
          'ApiServiceException: ${e.code} ${e.message ?? ''}'.trim();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          action: SnackBarAction(
            label: '复制错误',
            onPressed: () => Clipboard.setData(ClipboardData(text: details)),
          ),
        ),
      );
    } catch (_) {
      if (!mounted) {
        return;
      }
      final l10n = AppLocalizations.of(context)!;
      const details = 'Unknown error during analyze';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.resultErrorMessage),
          action: SnackBarAction(
            label: '复制错误',
            onPressed: () =>
                Clipboard.setData(const ClipboardData(text: details)),
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isAnalyzing = false;
        });
      }
    }
  }

  Map<String, dynamic>? _buildContextInput() {
    final hasAny = _moodState != null ||
        _appetite != null ||
        _hydrationIntake != null ||
        _odor != null ||
        _dietTags.isNotEmpty ||
        _warningSigns.isNotEmpty ||
        _painOrStrain ||
        _poopCountTouched;
    if (!hasAny) {
      return null;
    }
    final context = <String, dynamic>{
      'age_months': 30,
      if (_moodState != null) 'mood_state': _moodState,
      if (_appetite != null) 'appetite': _appetite,
      if (_poopCountTouched) 'poop_count_24h': _poopCount24h,
      'pain_or_strain': _painOrStrain,
      if (_dietTags.isNotEmpty) 'diet_tags': _dietTags.toList(),
      if (_hydrationIntake != null) 'hydration_intake': _hydrationIntake,
      if (_warningSigns.isNotEmpty) 'warning_signs': _warningSigns.toList(),
      if (_odor != null) 'odor': _odor,
    };
    return context;
  }

  String _buildContextSummary(Map<String, dynamic>? context) {
    if (context == null || context.isEmpty) {
      return '你填写的情况显示：未补充额外信息。';
    }
    final parts = <String>[];
    final mood = context['mood_state']?.toString();
    if (mood == 'good') parts.add('精神状态良好');
    if (mood == 'normal') parts.add('精神状态一般');
    if (mood == 'poor') parts.add('精神状态偏差');
    final appetite = context['appetite']?.toString();
    if (appetite == 'normal') parts.add('食欲正常');
    if (appetite == 'slightly_low') parts.add('食欲稍差');
    if (appetite == 'poor') parts.add('食欲明显下降');
    if (context['poop_count_24h'] != null) {
      parts.add('24 小时内排便 ${context['poop_count_24h']} 次');
    }
    if (context['pain_or_strain'] == true) {
      parts.add('排便时有用力/哭闹');
    } else {
      parts.add('排便时无明显不适');
    }
    final hydration = context['hydration_intake']?.toString();
    if (hydration == 'normal') parts.add('饮水正常');
    if (hydration == 'low') parts.add('饮水偏少');
    if (hydration == 'high') parts.add('饮水偏多');
    final warning = context['warning_signs'];
    if (warning is List && warning.isNotEmpty) {
      final mapped = warning.map((item) {
        switch (item.toString()) {
          case 'fever':
            return '发热';
          case 'vomiting':
            return '呕吐';
          case 'abdominal_pain':
            return '明显腹痛';
          case 'blood_or_mucus':
            return '血丝/粘液';
          case 'black_or_pale':
            return '黑便/灰白便';
          default:
            return item.toString();
        }
      }).toList();
      parts.add('出现${mapped.join('、')}');
    } else {
      parts.add('未出现发热/呕吐/腹痛等危险信号');
    }
    return '你填写的情况显示：${parts.join('，')}。';
  }

  Widget _buildSingleChoice({
    required String title,
    required String? value,
    required Map<String, String> options,
    required ValueChanged<String?> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: AppTokens.s8),
        Wrap(
          spacing: AppTokens.s8,
          runSpacing: AppTokens.s8,
          children: options.entries
              .map(
                (entry) => ChoiceChip(
                  label: Text(entry.key),
                  selected: value == entry.value,
                  onSelected: (_) => setState(
                    () => onChanged(value == entry.value ? null : entry.value),
                  ),
                ),
              )
              .toList(),
        ),
      ],
    );
  }

  Widget _buildTagGroup({
    required String title,
    required Map<String, String> options,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: AppTokens.s8),
        Wrap(
          spacing: AppTokens.s8,
          runSpacing: AppTokens.s8,
          children: options.entries
              .map(
                (entry) => FilterChip(
                  label: Text(entry.key),
                  selected: _dietTags.contains(entry.value),
                  onSelected: (value) {
                    setState(() {
                      if (value) {
                        _dietTags.add(entry.value);
                      } else {
                        _dietTags.remove(entry.value);
                      }
                    });
                  },
                ),
              )
              .toList(),
        ),
      ],
    );
  }

  Widget _buildMultiSelect({
    required String title,
    required Map<String, String> options,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: AppTokens.s8),
        ...options.entries.map(
          (entry) => CheckboxListTile(
            value: _warningSigns.contains(entry.value),
            onChanged: (value) {
              setState(() {
                if (value == true) {
                  _warningSigns.add(entry.value);
                } else {
                  _warningSigns.remove(entry.value);
                }
              });
            },
            title: Text(entry.key),
            contentPadding: EdgeInsets.zero,
            controlAffinity: ListTileControlAffinity.leading,
          ),
        ),
      ],
    );
  }

  Widget _buildStepper({
    required String title,
    required int value,
    required ValueChanged<int> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: AppTokens.s8),
        Row(
          children: [
            IconButton(
              onPressed: value <= 0 ? null : () => onChanged(value - 1),
              icon: const Icon(Icons.remove_circle_outline),
            ),
            Text('$value', style: Theme.of(context).textTheme.titleMedium),
            IconButton(
              onPressed: value >= 10 ? null : () => onChanged(value + 1),
              icon: const Icon(Icons.add_circle_outline),
            ),
          ],
        ),
      ],
    );
  }

  int _filledCount() {
    var count = 0;
    if (_moodState != null) count += 1;
    if (_appetite != null) count += 1;
    if (_poopCountTouched) count += 1;
    if (_painOrStrain) count += 1;
    if (_dietTags.isNotEmpty) count += 1;
    if (_hydrationIntake != null) count += 1;
    if (_warningSigns.isNotEmpty) count += 1;
    if (_odor != null) count += 1;
    return count;
  }

  void _resetInputs() {
    setState(() {
      _moodState = null;
      _appetite = null;
      _hydrationIntake = null;
      _odor = null;
      _painOrStrain = false;
      _poopCount24h = 1;
      _poopCountTouched = false;
      _dietTags.clear();
      _warningSigns.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    if (_bytes == null) {
      return AppScaffold(
        title: l10n.previewTitle,
        body: ErrorStateCard(
          title: l10n.previewNoImageTitle,
          message: l10n.previewNoImageMessage,
          primaryLabel: l10n.previewBackHome,
          onPrimary: () => context.go('/home'),
        ),
      );
    }

    final canAnalyze = _bytes != null && !_isValidating && !_isAnalyzing;

    return AppScaffold(
      title: l10n.previewTitle,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SoftCard(
            padding: EdgeInsets.zero,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppTokens.r16),
              child: AspectRatio(
                aspectRatio: 1,
                child: Image.memory(
                  _bytes!,
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
          const SizedBox(height: AppTokens.s12),
          if (_isValidating)
            Row(
              children: [
                const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                const SizedBox(width: 8),
                Text(l10n.previewValidating),
              ],
            )
          else if (_validation?.ok == true && _validation?.weakPass == true)
            Text(
              l10n.previewWeakPass,
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: AppTokens.riskMedium),
            )
          else if (_validation != null && _validation!.ok == false)
            Text(
              _errorDescription(_validation!.reason, _validation!.message),
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: AppTokens.riskMedium),
            )
          else if (_validation?.ok == true)
            Text(
              l10n.previewPass,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          const SizedBox(height: AppTokens.s12),
          SoftCard(
            padding: const EdgeInsets.symmetric(
              horizontal: AppTokens.s12,
              vertical: AppTokens.s8,
            ),
            child: ExpansionTile(
              tilePadding: EdgeInsets.zero,
              title: Row(
                children: [
                  const Text('补充信息（可选）'),
                  const SizedBox(width: AppTokens.s8),
                  Text('已填写 ${_filledCount()}/8 项',
                      style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
              subtitle: const Text('建议填写，提升准确度'),
              childrenPadding: const EdgeInsets.only(bottom: AppTokens.s12),
              children: [
                _buildSingleChoice(
                  title: '精神状态',
                  value: _moodState,
                  options: const {
                    '😊 精神好（活跃/玩耍）': 'good',
                    '😐 一般（略疲惫）': 'normal',
                    '😴 精神差（嗜睡/不爱动）': 'poor',
                  },
                  onChanged: (next) => _moodState = next,
                ),
                const SizedBox(height: AppTokens.s12),
                _buildSingleChoice(
                  title: '食欲情况',
                  value: _appetite,
                  options: const {
                    '👍 吃得和平时差不多': 'normal',
                    '😕 吃得少一点': 'slightly_low',
                    '❌ 明显不想吃': 'poor',
                  },
                  onChanged: (next) => _appetite = next,
                ),
                const SizedBox(height: AppTokens.s12),
                _buildStepper(
                  title: '24 小时内排便次数',
                  value: _poopCount24h,
                  onChanged: (next) {
                    setState(() {
                      _poopCount24h = next;
                      _poopCountTouched = true;
                    });
                  },
                ),
                const SizedBox(height: AppTokens.s12),
                SwitchListTile(
                  value: _painOrStrain,
                  onChanged: (v) => setState(() => _painOrStrain = v),
                  title: const Text('是否疼痛或用力'),
                  contentPadding: EdgeInsets.zero,
                ),
                const SizedBox(height: AppTokens.s12),
                _buildTagGroup(
                  title: '最近 24h 吃过哪些',
                  options: const {
                    '水果多（香蕉/苹果/梨）': 'fruit',
                    '绿叶菜多': 'vegetable',
                    '肉类多': 'meat',
                    '汤水多': 'soup',
                    '奶 / 配方奶': 'milk',
                    '酸奶': 'yogurt',
                    '冷饮/凉食': 'cold',
                    '油腻食物': 'greasy',
                    '新加辅食': 'new_food',
                  },
                ),
                const SizedBox(height: AppTokens.s12),
                _buildSingleChoice(
                  title: '饮水/喝的东西',
                  value: _hydrationIntake,
                  options: const {
                    '正常喝水': 'normal',
                    '喝得偏少': 'low',
                    '最近喝得很多': 'high',
                  },
                  onChanged: (next) => _hydrationIntake = next,
                ),
                const SizedBox(height: AppTokens.s12),
                _buildMultiSelect(
                  title: '是否出现以下情况',
                  options: const {
                    '发热': 'fever',
                    '呕吐': 'vomiting',
                    '明显腹痛': 'abdominal_pain',
                    '血丝/粘液': 'blood_or_mucus',
                    '黑便/灰白便': 'black_or_pale',
                  },
                ),
                const SizedBox(height: AppTokens.s12),
                DropdownButtonFormField<String>(
                  value: _odor,
                  decoration: const InputDecoration(
                    labelText: '气味',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  items: const [
                    DropdownMenuItem(value: 'none', child: Text('无明显气味')),
                    DropdownMenuItem(value: 'stronger', child: Text('比平时重')),
                    DropdownMenuItem(value: 'foul', child: Text('非常臭 / 刺鼻')),
                  ],
                  onChanged: (value) => setState(() => _odor = value),
                ),
                const SizedBox(height: AppTokens.s12),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: _resetInputs,
                    child: const Text('恢复默认'),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppTokens.s24),
          Row(
            children: [
              Expanded(
                child: PressScale(
                  child: OutlinedButton(
                    onPressed: () => _repick(ImageSourceType.gallery),
                    child: Text(l10n.previewRechoose),
                  ),
                ),
              ),
              const SizedBox(width: AppTokens.s12),
              Expanded(
                child: PressScale(
                  enabled: canAnalyze,
                  child: FilledButton(
                    onPressed: canAnalyze ? _startAnalyze : null,
                    child: _isAnalyzing
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(l10n.previewStartAnalyze),
                  ),
                ),
              ),
            ],
          ),
          if (_isAnalyzing) ...[
            const SizedBox(height: AppTokens.s8),
            Text(
              '预计 10~30 秒',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
          const SizedBox(height: AppTokens.s12),
          Text(
            l10n.previewHint,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}
