import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'dart:io';

import 'package:go_router/go_router.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:app/l10n/app_localizations.dart';

import '../../core/image/image_source_service.dart';
import '../../core/validation/basic_image_validator.dart';
import '../../core/validation/image_validator.dart';
import '../../design/widgets/app_scaffold.dart';
import '../../ui/components/app_card.dart';
import '../../ui/components/notice_banner.dart';
import '../../ui/components/primary_button.dart';
import '../../ui/components/section_header.dart';
import '../../ui/design_tokens.dart';
import '../models/analyze_context.dart';
import '../models/result_payload.dart';
import '../services/api_service.dart';
import '../widgets/error_state_card.dart';
import '../services/image_crop_service.dart';

class PreviewPage extends StatefulWidget {
  final ImageSelection? selection;

  const PreviewPage({super.key, this.selection});

  @override
  State<PreviewPage> createState() => _PreviewPageState();
}

class _PreviewPageState extends State<PreviewPage> {
  final ImageValidator _validator = BasicImageValidator();
  AnalyzeContext _ctx = const AnalyzeContext();
  bool _allowEmptyContextDebug = false;
  Uint8List? _bytes;
  bool _isValidating = false;
  bool _isAnalyzing = false;
  ImageValidationResult? _validation;
  final ScrollController _scrollController = ScrollController();
  late final TextEditingController _foodsController;
  late final TextEditingController _drinksController;
  late final TextEditingController _moodController;
  late final TextEditingController _notesController;

  @override
  void initState() {
    super.initState();
    _bytes = widget.selection?.bytes;
    _foodsController = TextEditingController(text: _ctx.foodsEaten ?? '');
    _drinksController = TextEditingController(text: _ctx.drinksTaken ?? '');
    _moodController = TextEditingController(text: _ctx.moodState ?? '');
    _notesController = TextEditingController(text: _ctx.otherNotes ?? '');
    _foodsController.addListener(_syncContext);
    _drinksController.addListener(_syncContext);
    _moodController.addListener(_syncContext);
    _notesController.addListener(_syncContext);
    _syncContext();
    if (_bytes != null) {
      _validate();
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _foodsController.dispose();
    _drinksController.dispose();
    _moodController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _syncContext() {
    final foods = _foodsController.text.trim();
    final drinks = _drinksController.text.trim();
    final mood = _moodController.text.trim();
    final notes = _notesController.text.trim();
    _ctx = AnalyzeContext(
      foodsEaten: foods.isEmpty ? '未填写' : foods,
      drinksTaken: drinks.isEmpty ? '未填写' : drinks,
      moodState: mood.isEmpty ? '未填写' : mood,
      otherNotes: notes.isEmpty ? null : notes,
    );
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
                size: 36, color: UiColors.riskMedium),
            const SizedBox(height: UiSpacing.md),
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

  Future<(int width, int height)?> _decodeImageSize(Uint8List bytes) async {
    try {
      final completer = Completer<ui.Image>();
      ui.decodeImageFromList(bytes, (image) => completer.complete(image));
      final image = await completer.future;
      final size = (image.width, image.height);
      image.dispose();
      return size;
    } catch (_) {
      return null;
    }
  }

  Future<void> _startAnalyze() async {
    if (_bytes == null || _isAnalyzing) {
      return;
    }
    final imageSize = await _decodeImageSize(_bytes!);
    final width = imageSize?.$1 ?? 0;
    final height = imageSize?.$2 ?? 0;
    debugPrint(
      '[Preview] upload image size: ${width}x$height bytes=${_bytes!.length}',
    );
    const minEdge = 800;
    const minBytes = 60 * 1024;
    if (width < minEdge || height < minEdge || _bytes!.length < minBytes) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('建议更近更清晰，目标占画面 50% 以上（仍可继续分析）'),
          ),
        );
      }
    }
    final foods = _foodsController.text.trim();
    final drinks = _drinksController.text.trim();
    final mood = _moodController.text.trim();
    if (foods.isEmpty || drinks.isEmpty || mood.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('补充吃喝/精神状态可让分析更准确（可跳过）')),
        );
      }
    }
    if (_validation != null && _validation!.ok == false) {
      if (_validation!.reason == ImageValidationReason.tooSmall) {
        final proceed =
            await _showQualityDialog(_validation!.reason, allowProceed: true);
        if (!proceed) {
          return;
        }
      } else {
        await _showQualityDialog(_validation!.reason);
        return;
      }
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
        mode: _allowEmptyContextDebug ? 'debug' : 'prod',
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
        debugInfo: result.debugInfo,
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

  Future<bool> _showQualityDialog(
    ImageValidationReason reason, {
    bool allowProceed = false,
  }) async {
    if (!mounted) {
      return false;
    }
    final reasonText = _qualityReasonText(reason);
    var proceed = false;
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('图片不清晰，建议重拍'),
        content: Text(
          '原因：$reasonText\n建议：目标占画面 50% 以上，优先裁剪/放大目标区域。',
        ),
        actions: [
          if (allowProceed)
            FilledButton(
              onPressed: () {
                proceed = true;
                Navigator.of(context).pop();
              },
              child: const Text('仍然继续分析'),
            ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await _recropCurrent();
            },
            child: const Text('重新裁剪'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _repick(ImageSourceType.gallery);
            },
            child: const Text('重新选择'),
          ),
        ],
      ),
    );
    return proceed;
  }

  String _qualityReasonText(ImageValidationReason reason) {
    switch (reason) {
      case ImageValidationReason.tooSmall:
        return '目标太小';
      case ImageValidationReason.tooDark:
        return '光线不足';
      case ImageValidationReason.tooBlurry:
        return '对焦不清';
      case ImageValidationReason.notTarget:
        return '目标不在画面中';
      case ImageValidationReason.unknown:
        return '图片无法识别';
    }
  }

  Future<void> _recropCurrent() async {
    if (_bytes == null) {
      return;
    }
    try {
      final tempDir = await getTemporaryDirectory();
      final tempFile = File('${tempDir.path}/stool_preview_${DateTime.now().millisecondsSinceEpoch}.jpg');
      await tempFile.writeAsBytes(_bytes!, flush: true);
      final cropped = await ImageCropService.crop(tempFile);
      if (cropped == null) {
        return;
      }
      final newBytes = await cropped.readAsBytes();
      if (!mounted) {
        return;
      }
      setState(() {
        _bytes = newBytes;
        _validation = null;
      });
      _validate();
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
      padding: EdgeInsets.zero,
      resizeToAvoidBottomInset: true,
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(UiSpacing.md),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                canAnalyze ? '将结合图片与补充信息进行分析' : '请先选择图片',
                style: UiText.hint,
              ),
              const SizedBox(height: UiSpacing.sm),
              PrimaryButton(
                label: '提交并分析',
                isLoading: _isAnalyzing,
                onPressed: canAnalyze ? _startAnalyze : null,
              ),
            ],
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            _buildImagePreview(),
            const Divider(height: 1),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                controller: _scrollController,
                child: _buildExtraInputsForm(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImagePreview() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: AppCard(
        padding: EdgeInsets.zero,
        child: SizedBox(
          height: 300,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(UiRadius.card),
            child: Image.memory(
              _bytes!,
              fit: BoxFit.cover,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildExtraInputsForm() {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
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
          NoticeBanner(
            title: '拍摄质量提示',
            items: [l10n.previewWeakPass],
            color: UiColors.riskMedium,
          )
        else if (_validation != null && _validation!.ok == false)
          NoticeBanner(
            title: '拍摄质量提示',
            items: [_errorDescription(_validation!.reason, _validation!.message)],
            color: UiColors.riskMedium,
          )
        else if (_validation?.ok == true)
          Text(l10n.previewPass, style: UiText.hint),
        const SizedBox(height: 6),
        Text('建议：目标占画面 50% 以上', style: UiText.hint),
        const SizedBox(height: UiSpacing.lg),
        const SectionHeader(
          icon: Icons.edit_note,
          title: '补充信息',
          tag: '提升准确度',
        ),
        const SizedBox(height: UiSpacing.sm),
        Text('填写后可提升判断准确度', style: UiText.hint),
        const SizedBox(height: UiSpacing.md),
        _buildTextFieldCard(
          label: '吃了什么',
          hint: '例如：香蕉+米饭',
          controller: _foodsController,
        ),
        const SizedBox(height: UiSpacing.md),
        _buildTextFieldCard(
          label: '喝了什么',
          hint: '例如：牛奶+温水',
          controller: _drinksController,
        ),
        const SizedBox(height: UiSpacing.md),
        _buildTextFieldCard(
          label: '精神状态',
          hint: '例如：精神好/一般/嗜睡/烦躁',
          controller: _moodController,
        ),
        const SizedBox(height: UiSpacing.md),
        _buildTextFieldCard(
          label: '其他',
          hint: '例如：无发热，无呕吐，次数不多',
          controller: _notesController,
          maxLines: 4,
        ),
        const SizedBox(height: UiSpacing.lg),
        if (kDebugMode)
          TextButton(
            onPressed: () {
              setState(() => _allowEmptyContextDebug = !_allowEmptyContextDebug);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    _allowEmptyContextDebug ? '已开启调试模式' : '已关闭调试模式',
                  ),
                ),
              );
            },
            child: Text(
              _allowEmptyContextDebug ? '关闭调试模式' : '开启调试模式',
            ),
          ),
        OutlinedButton(
          onPressed: () => _repick(ImageSourceType.gallery),
          child: Text(l10n.previewRechoose),
        ),
      ],
    );
  }

  Widget _buildTextFieldCard({
    required String label,
    required String hint,
    required TextEditingController controller,
    int maxLines = 1,
  }) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: UiText.section),
          const SizedBox(height: UiSpacing.sm),
          TextFormField(
            controller: controller,
            maxLines: maxLines,
            decoration: InputDecoration(
              hintText: hint,
            ),
          ),
        ],
      ),
    );
  }
}
