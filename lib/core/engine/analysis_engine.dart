import 'dart:typed_data';

import '../../features/models/advice_response.dart';
import '../../features/models/analyze_response.dart';
import '../../features/models/user_inputs.dart';
import 'analysis_context.dart';

abstract class AnalysisEngine {
  Future<AnalyzeResponse> analyze({
    required Uint8List imageBytes,
    required AnalysisContext context,
  });

  Future<AdviceResponse> generateAdvice({
    required AnalyzeResponse analysis,
    required UserInputs inputs,
  });
}
