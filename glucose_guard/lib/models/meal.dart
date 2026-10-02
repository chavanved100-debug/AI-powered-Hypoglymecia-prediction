import 'food_item.dart';
import 'prediction.dart';

class NutritionTotals {
  const NutritionTotals({
    this.carbohydrates = 0,
    this.calories = 0,
    this.protein = 0,
    this.fat = 0,
    this.fiber = 0,
  });

  final double carbohydrates;
  final double calories;
  final double protein;
  final double fat;
  final double fiber;

  NutritionTotals operator +(NutritionTotals other) => NutritionTotals(
        carbohydrates: carbohydrates + other.carbohydrates,
        calories: calories + other.calories,
        protein: protein + other.protein,
        fat: fat + other.fat,
        fiber: fiber + other.fiber,
      );

  Map<String, dynamic> toJson() => {
        'carbohydrates': carbohydrates,
        'calories': calories,
        'protein': protein,
        'fat': fat,
        'fiber': fiber,
      };

  factory NutritionTotals.fromJson(Map<String, dynamic> json) =>
      NutritionTotals(
        carbohydrates: (json['carbohydrates'] as num).toDouble(),
        calories: (json['calories'] as num).toDouble(),
        protein: (json['protein'] as num).toDouble(),
        fat: (json['fat'] as num).toDouble(),
        fiber: (json['fiber'] as num).toDouble(),
      );
}

class Meal {
  const Meal({
    required this.id,
    required this.name,
    required this.dateTime,
    required this.entries,
    required this.nutrition,
    required this.prediction,
  });

  final String id;
  final String name;
  final DateTime dateTime;
  final List<SelectedFoodEntry> entries;
  final NutritionTotals nutrition;
  final PredictionResult prediction;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'dateTime': dateTime.toIso8601String(),
        'entries': entries.map((e) => e.toJson()).toList(),
        'nutrition': nutrition.toJson(),
        'prediction': prediction.toJson(),
      };

  factory Meal.fromJson(Map<String, dynamic> json) => Meal(
        id: json['id'] as String,
        name: json['name'] as String,
        dateTime: DateTime.parse(json['dateTime'] as String),
        entries: (json['entries'] as List<dynamic>)
            .map((e) => SelectedFoodEntry.fromJson(e as Map<String, dynamic>))
            .toList(),
        nutrition:
            NutritionTotals.fromJson(json['nutrition'] as Map<String, dynamic>),
        prediction: PredictionResult.fromJson(
            json['prediction'] as Map<String, dynamic>),
      );
}
