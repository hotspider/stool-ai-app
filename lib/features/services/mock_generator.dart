import 'dart:math';

import '../models/advice_response.dart';
import '../models/analyze_response.dart';
import '../models/user_inputs.dart';

class MockGenerator {
  static final Random _random = Random();

  static const List<RiskLevel> _riskLevels = [
    RiskLevel.low,
    RiskLevel.medium,
    RiskLevel.high,
  ];
  static const List<int> _bristolTypes = [1, 2, 3, 4, 5, 6, 7];
  static const List<StoolColor> _colors = [
    StoolColor.brown,
    StoolColor.yellow,
    StoolColor.green,
    StoolColor.black,
    StoolColor.mixed,
  ];
  static const List<StoolTexture> _textures = [
    StoolTexture.normal,
    StoolTexture.hard,
    StoolTexture.mushy,
    StoolTexture.watery,
    StoolTexture.oily,
  ];
  static const List<String> _suspiciousSignals = [
    '轻微黏液',
    '颜色略深',
    '表面裂纹',
    '颗粒感明显',
    '边缘不整齐',
  ];
  static const List<String> _qualityIssues = [
    '光线偏暗',
    '对焦略糊',
    '目标区域偏小',
    '阴影遮挡',
  ];

  static AnalyzeResponse randomAnalysis() {
    final riskLevel = _riskLevels[_random.nextInt(_riskLevels.length)];
    final summary = switch (riskLevel) {
      RiskLevel.low => '整体表现较稳定，可先继续观察。',
      RiskLevel.medium => '有轻度波动迹象，建议关注近48小时变化。',
      RiskLevel.high => '存在需要留意的信号，建议结合症状判断。',
    };

    return AnalyzeResponse(
      riskLevel: riskLevel,
      summary: summary,
      bristolType: _bristolTypes[_random.nextInt(_bristolTypes.length)],
      color: _colors[_random.nextInt(_colors.length)],
      texture: _textures[_random.nextInt(_textures.length)],
      suspiciousSignals: _pickMany(_suspiciousSignals, 2, 3),
      qualityScore: 60 + _random.nextInt(36),
      qualityIssues: _pickMany(_qualityIssues, 1, 2),
      analyzedAt: DateTime.now(),
    );
  }

  static AdviceResponse adviceFor(AnalyzeResponse analysis, [UserInputs? inputs]) {
    final baseNext = <String>[
      '补水与均衡饮食，保持规律进食',
      '观察24-48小时内的变化趋势',
      '尽量保持充足睡眠与适度运动',
    ];
    final baseSeek = <String>[
      '持续腹痛或发热',
      '明显血色或黑便',
      '伴随严重乏力或头晕',
    ];

    if (analysis.riskLevel == RiskLevel.high) {
      baseNext.add('减少辛辣与酒精摄入');
      baseSeek.add('短时间内反复出现异常表现');
    } else if (analysis.riskLevel == RiskLevel.medium) {
      baseNext.add('记录饮食与作息，便于观察关联');
    }

    if (inputs != null) {
      if (inputs.odor == 'strong' ||
          inputs.odor == 'sour' ||
          inputs.odor == 'rotten') {
        baseNext.add('近期注意蛋白与油脂摄入比例');
      }
      if (inputs.painOrStrain) {
        baseNext.add('如有不适，优先休息并减少刺激性食物');
        baseSeek.add('疼痛持续加重或无法缓解');
      }
      if (inputs.dietKeywords.isNotEmpty) {
        baseNext.add('回顾近期饮食关键词：${inputs.dietKeywords}');
      }
    }

    return AdviceResponse(
      summary: '建议以自我观察为主，必要时寻求专业帮助。',
      next48hActions: baseNext,
      seekCareIf: baseSeek,
      disclaimers: const ['仅健康参考，不替代诊断'],
    );
  }

  static UserInputs defaultInputs() {
    return const UserInputs(
      odor: '无',
      painOrStrain: false,
      dietKeywords: '',
    );
  }

  static List<String> _pickMany(List<String> source, int min, int max) {
    final count = min + _random.nextInt(max - min + 1);
    final pool = List<String>.from(source)..shuffle(_random);
    return pool.take(count).toList();
  }
}
