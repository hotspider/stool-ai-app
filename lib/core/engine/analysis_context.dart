class AnalysisContext {
  final DateTime timestamp;
  final String locale;
  final String? appVersion;
  final String? deviceInfo;
  final String? sessionId;

  const AnalysisContext({
    required this.timestamp,
    required this.locale,
    this.appVersion,
    this.deviceInfo,
    this.sessionId,
  });
}
