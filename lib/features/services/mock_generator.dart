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

  static Map<String, dynamic> mockStructuredV2() {
    return {
      "ok": true,
      "schema_version": 2,
      "headline": "这次便便偏软但不算异常，更像轻度消化偏快。",
      "score": 72,
      "risk_level": "low",
      "confidence": 0.7,
      "uncertainty_note": "仅供参考，若症状加重请就医。",
      "stool_features": {
        "shape": "偏软/糊状",
        "shape_desc": "像稠粥/土豆泥",
        "color": "黄褐偏绿",
        "color_desc": "黄褐偏绿",
        "color_reason": "多与蔬菜摄入和肠道通过速度相关",
        "texture": "细腻",
        "texture_desc": "细腻糊状",
        "abnormal_signs": ["未见明显异常"],
        "bristol_type": 5,
        "bristol_range": "5-6",
        "volume": "medium",
        "wateriness": "mild",
        "mucus": "none",
        "foam": "none",
        "blood": "none",
        "undigested_food": "suspected",
        "separation_layers": "none",
        "odor_level": "normal",
        "visible_findings": ["seeds"],
      },
      "doctor_explanation": {
        "one_sentence_conclusion": "这次便便偏软但不算异常，更像轻度消化偏快。",
        "shape": "形态偏软、成团但不成型，符合轻度偏软。",
        "color": "黄褐偏绿常见于蔬菜摄入较多。",
        "texture": "未见水样分层或血丝，不像感染性腹泻。",
        "visual_analysis": {
          "shape": "形态偏软、成团但不成型，符合轻度偏软。",
          "color": "黄褐偏绿常见于蔬菜摄入较多。",
          "texture": "未见水样分层或血丝，不像感染性腹泻。",
        },
        "combined_judgement": "结合精神食欲尚可，更偏功能性偏软。",
      },
      "possible_causes": [
        {"title": "饮食结构影响", "explanation": "水果/蔬菜多时便便容易偏软。"},
        {"title": "肠道蠕动偏快", "explanation": "2-3 岁是肠道功能调试期。"},
        {"title": "轻微受凉或作息变化", "explanation": "短期波动但未发展成腹泻。"},
      ],
      "interpretation": {
        "overall_judgement": "偏功能性软便",
        "why_shape": ["含水量略高", "肠道通过偏快"],
        "why_color": ["蔬菜摄入较多", "胆汁通过速度略快"],
        "why_texture": ["未见血丝或脓液", "不符合感染性腹泻表现"],
        "how_context_affects": ["精神状态良好", "能吃能睡", "次数不多且晨起一泡"],
        "confidence_explain": "图片清晰且补充信息完整。",
      },
      "reasoning_bullets": [
        "形态偏软但非水样",
        "颜色无黑白或鲜红",
        "质地未见血丝/黏液",
        "精神食欲正常",
        "更符合功能性波动",
      ],
      "actions_today": {
        "diet": ["正常饮食，少量多餐", "米饭/面条/鸡蛋为主", "蔬菜适量"],
        "hydration": ["正常饮水", "少量多次补液", "观察尿量"],
        "care": ["便后温水清洁", "记录次数与形态", "保持作息规律"],
        "avoid": ["水果一次别太多", "冷饮/高糖减少", "油腻食物少一点"],
        "observe": ["次数是否增加", "是否发热/呕吐", "精神食欲变化"],
      },
      "red_flags": [
        {"title": "一天 ≥3-4 次", "detail": "且持续超过 24 小时"},
        {"title": "水样/喷射", "detail": "提示腹泻加重"},
        {"title": "血丝/黏液", "detail": "需就医评估"},
        {"title": "精神差 + 发热", "detail": "警惕感染"},
        {"title": "明显脱水", "detail": "尿量明显减少"},
      ],
      "follow_up_questions": ["是否发热？", "是否呕吐？", "24h 排便次数？", "是否腹痛？", "近期饮食变化？", "睡眠情况如何？"],
      "ui_strings": {
        "summary": "整体偏软但更像消化偏快。",
        "tags": ["Bristol 5-6", "黄褐偏绿", "偏软"],
        "sections": [
          {"title": "饮食", "icon_key": "diet", "items": ["正常饮食", "米饭/面条/鸡蛋", "蔬菜适量"]},
          {"title": "补液", "icon_key": "hydration", "items": ["正常饮水", "少量多次", "观察尿量"]},
          {"title": "护理", "icon_key": "care", "items": ["温水清洁", "记录变化", "作息规律"]},
          {"title": "警戒信号", "icon_key": "warning", "items": ["次数增多", "水样便", "血丝黏液"]},
        ],
        "longform": {
          "conclusion": "这次便便偏软但不算异常，更像轻度消化偏快。",
          "how_to_read": "形态偏软、颜色黄褐偏绿、质地细腻。",
          "context": "精神好、能吃能睡、次数不多，支持功能性偏软。",
          "causes": "多为饮食与肠道通过速度相关。",
          "todo": "正常饮食、少量多餐、观察变化。",
          "red_flags": "若次数增多或伴发热需警惕。",
          "reassure": "大多数情况可先观察。",
        },
      },
      "model_used": "mock",
      "proxy_version": "mock",
      "worker_version": "mock",
    };
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
