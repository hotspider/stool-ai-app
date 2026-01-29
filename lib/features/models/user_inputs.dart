class UserInputs {
  final String odor;
  final bool painOrStrain;
  final String dietKeywords;
  final Map<String, dynamic>? contextInput;

  const UserInputs({
    required this.odor,
    required this.painOrStrain,
    required this.dietKeywords,
    this.contextInput,
  });

  Map<String, dynamic> toJson() {
    return {
      'odor': odor,
      'painOrStrain': painOrStrain,
      'dietKeywords': dietKeywords,
      if (contextInput != null) 'contextInput': contextInput,
    };
  }

  factory UserInputs.fromJson(Map<String, dynamic> json) {
    return UserInputs(
      odor: json['odor']?.toString() ?? 'none',
      painOrStrain: json['painOrStrain'] == true,
      dietKeywords: json['dietKeywords']?.toString() ?? '',
      contextInput: json['contextInput'] is Map
          ? (json['contextInput'] as Map).map((k, v) => MapEntry(k.toString(), v))
          : null,
    );
  }
}
