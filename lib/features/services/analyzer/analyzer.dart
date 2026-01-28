import 'dart:typed_data';

import '../../models/advice_response.dart';
import '../../models/analyze_response.dart';
import '../../models/stool_analysis_result.dart';
import '../../models/user_inputs.dart';

class AnalyzeResult {
  final AnalyzeResponse analysis;
  final AdviceResponse advice;
  final StoolAnalysisParseResult? structured;

  const AnalyzeResult({
    required this.analysis,
    required this.advice,
    this.structured,
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
