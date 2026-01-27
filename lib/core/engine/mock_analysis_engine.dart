import 'dart:typed_data';

import '../../features/models/advice_response.dart';
import '../../features/models/analyze_response.dart';
import '../../features/models/user_inputs.dart';
import '../../features/services/mock_generator.dart';
import 'analysis_context.dart';
import 'analysis_engine.dart';

class MockAnalysisEngine implements AnalysisEngine {
  @override
  Future<AnalyzeResponse> analyze({
    required Uint8List imageBytes,
    required AnalysisContext context,
  }) async {
    return MockGenerator.randomAnalysis();
  }

  @override
  Future<AdviceResponse> generateAdvice({
    required AnalyzeResponse analysis,
    required UserInputs inputs,
  }) async {
    return MockGenerator.adviceFor(analysis, inputs);
  }
}
