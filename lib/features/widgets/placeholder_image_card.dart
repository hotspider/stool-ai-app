import 'package:flutter/material.dart';
import 'package:app/l10n/app_localizations.dart';

class PlaceholderImageCard extends StatelessWidget {
  final double height;

  const PlaceholderImageCard({super.key, this.height = 240});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Container(
        height: height,
        width: double.infinity,
        decoration: BoxDecoration(
          color: const Color(0xFFF0F2F5),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.image_outlined, size: 48, color: Color(0xFF9CA3AF)),
            const SizedBox(height: 12),
            Text(
              AppLocalizations.of(context)!.placeholderImage,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}
