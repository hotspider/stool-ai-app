import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';

import '../../../core/locale/locale_helper.dart';
import '../../models/advice_response.dart';
import '../../models/analyze_response.dart';
import '../../models/user_inputs.dart';
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
        'image_base64': base64,
        'inputs': inputs.toJson(),
        'schema_version': 1,
        'lang': LocaleHelper.currentLanguageCode(),
      });
      final analysisJson =
          response['analysis'] as Map<String, dynamic>? ?? response;
      final adviceJson = response['advice'] as Map<String, dynamic>? ?? {};
      final analysis = AnalyzeResponse.fromJson(analysisJson);
      final advice = AdviceResponse.fromJson(adviceJson);
      return AnalyzeResult(analysis: analysis, advice: advice);
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
}
