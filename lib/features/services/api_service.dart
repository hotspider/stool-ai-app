import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../models/advice_response.dart';
import '../models/analyze_response.dart';
import '../models/result_payload.dart';
import '../models/stool_analysis_result.dart';
import 'mock_generator.dart';

class ApiService {
  static const String _baseUrl = 'https://api.tapgiga.com';

  static String get baseUrl => _baseUrl;

  static Future<ResultPayload> analyzeImage({
    required Uint8List imageBytes,
    int ageMonths = 30,
    String odor = '',
    bool painOrStrain = false,
    String dietKeywords = '',
  }) async {
    debugPrint('ApiService analyze sending request');
    final url = Uri.parse('$_baseUrl/analyze');
    final base64Len = ((imageBytes.length + 2) ~/ 3) * 4;
    try {
      final bodyMap = <String, dynamic>{
        'image': base64Encode(imageBytes),
        'age_months': ageMonths,
        'odor': odor,
        'pain_or_strain': painOrStrain,
        'diet_keywords': dietKeywords,
      };
      final jsonBody = jsonEncode(bodyMap);
      const headers = {
        'Content-Type': 'application/json; charset=utf-8',
        'Accept': 'application/json',
      };
      debugPrint(
        'ApiService request: $url bytes=${imageBytes.length} base64Len=$base64Len',
      );
      debugPrint('ApiService json length: ${jsonBody.length}');
      debugPrint('ApiService headers: $headers');
      debugPrint(
        'ApiService json preview: ${jsonBody.substring(0, jsonBody.length > 200 ? 200 : jsonBody.length)}',
      );
      final response = await _postJsonWithRetry(url, jsonBody, headers);
      debugPrint(
        'ApiService response: ${response.statusCode} ${_snippet(response.body, 300)}',
      );
      debugPrint(
        'ApiService headers: x-worker-version=${response.headers['x-worker-version']} '
        'x-proxy-version=${response.headers['x-proxy-version']} '
        'schema_version=${response.headers['schema_version']}',
      );

      final body = jsonDecode(response.body);
      if (body is Map<String, dynamic>) {
        debugPrint('ApiService body schema_version: ${body['schema_version']}');
      }
      if (response.statusCode >= 400) {
        final message = body is Map<String, dynamic>
            ? body['message']?.toString() ?? 'Request failed'
            : 'Request failed';
        throw ApiServiceException(ApiServiceErrorCode.remoteError, message);
      }

      if (body is! Map<String, dynamic>) {
        throw ApiServiceException(
          ApiServiceErrorCode.invalidResponse,
          'Invalid response',
        );
      }

      if (body['ok'] == false) {
        debugPrint(
          'ApiService response ok=false: ${body['error'] ?? ''} ${body['message'] ?? ''}',
        );
      }

      final parsed = StoolAnalysisResult.parse(body);
      if (parsed.missing.isNotEmpty) {
        debugPrint(
          '[ApiService][WARN] missing fields: ${parsed.missing.join(', ')}',
        );
      }
      final result = parsed.result;
      final redFlags = result.redFlags
          .map((item) => '${item.title} ${item.detail}'.trim())
          .where((item) => item.isNotEmpty)
          .toList();

      final analysisJson = <String, dynamic>{
        'riskLevel': result.riskLevel,
        'summary': result.summary,
        'bristolType': result.bristolType,
        'color': result.color,
        'texture': result.texture,
        'suspiciousSignals': redFlags,
        'qualityScore': result.score,
        'qualityIssues': result.reasoningBullets,
        'analyzedAt': DateTime.now().toIso8601String(),
      };
      final adviceJson = <String, dynamic>{
        'summary': result.headline,
        'next48hActions': [
          ...result.actionsToday.diet,
          ...result.actionsToday.hydration,
          ...result.actionsToday.care,
          ...result.actionsToday.avoid,
        ],
        'seekCareIf': redFlags,
        'disclaimers': result.uncertaintyNote.isEmpty
            ? const []
            : [result.uncertaintyNote],
      };

      return ResultPayload(
        analysis: AnalyzeResponse.fromJson(analysisJson),
        advice: AdviceResponse.fromJson(adviceJson),
        structured: parsed,
      );
    } catch (error, stack) {
      if (error is TimeoutException || error is HandshakeException) {
        debugPrint('ApiService exception: $error');
        debugPrint(stack.toString());
      } else {
        debugPrint('ApiService exception: $error');
        debugPrint(stack.toString());
      }
      rethrow;
    }
  }

  static Future<ResultPayload> mockAnalyzeImage({
    required Uint8List imageBytes,
  }) async {
    await Future.delayed(const Duration(milliseconds: 800));
    final analysis = MockGenerator.randomAnalysis();
    final advice = MockGenerator.adviceFor(analysis, null);
    return ResultPayload(analysis: analysis, advice: advice);
  }
}

String _snippet(String input, [int max = 300]) {
  if (input.length <= max) {
    return input;
  }
  return input.substring(0, max);
}

Future<http.Response> _postJsonWithRetry(
  Uri url,
  String body,
  Map<String, String> headers,
) async {
  const maxAttempts = 3;
  var attempt = 0;
  var delayMs = 600;

  while (true) {
    attempt++;
    try {
      final resp = await http
          .post(url, headers: headers, body: body)
          .timeout(const Duration(seconds: 45));
      if ((resp.statusCode == 502 || resp.statusCode == 503) &&
          attempt < maxAttempts) {
        throw HttpException('retryable_${resp.statusCode}');
      }
      return resp;
    } on TimeoutException {
      if (attempt >= maxAttempts) rethrow;
    } catch (_) {
      if (attempt >= maxAttempts) rethrow;
    }

    await Future.delayed(Duration(milliseconds: delayMs));
    delayMs = (delayMs * 2).clamp(600, 2500);
  }
}

enum ApiServiceErrorCode { notTarget, remoteError, invalidResponse }

class ApiServiceException implements Exception {
  final ApiServiceErrorCode code;
  final String? message;

  ApiServiceException(this.code, [this.message]);
}
