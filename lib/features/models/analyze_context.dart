class AnalyzeContext {
  final String? moodState; // good | normal | poor
  final String? appetite; // normal | slightly_low | poor
  final int? poopCount24h; // 0-10
  final bool? painOrStrain; // true/false
  final List<String>? dietTags; // ["fruit","vegetable",...]
  final String? hydrationIntake; // normal | low | high
  final List<String>? warningSigns; // ["fever","vomiting",...]
  final String? odor; // none | stronger | foul

  const AnalyzeContext({
    this.moodState,
    this.appetite,
    this.poopCount24h,
    this.painOrStrain,
    this.dietTags,
    this.hydrationIntake,
    this.warningSigns,
    this.odor,
  });

  Map<String, dynamic> toJson() {
    final m = <String, dynamic>{};
    if (moodState != null) m['mood_state'] = moodState;
    if (appetite != null) m['appetite'] = appetite;
    if (poopCount24h != null) m['poop_count_24h'] = poopCount24h;
    if (painOrStrain != null) m['pain_or_strain'] = painOrStrain;
    if (dietTags != null && dietTags!.isNotEmpty) m['diet_tags'] = dietTags;
    if (hydrationIntake != null) m['hydration_intake'] = hydrationIntake;
    if (warningSigns != null && warningSigns!.isNotEmpty) {
      m['warning_signs'] = warningSigns;
    }
    if (odor != null) m['odor'] = odor;
    return m;
  }

  bool get isEmpty => toJson().isEmpty;
}
