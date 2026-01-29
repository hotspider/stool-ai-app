import 'package:flutter/material.dart';

import '../models/analyze_context.dart';

class OptionalContextPanel extends StatefulWidget {
  final ValueChanged<AnalyzeContext> onChanged;
  final AnalyzeContext initial;

  const OptionalContextPanel({
    super.key,
    required this.onChanged,
    this.initial = const AnalyzeContext(),
  });

  @override
  State<OptionalContextPanel> createState() => _OptionalContextPanelState();
}

class _OptionalContextPanelState extends State<OptionalContextPanel> {
  bool _expanded = false;

  String? moodState;
  String? appetite;
  int poopCount24h = 1;
  bool painOrStrain = false;
  final Set<String> dietTags = {};
  String? hydrationIntake;
  final Set<String> warningSigns = {};
  String? odor;

  @override
  void initState() {
    super.initState();
    final i = widget.initial;
    moodState = i.moodState;
    appetite = i.appetite;
    poopCount24h = i.poopCount24h ?? 1;
    painOrStrain = i.painOrStrain ?? false;
    if (i.dietTags != null) dietTags.addAll(i.dietTags!);
    hydrationIntake = i.hydrationIntake;
    if (i.warningSigns != null) warningSigns.addAll(i.warningSigns!);
    odor = i.odor;
    _emit();
  }

  int _filledCount() {
    int c = 0;
    if (moodState != null) c++;
    if (appetite != null) c++;
    if (painOrStrain) c++;
    if (dietTags.isNotEmpty) c++;
    if (hydrationIntake != null) c++;
    if (warningSigns.isNotEmpty) c++;
    if (odor != null) c++;
    return c;
  }

  void _emit() {
    widget.onChanged(AnalyzeContext(
      moodState: moodState,
      appetite: appetite,
      poopCount24h: poopCount24h,
      painOrStrain: painOrStrain,
      dietTags: dietTags.toList(),
      hydrationIntake: hydrationIntake,
      warningSigns: warningSigns.toList(),
      odor: odor,
    ));
  }

  void _reset() {
    setState(() {
      moodState = null;
      appetite = null;
      poopCount24h = 1;
      painOrStrain = false;
      dietTags.clear();
      hydrationIntake = null;
      warningSigns.clear();
      odor = null;
    });
    _emit();
  }

  @override
  Widget build(BuildContext context) {
    final filled = _filledCount();
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            InkWell(
              onTap: () => setState(() => _expanded = !_expanded),
              child: Row(
                children: [
                  const Icon(Icons.tune),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      "补充信息（可选）",
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                  ),
                  Text("$filled/8", style: TextStyle(color: Colors.grey.shade700)),
                  const SizedBox(width: 8),
                  Icon(_expanded ? Icons.expand_less : Icons.expand_more),
                ],
              ),
            ),
            const SizedBox(height: 6),
            if (!_expanded)
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "填写后可提升判断准确度（可选）",
                  style: TextStyle(color: Colors.grey.shade700),
                ),
              ),
            if (_expanded) ...[
              const SizedBox(height: 12),
              _sectionTitle("宝宝状态"),
              _segmented(
                label: "精神状态",
                value: moodState,
                items: const {
                  "good": "精神好",
                  "normal": "一般",
                  "poor": "精神差",
                },
                onChanged: (v) {
                  setState(() => moodState = v);
                  _emit();
                },
              ),
              _segmented(
                label: "食欲",
                value: appetite,
                items: const {
                  "normal": "正常",
                  "slightly_low": "少一点",
                  "poor": "明显不想吃",
                },
                onChanged: (v) {
                  setState(() => appetite = v);
                  _emit();
                },
              ),
              const SizedBox(height: 12),
              _sectionTitle("排便情况"),
              _stepper(
                label: "24小时排便次数",
                value: poopCount24h,
                min: 0,
                max: 10,
                onChanged: (v) {
                  setState(() => poopCount24h = v);
                  _emit();
                },
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text("是否疼痛/明显用力"),
                value: painOrStrain,
                onChanged: (v) {
                  setState(() => painOrStrain = v);
                  _emit();
                },
              ),
              const SizedBox(height: 12),
              _sectionTitle("近期饮食"),
              _tagSelector(
                label: "最近24h吃过（可多选）",
                options: const {
                  "fruit": "水果多",
                  "vegetable": "绿叶菜多",
                  "meat": "肉类多",
                  "soup": "汤水多",
                  "milk": "奶/配方奶",
                  "yogurt": "酸奶",
                  "cold": "冷饮/凉食",
                  "oily": "油腻",
                  "new_food": "新加辅食",
                },
                selected: dietTags,
                onChanged: () {
                  setState(() {});
                  _emit();
                },
              ),
              _segmented(
                label: "饮水/喝的东西",
                value: hydrationIntake,
                items: const {
                  "normal": "正常",
                  "low": "偏少",
                  "high": "偏多",
                },
                onChanged: (v) {
                  setState(() => hydrationIntake = v);
                  _emit();
                },
              ),
              const SizedBox(height: 12),
              _sectionTitle("危险信号"),
              _checkboxList(
                label: "是否出现（可多选）",
                options: const {
                  "fever": "发热",
                  "vomiting": "呕吐",
                  "abdominal_pain": "明显腹痛",
                  "blood_or_mucus": "血丝/粘液",
                  "black_or_pale": "黑便/灰白便",
                },
                selected: warningSigns,
                onChanged: () {
                  setState(() {});
                  _emit();
                },
              ),
              const SizedBox(height: 12),
              _sectionTitle("气味"),
              _segmented(
                label: "气味",
                value: odor,
                items: const {
                  "none": "无明显",
                  "stronger": "比平时重",
                  "foul": "非常臭/刺鼻",
                },
                onChanged: (v) {
                  setState(() => odor = v);
                  _emit();
                },
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: _reset,
                  icon: const Icon(Icons.refresh),
                  label: const Text("清空"),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String t) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(t, style: const TextStyle(fontWeight: FontWeight.w700)),
    );
  }

  Widget _segmented({
    required String label,
    required String? value,
    required Map<String, String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(color: Colors.grey.shade700)),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: items.entries.map((e) {
              final selected = value == e.key;
              return ChoiceChip(
                label: Text(e.value),
                selected: selected,
                onSelected: (_) => onChanged(selected ? null : e.key),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _stepper({
    required String label,
    required int value,
    required int min,
    required int max,
    required ValueChanged<int> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        children: [
          Expanded(child: Text(label)),
          IconButton(
            onPressed: value > min ? () => onChanged(value - 1) : null,
            icon: const Icon(Icons.remove_circle_outline),
          ),
          Text("$value"),
          IconButton(
            onPressed: value < max ? () => onChanged(value + 1) : null,
            icon: const Icon(Icons.add_circle_outline),
          ),
        ],
      ),
    );
  }

  Widget _tagSelector({
    required String label,
    required Map<String, String> options,
    required Set<String> selected,
    required VoidCallback onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(color: Colors.grey.shade700)),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: options.entries.map((e) {
              final isOn = selected.contains(e.key);
              return FilterChip(
                label: Text(e.value),
                selected: isOn,
                onSelected: (v) {
                  if (v) {
                    selected.add(e.key);
                  } else {
                    selected.remove(e.key);
                  }
                  onChanged();
                },
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _checkboxList({
    required String label,
    required Map<String, String> options,
    required Set<String> selected,
    required VoidCallback onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(color: Colors.grey.shade700)),
          const SizedBox(height: 6),
          ...options.entries.map((e) {
            final isOn = selected.contains(e.key);
            return CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              value: isOn,
              title: Text(e.value),
              onChanged: (v) {
                if (v == true) {
                  selected.add(e.key);
                } else {
                  selected.remove(e.key);
                }
                onChanged();
              },
            );
          }),
        ],
      ),
    );
  }
}
