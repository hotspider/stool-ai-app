import 'advice_response.dart';
import 'analyze_response.dart';
import 'stool_analysis_result.dart';

class ResultPayload {
  final AnalyzeResponse analysis;
  final AdviceResponse? advice;
  final StoolAnalysisParseResult? structured;
  final String? validationWarning;

  const ResultPayload({
    required this.analysis,
    this.advice,
    this.structured,
    this.validationWarning,
  });
}
