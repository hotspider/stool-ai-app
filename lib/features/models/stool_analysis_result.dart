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
  final String headline;
  final int score;
  final String riskLevel;
  final double confidence;
  final String uncertaintyNote;
  final StoolFeatures stoolFeatures;
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
    required this.headline,
    required this.score,
    required this.riskLevel,
    required this.confidence,
    required this.uncertaintyNote,
    required this.stoolFeatures,
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
    final headline = _string('headline');
    final score = _int('score');
    final riskLevel = _string('risk_level', fallback: 'low');
    final confidence = _double('confidence');
    final uncertaintyNote = _string('uncertainty_note');

    final stoolFeatures = StoolFeatures.parse(
      _map('stool_features'),
      missing,
    );
    final reasoningBullets = _list('reasoning_bullets');
    final actionsTodayRaw = ActionsToday.parse(_map('actions_today'), missing);
    final actionsToday = actionsTodayRaw.withDefaults();
    final redFlags = RedFlagItem.parseList(_listOfMaps(json, 'red_flags', missing));
    final followUpQuestions = _list('follow_up_questions');
    final uiStrings = UiStrings.parse(_map('ui_strings'), missing);

    final summary = _string('summary', fallback: uiStrings.summary);
    final bristolType = stoolFeatures.bristolType;
    final color = stoolFeatures.color;
    final texture = stoolFeatures.texture;
    final hydrationHint =
        _string('hydration_hint', fallback: actionsToday.hydration.isNotEmpty ? actionsToday.hydration.first : '');
    final dietAdvice =
        _list('diet_advice').isNotEmpty ? _list('diet_advice') : actionsToday.diet;

    if (missing.isNotEmpty) {
      debugPrint('[StoolAnalysisResult] missing fields: ${missing.join(', ')}');
    }

    return StoolAnalysisParseResult(
      result: StoolAnalysisResult(
        ok: ok,
        headline: headline.isEmpty ? summary : headline,
        score: score,
        riskLevel: riskLevel,
        confidence: confidence,
        uncertaintyNote: uncertaintyNote,
        stoolFeatures: stoolFeatures,
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
  final String volume;
  final List<String> visibleFindings;

  const StoolFeatures({
    required this.bristolType,
    required this.color,
    required this.texture,
    required this.volume,
    required this.visibleFindings,
  });

  static StoolFeatures parse(Map<String, dynamic> json, List<String> missing) {
    int? bristolType;
    final raw = json['bristol_type'];
    if (raw != null) {
      bristolType = int.tryParse(raw.toString());
    } else {
      missing.add('stool_features.bristol_type');
    }

    final color = json['color']?.toString();
    if (color == null) missing.add('stool_features.color');
    final texture = json['texture']?.toString();
    if (texture == null) missing.add('stool_features.texture');

    final volumeRaw = json['volume']?.toString() ?? 'unknown';
    final volume = ['small', 'medium', 'large', 'unknown'].contains(volumeRaw)
        ? volumeRaw
        : 'unknown';

    final findings = json['visible_findings'];
    final visibleFindings = findings is List ? findings.map((e) => e.toString()).toList() : const [];
    if (visibleFindings.isEmpty) missing.add('stool_features.visible_findings');

    return StoolFeatures(
      bristolType: bristolType,
      color: color,
      texture: texture,
      volume: volume,
      visibleFindings: visibleFindings,
    );
  }
}

class ActionsToday {
  final List<String> diet;
  final List<String> hydration;
  final List<String> care;
  final List<String> avoid;

  const ActionsToday({
    required this.diet,
    required this.hydration,
    required this.care,
    required this.avoid,
  });

  static ActionsToday parse(Map<String, dynamic> json, List<String> missing) {
    final diet = _stringList(json['diet'], 'actions_today.diet', missing);
    final hydration = _stringList(json['hydration'], 'actions_today.hydration', missing);
    final care = _stringList(json['care'], 'actions_today.care', missing);
    final avoid = _stringList(json['avoid'], 'actions_today.avoid', missing);
    return ActionsToday(diet: diet, hydration: hydration, care: care, avoid: avoid);
  }

  ActionsToday withDefaults() {
    return ActionsToday(
      diet: diet.isEmpty
          ? const ['清淡饮食，减少油腻与刺激性食物', '少量多餐，观察耐受情况']
          : diet,
      hydration: hydration.isEmpty
          ? const ['少量多次补液，避免一次性大量饮水']
          : hydration,
      care: care.isEmpty
          ? const ['勤更换尿布/清洁，保持干爽', '观察皮肤是否红肿或破损']
          : care,
      avoid: avoid.isEmpty
          ? const ['避免高糖/高脂/刺激性食物']
          : avoid,
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

  const UiStrings({
    required this.summary,
    required this.tags,
    required this.sections,
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
          sections.add(UiSection(
            title: item['title']?.toString() ?? '',
            items: _stringList(item['items'], 'ui_strings.sections.items', missing),
          ));
        }
      }
    } else {
      missing.add('ui_strings.sections');
    }
    return UiStrings(summary: summary, tags: tags, sections: sections);
  }
}

class UiSection {
  final String title;
  final List<String> items;

  const UiSection({required this.title, required this.items});
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
