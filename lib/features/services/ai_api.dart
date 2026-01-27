import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;

class AiApi {
  // Android 模拟器访问你电脑的 localhost 的固定地址
  static const String baseUrl = 'http://10.0.2.2:8787';

  static Future<Map<String, dynamic>> analyze({
    required Uint8List imageBytes,
    required String locale,
  }) async {
    final b64 = base64Encode(imageBytes);

    final resp = await http
        .post(
          Uri.parse('$baseUrl/analyze'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'locale': locale,
            'imageBase64': b64,
          }),
        )
        .timeout(const Duration(seconds: 60));

    final json = jsonDecode(resp.body) as Map<String, dynamic>;
    if (resp.statusCode >= 400) {
      throw Exception(json['message'] ?? 'Request failed');
    }
    return json;
  }
}