import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';

import '../../../core/locale/locale_helper.dart';
import '../../models/advice_response.dart';
import '../../models/analyze_response.dart';
import '../../models/user_inputs.dart';
import '../../models/stool_analysis_result.dart';
import '../network/api_client.dart';
import 'analyzer.dart';
import 'mock_analyzer.dart';

class RemoteAnalyzer implements Analyzer {
  static const String defaultBaseUrl = 'https://api.tapgiga.com';

  final ApiClient client;
  final bool allowFallbackInDebug;

  RemoteAnalyzer({
    required this.client,
    this.allowFallbackInDebug = true,
  });

  @override
  Future<AnalyzeResult> analyze({
    required Uint8List imageBytes,
    required UserInputs inputs,
  }) async {
    final base64 = base64Encode(imageBytes);
    try {
      final response = await client.postJson('/analyze', {
        'image': base64,
        'age_months': 30,
        'odor': inputs.odor,
        'pain_or_strain': inputs.painOrStrain,
        'diet_keywords': inputs.dietKeywords,
        'lang': LocaleHelper.currentLanguageCode(),
      });
      final structured = StoolAnalysisResult.parse(response);
      final analysis = _analysisFromStructured(structured.result);
      final advice = _adviceFromStructured(structured.result);
      return AnalyzeResult(
        analysis: analysis,
        advice: advice,
        structured: structured,
      );
    } on ApiException catch (_) {
      if (kDebugMode && allowFallbackInDebug) {
        final fallback = MockAnalyzer();
        return fallback.analyze(imageBytes: imageBytes, inputs: inputs);
      }
      throw const AnalyzerException('remote_unavailable');
    } catch (_) {
      if (kDebugMode && allowFallbackInDebug) {
        final fallback = MockAnalyzer();
        return fallback.analyze(imageBytes: imageBytes, inputs: inputs);
      }
      throw const AnalyzerException('remote_unavailable');
    }
  }

  AnalyzeResponse _analysisFromStructured(StoolAnalysisResult data) {
    final redFlags = data.redFlags
        .map((item) => '${item.title} ${item.detail}'.trim())
        .where((item) => item.isNotEmpty)
        .toList();
    return AnalyzeResponse(
      riskLevel: _riskLevel(data.riskLevel),
      summary: data.summary,
      bristolType: data.stoolFeatures.bristolType,
      color: _colorTag(data.stoolFeatures.color),
      texture: _textureTag(data.stoolFeatures.texture),
      suspiciousSignals: redFlags,
      qualityScore: data.score,
      qualityIssues: data.reasoningBullets,
      analyzedAt: DateTime.now(),
    );
  }

  AdviceResponse _adviceFromStructured(StoolAnalysisResult data) {
    final next48h = <String>[
      ...data.actionsToday.diet,
      ...data.actionsToday.hydration,
      ...data.actionsToday.care,
      ...data.actionsToday.avoid,
    ];
    final redFlags = data.redFlags
        .map((item) => '${item.title} ${item.detail}'.trim())
        .where((item) => item.isNotEmpty)
        .toList();
    return AdviceResponse(
      summary: data.headline,
      next48hActions: next48h,
      seekCareIf: redFlags,
      disclaimers: data.uncertaintyNote.isEmpty
          ? const []
          : [data.uncertaintyNote],
    );
  }

  RiskLevel _riskLevel(String raw) {
    switch (raw.toLowerCase()) {
      case 'high':
        return RiskLevel.high;
      case 'medium':
        return RiskLevel.medium;
      default:
        return RiskLevel.low;
    }
  }

  StoolColor _colorTag(String? raw) {
    switch ((raw ?? '').toLowerCase()) {
      case 'yellow':
        return StoolColor.yellow;
      case 'green':
        return StoolColor.green;
      case 'black':
        return StoolColor.black;
      case 'red':
        return StoolColor.red;
      case 'white_gray':
        return StoolColor.pale;
      case 'brown':
        return StoolColor.brown;
      default:
        return StoolColor.unknown;
    }
  }

  StoolTexture _textureTag(String? raw) {
    switch ((raw ?? '').toLowerCase()) {
      case 'hard':
        return StoolTexture.hard;
      case 'normal':
        return StoolTexture.normal;
      case 'mushy':
        return StoolTexture.mushy;
      case 'watery':
        return StoolTexture.watery;
      default:
        return StoolTexture.unknown;
    }
  }
}
