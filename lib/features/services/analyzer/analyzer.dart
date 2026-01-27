import 'dart:typed_data';

import '../../models/advice_response.dart';
import '../../models/analyze_response.dart';
import '../../models/user_inputs.dart';

class AnalyzeResult {
  final AnalyzeResponse analysis;
  final AdviceResponse advice;

  const AnalyzeResult({
    required this.analysis,
    required this.advice,
  });
}

abstract class Analyzer {
  Future<AnalyzeResult> analyze({
    required Uint8List imageBytes,
    required UserInputs inputs,
  });
}

class AnalyzerException implements Exception {
  final String message;

  const AnalyzerException(this.message);
}
