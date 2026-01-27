class AdviceResponse {
  final String summary;
  final List<String> next48hActions;
  final List<String> seekCareIf;
  final List<String> disclaimers;

  const AdviceResponse({
    required this.summary,
    required this.next48hActions,
    required this.seekCareIf,
    required this.disclaimers,
  });

  static AdviceResponse empty() {
    return const AdviceResponse(
      summary: '',
      next48hActions: [],
      seekCareIf: [],
      disclaimers: [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'summary': summary,
      'next48hActions': next48hActions,
      'seekCareIf': seekCareIf,
      'disclaimers': disclaimers,
    };
  }

  factory AdviceResponse.fromJson(Map<String, dynamic> json) {
    return AdviceResponse(
      summary: json['summary']?.toString() ?? '',
      next48hActions: _stringList(json['next48hActions'] ?? json['next48h']),
      seekCareIf: _stringList(json['seekCareIf']),
      disclaimers: _stringList(json['disclaimers']),
    );
  }

  static List<String> _stringList(Object? value) {
    if (value is List) {
      return value.map((e) => e.toString()).toList();
    }
    return const [];
  }
}
