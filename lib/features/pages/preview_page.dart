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
  final TextEditingController _stoolTimesController = TextEditingController();
  final TextEditingController _otherNotesController = TextEditingController();
  final Set<String> _selectedFoods = {};
  final Set<String> _selectedDrinks = {};
  final Set<String> _selectedOther = {};
  String? _moodEnergy;
  String? _appetite;
  String? _sleep;
  bool _fever = false;
  bool _vomit = false;
  bool _bellyPain = false;
  int? _stoolTimes24h;
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
    _stoolTimesController.dispose();
    _otherNotesController.dispose();
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
      final result = await ApiService.analyzeImage(
        imageBytes: _bytes!,
        contextInput: _buildContextInput(),
      );
      if (!mounted) {
        return;
      }
      final l10n = AppLocalizations.of(context)!;
      final payload = ResultPayload(
        analysis: result.analysis,
        advice: result.advice,
        structured: result.structured,
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
    final hasAny = _selectedFoods.isNotEmpty ||
        _selectedDrinks.isNotEmpty ||
        _selectedOther.isNotEmpty ||
        _moodEnergy != null ||
        _appetite != null ||
        _sleep != null ||
        _stoolTimes24h != null ||
        _otherNotesController.text.trim().isNotEmpty ||
        _fever ||
        _vomit ||
        _bellyPain;
    if (!hasAny) {
      return null;
    }
    final context = <String, dynamic>{
      if (_selectedFoods.isNotEmpty) 'recent_foods': _selectedFoods.toList(),
      if (_selectedDrinks.isNotEmpty) 'recent_drinks': _selectedDrinks.toList(),
      if (_moodEnergy != null) 'mood_energy': _moodEnergy,
      if (_appetite != null) 'appetite': _appetite,
      if (_sleep != null) 'sleep': _sleep,
      'fever': _fever,
      'vomit': _vomit,
      'belly_pain': _bellyPain,
      if (_stoolTimes24h != null) 'stool_times_24h': _stoolTimes24h,
      if (_selectedOther.contains('受凉')) 'cold_exposure': true,
      if (_selectedOther.isNotEmpty)
        'recent_events': _selectedOther.where((e) => e != '受凉').toList(),
      if (_otherNotesController.text.trim().isNotEmpty)
        'other_notes': _otherNotesController.text.trim(),
    };
    return context;
  }

  Widget _buildChipGroup({
    required String title,
    required List<String> options,
    required Set<String> selected,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: AppTokens.s8),
        Wrap(
          spacing: AppTokens.s8,
          runSpacing: AppTokens.s8,
          children: options
              .map(
                (label) => FilterChip(
                  label: Text(label),
                  selected: selected.contains(label),
                  onSelected: (value) {
                    setState(() {
                      if (value) {
                        selected.add(label);
                      } else {
                        selected.remove(label);
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

  Widget _buildDropdownField({
    required String title,
    required String? value,
    required ValueChanged<String?> onChanged,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      decoration: InputDecoration(
        labelText: title,
        border: const OutlineInputBorder(),
        isDense: true,
      ),
      items: const [
        DropdownMenuItem(value: 'good', child: Text('良好')),
        DropdownMenuItem(value: 'ok', child: Text('一般')),
        DropdownMenuItem(value: 'poor', child: Text('较差')),
      ],
      onChanged: (next) => setState(() => onChanged(next)),
    );
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
              title: const Text('补充信息（可选）'),
              subtitle: const Text('填写越完整，分析越准确'),
              childrenPadding: const EdgeInsets.only(bottom: AppTokens.s12),
              children: [
                _buildChipGroup(
                  title: '最近吃的',
                  options: const [
                    '水果多',
                    '香蕉',
                    '酸奶',
                    '牛奶',
                    '蔬菜多',
                    '肉多',
                    '油腻',
                    '辣',
                    '甜食',
                    '外食',
                  ],
                  selected: _selectedFoods,
                ),
                const SizedBox(height: AppTokens.s12),
                _buildChipGroup(
                  title: '最近喝的',
                  options: const ['奶', '果汁', '电解质水', '冷饮'],
                  selected: _selectedDrinks,
                ),
                const SizedBox(height: AppTokens.s12),
                _buildChipGroup(
                  title: '其他',
                  options: const ['受凉', '作息变化', '刚打疫苗', '刚生病恢复'],
                  selected: _selectedOther,
                ),
                const SizedBox(height: AppTokens.s16),
                _buildDropdownField(
                  title: '精神',
                  value: _moodEnergy,
                  onChanged: (v) => _moodEnergy = v,
                ),
                const SizedBox(height: AppTokens.s12),
                _buildDropdownField(
                  title: '食欲',
                  value: _appetite,
                  onChanged: (v) => _appetite = v,
                ),
                const SizedBox(height: AppTokens.s12),
                _buildDropdownField(
                  title: '睡眠',
                  value: _sleep,
                  onChanged: (v) => _sleep = v,
                ),
                const SizedBox(height: AppTokens.s12),
                SwitchListTile(
                  value: _fever,
                  onChanged: (v) => setState(() => _fever = v),
                  title: const Text('发热'),
                  contentPadding: EdgeInsets.zero,
                ),
                SwitchListTile(
                  value: _vomit,
                  onChanged: (v) => setState(() => _vomit = v),
                  title: const Text('呕吐'),
                  contentPadding: EdgeInsets.zero,
                ),
                SwitchListTile(
                  value: _bellyPain,
                  onChanged: (v) => setState(() => _bellyPain = v),
                  title: const Text('腹痛/哭闹'),
                  contentPadding: EdgeInsets.zero,
                ),
                const SizedBox(height: AppTokens.s8),
                TextField(
                  controller: _stoolTimesController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: const InputDecoration(
                    labelText: '24h 排便次数',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  onChanged: (value) {
                    final parsed = int.tryParse(value);
                    setState(() => _stoolTimes24h = parsed);
                  },
                ),
                const SizedBox(height: AppTokens.s12),
                TextField(
                  controller: _otherNotesController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: '补充说明',
                    border: OutlineInputBorder(),
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
