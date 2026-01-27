import '../engine/analysis_engine.dart';
import '../engine/mock_analysis_engine.dart';

class EngineProvider {
  EngineProvider._();

  static final AnalysisEngine engine = MockAnalysisEngine();
}
