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

  late final TextEditingController _foodsController;
  late final TextEditingController _drinksController;
  late final TextEditingController _moodController;
  late final TextEditingController _notesController;

  @override
  void initState() {
    super.initState();
    final i = widget.initial;
    _foodsController = TextEditingController(text: i.foodsEaten ?? '');
    _drinksController = TextEditingController(text: i.drinksTaken ?? '');
    _moodController = TextEditingController(text: i.moodState ?? '');
    _notesController = TextEditingController(text: i.otherNotes ?? '');
    _foodsController.addListener(_emit);
    _drinksController.addListener(_emit);
    _moodController.addListener(_emit);
    _notesController.addListener(_emit);
    _emit();
  }

  @override
  void dispose() {
    _foodsController.dispose();
    _drinksController.dispose();
    _moodController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  int _filledCount() {
    int c = 0;
    if (_foodsController.text.trim().isNotEmpty) c++;
    if (_drinksController.text.trim().isNotEmpty) c++;
    if (_moodController.text.trim().isNotEmpty) c++;
    if (_notesController.text.trim().isNotEmpty) c++;
    return c;
  }

  void _emit() {
    widget.onChanged(AnalyzeContext(
      foodsEaten: _foodsController.text.trim().isEmpty
          ? null
          : _foodsController.text.trim(),
      drinksTaken: _drinksController.text.trim().isEmpty
          ? null
          : _drinksController.text.trim(),
      moodState: _moodController.text.trim().isEmpty
          ? null
          : _moodController.text.trim(),
      otherNotes: _notesController.text.trim().isEmpty
          ? null
          : _notesController.text.trim(),
    ));
  }

  void _reset() {
    setState(() {
      _foodsController.text = '';
      _drinksController.text = '';
      _moodController.text = '';
      _notesController.text = '';
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
                  Text("$filled/4", style: TextStyle(color: Colors.grey.shade700)),
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
              _sectionTitle("吃了什么"),
              TextField(
                controller: _foodsController,
                decoration: const InputDecoration(
                  hintText: "例如：香蕉+米饭",
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
              ),
              const SizedBox(height: 12),
              _sectionTitle("喝了什么"),
              TextField(
                controller: _drinksController,
                decoration: const InputDecoration(
                  hintText: "例如：牛奶+温水",
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
              ),
              const SizedBox(height: 12),
              _sectionTitle("精神状态"),
              TextField(
                controller: _moodController,
                decoration: const InputDecoration(
                  hintText: "例如：精神很好，能吃能睡",
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
              ),
              const SizedBox(height: 12),
              _sectionTitle("其他"),
              TextField(
                controller: _notesController,
                maxLines: 3,
                decoration: const InputDecoration(
                  hintText: "例如：无发热，无呕吐，次数不多",
                  border: OutlineInputBorder(),
                ),
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
}
