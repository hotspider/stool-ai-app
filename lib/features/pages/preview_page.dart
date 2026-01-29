import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:app/l10n/app_localizations.dart';

import '../../core/image/image_source_service.dart';
import '../../core/validation/basic_image_validator.dart';
import '../../core/validation/image_validator.dart';
import '../../design/tokens.dart';
import '../../design/widgets/app_scaffold.dart';
import '../../design/widgets/press_scale.dart';
import '../../design/widgets/soft_card.dart';
import '../models/analyze_context.dart';
import '../models/result_payload.dart';
import '../services/api_service.dart';
import '../widgets/error_state_card.dart';
import '../widgets/optional_context_panel.dart';

class PreviewPage extends StatefulWidget {
  final ImageSelection? selection;

  const PreviewPage({super.key, this.selection});

  @override
  State<PreviewPage> createState() => _PreviewPageState();
}

class _PreviewPageState extends State<PreviewPage> {
  final ImageValidator _validator = BasicImageValidator();
  AnalyzeContext _ctx = const AnalyzeContext();
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
      final result = await ApiService.analyzeImage(
        imageBytes: _bytes!,
        odor: 'none',
        painOrStrain: false,
        context: _ctx,
      );
      if (!mounted) {
        return;
      }
      final l10n = AppLocalizations.of(context)!;
      final payload = ResultPayload(
        analysis: result.analysis,
        advice: result.advice,
        structured: result.structured,
        contextInput: _ctx.toJson(),
        contextSummary: _buildContextSummary(_ctx.toJson()),
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
                Clipboard.setData(ClipboardData(text: details)),
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

  String _buildContextSummary(Map<String, dynamic>? context) {
    if (context == null || context.isEmpty) {
      return '你填写的情况显示：未补充额外信息。';
    }
    final parts = <String>[];
    final foods = context['foods_eaten']?.toString();
    if (foods != null && foods.trim().isNotEmpty) {
      parts.add('吃了：$foods');
    }
    final drinks = context['drinks_taken']?.toString();
    if (drinks != null && drinks.trim().isNotEmpty) {
      parts.add('喝了：$drinks');
    }
    final mood = context['mood_state']?.toString();
    if (mood != null && mood.trim().isNotEmpty) {
      parts.add('精神状态：$mood');
    }
    final notes = context['other_notes']?.toString();
    if (notes != null && notes.trim().isNotEmpty) {
      parts.add('其他：$notes');
    }
    return '你填写的情况显示：${parts.join('，')}。';
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
            child: OptionalContextPanel(
              initial: _ctx,
              onChanged: (next) => _ctx = next,
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
