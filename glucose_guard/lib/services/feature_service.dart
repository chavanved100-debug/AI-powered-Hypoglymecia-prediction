import 'package:flutter/services.dart';

import '../data/csv_utils.dart';
import '../models/clinical_features.dart';
import '../models/meal.dart';
import 'feature_estimator.dart';

/// Resolves clinical features from a future Dataset CSV, or estimates them.
class FeatureService {
  FeatureService._();

  static final FeatureService instance = FeatureService._();

  bool _loaded = false;
  ClinicalFeatures? _datasetRow;
  String? _datasetPath;

  ClinicalFeatures? get datasetRow => _datasetRow;
  String? get datasetPath => _datasetPath;
  bool get hasDatasetRow => _datasetRow != null;

  Future<void> ensureLoaded() async {
    if (_loaded) return;
    await loadFromAssetBundle(rootBundle);
  }

  Future<void> loadFromAssetBundle(AssetBundle bundle) async {
    final manifest = await AssetManifest.loadFromAssetBundle(bundle);
    final csvPaths = manifest
        .listAssets()
        .where(
          (path) =>
              path.toLowerCase().startsWith('dataset/') &&
              path.toLowerCase().endsWith('.csv'),
        )
        .toList()
      ..sort();

    ClinicalFeatures? row;
    String? pathFound;
    for (final path in csvPaths) {
      final raw = await bundle.loadString(path);
      final table = CsvTable.parse(raw);
      if (!_isFeatureTable(table) || table.rows.isEmpty) continue;
      row = ClinicalFeatures.fromCsvMap(
        {
          for (final header in table.headers)
            header: table.value(table.rows.last, header),
        },
      );
      pathFound = path;
    }

    _datasetRow = row;
    _datasetPath = pathFound;
    _loaded = true;
  }

  ClinicalFeatures resolve({
    required DateTime now,
    List<Meal> priorMeals = const [],
    FeatureOverrides overrides = const FeatureOverrides(),
  }) {
    if (_datasetRow != null && overrides.isEmpty) {
      return _datasetRow!;
    }
    if (_datasetRow != null) {
      return _applyOverrides(_datasetRow!, overrides, now);
    }
    return const FeatureEstimator().estimate(
      now: now,
      priorMeals: priorMeals,
      overrides: overrides,
    );
  }

  bool _isFeatureTable(CsvTable table) {
    final headers = table.headers.map((h) => h.toLowerCase()).toSet();
    return headers.contains('current_glucose') &&
        headers.contains('glucose_rate_change_15min');
  }

  ClinicalFeatures _applyOverrides(
    ClinicalFeatures base,
    FeatureOverrides overrides,
    DateTime now,
  ) {
    return const FeatureEstimator().estimate(
      now: now,
      overrides: FeatureOverrides(
        currentGlucose: overrides.currentGlucose ?? base.currentGlucose,
        bolusInsulinUnits:
            overrides.bolusInsulinUnits ?? base.bolusInsulinLast60min,
        timeSinceLastInsulinMinutes: overrides.timeSinceLastInsulinMinutes ??
            base.timeSinceLastInsulin,
        exerciseDurationMinutes:
            overrides.exerciseDurationMinutes ?? base.exerciseDuration,
        exerciseIntensity: overrides.exerciseIntensity ?? base.exerciseIntensity,
        timeSinceExerciseMinutes:
            overrides.timeSinceExerciseMinutes ?? base.timeSinceExercise,
        sleepHours: overrides.sleepHours ?? base.sleepHours,
        sleepQuality: overrides.sleepQuality ?? base.sleepQuality,
        sleepCycleType: overrides.sleepCycleType ?? base.sleepCycleType,
      ),
      source: FeatureSource.dataset,
    );
  }
}
