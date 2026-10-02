import 'package:flutter/material.dart';

import '../models/clinical_features.dart';
import '../models/food_item.dart';
import '../models/meal.dart';
import '../services/feature_service.dart';
import '../services/nutrition_service.dart';
import '../services/prediction_service.dart';
import '../services/storage_service.dart';
import '../theme/app_theme.dart';
import '../widgets/food_search.dart';
import 'prediction_screen.dart';

class AddMealScreen extends StatefulWidget {
  const AddMealScreen({
    super.key,
    required this.onMealSaved,
    required this.onOpenHealth,
  });

  final VoidCallback onMealSaved;
  final VoidCallback onOpenHealth;

  @override
  State<AddMealScreen> createState() => _AddMealScreenState();
}

class _AddMealScreenState extends State<AddMealScreen> {
  final TextEditingController _searchController = TextEditingController();
  final NutritionService _nutritionService = NutritionService();
  final PredictionService _predictionService = PredictionService();
  final StorageService _storage = StorageService();

  final List<SelectedFoodEntry> _entries = [];
  bool _calculating = false;

  NutritionTotals get _totals => _nutritionService.calculateTotals(_entries);

  Map<String, int> get _quantities => {
        for (final e in _entries) e.food.id: e.quantity,
      };

  void _addFood(FoodItem food, {int quantity = 1}) {
    if (quantity < 1) return;
    setState(() {
      final index = _entries.indexWhere((e) => e.food.id == food.id);
      if (index >= 0) {
        _entries[index] = _entries[index].copyWith(
          quantity: _entries[index].quantity + quantity,
        );
      } else {
        _entries.add(SelectedFoodEntry(food: food, quantity: quantity));
      }
    });
  }

  void _addFoodEntry(SelectedFoodEntry entry) {
    _addFood(entry.food, quantity: entry.quantity);
  }

  void _setQuantity(String foodId, int quantity) {
    if (quantity < 1) {
      _removeFood(foodId);
      return;
    }
    setState(() {
      final index = _entries.indexWhere((e) => e.food.id == foodId);
      if (index >= 0) {
        _entries[index] = _entries[index].copyWith(quantity: quantity);
      }
    });
  }

  void _removeFood(String foodId) {
    setState(() {
      _entries.removeWhere((e) => e.food.id == foodId);
    });
  }

  Future<void> _openFoodPicker() async {
    await showFoodPickerSheet(
      context: context,
      onFoodAdded: _addFoodEntry,
      currentQuantities: _quantities,
    );
  }

  Future<void> _calculateRisk() async {
    if (_entries.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Add at least one food.'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.borderRadius),
          ),
        ),
      );
      return;
    }

    setState(() => _calculating = true);
    final totals = _totals;
    final priorMeals = await _storage.getMeals();
    final savedHealth = await _storage.getHealthContext();
    final features = FeatureService.instance.resolve(
      now: DateTime.now(),
      priorMeals: priorMeals,
      overrides: savedHealth?.overrides ?? const FeatureOverrides(),
    );
    final prediction = _predictionService.predict(
      entries: _entries,
      nutrition: totals,
      features: features,
    );

    if (!mounted) return;
    setState(() => _calculating = false);

    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => PredictionScreen(
          entries: List.unmodifiable(_entries),
          nutrition: totals,
          prediction: prediction,
          mealName: _nutritionService.buildMealName(_entries),
          onMealSaved: widget.onMealSaved,
        ),
      ),
    );

    if (result == true && mounted) {
      setState(() {
        _entries.clear();
        _searchController.clear();
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
                children: [
                  Text('Log meal',
                      style: Theme.of(context).textTheme.headlineMedium),
                  const SizedBox(height: 16),
                  FoodSearch(
                    controller: _searchController,
                    onFoodSelected: (food) => _addFood(food),
                    quantities: _quantities,
                  ),
                  const SizedBox(height: 12),
                  FoodSuggestionChips(
                    onFoodSelected: (food) => _addFood(food),
                    quantities: _quantities,
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      onPressed: _openFoodPicker,
                      icon: const Icon(Icons.search, size: 18),
                      label: const Text('Browse all foods'),
                    ),
                  ),
                  TextButton.icon(
                    onPressed: widget.onOpenHealth,
                    icon: const Icon(Icons.monitor_heart_outlined, size: 18),
                    label: const Text('Uses Health tab for glucose & insulin'),
                  ),
                  if (_entries.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Text(
                          'Selected (${_entries.length})',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const Spacer(),
                        TextButton(
                          onPressed: () => setState(_entries.clear),
                          child: const Text('Clear'),
                        ),
                      ],
                    ),
                    ..._entries.map(
                      (entry) => SelectedFoodTile(
                        key: ValueKey(entry.food.id),
                        entry: entry,
                        onQuantityChanged: (qty) =>
                            _setQuantity(entry.food.id, qty),
                        onRemove: () => _removeFood(entry.food.id),
                      ),
                    ),
                  ] else
                    Padding(
                      padding: const EdgeInsets.only(top: 24),
                      child: Text(
                        'Search or tap a food to start.',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                ],
              ),
            ),
            SafeArea(
              top: false,
              child: Container(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      '${_totals.carbohydrates.round()}g carbs  ·  ${_totals.calories.round()} kcal',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 12),
                    FilledButton(
                      onPressed: _calculating ? null : _calculateRisk,
                      child: _calculating
                          ? const SizedBox(
                              height: 22,
                              width: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text('Calculate risk'),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
