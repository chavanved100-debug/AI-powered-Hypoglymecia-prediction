import 'package:flutter_test/flutter_test.dart';
import 'package:glucose_guard/data/food_database.dart';
import 'package:glucose_guard/models/clinical_features.dart';
import 'package:glucose_guard/models/food_item.dart';
import 'package:glucose_guard/services/dataset_service.dart';
import 'package:glucose_guard/services/feature_estimator.dart';
import 'package:glucose_guard/services/nutrition_service.dart';
import 'package:glucose_guard/services/prediction_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await DatasetService.instance.ensureLoaded();
  });

  final nutritionService = NutritionService();
  final predictionService = PredictionService();

  SelectedFoodEntry entry(String id, int qty) => SelectedFoodEntry(
        food: FoodDatabase.findById(id)!,
        quantity: qty,
      );

  test('loads all Dataset CSV files', () {
    expect(DatasetService.instance.loadedFiles.length, greaterThanOrEqualTo(3));
    expect(DatasetService.instance.foods.length, greaterThanOrEqualTo(100));
    expect(DatasetService.instance.quantities.length, greaterThanOrEqualTo(50));
    expect(
      DatasetService.instance.referenceMeals.length,
      greaterThanOrEqualTo(100),
    );
  });

  test('nutrition totals scale with quantity mapping', () {
    final roti = FoodDatabase.findById('F001')!;
    final one = nutritionService.calculateTotals([entry('F001', 1)]);
    final two = nutritionService.calculateTotals([entry('F001', 2)]);
    final multiplier = DatasetService.instance.multiplierFor(roti, 2);
    expect(two.carbohydrates, closeTo(roti.carbohydrates * multiplier, 0.01));
    expect(two.carbohydrates, greaterThan(one.carbohydrates));
  });

  test('prediction is deterministic and uses dataset meals', () {
    final entries = [entry('F001', 2), entry('F003', 1), entry('F002', 1)];
    final totals = nutritionService.calculateTotals(entries);

    final now = DateTime(2026, 8, 19, 18, 30);
    final features = const FeatureEstimator().estimate(now: now);
    final first = predictionService.predict(
      entries: entries,
      nutrition: totals,
      features: features,
    );
    final second = predictionService.predict(
      entries: entries,
      nutrition: totals,
      features: features,
    );

    expect(first.riskScore, second.riskScore);
    expect(first.riskLevel, second.riskLevel);
    expect(first.riskFactors.length, greaterThanOrEqualTo(3));
    expect(
      first.riskFactors.any((f) => f.name == 'Glycemic Load'),
      isTrue,
    );
    expect(
      first.riskFactors.any((f) => f.name == 'Current Glucose'),
      isTrue,
    );
    expect(first.features?.toCsvMap().keys, ClinicalFeatures.csvHeaders);
  });

  test('feature estimator fills every clinical column', () {
    final features = const FeatureEstimator().estimate(
      now: DateTime(2026, 8, 19, 9, 0),
    );
    final map = features.toCsvMap();
    expect(map.keys.toList(), ClinicalFeatures.csvHeaders);
    expect(features.currentGlucose, greaterThan(40));
    expect(features.source, FeatureSource.estimated);
  });

  test('food database is sourced from nutrition CSV', () {
    expect(FoodDatabase.foods.length, greaterThanOrEqualTo(100));
    expect(FoodDatabase.findById('F001')?.name, 'Roti');
  });
}
