enum AnalyzerMode { mock, remote }

class EngineConfig {
  static const AnalyzerMode defaultMode = AnalyzerMode.mock;

  static AnalyzerMode fromString(String? value) {
    switch (value) {
      case 'remote':
        return AnalyzerMode.remote;
      case 'mock':
      default:
        return AnalyzerMode.mock;
    }
  }

  static String toStringValue(AnalyzerMode mode) {
    return mode.name;
  }
}
