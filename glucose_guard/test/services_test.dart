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
    expect(first.features?.toCsvMap().keys, ClinicalFeatures.csvHeaders);
  });

  test('glucose stays blank until the user enters a reading', () {
    final now = DateTime(2026, 8, 19, 18, 30);
    final entries = [entry('F001', 2)];
    final totals = nutritionService.calculateTotals(entries);

    final without = const FeatureEstimator().estimate(now: now);
    expect(without.hasUserGlucose, isFalse);

    final noReading = predictionService.predict(
      entries: entries,
      nutrition: totals,
      features: without,
    );
    expect(
      noReading.riskFactors.any((f) => f.name == 'Current Glucose'),
      isFalse,
    );
    expect(
      noReading.riskFactors.any((f) => f.name == 'Glucose Trend'),
      isFalse,
    );
    expect(noReading.recommendation, isNot(contains('Current glucose is')));

    final entered = const FeatureEstimator().estimate(
      now: now,
      overrides: const FeatureOverrides(currentGlucose: 120),
    );
    expect(entered.hasUserGlucose, isTrue);
    expect(entered.currentGlucose, 120);

    final reading = predictionService.predict(
      entries: entries,
      nutrition: totals,
      features: entered,
    );
    expect(
      reading.riskFactors.any((f) => f.name == 'Current Glucose'),
      isTrue,
    );
    expect(reading.recommendation, contains('120 mg/dL'));
  });

  test('insulin factors mirror the dose and time entered by the user', () {
    final now = DateTime(2026, 8, 19, 18, 30);
    final entries = [entry('F001', 2)];
    final totals = nutritionService.calculateTotals(entries);

    final none = const FeatureEstimator().estimate(now: now);
    expect(none.hasUserInsulin, isFalse);
    expect(none.insulinDoseLabel, 'Not logged');
    expect(none.insulinTimeLabel, 'Not logged');
    expect(none.insulinLast120min, 0);
    expect(none.totalInsulinLast2Hours, 0);

    final result = predictionService.predict(
      entries: entries,
      nutrition: totals,
      features: none,
    );
    String factor(String name) =>
        result.riskFactors.firstWhere((f) => f.name == name).value;
    expect(factor('Insulin Dose'), 'Not logged');
    expect(factor('Insulin Time'), 'Not logged');
    expect(factor('Insulin On Board (2h)'), 'None logged');
    expect(result.recommendation, isNot(contains('on board')));

    final logged = const FeatureEstimator().estimate(
      now: now,
      overrides: const FeatureOverrides(
        bolusInsulinUnits: 6,
        timeSinceLastInsulinMinutes: 30,
      ),
    );
    expect(logged.hasUserInsulin, isTrue);
    expect(logged.insulinDoseLabel, '6.0 U');
    expect(logged.insulinTimeLabel, '30 min ago');
    expect(logged.totalInsulinLast2Hours, 6);

    final withInsulin = predictionService.predict(
      entries: entries,
      nutrition: totals,
      features: logged,
    );
    String insulinFactor(String name) =>
        withInsulin.riskFactors.firstWhere((f) => f.name == name).value;
    expect(insulinFactor('Insulin Dose'), '6.0 U');
    expect(insulinFactor('Insulin Time'), '30 min ago');
    expect(insulinFactor('Insulin On Board (45m)'), '6.0 U');
    expect(insulinFactor('Insulin On Board (60m)'), '6.0 U');
    expect(insulinFactor('Insulin On Board (2h)'), '6.0 U');
    expect(withInsulin.recommendation, contains('6.0 U'));
  });

  test('insulin on board windows are cumulative and drop out over time', () {
    final now = DateTime(2026, 8, 19, 18, 30);

    ClinicalFeatures withDose(double units, double minutes) =>
        const FeatureEstimator().estimate(
          now: now,
          overrides: FeatureOverrides(
            bolusInsulinUnits: units,
            timeSinceLastInsulinMinutes: minutes,
          ),
        );

    // 6 U taken 30 min ago sits inside every window up to 2h.
    final recent = withDose(6, 30);
    expect(recent.insulinLast45min, 6);
    expect(recent.insulinLast60min, 6);
    expect(recent.insulinLast120min, 6);
    expect(recent.insulinLast240min, 6);

    // 6 U taken 90 min ago has left the 45m and 60m windows only.
    final older = withDose(6, 90);
    expect(older.insulinLast45min, 0);
    expect(older.insulinLast60min, 0);
    expect(older.insulinLast120min, 6);
    expect(older.insulinLast240min, 6);

    // 6 U taken 5h ago is outside every tracked window.
    final stale = withDose(6, 300);
    expect(stale.insulinLast120min, 0);
    expect(stale.insulinLast240min, 0);
    expect(stale.totalInsulinLast2Hours, 0);
    expect(stale.totalInsulinLast4Hours, 0);
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
