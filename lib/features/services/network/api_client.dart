import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class ApiException implements Exception {
  final int statusCode;
  final String message;

  const ApiException(this.statusCode, this.message);
}

class ApiClient {
  final String baseUrl;
  final Duration timeout;

  ApiClient({
    required this.baseUrl,
    this.timeout = const Duration(seconds: 15),
  });

  Future<Map<String, dynamic>> postJson(
    String path,
    Map<String, dynamic> body,
  ) async {
    final uri = Uri.parse('$baseUrl$path');
    if (kDebugMode) {
      debugPrint('[ApiClient] POST $uri');
    }
    final response = await http
        .post(
          uri,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(body),
        )
        .timeout(timeout);
    if (kDebugMode) {
      debugPrint('[ApiClient] status=${response.statusCode}');
      debugPrint('[ApiClient] headers: x-openai-model=${response.headers['x-openai-model']} '
          'x-worker-version=${response.headers['x-worker-version']} '
          'x-proxy-version=${response.headers['x-proxy-version']}');
    }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiException(response.statusCode, response.body);
    }
    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw const ApiException(500, 'invalid_response');
    }
    return decoded;
  }
}
