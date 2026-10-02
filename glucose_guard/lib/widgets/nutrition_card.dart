import 'package:flutter/material.dart';

class NutritionCard extends StatelessWidget {
  const NutritionCard({
    super.key,
    required this.carbohydrates,
    required this.calories,
    required this.protein,
    this.fiber,
    this.title = "Today's Nutrition",
    this.compact = false,
  });

  final String title;
  final double carbohydrates;
  final double calories;
  final double protein;
  final double? fiber;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(compact ? 16 : 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleLarge),
            SizedBox(height: compact ? 12 : 16),
            if (compact)
              Row(
                children: [
                  Expanded(
                    child: _NutritionItem(
                      label: 'Carbs',
                      value: '${carbohydrates.round()} g',
                    ),
                  ),
                  Expanded(
                    child: _NutritionItem(
                      label: 'Calories',
                      value: '${calories.round()} kcal',
                    ),
                  ),
                  Expanded(
                    child: _NutritionItem(
                      label: 'Protein',
                      value: '${protein.round()} g',
                    ),
                  ),
                ],
              )
            else ...[
              _NutritionRow(
                label: 'Carbohydrates',
                value: '${carbohydrates.round()} g',
              ),
              const SizedBox(height: 12),
              _NutritionRow(
                label: 'Calories',
                value: '${calories.round()} kcal',
              ),
              const SizedBox(height: 12),
              _NutritionRow(
                label: 'Protein',
                value: '${protein.round()} g',
              ),
              if (fiber != null) ...[
                const SizedBox(height: 12),
                _NutritionRow(
                  label: 'Fiber',
                  value: '${fiber!.round()} g',
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }
}

class _NutritionRow extends StatelessWidget {
  const _NutritionRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 8),
        Text(value, style: Theme.of(context).textTheme.titleMedium),
      ],
    );
  }
}

class _NutritionItem extends StatelessWidget {
  const _NutritionItem({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.bodyMedium),
        const SizedBox(height: 4),
        Text(value, style: Theme.of(context).textTheme.titleMedium),
      ],
    );
  }
}
