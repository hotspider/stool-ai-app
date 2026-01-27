import 'package:flutter/material.dart';
import 'package:app/l10n/app_localizations.dart';

enum LoadingStepStatus { pending, active, done }

class LoadingStepItem {
  final String label;
  final LoadingStepStatus status;

  const LoadingStepItem({
    required this.label,
    required this.status,
  });
}

class LoadingSteps extends StatelessWidget {
  final List<LoadingStepItem> steps;

  const LoadingSteps({super.key, required this.steps});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppLocalizations.of(context)!.loadingTitle,
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 12),
            const LinearProgressIndicator(minHeight: 6),
            const SizedBox(height: 16),
            ...steps.map((step) => _StepRow(step: step)),
          ],
        ),
      ),
    );
  }
}

class _StepRow extends StatelessWidget {
  final LoadingStepItem step;

  const _StepRow({required this.step});

  @override
  Widget build(BuildContext context) {
    final color = switch (step.status) {
      LoadingStepStatus.done => const Color(0xFF16A34A),
      LoadingStepStatus.active => const Color(0xFF2563EB),
      LoadingStepStatus.pending => const Color(0xFF9CA3AF),
    };
    final icon = switch (step.status) {
      LoadingStepStatus.done => Icons.check_circle,
      LoadingStepStatus.active => Icons.timelapse,
      LoadingStepStatus.pending => Icons.radio_button_unchecked,
    };

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              step.label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: color,
                    fontWeight: step.status == LoadingStepStatus.active
                        ? FontWeight.w600
                        : FontWeight.w400,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
