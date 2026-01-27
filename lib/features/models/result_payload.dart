import 'advice_response.dart';
import 'analyze_response.dart';

class ResultPayload {
  final AnalyzeResponse analysis;
  final AdviceResponse? advice;
  final String? validationWarning;

  const ResultPayload({
    required this.analysis,
    this.advice,
    this.validationWarning,
  });
}
