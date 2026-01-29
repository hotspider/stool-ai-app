import 'dart:typed_data';

import '../../models/user_inputs.dart';
import '../../services/mock_generator.dart';
import '../../models/stool_analysis_result.dart';
import 'analyzer.dart';

class MockAnalyzer implements Analyzer {
  @override
  Future<AnalyzeResult> analyze({
    required Uint8List imageBytes,
    required UserInputs inputs,
  }) async {
    final analysis = MockGenerator.randomAnalysis();
    final advice = MockGenerator.adviceFor(analysis, inputs);
    final structured = StoolAnalysisResult.parse(
      MockGenerator.mockStructuredV2(),
    );
    return AnalyzeResult(analysis: analysis, advice: advice, structured: structured);
  }
}
