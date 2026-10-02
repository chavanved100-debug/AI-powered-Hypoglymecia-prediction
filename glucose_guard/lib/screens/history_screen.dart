import 'package:flutter/material.dart';

import '../models/meal.dart';
import '../services/storage_service.dart';
import '../theme/app_theme.dart';
import '../widgets/meal_card.dart';
import 'meal_detail_screen.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key, required this.refreshTrigger});

  final ValueNotifier<int> refreshTrigger;

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final StorageService _storage = StorageService();
  List<Meal> _meals = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    widget.refreshTrigger.addListener(_loadMeals);
    _loadMeals();
  }

  @override
  void dispose() {
    widget.refreshTrigger.removeListener(_loadMeals);
    super.dispose();
  }

  Future<void> _loadMeals() async {
    setState(() => _loading = true);
    final meals = await _storage.getMeals();
    if (mounted) {
      setState(() {
        _meals = meals;
        _loading = false;
      });
    }
  }

  Future<void> _deleteMeal(Meal meal) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete meal'),
        content: Text('Remove "${meal.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await _storage.deleteMeal(meal.id);
      widget.refreshTrigger.value++;
      _loadMeals();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                    child: Text(
                      'History',
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
                    child: Text(
                      'Meals with health context',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                  Expanded(
                    child: _meals.isEmpty
                        ? Center(
                            child: Text(
                              'No saved meals yet',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(color: AppColors.textSecondary),
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: _loadMeals,
                            child: ListView.builder(
                              padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                              itemCount: _meals.length,
                              itemBuilder: (context, index) {
                                final meal = _meals[index];
                                return MealCard(
                                  meal: meal,
                                  onTap: () => Navigator.of(context).push(
                                    MaterialPageRoute<void>(
                                      builder: (_) =>
                                          MealDetailScreen(meal: meal),
                                    ),
                                  ),
                                  onDelete: () => _deleteMeal(meal),
                                );
                              },
                            ),
                          ),
                  ),
                ],
              ),
      ),
    );
  }
}
