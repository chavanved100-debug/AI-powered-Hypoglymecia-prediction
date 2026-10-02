import '../models/clinical_features.dart';
import '../models/food_item.dart';
import '../models/meal.dart';
import '../models/prediction.dart';
import 'dataset_service.dart';

/// Combines meal Dataset CSVs with CGM / insulin / exercise features.
class PredictionService {
  PredictionService({DatasetService? dataset})
      : _dataset = dataset ?? DatasetService.instance;

  final DatasetService _dataset;

  PredictionResult predict({
    required List<SelectedFoodEntry> entries,
    required NutritionTotals nutrition,
    ClinicalFeatures? features,
  }) {
    if (entries.isEmpty) {
      return const PredictionResult(
        riskScore: 0,
        riskLevel: RiskLevel.low,
        riskFactors: [],
        recommendation:
            'Add food items to receive a risk estimate from the Dataset CSVs.',
      );
    }

    final foodNames = entries.map((e) => e.food.name).toList();
    final neighbors = _dataset.nearestMeals(
      nutrition: nutrition,
      foodNames: foodNames,
    );
    final glScore = _dataset.weightedGlycemicLoadScore(
      nutrition: nutrition,
      foodNames: foodNames,
    );
    final glLabel = _dataset.dominantGlycemicLoad(neighbors);
    final avgGi = _averageGlycemicIndex(entries);
    final carbScore = _dataset.carbPercentileScore(nutrition.carbohydrates);
    final proteinFiber = nutrition.protein + nutrition.fiber;
    final compositionScore =
        _compositionScore(proteinFiber, nutrition.carbohydrates);

    var mealScore =
        (glScore * 0.42) + (avgGi * 0.22) + (carbScore * 0.22) + (compositionScore * 0.14);

    final highGiCount =
        entries.where((e) => e.food.glycemicIndex >= 70).length;
    mealScore += highGiCount * 3;

    final clinicalScore =
        features == null ? mealScore : _clinicalScore(features);
    final score = features == null
        ? mealScore
        : (mealScore * 0.55) + (clinicalScore * 0.45);

    final riskScore = score.round().clamp(0, 100);
    final riskLevel = RiskLevelX.fromScore(riskScore);
    final closest = neighbors.isEmpty ? null : neighbors.first;

    return PredictionResult(
      riskScore: riskScore,
      riskLevel: riskLevel,
      features: features,
      riskFactors: [
        if (features != null) ...[
          RiskFactor(
            name: 'Current Glucose',
            value: '${features.currentGlucose.round()} mg/dL',
          ),
          RiskFactor(name: 'Glucose Trend', value: features.trendLabel),
          RiskFactor(
            name: 'Insulin (2h)',
            value: '${features.totalInsulinLast2Hours.toStringAsFixed(1)} U',
          ),
          RiskFactor(
            name: 'Sleep cycle',
            value:
                '${features.sleepHours.toStringAsFixed(1)}h · ${features.sleepCycleLabel}',
          ),
        ],
        RiskFactor(name: 'Glycemic Load', value: glLabel),
        RiskFactor(
          name: 'Carbohydrate Load',
          value: _carbLoadLabel(nutrition.carbohydrates),
        ),
        RiskFactor(
          name: 'Meal Composition',
          value: _compositionLabel(proteinFiber, nutrition.carbohydrates),
        ),
        if (closest != null)
          RiskFactor(
            name: 'Closest Dataset Meal',
            value: closest.name,
          ),
      ],
      recommendation: _recommendation(riskLevel, glLabel, features),
    );
  }

  double _clinicalScore(ClinicalFeatures f) {
    var score = 0.0;

    if (f.currentGlucose < 70) {
      score += 48;
    } else if (f.currentGlucose < 90) {
      score += 26;
    } else if (f.currentGlucose > 250) {
      score += 36;
    } else if (f.currentGlucose > 180) {
      score += 24;
    } else if (f.currentGlucose > 140) {
      score += 12;
    } else {
      score += 8;
    }

    if (f.glucoseRateChange15min <= -1.5) {
      score += 22;
    } else if (f.glucoseRateChange15min <= -0.5) {
      score += 12;
    } else if (f.glucoseRateChange15min >= 1.5) {
      score += 10;
    }

    score += (f.totalInsulinLast2Hours * 3.5).clamp(0, 16);

    if (f.exerciseDuration > 10 && f.timeSinceExercise <= 90) {
      score += 8 + (f.exerciseIntensity * 3);
    }

    if (f.carbsLast2Hours < 15 && f.insulinLast60min >= 2) {
      score += 10;
    }

    if (f.sleepHours < 6) score += 10;
    if (f.sleepQuality <= 0) score += 8;
    if (f.sleepCycleType >= 2) score += 6;

    return score.clamp(0, 100);
  }

  double _averageGlycemicIndex(List<SelectedFoodEntry> entries) {
    var totalWeight = 0.0;
    var weightedGi = 0.0;
    for (final entry in entries) {
      final weight =
          entry.food.carbohydrates * _dataset.multiplierFor(entry.food, entry.quantity);
      weightedGi += entry.food.glycemicIndex * weight;
      totalWeight += weight;
    }
    if (totalWeight == 0) return 50;
    return weightedGi / totalWeight;
  }

  double _compositionScore(double proteinFiber, double carbs) {
    if (carbs == 0) return 20;
    final ratio = proteinFiber / carbs;
    if (ratio >= 0.4) return 18;
    if (ratio >= 0.25) return 45;
    return 78;
  }

  String _carbLoadLabel(double carbs) {
    if (carbs <= 45) return 'Low';
    if (carbs <= 75) return 'Moderate';
    return 'High';
  }

  String _compositionLabel(double proteinFiber, double carbs) {
    if (carbs == 0) return 'Balanced';
    final ratio = proteinFiber / carbs;
    if (ratio >= 0.35) return 'Balanced';
    if (ratio >= 0.2) return 'Moderate';
    return 'Carb-heavy';
  }

  String _recommendation(
    RiskLevel level,
    String glycemicLoad,
    ClinicalFeatures? features,
  ) {
    final glucoseNote = features == null
        ? ''
        : ' Current glucose is estimated at ${features.currentGlucose.round()} mg/dL (${features.trendLabel.toLowerCase()}).';

    switch (level) {
      case RiskLevel.low:
        return 'Similar meals in the Dataset have a $glycemicLoad glycemic load.$glucoseNote '
            'This meal appears relatively balanced. Continue your usual '
            'diabetes-management routine and stay hydrated.';
      case RiskLevel.moderate:
        return 'Similar meals in the Dataset have a $glycemicLoad glycemic load.$glucoseNote '
            'Monitor glucose levels after the meal and maintain your usual '
            'diabetes-management routine.';
      case RiskLevel.high:
        return 'Similar meals in the Dataset have a $glycemicLoad glycemic load.$glucoseNote '
            'Consider pairing with protein or fiber-rich foods and monitor '
            'glucose closely. Consult your care team for personalized guidance.';
    }
  }
}
