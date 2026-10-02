import '../models/food_item.dart';
import '../services/dataset_service.dart';

/// Foods loaded from Dataset CSV files (Food_Nutrition_Dataset and any extra
/// nutrition CSVs discovered in the folder).
class FoodDatabase {
  FoodDatabase._();

  static List<FoodItem> get foods => DatasetService.instance.foods;

  static List<FoodItem> search(String query) =>
      DatasetService.instance.searchFoods(query);

  static FoodItem? findById(String id) =>
      DatasetService.instance.findFoodById(id);
}
