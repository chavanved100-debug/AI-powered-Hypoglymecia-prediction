import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../data/food_database.dart';
import '../models/clinical_features.dart';
import '../models/food_item.dart';
import '../models/meal.dart';
import '../services/feature_estimator.dart';
import '../services/nutrition_service.dart';
import '../services/prediction_service.dart';

class StorageService {
  static const _mealsKey = 'saved_meals';
  static const _carbGoalKey = 'carb_goal';
  static const _demoSeededKey = 'demo_seeded';
  static const _healthKey = 'health_context';

  final NutritionService _nutritionService = NutritionService();
  final PredictionService _predictionService = PredictionService();

  Future<double> getCarbGoal() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble(_carbGoalKey) ?? 180;
  }

  Future<void> setCarbGoal(double goal) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_carbGoalKey, goal);
  }

  Future<SavedHealthContext?> getHealthContext() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_healthKey);
    if (raw == null || raw.isEmpty) return null;
    return SavedHealthContext.fromJson(
      jsonDecode(raw) as Map<String, dynamic>,
    );
  }

  Future<void> saveHealthContext(SavedHealthContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_healthKey, jsonEncode(context.toJson()));
  }

  Future<List<Meal>> getMeals() async {
    await _seedDemoDataIfNeeded();
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_mealsKey);
    if (raw == null || raw.isEmpty) return [];
    final list = jsonDecode(raw) as List<dynamic>;
    return list
        .map((e) => Meal.fromJson(e as Map<String, dynamic>))
        .toList()
      ..sort((a, b) => b.dateTime.compareTo(a.dateTime));
  }

  Future<void> saveMeal(Meal meal) async {
    final meals = await getMeals();
    meals.removeWhere((m) => m.id == meal.id);
    meals.insert(0, meal);
    await _persistMeals(meals);
  }

  Future<void> deleteMeal(String id) async {
    final meals = await getMeals();
    meals.removeWhere((m) => m.id == id);
    await _persistMeals(meals);
  }

  Future<void> _persistMeals(List<Meal> meals) async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(meals.map((m) => m.toJson()).toList());
    await prefs.setString(_mealsKey, encoded);
  }

  Future<void> _seedDemoDataIfNeeded() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(_demoSeededKey) == true) return;

    final demoMeals = _buildDemoMeals();
    await prefs.setString(
      _mealsKey,
      jsonEncode(demoMeals.map((m) => m.toJson()).toList()),
    );
    await prefs.setBool(_demoSeededKey, true);
  }

  List<Meal> _buildDemoMeals() {
    Meal buildDemo({
      required String id,
      required List<SelectedFoodEntry> entries,
      required DateTime dateTime,
    }) {
      final nutrition = _nutritionService.calculateTotals(entries);
      final features = const FeatureEstimator().estimate(
        now: dateTime,
        priorMeals: const [],
      );
      final prediction = _predictionService.predict(
        entries: entries,
        nutrition: nutrition,
        features: features,
      );
      return Meal(
        id: id,
        name: _nutritionService.buildMealName(entries),
        dateTime: dateTime,
        entries: entries,
        nutrition: nutrition,
        prediction: prediction,
      );
    }

    SelectedFoodEntry entry(String foodId, int qty) => SelectedFoodEntry(
          food: FoodDatabase.findById(foodId)!,
          quantity: qty,
        );

    final now = DateTime.now();
    return [
      buildDemo(
        id: 'demo_1',
        entries: [
          entry('F002', 1),
          entry('F003', 1),
          entry('F001', 2),
        ],
        dateTime: now.subtract(const Duration(hours: 2)),
      ),
      buildDemo(
        id: 'demo_2',
        entries: [
          entry('F008', 1),
          entry('F015', 1),
        ],
        dateTime: now.subtract(const Duration(hours: 6)),
      ),
      buildDemo(
        id: 'demo_3',
        entries: [
          entry('F001', 2),
          entry('F005', 1),
        ],
        dateTime: now.subtract(const Duration(days: 1)),
      ),
    ];
  }
}
