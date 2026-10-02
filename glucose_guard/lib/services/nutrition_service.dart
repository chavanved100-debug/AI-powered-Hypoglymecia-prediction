import '../models/food_item.dart';
import '../models/meal.dart';
import 'dataset_service.dart';

class NutritionService {
  NutritionService({DatasetService? dataset})
      : _dataset = dataset ?? DatasetService.instance;

  final DatasetService _dataset;

  NutritionTotals calculateTotals(List<SelectedFoodEntry> entries) {
    var totals = const NutritionTotals();
    for (final entry in entries) {
      final q = _dataset.multiplierFor(entry.food, entry.quantity);
      totals += NutritionTotals(
        carbohydrates: entry.food.carbohydrates * q,
        calories: entry.food.calories * q,
        protein: entry.food.protein * q,
        fat: entry.food.fat * q,
        fiber: entry.food.fiber * q,
      );
    }
    return totals;
  }

  String buildMealName(List<SelectedFoodEntry> entries) {
    if (entries.isEmpty) return 'Empty Meal';
    if (entries.length <= 3) {
      return entries.map((e) => e.food.name).join(' + ');
    }
    final first = entries.take(2).map((e) => e.food.name).join(' + ');
    return '$first + ${entries.length - 2} more';
  }
}
