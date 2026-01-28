enum RiskLevel { low, medium, high }

enum StoolColor { brown, yellow, green, black, red, pale, mixed, unknown }

enum StoolTexture { watery, mushy, normal, hard, oily, foamy, unknown }

class AnalyzeResponse {
  final RiskLevel riskLevel;
  final String summary;
  final int? bristolType;
  final StoolColor color;
  final StoolTexture texture;
  final List<String> suspiciousSignals;
  final int qualityScore;
  final List<String> qualityIssues;
  final DateTime analyzedAt;

  const AnalyzeResponse({
    required this.riskLevel,
    required this.summary,
    required this.bristolType,
    required this.color,
    required this.texture,
    required this.suspiciousSignals,
    required this.qualityScore,
    required this.qualityIssues,
    required this.analyzedAt,
  });

  static AnalyzeResponse empty() {
    return AnalyzeResponse(
      riskLevel: RiskLevel.low,
      summary: '',
      bristolType: null,
      color: StoolColor.unknown,
      texture: StoolTexture.unknown,
      suspiciousSignals: const [],
      qualityScore: 0,
      qualityIssues: const [],
      analyzedAt: DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'riskLevel': riskLevel.name,
      'summary': summary,
      'bristolType': bristolType,
      'color': color.name,
      'texture': texture.name,
      'suspiciousSignals': suspiciousSignals,
      'qualityScore': qualityScore,
      'qualityIssues': qualityIssues,
      'analyzedAt': analyzedAt.toIso8601String(),
    };
  }

  factory AnalyzeResponse.fromJson(Map<String, dynamic> json) {
    final riskLevel = _parseRiskLevel(json['riskLevel']);
    final summary = json['summary']?.toString() ?? '';
    final bristolType = _optionalClampInt(json['bristolType'], min: 1, max: 7);
    final color = _parseColor(json['color']);
    final texture = _parseTexture(json['texture']);
    final suspiciousSignals = _stringList(
      json['suspiciousSignals'] ?? json['suspectedPoints'],
    );
    final qualityScore = _clampInt(
      json['qualityScore'],
      min: 0,
      max: 100,
      fallback: 0,
    );
    final qualityIssues = _stringList(json['qualityIssues']);
    final analyzedAt = _parseDate(json['analyzedAt']) ??
        _parseDate(json['createdAt']) ??
        DateTime.now();

    return AnalyzeResponse(
      riskLevel: riskLevel,
      summary: summary,
      bristolType: bristolType,
      color: color,
      texture: texture,
      suspiciousSignals: suspiciousSignals,
      qualityScore: qualityScore,
      qualityIssues: qualityIssues,
      analyzedAt: analyzedAt,
    );
  }

  static RiskLevel _parseRiskLevel(Object? value) {
    final raw = value?.toString().toLowerCase().trim();
    switch (raw) {
      case 'medium':
        return RiskLevel.medium;
      case 'high':
        return RiskLevel.high;
      default:
        return RiskLevel.low;
    }
  }

  static StoolColor _parseColor(Object? value) {
    final raw = value?.toString().toLowerCase().trim();
    switch (raw) {
      case 'yellow':
        return StoolColor.yellow;
      case 'green':
        return StoolColor.green;
      case 'black':
        return StoolColor.black;
      case 'red':
        return StoolColor.red;
      case 'pale':
        return StoolColor.pale;
      case 'mixed':
        return StoolColor.mixed;
      case 'brown':
        return StoolColor.brown;
      default:
        return StoolColor.unknown;
    }
  }

  static StoolTexture _parseTexture(Object? value) {
    final raw = value?.toString().toLowerCase().trim();
    switch (raw) {
      case 'watery':
        return StoolTexture.watery;
      case 'mushy':
        return StoolTexture.mushy;
      case 'normal':
        return StoolTexture.normal;
      case 'hard':
        return StoolTexture.hard;
      case 'oily':
        return StoolTexture.oily;
      case 'foamy':
        return StoolTexture.foamy;
      default:
        return StoolTexture.unknown;
    }
  }

  static int _clampInt(Object? value,
      {required int min, required int max, required int fallback}) {
    final parsed = int.tryParse(value?.toString() ?? '');
    if (parsed == null) {
      return fallback;
    }
    if (parsed < min) {
      return min;
    }
    if (parsed > max) {
      return max;
    }
    return parsed;
  }

  static int? _optionalClampInt(Object? value,
      {required int min, required int max}) {
    final parsed = int.tryParse(value?.toString() ?? '');
    if (parsed == null) {
      return null;
    }
    if (parsed < min) {
      return min;
    }
    if (parsed > max) {
      return max;
    }
    return parsed;
  }

  static List<String> _stringList(Object? value) {
    if (value is List) {
      return value.map((e) => e.toString()).toList();
    }
    return const [];
  }

  static DateTime? _parseDate(Object? value) {
    if (value == null) {
      return null;
    }
    if (value is DateTime) {
      return value;
    }
    return DateTime.tryParse(value.toString());
  }
}
