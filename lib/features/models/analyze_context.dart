class AnalyzeContext {
  final String? foodsEaten;
  final String? drinksTaken;
  final String? moodState;
  final String? otherNotes;

  const AnalyzeContext({
    this.foodsEaten,
    this.drinksTaken,
    this.moodState,
    this.otherNotes,
  });

  Map<String, dynamic> toJson() {
    final m = <String, dynamic>{};
    if (foodsEaten != null) m['foods_eaten'] = foodsEaten;
    if (drinksTaken != null) m['drinks_taken'] = drinksTaken;
    if (moodState != null) m['mood_state'] = moodState;
    if (otherNotes != null) m['other_notes'] = otherNotes;
    return m;
  }

  bool get isEmpty => toJson().isEmpty;
}
