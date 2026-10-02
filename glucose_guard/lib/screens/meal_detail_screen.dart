import 'package:flutter/material.dart';

import '../models/clinical_features.dart';
import '../models/meal.dart';
import '../theme/app_theme.dart';
import '../widgets/clinical_features_card.dart';
import '../widgets/nutrition_card.dart';
import '../widgets/risk_card.dart';

class MealDetailScreen extends StatelessWidget {
  const MealDetailScreen({super.key, required this.meal});

  final Meal meal;

  @override
  Widget build(BuildContext context) {
    final features = meal.prediction.features;
    return Scaffold(
      appBar: AppBar(title: const Text('Meal details')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(meal.name, style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 16),
          RiskCard(
            title: 'Risk level',
            riskScore: meal.prediction.riskScore,
            riskLevel: meal.prediction.riskLevel,
            large: false,
          ),
          if (features != null) ...[
            const SizedBox(height: 16),
            _HealthSummary(features: features),
            const SizedBox(height: 12),
            ClinicalFeaturesCard(features: features),
          ],
          const SizedBox(height: 16),
          NutritionCard(
            title: 'Nutrition',
            carbohydrates: meal.nutrition.carbohydrates,
            calories: meal.nutrition.calories,
            protein: meal.nutrition.protein,
            fiber: meal.nutrition.fiber,
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Foods', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 12),
                  ...meal.entries.map(
                    (e) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(child: Text(e.food.name)),
                          Text('× ${e.quantity}'),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HealthSummary extends StatelessWidget {
  const _HealthSummary({required this.features});

  final ClinicalFeatures features;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppColors.primary.withValues(alpha: 0.08),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const Icon(Icons.monitor_heart_outlined, color: AppColors.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                '${features.currentGlucose.round()} mg/dL · ${features.trendLabel}\n'
                '${features.sleepHours.toStringAsFixed(1)}h ${features.sleepCycleLabel} · ${features.sleepQualityLabel}',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
