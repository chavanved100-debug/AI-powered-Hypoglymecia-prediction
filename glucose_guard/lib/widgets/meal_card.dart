import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/meal.dart';
import '../theme/app_theme.dart';
import 'risk_card.dart';

class MealCard extends StatelessWidget {
  const MealCard({
    super.key,
    required this.meal,
    this.onTap,
    this.onDelete,
  });

  final Meal meal;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MMM d, h:mm a');

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.borderRadius),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      meal.name,
                      style: Theme.of(context).textTheme.titleMedium,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      dateFormat.format(meal.dateTime),
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _subtitle(meal),
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  RiskBadge(riskLevel: meal.prediction.riskLevel),
                  if (onDelete != null) ...[
                    const SizedBox(height: 8),
                    IconButton(
                      onPressed: onDelete,
                      icon: const Icon(Icons.delete_outline,
                          color: AppColors.textSecondary, size: 20),
                      visualDensity: VisualDensity.compact,
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _subtitle(Meal meal) {
    final carbs = '${meal.nutrition.carbohydrates.round()}g carbs';
    final glucose = meal.prediction.features?.currentGlucose;
    final sleep = meal.prediction.features?.sleepHours;
    final parts = [carbs];
    if (glucose != null) parts.add('${glucose.round()} mg/dL');
    if (sleep != null) {
      parts.add('${sleep.toStringAsFixed(1)}h sleep');
    }
    return parts.join(' · ');
  }
}
