class FoodItem {
  const FoodItem({
    required this.id,
    required this.name,
    required this.servingSize,
    required this.weightGrams,
    required this.carbohydrates,
    required this.protein,
    required this.fat,
    required this.fiber,
    required this.calories,
    required this.glycemicIndex,
    this.glycemicLabel = 'Medium',
  });

  final String id;
  final String name;
  final String servingSize;
  final double weightGrams;
  final double carbohydrates;
  final double protein;
  final double fat;
  final double fiber;
  final double calories;
  final int glycemicIndex;
  final String glycemicLabel;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'servingSize': servingSize,
        'weightGrams': weightGrams,
        'carbohydrates': carbohydrates,
        'protein': protein,
        'fat': fat,
        'fiber': fiber,
        'calories': calories,
        'glycemicIndex': glycemicIndex,
        'glycemicLabel': glycemicLabel,
      };

  factory FoodItem.fromJson(Map<String, dynamic> json) => FoodItem(
        id: json['id'] as String,
        name: json['name'] as String,
        servingSize: json['servingSize'] as String,
        weightGrams: (json['weightGrams'] as num).toDouble(),
        carbohydrates: (json['carbohydrates'] as num).toDouble(),
        protein: (json['protein'] as num).toDouble(),
        fat: (json['fat'] as num).toDouble(),
        fiber: (json['fiber'] as num).toDouble(),
        calories: (json['calories'] as num).toDouble(),
        glycemicIndex: json['glycemicIndex'] as int,
        glycemicLabel: json['glycemicLabel'] as String? ??
            glycemicLabelFromIndex(json['glycemicIndex'] as int),
      );
}

String glycemicLabelFromIndex(int gi) {
  if (gi <= 40) return 'Low';
  if (gi <= 62) return 'Medium';
  return 'High';
}

int glycemicIndexFromLabel(String label) {
  switch (label.trim().toLowerCase()) {
    case 'low':
      return 35;
    case 'medium':
      return 55;
    case 'high':
      return 70;
    default:
      return int.tryParse(label.trim()) ?? 50;
  }
}

class SelectedFoodEntry {
  const SelectedFoodEntry({
    required this.food,
    required this.quantity,
  });

  final FoodItem food;
  final int quantity;

  SelectedFoodEntry copyWith({FoodItem? food, int? quantity}) =>
      SelectedFoodEntry(
        food: food ?? this.food,
        quantity: quantity ?? this.quantity,
      );

  Map<String, dynamic> toJson() => {
        'food': food.toJson(),
        'quantity': quantity,
      };

  factory SelectedFoodEntry.fromJson(Map<String, dynamic> json) =>
      SelectedFoodEntry(
        food: FoodItem.fromJson(json['food'] as Map<String, dynamic>),
        quantity: json['quantity'] as int,
      );
}
