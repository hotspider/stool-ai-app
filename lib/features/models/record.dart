import 'dart:convert';

import 'analyze_response.dart';
import 'advice_response.dart';
import 'user_inputs.dart';

class StoolRecord {
  final String id;
  final DateTime createdAt;
  final int schemaVersion;
  final AnalyzeResponse analysis;
  final AdviceResponse advice;
  final UserInputs userInputs;
  final Map<String, bool> checkedActions;

  StoolRecord({
    required this.id,
    required this.createdAt,
    this.schemaVersion = 1,
    required this.analysis,
    required this.advice,
    required this.userInputs,
    this.checkedActions = const {},
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'createdAt': createdAt.toIso8601String(),
        'schemaVersion': schemaVersion,
        'analysis': analysis.toJson(),
        'advice': advice.toJson(),
        'userInputs': userInputs.toJson(),
        'checkedActions': checkedActions,
      };

  factory StoolRecord.fromJson(Map<String, dynamic> json) {
    final createdAtRaw = (json['createdAt'] ?? '').toString();
    return StoolRecord(
      id: (json['id'] ?? '').toString(),
      createdAt: DateTime.tryParse(createdAtRaw) ?? DateTime.now(),
      schemaVersion: json['schemaVersion'] is int ? json['schemaVersion'] as int : 1,
      analysis: AnalyzeResponse.fromJson(
        (json['analysis'] as Map?)?.cast<String, dynamic>() ?? const <String, dynamic>{},
      ),
      advice: AdviceResponse.fromJson(
        (json['advice'] as Map?)?.cast<String, dynamic>() ?? const <String, dynamic>{},
      ),
      userInputs: UserInputs.fromJson(
        (json['userInputs'] as Map?)?.cast<String, dynamic>() ?? const <String, dynamic>{},
      ),
      checkedActions: (json['checkedActions'] as Map?)
              ?.map((k, v) => MapEntry(k.toString(), v == true)) ??
          <String, bool>{},
    );
  }

  /// 方便你将来导出/导入时使用
  String toJsonString({bool pretty = false}) {
    final obj = toJson();
    return pretty ? const JsonEncoder.withIndent('  ').convert(obj) : jsonEncode(obj);
  }
}