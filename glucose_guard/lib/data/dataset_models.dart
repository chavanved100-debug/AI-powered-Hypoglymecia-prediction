class QuantityMapping {
  const QuantityMapping({
    required this.id,
    required this.text,
    required this.value,
    required this.unit,
    required this.multiplier,
  });

  final String id;
  final String text;
  final double value;
  final String unit;
  final double multiplier;
}

class ReferenceMeal {
  const ReferenceMeal({
    required this.id,
    required this.name,
    required this.foodItems,
    required this.carbohydrates,
    required this.protein,
    required this.fat,
    required this.fiber,
    required this.calories,
    required this.glycemicLoad,
  });

  final String id;
  final String name;
  final String foodItems;
  final double carbohydrates;
  final double protein;
  final double fat;
  final double fiber;
  final double calories;
  final String glycemicLoad;

  int get glycemicLoadScore {
    switch (glycemicLoad.toLowerCase()) {
      case 'low':
        return 22;
      case 'high':
        return 88;
      default:
        return 55;
    }
  }
}
