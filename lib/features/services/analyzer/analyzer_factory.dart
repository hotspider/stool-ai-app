import '../network/api_client.dart';
import '../storage_service.dart';
import 'analyzer.dart';
import 'engine_config.dart';
import 'mock_analyzer.dart';
import 'remote_analyzer.dart';

class AnalyzerFactory {
  static Analyzer create() {
    final mode = StorageService.instance.getAnalyzerMode();
    switch (mode) {
      case AnalyzerMode.remote:
        return RemoteAnalyzer(
          client: ApiClient(baseUrl: RemoteAnalyzer.defaultBaseUrl),
        );
      case AnalyzerMode.mock:
      default:
        return MockAnalyzer();
    }
  }
}
