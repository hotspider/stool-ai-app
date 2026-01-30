import 'package:flutter/foundation.dart';

class StoolAnalysisParseResult {
  final StoolAnalysisResult result;
  final List<String> missing;

  const StoolAnalysisParseResult({
    required this.result,
    required this.missing,
  });
}

class StoolAnalysisResult {
  final bool ok;
  final String errorCode;
  final String modelUsed;
  final bool isStoolImage;
  final String explanation;
  final Map<String, dynamic>? inputContext;
  final String headline;
  final int score;
  final String riskLevel;
  final double confidence;
  final double analysisConfidence;
  final String analysisMode;
  final String uncertaintyNote;
  final String imageValidationStatus;
  final List<String> imageValidationTips;
  final StoolFeatures stoolFeatures;
  final DoctorExplanation doctorExplanation;
  final List<PossibleCause> possibleCauses;
  final Interpretation interpretation;
  final List<String> reasoningBullets;
  final ActionsToday actionsToday;
  final List<RedFlagItem> redFlags;
  final List<String> followUpQuestions;
  final UiStrings uiStrings;

  final String summary;
  final int? bristolType;
  final String? color;
  final String? texture;
  final String hydrationHint;
  final List<String> dietAdvice;

  const StoolAnalysisResult({
    required this.ok,
    required this.errorCode,
    required this.modelUsed,
    required this.isStoolImage,
    required this.explanation,
    required this.inputContext,
    required this.headline,
    required this.score,
    required this.riskLevel,
    required this.confidence,
    required this.analysisConfidence,
    required this.analysisMode,
    required this.uncertaintyNote,
    required this.imageValidationStatus,
    required this.imageValidationTips,
    required this.stoolFeatures,
    required this.doctorExplanation,
    required this.possibleCauses,
    required this.interpretation,
    required this.reasoningBullets,
    required this.actionsToday,
    required this.redFlags,
    required this.followUpQuestions,
    required this.uiStrings,
    required this.summary,
    required this.bristolType,
    required this.color,
    required this.texture,
    required this.hydrationHint,
    required this.dietAdvice,
  });

  static StoolAnalysisParseResult parse(Map<String, dynamic> json) {
    final missing = <String>[];

    String _string(String key, {String fallback = ''}) {
      final value = json[key];
      if (value == null) {
        missing.add(key);
        return fallback;
      }
      final s = value.toString().trim();
      if (s.isEmpty) {
        missing.add(key);
        return fallback;
      }
      return s;
    }

    int _int(String key, {int fallback = 50}) {
      final value = json[key];
      if (value == null) {
        missing.add(key);
        return fallback;
      }
      if (value is int) return value;
      final parsed = int.tryParse(value.toString());
      if (parsed == null) {
        missing.add(key);
        return fallback;
      }
      return parsed;
    }

    double _double(String key, {double fallback = 0.6}) {
      final value = json[key];
      if (value == null) {
        missing.add(key);
        return fallback;
      }
      if (value is num) return value.toDouble();
      final parsed = double.tryParse(value.toString());
      if (parsed == null) {
        missing.add(key);
        return fallback;
      }
      return parsed;
    }

    Map<String, dynamic> _map(String key) {
      final value = json[key];
      if (value is Map<String, dynamic>) return value;
      if (value is Map) {
        return value.map((k, v) => MapEntry(k.toString(), v));
      }
      missing.add(key);
      return const <String, dynamic>{};
    }

    List<String> _list(String key) {
      final value = json[key];
      if (value is List) {
        final list = value.map((e) => e.toString()).toList();
        if (list.isEmpty) missing.add(key);
        return list;
      }
      missing.add(key);
      return const [];
    }

    final ok = json['ok'] == true;
    final errorCode = json['error_code']?.toString() ?? '';
    final modelUsed = json['model_used']?.toString() ?? '';
    final headline = _string('headline');
    final score = _int('score');
    final riskLevel = _string('risk_level', fallback: 'low');
    final confidence = _double('confidence');
    final analysisConfidence =
        _double('analysis_confidence', fallback: 0.4);
    final analysisModeRaw = json['analysis_mode']?.toString() ?? '';
    final analysisMode = ['full', 'low_confidence', 'general_advice']
            .contains(analysisModeRaw)
        ? analysisModeRaw
        : 'low_confidence';
    final uncertaintyNote = _string('uncertainty_note');
    String imageValidationStatus = '';
    List<String> imageValidationTips = const [];
    final imageValidation = json['image_validation'];
    if (imageValidation is Map) {
      imageValidationStatus =
          imageValidation['status']?.toString() ?? '';
      final tips = imageValidation['tips'];
      if (tips is List) {
        imageValidationTips = tips.map((e) => e.toString()).toList();
      }
    }
    final isStoolImage = json['is_stool_image'] != false;
    final explanation = json['explanation']?.toString() ?? '';
    Map<String, dynamic>? inputContext;
    final inputEcho = json['input_echo'];
    if (inputEcho is Map && inputEcho['context'] is Map) {
      inputContext = (inputEcho['context'] as Map)
          .map((k, v) => MapEntry(k.toString(), v));
    } else if (json['input_context'] is Map) {
      inputContext = (json['input_context'] as Map)
          .map((k, v) => MapEntry(k.toString(), v));
    } else if (json['context'] is Map) {
      inputContext =
          (json['context'] as Map).map((k, v) => MapEntry(k.toString(), v));
    } else if (json['context_input'] is Map) {
      inputContext = (json['context_input'] as Map)
          .map((k, v) => MapEntry(k.toString(), v));
    }

    StoolFeatures stoolFeatures;
    final stoolRaw = json['stool_features'];
    if (stoolRaw == null) {
      stoolFeatures = StoolFeatures.empty();
    } else {
      stoolFeatures = StoolFeatures.parse(
        _map('stool_features'),
        missing,
      );
    }
    DoctorExplanation doctorExplanation;
    final doctorRaw = json['doctor_explanation'];
    if (doctorRaw == null) {
      doctorExplanation = const DoctorExplanation.empty();
    } else {
      doctorExplanation = DoctorExplanation.parse(
        _map('doctor_explanation'),
        missing,
      );
    }
    final possibleCauses = PossibleCause.parseList(
      _listOfMaps(json, 'possible_causes', missing),
    );
    final interpretation = Interpretation.parse(
      _map('interpretation'),
      missing,
    );
    final reasoningBullets = _list('reasoning_bullets');
    final actionsToday = ActionsToday.parse(_map('actions_today'), missing);
    final redFlags =
        RedFlagItem.parseList(_listOfMaps(json, 'red_flags', missing));
    final followUpQuestions = _list('follow_up_questions');
    final uiStrings = UiStrings.parse(_map('ui_strings'), missing);

    final summary = _string('summary', fallback: uiStrings.summary);
    final bristolType = stoolFeatures.bristolType;
    final color = stoolFeatures.color;
    final texture = stoolFeatures.texture;
    final hydrationHint = _string('hydration_hint', fallback: '');
    final dietAdvice = _list('diet_advice');

    if (missing.isNotEmpty) {
      debugPrint(
          '[StoolAnalysisResult][WARN] missing fields: ${missing.join(', ')}');
    }

    return StoolAnalysisParseResult(
      result: StoolAnalysisResult(
        ok: ok,
        errorCode: errorCode,
        modelUsed: modelUsed,
        isStoolImage: isStoolImage,
        explanation: explanation,
        inputContext: inputContext,
        headline: headline.isEmpty ? summary : headline,
        score: score,
        riskLevel: riskLevel,
        confidence: confidence,
        analysisConfidence: analysisConfidence,
        analysisMode: analysisMode,
        uncertaintyNote: uncertaintyNote,
        imageValidationStatus: imageValidationStatus,
        imageValidationTips: imageValidationTips,
        stoolFeatures: stoolFeatures,
        doctorExplanation: doctorExplanation,
        possibleCauses: possibleCauses,
        interpretation: interpretation,
        reasoningBullets: reasoningBullets,
        actionsToday: actionsToday,
        redFlags: redFlags,
        followUpQuestions: followUpQuestions,
        uiStrings: uiStrings,
        summary: summary,
        bristolType: bristolType,
        color: color,
        texture: texture,
        hydrationHint: hydrationHint,
        dietAdvice: dietAdvice,
      ),
      missing: missing,
    );
  }
}

class StoolFeatures {
  final int? bristolType;
  final String? color;
  final String? texture;
  final String shape;
  final String colorLabel;
  final String colorReason;
  final String textureLabel;
  final List<String> abnormalSigns;
  final String bristolRange;
  final String shapeDesc;
  final String colorDesc;
  final String textureDesc;
  final String volume;
  final String wateriness;
  final String mucus;
  final String foam;
  final String blood;
  final String undigestedFood;
  final String separationLayers;
  final String odorLevel;
  final List<String> visibleFindings;

  const StoolFeatures({
    required this.bristolType,
    required this.color,
    required this.texture,
    required this.shape,
    required this.colorLabel,
    required this.colorReason,
    required this.textureLabel,
    required this.abnormalSigns,
    required this.bristolRange,
    required this.shapeDesc,
    required this.colorDesc,
    required this.textureDesc,
    required this.volume,
    required this.wateriness,
    required this.mucus,
    required this.foam,
    required this.blood,
    required this.undigestedFood,
    required this.separationLayers,
    required this.odorLevel,
    required this.visibleFindings,
  });

  const StoolFeatures.empty()
      : bristolType = null,
        color = 'unknown',
        texture = 'unknown',
        shape = 'unknown',
        colorLabel = 'unknown',
        colorReason = '',
        textureLabel = 'unknown',
        abnormalSigns = const [],
        bristolRange = 'unknown',
        shapeDesc = '',
        colorDesc = '',
        textureDesc = '',
        volume = 'unknown',
        wateriness = 'none',
        mucus = 'none',
        foam = 'none',
        blood = 'none',
        undigestedFood = 'none',
        separationLayers = 'none',
        odorLevel = 'unknown',
        visibleFindings = const [];

  static StoolFeatures parse(Map<String, dynamic> json, List<String> missing) {
    int? bristolType;
    final raw = json['bristol_type'];
    if (raw != null) {
      bristolType = int.tryParse(raw.toString());
    } else {
      missing.add('stool_features.bristol_type');
    }

    final shapeRaw = json['shape']?.toString() ?? '';
    final shape = shapeRaw.isNotEmpty ? shapeRaw : 'unknown';
    if (shapeRaw.isEmpty) missing.add('stool_features.shape');
    final colorLabelRaw = json['color']?.toString() ?? '';
    final colorLabel = colorLabelRaw.isNotEmpty ? colorLabelRaw : 'unknown';
    if (colorLabelRaw.isEmpty) missing.add('stool_features.color');
    final textureLabelRaw = json['texture']?.toString() ?? '';
    final textureLabel = textureLabelRaw.isNotEmpty ? textureLabelRaw : 'unknown';
    if (textureLabelRaw.isEmpty) missing.add('stool_features.texture');
    final colorReason = json['color_reason']?.toString() ?? '';
    if (colorReason.isEmpty) missing.add('stool_features.color_reason');
    final abnormalSignsRaw = json['abnormal_signs'];
    final abnormalSigns = abnormalSignsRaw is List
        ? abnormalSignsRaw.map((e) => e.toString()).toList()
        : const <String>[];
    if (abnormalSigns.isEmpty) missing.add('stool_features.abnormal_signs');

    final colorDesc = json['color_desc']?.toString() ?? json['color']?.toString();
    if (colorDesc == null || colorDesc.isEmpty) {
      missing.add('stool_features.color_desc');
    }
    final textureDesc = json['texture_desc']?.toString() ?? json['texture']?.toString();
    if (textureDesc == null || textureDesc.isEmpty) {
      missing.add('stool_features.texture_desc');
    }
    final shapeDesc = json['shape_desc']?.toString() ?? '';
    if (shapeDesc.isEmpty) missing.add('stool_features.shape_desc');
    final bristolRange = json['bristol_range']?.toString() ?? '';
    if (bristolRange.isEmpty) missing.add('stool_features.bristol_range');

    final volumeRaw = json['volume']?.toString() ?? 'unknown';
    final volume = ['small', 'medium', 'large', 'unknown'].contains(volumeRaw)
        ? volumeRaw
        : 'unknown';

    final wateriness = json['wateriness']?.toString() ?? 'none';
    final mucus = json['mucus']?.toString() ?? 'none';
    final foam = json['foam']?.toString() ?? 'none';
    final blood = json['blood']?.toString() ?? 'none';
    final undigestedFood = json['undigested_food']?.toString() ?? 'none';
    final separationLayers = json['separation_layers']?.toString() ?? 'none';
    final odorLevel = json['odor_level']?.toString() ?? 'unknown';

    final findings = json['visible_findings'];
    final visibleFindings = findings is List
        ? findings.map((e) => e.toString()).toList()
        : const <String>[];
    if (visibleFindings.isEmpty) missing.add('stool_features.visible_findings');

    return StoolFeatures(
      bristolType: bristolType,
      color: (colorDesc ?? '').isNotEmpty ? colorDesc : 'unknown',
      texture: (textureDesc ?? '').isNotEmpty ? textureDesc : 'unknown',
      shape: shape,
      colorLabel: colorLabel,
      colorReason: colorReason,
      textureLabel: textureLabel,
      abnormalSigns: abnormalSigns,
      bristolRange: bristolRange,
      shapeDesc: shapeDesc,
      colorDesc: colorDesc ?? '',
      textureDesc: textureDesc ?? '',
      volume: volume,
      wateriness: wateriness,
      mucus: mucus,
      foam: foam,
      blood: blood,
      undigestedFood: undigestedFood,
      separationLayers: separationLayers,
      odorLevel: odorLevel,
      visibleFindings: visibleFindings,
    );
  }
}

class Interpretation {
  final String overallJudgement;
  final List<String> whyShape;
  final List<String> whyColor;
  final List<String> whyTexture;
  final List<String> howContextAffects;
  final String confidenceExplain;

  const Interpretation({
    required this.overallJudgement,
    required this.whyShape,
    required this.whyColor,
    required this.whyTexture,
    required this.howContextAffects,
    required this.confidenceExplain,
  });

  static Interpretation parse(Map<String, dynamic> json, List<String> missing) {
    final overall = json['overall_judgement']?.toString() ?? '';
    if (overall.isEmpty) missing.add('interpretation.overall_judgement');
    final whyShape = _stringList(json['why_shape'], 'interpretation.why_shape', missing);
    final whyColor = _stringList(json['why_color'], 'interpretation.why_color', missing);
    final whyTexture = _stringList(json['why_texture'], 'interpretation.why_texture', missing);
    final howContext =
        _stringList(json['how_context_affects'], 'interpretation.how_context_affects', missing);
    final confidenceExplain = json['confidence_explain']?.toString() ?? '';
    if (confidenceExplain.isEmpty) missing.add('interpretation.confidence_explain');
    return Interpretation(
      overallJudgement: overall,
      whyShape: whyShape,
      whyColor: whyColor,
      whyTexture: whyTexture,
      howContextAffects: howContext,
      confidenceExplain: confidenceExplain,
    );
  }
}

class DoctorExplanation {
  final String oneSentenceConclusion;
  final String shapeAnalysis;
  final String colorAnalysis;
  final String textureAnalysis;
  final String combinedJudgement;

  const DoctorExplanation({
    required this.oneSentenceConclusion,
    required this.shapeAnalysis,
    required this.colorAnalysis,
    required this.textureAnalysis,
    required this.combinedJudgement,
  });

  const DoctorExplanation.empty()
      : oneSentenceConclusion = '',
        shapeAnalysis = '',
        colorAnalysis = '',
        textureAnalysis = '',
        combinedJudgement = '';

  static DoctorExplanation parse(Map<String, dynamic> json, List<String> missing) {
    final conclusion = json['one_sentence_conclusion']?.toString() ?? '';
    if (conclusion.isEmpty) missing.add('doctor_explanation.one_sentence_conclusion');
    final visual = json['visual_analysis'];
    final visualMap = visual is Map
        ? visual.map((k, v) => MapEntry(k.toString(), v))
        : const <String, dynamic>{};
    final shape = json['shape']?.toString() ?? visualMap['shape']?.toString() ?? '';
    final color = json['color']?.toString() ?? visualMap['color']?.toString() ?? '';
    final texture = json['texture']?.toString() ?? visualMap['texture']?.toString() ?? '';
    if (shape.isEmpty) missing.add('doctor_explanation.visual_analysis.shape');
    if (color.isEmpty) missing.add('doctor_explanation.visual_analysis.color');
    if (texture.isEmpty) missing.add('doctor_explanation.visual_analysis.texture');
    final combined = json['combined_judgement']?.toString() ?? '';
    if (combined.isEmpty) missing.add('doctor_explanation.combined_judgement');
    return DoctorExplanation(
      oneSentenceConclusion: conclusion,
      shapeAnalysis: shape,
      colorAnalysis: color,
      textureAnalysis: texture,
      combinedJudgement: combined,
    );
  }
}

class PossibleCause {
  final String title;
  final String explanation;

  const PossibleCause({required this.title, required this.explanation});

  static List<PossibleCause> parseList(List<Map<String, dynamic>> list) {
    return list
        .map((item) => PossibleCause(
              title: item['title']?.toString() ?? '',
              explanation: item['explanation']?.toString() ?? '',
            ))
        .toList();
  }
}

class ActionsToday {
  final List<String> diet;
  final List<String> hydration;
  final List<String> care;
  final List<String> avoid;
  final List<String> observe;

  const ActionsToday({
    required this.diet,
    required this.hydration,
    required this.care,
    required this.avoid,
    required this.observe,
  });

  static ActionsToday parse(Map<String, dynamic> json, List<String> missing) {
    final diet = _stringList(json['diet'], 'actions_today.diet', missing);
    final hydration =
        _stringList(json['hydration'], 'actions_today.hydration', missing);
    final care = _stringList(json['care'], 'actions_today.care', missing);
    final avoid = _stringList(json['avoid'], 'actions_today.avoid', missing);
    final observe =
        _stringList(json['observe'], 'actions_today.observe', missing);
    return ActionsToday(
      diet: diet,
      hydration: hydration,
      care: care,
      avoid: avoid,
      observe: observe,
    );
  }

  ActionsToday withDefaults() {
    return ActionsToday(
      diet: diet,
      hydration: hydration,
      care: care,
      avoid: avoid,
      observe: observe,
    );
  }
}

class RedFlagItem {
  final String title;
  final String detail;

  const RedFlagItem({required this.title, required this.detail});

  static List<RedFlagItem> parseList(List<Map<String, dynamic>> list) {
    return list
        .map((item) => RedFlagItem(
              title: item['title']?.toString() ?? '',
              detail: item['detail']?.toString() ?? '',
            ))
        .toList();
  }
}

class UiStrings {
  final String summary;
  final List<String> tags;
  final List<UiSection> sections;
  final UiLongform longform;

  const UiStrings({
    required this.summary,
    required this.tags,
    required this.sections,
    required this.longform,
  });

  static UiStrings parse(Map<String, dynamic> json, List<String> missing) {
    final summary = json['summary']?.toString() ?? '';
    if (summary.isEmpty) missing.add('ui_strings.summary');
    final tags = _stringList(json['tags'], 'ui_strings.tags', missing);
    final sectionsRaw = json['sections'];
    final sections = <UiSection>[];
    if (sectionsRaw is List) {
      for (final item in sectionsRaw) {
        if (item is Map) {
          final itemsValue = item['items'] ?? item['bullets'];
          sections.add(UiSection(
            title: item['title']?.toString() ?? '',
            iconKey: item['icon_key']?.toString() ?? '',
            items: _stringList(
              itemsValue,
              'ui_strings.sections.items',
              missing,
            ),
          ));
        }
      }
    } else {
      missing.add('ui_strings.sections');
    }
    final longformMap = json['longform'];
    UiLongform longform = const UiLongform.empty();
    if (longformMap is Map) {
      longform = UiLongform.parse(
        longformMap.map((k, v) => MapEntry(k.toString(), v)),
        missing,
      );
    }
    return UiStrings(
      summary: summary,
      tags: tags,
      sections: sections,
      longform: longform,
    );
  }
}

class UiLongform {
  final String conclusion;
  final String howToRead;
  final String context;
  final String causes;
  final String todo;
  final String redFlags;
  final String reassure;

  const UiLongform({
    required this.conclusion,
    required this.howToRead,
    required this.context,
    required this.causes,
    required this.todo,
    required this.redFlags,
    required this.reassure,
  });

  const UiLongform.empty()
      : conclusion = '',
        howToRead = '',
        context = '',
        causes = '',
        todo = '',
        redFlags = '',
        reassure = '';

  static UiLongform parse(Map<String, dynamic> json, List<String> missing) {
    String _field(String key) {
      final value = json[key]?.toString() ?? '';
      if (value.isEmpty) missing.add('ui_strings.longform.$key');
      return value;
    }

    return UiLongform(
      conclusion: _field('conclusion'),
      howToRead: _field('how_to_read'),
      context: _field('context'),
      causes: _field('causes'),
      todo: _field('todo'),
      redFlags: _field('red_flags'),
      reassure: _field('reassure'),
    );
  }
}

class UiSection {
  final String title;
  final String iconKey;
  final List<String> items;

  const UiSection({
    required this.title,
    required this.iconKey,
    required this.items,
  });
}

List<Map<String, dynamic>> _listOfMaps(
  Map<String, dynamic> json,
  String key,
  List<String> missing,
) {
  final value = json[key];
  if (value is List) {
    return value
        .whereType<Map>()
        .map((e) => e.map((k, v) => MapEntry(k.toString(), v)))
        .toList();
  }
  missing.add(key);
  return const [];
}

List<String> _stringList(
  Object? value,
  String key,
  List<String> missing,
) {
  if (value is List) {
    final list = value.map((e) => e.toString()).toList();
    if (list.isEmpty) missing.add(key);
    return list;
  }
  missing.add(key);
  return const [];
}
