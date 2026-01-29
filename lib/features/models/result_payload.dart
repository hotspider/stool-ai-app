import 'advice_response.dart';
import 'analyze_response.dart';
import 'stool_analysis_result.dart';

class ResultPayload {
  final AnalyzeResponse analysis;
  final AdviceResponse? advice;
  final StoolAnalysisParseResult? structured;
  final String? validationWarning;
  final Map<String, dynamic>? contextInput;
  final String? contextSummary;
  final Map<String, String?>? debugInfo;

  const ResultPayload({
    required this.analysis,
    this.advice,
    this.structured,
    this.validationWarning,
    this.contextInput,
    this.contextSummary,
    this.debugInfo,
  });
}
