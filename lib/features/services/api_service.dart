import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../models/advice_response.dart';
import '../models/analyze_context.dart';
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
    AnalyzeContext? context,
    bool userConfirmedStool = false,
  }) async {
    final requestId = DateTime.now().microsecondsSinceEpoch.toString();
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
        'context': context?.toJson() ?? {},
        'user_confirmed_stool': userConfirmedStool,
        'mode': 'classify_then_analyze',
      };
      debugPrint('[Analyze][$requestId] context=${jsonEncode(bodyMap['context'])}');
      final jsonBody = jsonEncode(bodyMap);
      const headers = {
        'Content-Type': 'application/json; charset=utf-8',
        'Accept': 'application/json',
      };
      debugPrint(
        '[ApiService][$requestId] POST $url bytes=${imageBytes.length} base64Len=$base64Len',
      );
      debugPrint('[ApiService][$requestId] json length: ${jsonBody.length}');
      debugPrint('[ApiService][$requestId] headers: $headers');
      final response = await _postJsonWithRetry(url, jsonBody, headers);
      final responseRid = response.headers['x-request-id'] ?? 'unknown';
      debugPrint(
        '[ApiService][$requestId] response: ${response.statusCode} ${_snippet(response.body, 300)}',
      );
      debugPrint(
        '[RID:$responseRid] headers: x-request-id=${response.headers['x-request-id']} '
        'x-worker-git=${response.headers['x-worker-git']} '
        'x-proxy-version=${response.headers['x-proxy-version']} '
        'x-openai-model=${response.headers['x-openai-model']} '
        'schema_version=${response.headers['schema_version']}',
      );
      debugPrint(
        '[ApiService][$requestId] headers: x-worker-version=${response.headers['x-worker-version']} '
        'x-proxy-version=${response.headers['x-proxy-version']} '
        'schema_version=${response.headers['schema_version']} '
        'x-openai-model=${response.headers['x-openai-model']}',
      );

      final body = jsonDecode(response.body);
      if (body is Map<String, dynamic>) {
        debugPrint(
          '[ApiService][$requestId] response schema_version=${body['schema_version']} '
          'model_used=${body['model_used']} is_stool=${body['is_stool_image']} '
          'confidence=${body['confidence']}',
        );
      }
      if (response.statusCode >= 400) {
        final errorCode = body is Map<String, dynamic>
            ? body['error_code']?.toString()
            : null;
        if (errorCode == 'INVALID_IMAGE' && body is Map<String, dynamic>) {
          debugPrint(
              'ApiService invalid image response: ${body['message'] ?? ''}');
        } else {
          final message = body is Map<String, dynamic>
              ? body['message']?.toString() ?? 'Request failed'
              : 'Request failed';
          throw ApiServiceException(ApiServiceErrorCode.remoteError, message);
        }
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

      final debugInfo = <String, String?>{
        'schema_version': body['schema_version']?.toString(),
        'model_used': body['model_used']?.toString(),
        'x-openai-model': response.headers['x-openai-model'],
        'x-worker-version': response.headers['x-worker-version'],
        'x-worker-git': response.headers['x-worker-git'],
        'x-proxy-version': response.headers['x-proxy-version'],
        'request_id': body['openai_request_id']?.toString() ??
            response.headers['x-request-id'],
      };

      return ResultPayload(
        analysis: AnalyzeResponse.fromJson(analysisJson),
        advice: AdviceResponse.fromJson(adviceJson),
        structured: parsed,
        debugInfo: debugInfo,
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
