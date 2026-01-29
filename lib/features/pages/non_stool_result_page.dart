import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/image/image_source_service.dart';
import '../../ui/components/app_card.dart';
import '../../ui/components/bullet_list.dart';
import '../../ui/components/primary_button.dart';
import '../../ui/components/section_header.dart';
import '../../ui/design_tokens.dart';

class NonStoolResultPage extends StatelessWidget {
  final String? explanation;

  const NonStoolResultPage({super.key, this.explanation});

  @override
  Widget build(BuildContext context) {
    final reasons = [
      '目标不清晰或不在画面中心',
      '光线不足/反光导致细节丢失',
      '画面内容更像背景或其他物品',
    ];
    final tips = [
      '光线充足，避免背光/强反光',
      '对焦清晰，大便占画面 50% 以上',
      '只拍大便本身，尽量减少背景干扰',
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('无法分析'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(UiSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('未检测到大便', style: UiText.title),
                    const SizedBox(height: UiSpacing.sm),
                    Text(
                      '这张图片看起来不像大便，暂时无法进行大便健康分析。',
                      style: UiText.body,
                    ),
                    const SizedBox(height: UiSpacing.sm),
                    Text(
                      explanation?.trim().isNotEmpty == true
                          ? explanation!.trim()
                          : '为了避免误判，我们只在确认是“大便图片”后才会进入分析。',
                      style: UiText.hint,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: UiSpacing.lg),
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SectionHeader(
                      icon: Icons.info_outline,
                      title: '可能原因',
                    ),
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
                    const SectionHeader(
                      icon: Icons.photo_camera_outlined,
                      title: '重拍要点',
                    ),
                    const SizedBox(height: UiSpacing.sm),
                    BulletList(items: tips),
                  ],
                ),
              ),
              const SizedBox(height: UiSpacing.lg),
              PrimaryButton(
                label: '重新拍摄',
                onPressed: () => _repick(context, ImageSourceType.camera),
              ),
              const SizedBox(height: UiSpacing.sm),
              OutlinedButton(
                onPressed: () => _repick(context, ImageSourceType.gallery),
                child: const Text('从相册选择'),
              ),
              const SizedBox(height: UiSpacing.sm),
              Text(
                '本工具用于健康记录与辅助观察，不替代医生诊断。',
                style: UiText.hint,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _repick(BuildContext context, ImageSourceType source) async {
    try {
      final bytes = source == ImageSourceType.camera
          ? await ImageSourceService.instance.pickFromCamera()
          : await ImageSourceService.instance.pickFromGallery();
      if (bytes == null) {
        return;
      }
      if (context.mounted) {
        context.go(
          '/preview',
          extra: ImageSelection(bytes: bytes, source: source),
        );
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('无法获取图片权限，请稍后重试。')),
        );
      }
    }
  }
}

