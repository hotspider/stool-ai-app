class UserInputs {
  final String odor;
  final bool painOrStrain;
  final String dietKeywords;

  const UserInputs({
    required this.odor,
    required this.painOrStrain,
    required this.dietKeywords,
  });

  Map<String, dynamic> toJson() {
    return {
      'odor': odor,
      'painOrStrain': painOrStrain,
      'dietKeywords': dietKeywords,
    };
  }

  factory UserInputs.fromJson(Map<String, dynamic> json) {
    return UserInputs(
      odor: json['odor']?.toString() ?? 'none',
      painOrStrain: json['painOrStrain'] == true,
      dietKeywords: json['dietKeywords']?.toString() ?? '',
    );
  }
}
