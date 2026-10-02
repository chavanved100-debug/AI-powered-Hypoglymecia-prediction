import 'dart:math' as math;

import 'package:flutter/services.dart';

import '../data/csv_utils.dart';
import '../data/dataset_models.dart';
import '../models/food_item.dart';
import '../models/meal.dart';

/// Loads every CSV under Dataset/ and exposes nutrition, quantity, and meal data.
class DatasetService {
  DatasetService._();

  static final DatasetService instance = DatasetService._();

  bool _loaded = false;
  final List<FoodItem> _foods = [];
  final List<QuantityMapping> _quantities = [];
  final List<ReferenceMeal> _meals = [];
  final List<String> _loadedFiles = [];

  double _carbStd = 25;
  double _proteinStd = 8;
  double _fatStd = 6;
  double _fiberStd = 4;
  double _calorieStd = 150;

  bool get isLoaded => _loaded;
  List<FoodItem> get foods => List.unmodifiable(_foods);
  List<QuantityMapping> get quantities => List.unmodifiable(_quantities);
  List<ReferenceMeal> get referenceMeals => List.unmodifiable(_meals);
  List<String> get loadedFiles => List.unmodifiable(_loadedFiles);

  Future<void> ensureLoaded() async {
    if (_loaded) return;
    await loadFromAssetBundle(rootBundle);
  }

  Future<void> loadFromAssetBundle(AssetBundle bundle) async {
    final paths = await _discoverCsvAssets(bundle);
    if (paths.isEmpty) {
      throw StateError('No CSV files found in the Dataset folder.');
    }

    final foods = <FoodItem>[];
    final quantities = <QuantityMapping>[];
    final meals = <ReferenceMeal>[];
    final loaded = <String>[];

    for (final path in paths) {
      final raw = await bundle.loadString(path);
      final table = CsvTable.parse(raw);
      switch (classifyCsv(table)) {
        case DatasetKind.foodNutrition:
          foods.addAll(_parseFoods(table));
          loaded.add(path);
          break;
        case DatasetKind.quantityMapping:
          quantities.addAll(_parseQuantities(table));
          loaded.add(path);
          break;
        case DatasetKind.mealReference:
          meals.addAll(_parseMeals(table));
          loaded.add(path);
          break;
        case DatasetKind.unknown:
          break;
      }
    }

    if (foods.isEmpty || quantities.isEmpty || meals.isEmpty) {
      throw StateError(
        'Dataset folder must include food nutrition, quantity mapping, '
        'and Indian meal CSVs.',
      );
    }

    _foods
      ..clear()
      ..addAll(_uniqueFoods(foods));
    _quantities
      ..clear()
      ..addAll(_uniqueQuantities(quantities));
    _meals
      ..clear()
      ..addAll(_uniqueMeals(meals));
    _loadedFiles
      ..clear()
      ..addAll(loaded);
    _computeMealStats();
    _loaded = true;
  }

  /// Used by tests to inject parsed tables without Flutter assets.
  void loadFromTables({
    required List<FoodItem> foods,
    required List<QuantityMapping> quantities,
    required List<ReferenceMeal> meals,
  }) {
    _foods
      ..clear()
      ..addAll(foods);
    _quantities
      ..clear()
      ..addAll(quantities);
    _meals
      ..clear()
      ..addAll(meals);
    _computeMealStats();
    _loaded = true;
  }

  void resetForTest() {
    _loaded = false;
    _foods.clear();
    _quantities.clear();
    _meals.clear();
    _loadedFiles.clear();
  }

  FoodItem? findFoodById(String id) {
    for (final food in _foods) {
      if (food.id == id) return food;
    }
    return null;
  }

  List<FoodItem> searchFoods(String query) {
    if (query.trim().isEmpty) return foods;
    final lower = query.toLowerCase();
    return _foods
        .where((f) => f.name.toLowerCase().contains(lower))
        .toList(growable: false);
  }

  /// Scales a serving using Quantity_Mapping.csv when a row matches.
  double multiplierFor(FoodItem food, int quantity) {
    if (!_loaded || _quantities.isEmpty) return quantity.toDouble();
    final unit = servingUnitFrom(food.servingSize);
    final name = food.name.toLowerCase();
    final qty = quantity.toDouble();

    QuantityMapping? best;
    var bestRank = 99;
    for (final mapping in _quantities) {
      if ((mapping.value - qty).abs() > 0.001) continue;
      final text = mapping.text.toLowerCase();
      final rank = text.contains(name)
          ? 0
          : mapping.unit == unit
              ? 1
              : mapping.unit == 'serving' || mapping.unit == 'portion'
                  ? 2
                  : 9;
      if (rank < bestRank) {
        bestRank = rank;
        best = mapping;
      }
    }
    return best?.multiplier ?? quantity.toDouble();
  }

  List<ReferenceMeal> nearestMeals({
    required NutritionTotals nutrition,
    required List<String> foodNames,
    int k = 12,
  }) {
    if (_meals.isEmpty) return const [];
    final scored = _meals
        .map(
          (meal) => (
            meal: meal,
            score: _similarity(nutrition, foodNames, meal),
          ),
        )
        .toList()
      ..sort((a, b) => b.score.compareTo(a.score));
    return scored.take(k).map((e) => e.meal).toList(growable: false);
  }

  double weightedGlycemicLoadScore({
    required NutritionTotals nutrition,
    required List<String> foodNames,
    int k = 12,
  }) {
    final neighbors = nearestMeals(
      nutrition: nutrition,
      foodNames: foodNames,
      k: k,
    );
    if (neighbors.isEmpty) return 55;
    var totalWeight = 0.0;
    var weighted = 0.0;
    for (var i = 0; i < neighbors.length; i++) {
      final weight = (neighbors.length - i).toDouble();
      totalWeight += weight;
      weighted += neighbors[i].glycemicLoadScore * weight;
    }
    return weighted / totalWeight;
  }

  String dominantGlycemicLoad(List<ReferenceMeal> neighbors) {
    if (neighbors.isEmpty) return 'Medium';
    final counts = <String, int>{};
    for (final meal in neighbors) {
      final key = meal.glycemicLoad;
      counts[key] = (counts[key] ?? 0) + 1;
    }
    return counts.entries.reduce((a, b) => a.value >= b.value ? a : b).key;
  }

  /// 0–100 score from where this carb load sits in the meal dataset.
  double carbPercentileScore(double carbohydrates) {
    if (_meals.isEmpty) return 50;
    final below =
        _meals.where((m) => m.carbohydrates <= carbohydrates).length;
    final percentile = below / _meals.length;
    return (percentile * 100).clamp(0, 100);
  }

  Future<List<String>> _discoverCsvAssets(AssetBundle bundle) async {
    final manifest = await AssetManifest.loadFromAssetBundle(bundle);
    final assets = manifest.listAssets()
      ..sort();
    return assets
        .where(
          (path) =>
              path.toLowerCase().startsWith('dataset/') &&
              path.toLowerCase().endsWith('.csv'),
        )
        .toList(growable: false);
  }

  List<FoodItem> _parseFoods(CsvTable table) {
    return table.rows.map((row) {
      final giLabel = table.value(row, 'Glycemic_Index');
      return FoodItem(
        id: table.value(row, 'Food_ID'),
        name: table.value(row, 'Food_Name'),
        servingSize: table.value(row, 'Serving_Size'),
        weightGrams: table.number(row, 'Weight_g'),
        carbohydrates: table.number(row, 'Carbohydrates_g'),
        protein: table.number(row, 'Protein_g'),
        fat: table.number(row, 'Fat_g'),
        fiber: table.number(row, 'Fiber_g'),
        calories: table.number(row, 'Calories_kcal'),
        glycemicIndex: glycemicIndexFromLabel(giLabel),
        glycemicLabel: giLabel.isEmpty ? 'Medium' : giLabel,
      );
    }).where((f) => f.id.isNotEmpty && f.name.isNotEmpty).toList();
  }

  List<QuantityMapping> _parseQuantities(CsvTable table) {
    return table.rows.map((row) {
      return QuantityMapping(
        id: table.value(row, 'Quantity_ID'),
        text: table.value(row, 'Quantity_Text'),
        value: table.number(row, 'Quantity_Value'),
        unit: table.value(row, 'Unit').toLowerCase(),
        multiplier: table.number(row, 'Multiplier', fallback: 1),
      );
    }).where((q) => q.id.isNotEmpty).toList();
  }

  List<ReferenceMeal> _parseMeals(CsvTable table) {
    return table.rows.map((row) {
      return ReferenceMeal(
        id: table.value(row, 'Meal_ID'),
        name: table.value(row, 'Meal_Name'),
        foodItems: table.value(row, 'Food_Items'),
        carbohydrates: table.number(row, 'Total_Carbohydrates_g'),
        protein: table.number(row, 'Total_Protein_g'),
        fat: table.number(row, 'Total_Fat_g'),
        fiber: table.number(row, 'Total_Fiber_g'),
        calories: table.number(row, 'Total_Calories_kcal'),
        glycemicLoad: table.value(row, 'Glycemic_Load'),
      );
    }).where((m) => m.id.isNotEmpty).toList();
  }

  List<FoodItem> _uniqueFoods(List<FoodItem> foods) {
    final seen = <String>{};
    return foods.where((f) => seen.add(f.id)).toList();
  }

  List<QuantityMapping> _uniqueQuantities(List<QuantityMapping> items) {
    final seen = <String>{};
    return items.where((q) => seen.add(q.id)).toList();
  }

  List<ReferenceMeal> _uniqueMeals(List<ReferenceMeal> meals) {
    final seen = <String>{};
    return meals.where((m) => seen.add(m.id)).toList();
  }

  void _computeMealStats() {
    if (_meals.isEmpty) return;
    final carbMean = _mean(_meals.map((m) => m.carbohydrates));
    _carbStd = _std(_meals.map((m) => m.carbohydrates), carbMean);
    final proteinMean = _mean(_meals.map((m) => m.protein));
    _proteinStd = _std(_meals.map((m) => m.protein), proteinMean);
    final fatMean = _mean(_meals.map((m) => m.fat));
    _fatStd = _std(_meals.map((m) => m.fat), fatMean);
    final fiberMean = _mean(_meals.map((m) => m.fiber));
    _fiberStd = _std(_meals.map((m) => m.fiber), fiberMean);
    final calorieMean = _mean(_meals.map((m) => m.calories));
    _calorieStd = _std(_meals.map((m) => m.calories), calorieMean);
  }

  double _similarity(
    NutritionTotals nutrition,
    List<String> foodNames,
    ReferenceMeal meal,
  ) {
    final nutritionScore = 1 /
        (1 +
            _norm(nutrition.carbohydrates, meal.carbohydrates, _carbStd) +
            _norm(nutrition.protein, meal.protein, _proteinStd) +
            _norm(nutrition.fat, meal.fat, _fatStd) +
            _norm(nutrition.fiber, meal.fiber, _fiberStd) +
            _norm(nutrition.calories, meal.calories, _calorieStd));

    if (foodNames.isEmpty) return nutritionScore;
    final haystack = meal.foodItems.toLowerCase();
    var hits = 0;
    for (final name in foodNames) {
      if (haystack.contains(name.toLowerCase())) hits++;
    }
    final overlap = hits / foodNames.length;
    return nutritionScore + (1.6 * overlap);
  }

  double _norm(double actual, double reference, double std) {
    final denom = std <= 0 ? 1.0 : std;
    final z = (actual - reference) / denom;
    return z * z;
  }

  double _mean(Iterable<double> values) {
    var sum = 0.0;
    var count = 0;
    for (final value in values) {
      sum += value;
      count++;
    }
    return count == 0 ? 0 : sum / count;
  }

  double _std(Iterable<double> values, double mean) {
    var sum = 0.0;
    var count = 0;
    for (final value in values) {
      final d = value - mean;
      sum += d * d;
      count++;
    }
    if (count == 0) return 1;
    final variance = sum / count;
    return variance <= 0 ? 1 : math.sqrt(variance);
  }
}
