import 'package:flutter/material.dart';

import '../models/prediction.dart';
import '../theme/app_theme.dart';

RiskLevelVisual riskVisualFromLevel(RiskLevel level) {
  switch (level) {
    case RiskLevel.low:
      return RiskLevelVisual.low;
    case RiskLevel.moderate:
      return RiskLevelVisual.moderate;
    case RiskLevel.high:
      return RiskLevelVisual.high;
  }
}

class RiskCard extends StatelessWidget {
  const RiskCard({
    super.key,
    required this.riskScore,
    required this.riskLevel,
    this.title = "Today's Risk",
    this.subtitle,
    this.large = true,
  });

  final String title;
  final int riskScore;
  final RiskLevel riskLevel;
  final String? subtitle;
  final bool large;

  @override
  Widget build(BuildContext context) {
    final visual = riskVisualFromLevel(riskLevel);
    final color = AppColors.riskColor(visual);
    final bgColor = AppColors.riskBgColor(visual);

    return Card(
      color: bgColor,
      child: Padding(
        padding: EdgeInsets.all(large ? 24 : 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 4),
              Text(subtitle!, style: Theme.of(context).textTheme.bodyMedium),
            ],
            SizedBox(height: large ? 16 : 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  riskLevel.label,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        color: color,
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const Spacer(),
                Text(
                  '$riskScore%',
                  style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                        color: color,
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            if (large) ...[
              const SizedBox(height: 8),
              Text(
                'Demo Risk Estimate',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontStyle: FontStyle.italic,
                    ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class RiskBadge extends StatelessWidget {
  const RiskBadge({super.key, required this.riskLevel});

  final RiskLevel riskLevel;

  @override
  Widget build(BuildContext context) {
    final visual = riskVisualFromLevel(riskLevel);
    final color = AppColors.riskColor(visual);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.riskBgColor(visual),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        riskLevel.displayLabel,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
