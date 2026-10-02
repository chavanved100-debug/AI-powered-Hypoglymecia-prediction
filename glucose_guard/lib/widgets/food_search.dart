import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/food_database.dart';
import '../models/food_item.dart';
import '../services/dataset_service.dart';
import '../theme/app_theme.dart';

/// Opens a bottom sheet to browse and add foods with a chosen quantity.
Future<void> showFoodPickerSheet({
  required BuildContext context,
  required ValueChanged<SelectedFoodEntry> onFoodAdded,
  required Map<String, int> currentQuantities,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => _FoodPickerSheet(
      onFoodAdded: onFoodAdded,
      currentQuantities: currentQuantities,
    ),
  );
}

class _FoodPickerSheet extends StatefulWidget {
  const _FoodPickerSheet({
    required this.onFoodAdded,
    required this.currentQuantities,
  });

  final ValueChanged<SelectedFoodEntry> onFoodAdded;
  final Map<String, int> currentQuantities;

  @override
  State<_FoodPickerSheet> createState() => _FoodPickerSheetState();
}

class _FoodPickerSheetState extends State<_FoodPickerSheet> {
  final TextEditingController _searchController = TextEditingController();
  int _pickerQuantity = 1;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _addFood(FoodItem food) {
    if (_pickerQuantity < 1) return;
    widget.onFoodAdded(
      SelectedFoodEntry(food: food, quantity: _pickerQuantity),
    );
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Added ${food.name} × $_pickerQuantity',
        ),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 1),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.borderRadius),
        ),
      ),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.5,
      maxChildSize: 0.92,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Add Food',
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Select a food and set quantity',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _searchController,
                      autofocus: true,
                      decoration: const InputDecoration(
                        hintText: 'Search Indian food...',
                        prefixIcon: Icon(Icons.search),
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Text(
                          'Quantity to add:',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const Spacer(),
                        _QuantityStepper(
                          quantity: _pickerQuantity,
                          compact: true,
                          onChanged: (q) =>
                              setState(() => _pickerQuantity = q),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: ValueListenableBuilder<TextEditingValue>(
                  valueListenable: _searchController,
                  builder: (context, value, _) {
                    final results = FoodDatabase.search(value.text);
                    if (results.isEmpty) {
                      return Center(
                        child: Text(
                          'No foods found',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      );
                    }
                    return ListView.separated(
                      controller: scrollController,
                      padding: const EdgeInsets.fromLTRB(12, 0, 12, 24),
                      itemCount: results.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 4),
                      itemBuilder: (context, index) {
                        final food = results[index];
                        final inMeal = widget.currentQuantities[food.id] ?? 0;
                        return ListTile(
                          shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(AppTheme.borderRadius),
                          ),
                          tileColor: AppColors.background,
                          title: Text(
                            food.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: Text(
                            '${food.servingSize} · '
                            '${food.carbohydrates.round()}g carbs',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (inMeal > 0)
                                Container(
                                  margin: const EdgeInsets.only(right: 8),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary
                                        .withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    'In meal: $inMeal',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              const Icon(Icons.add_circle,
                                  color: AppColors.primary),
                            ],
                          ),
                          onTap: () => _addFood(food),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class FoodSearch extends StatelessWidget {
  const FoodSearch({
    super.key,
    required this.controller,
    required this.onFoodSelected,
    required this.quantities,
  });

  final TextEditingController controller;
  final ValueChanged<FoodItem> onFoodSelected;
  final Map<String, int> quantities;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: controller,
      builder: (context, value, _) {
        final results = FoodDatabase.search(value.text);
        final showResults = value.text.isNotEmpty;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: controller,
              decoration: InputDecoration(
                hintText: 'Search Indian food...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: value.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: controller.clear,
                      )
                    : null,
              ),
            ),
            if (showResults) ...[
              const SizedBox(height: 8),
              Material(
                elevation: 2,
                borderRadius: BorderRadius.circular(AppTheme.borderRadius),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 220),
                  child: results.isEmpty
                      ? Padding(
                          padding: const EdgeInsets.all(20),
                          child: Text(
                            'No matching foods',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        )
                      : ListView.separated(
                          shrinkWrap: true,
                          itemCount: results.length,
                          separatorBuilder: (_, _) =>
                              const Divider(height: 1),
                          itemBuilder: (context, index) {
                            final food = results[index];
                            final qty = quantities[food.id] ?? 0;
                            return ListTile(
                              title: Text(
                                food.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              subtitle: Text(
                                '${food.servingSize} · '
                                '${food.carbohydrates.round()}g carbs',
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              trailing: qty > 0
                                  ? Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppColors.primary
                                            .withValues(alpha: 0.12),
                                        borderRadius:
                                            BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        '× $qty',
                                        style: const TextStyle(
                                          color: AppColors.primary,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    )
                                  : const Icon(Icons.add_circle_outline),
                              onTap: () {
                                onFoodSelected(food);
                                controller.clear();
                                FocusScope.of(context).unfocus();
                              },
                            );
                          },
                        ),
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}

class FoodSuggestionChips extends StatelessWidget {
  const FoodSuggestionChips({
    super.key,
    required this.onFoodSelected,
    required this.quantities,
  });

  final ValueChanged<FoodItem> onFoodSelected;
  final Map<String, int> quantities;

  @override
  Widget build(BuildContext context) {
    final suggestions = FoodDatabase.foods.take(6).toList();
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: suggestions.map((food) {
        final qty = quantities[food.id] ?? 0;
        return FilterChip(
          label: Text(
            qty > 0 ? '${food.name} ($qty)' : food.name,
          ),
          selected: qty > 0,
          showCheckmark: false,
          avatar: Icon(
            qty > 0 ? Icons.check_circle : Icons.restaurant,
            size: 18,
            color: qty > 0 ? AppColors.primary : AppColors.textSecondary,
          ),
          onSelected: (_) => onFoodSelected(food),
        );
      }).toList(),
    );
  }
}

class SelectedFoodTile extends StatefulWidget {
  const SelectedFoodTile({
    super.key,
    required this.entry,
    required this.onQuantityChanged,
    required this.onRemove,
  });

  final SelectedFoodEntry entry;
  final ValueChanged<int> onQuantityChanged;
  final VoidCallback onRemove;

  @override
  State<SelectedFoodTile> createState() => _SelectedFoodTileState();
}

class _SelectedFoodTileState extends State<SelectedFoodTile> {
  late TextEditingController _qtyController;
  bool _editing = false;

  @override
  void initState() {
    super.initState();
    _qtyController = TextEditingController(
      text: '${widget.entry.quantity}',
    );
  }

  @override
  void didUpdateWidget(covariant SelectedFoodTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_editing &&
        oldWidget.entry.quantity != widget.entry.quantity) {
      _qtyController.text = '${widget.entry.quantity}';
    }
  }

  @override
  void dispose() {
    _qtyController.dispose();
    super.dispose();
  }

  void _commitQuantity() {
    final parsed = int.tryParse(_qtyController.text.trim());
    if (parsed == null || parsed < 1) {
      _qtyController.text = '${widget.entry.quantity}';
      setState(() => _editing = false);
      return;
    }
    if (parsed > 99) {
      _qtyController.text = '99';
      widget.onQuantityChanged(99);
    } else {
      widget.onQuantityChanged(parsed);
    }
    setState(() => _editing = false);
    FocusScope.of(context).unfocus();
  }

  @override
  Widget build(BuildContext context) {
    final multiplier = DatasetService.instance.multiplierFor(
      widget.entry.food,
      widget.entry.quantity,
    );
    final subtotalCarbs = widget.entry.food.carbohydrates * multiplier;

    return Dismissible(
      key: ValueKey(widget.entry.food.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => widget.onRemove(),
      background: Container(
        margin: const EdgeInsets.only(bottom: 10),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        decoration: BoxDecoration(
          color: AppColors.riskHigh,
          borderRadius: BorderRadius.circular(AppTheme.borderRadius),
        ),
        child: const Icon(Icons.delete_outline, color: Colors.white),
      ),
      confirmDismiss: (_) async {
        return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Remove food?'),
            content: Text(
              'Remove ${widget.entry.food.name} from this meal?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Remove'),
              ),
            ],
          ),
        );
      },
      child: Card(
        margin: const EdgeInsets.only(bottom: 10),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.entry.food.name,
                          style: Theme.of(context).textTheme.titleMedium,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          widget.entry.food.servingSize,
                          style: Theme.of(context).textTheme.bodyMedium,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${subtotalCarbs.round()}g carbs total',
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w500,
                              ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Remove',
                    onPressed: widget.onRemove,
                    icon: const Icon(
                      Icons.close,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Text(
                    'Quantity',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const Spacer(),
                  _QuantityStepper(
                    quantity: widget.entry.quantity,
                    controller: _qtyController,
                    editing: _editing,
                    onEditingChanged: (v) => setState(() => _editing = v),
                    onCommit: _commitQuantity,
                    onChanged: widget.onQuantityChanged,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuantityStepper extends StatelessWidget {
  const _QuantityStepper({
    required this.quantity,
    required this.onChanged,
    this.controller,
    this.editing = false,
    this.onEditingChanged,
    this.onCommit,
    this.compact = false,
  });

  final int quantity;
  final ValueChanged<int> onChanged;
  final TextEditingController? controller;
  final bool editing;
  final ValueChanged<bool>? onEditingChanged;
  final VoidCallback? onCommit;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _StepperButton(
            icon: Icons.remove,
            onPressed: quantity > 1
                ? () => onChanged(quantity - 1)
                : null,
          ),
          GestureDetector(
            onTap: controller != null
                ? () => onEditingChanged?.call(true)
                : null,
            child: Container(
              width: compact ? 44 : 52,
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: editing && controller != null
                  ? TextField(
                      controller: controller,
                      autofocus: true,
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(2),
                      ],
                      style: Theme.of(context).textTheme.titleLarge,
                      decoration: const InputDecoration(
                        isDense: true,
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.zero,
                      ),
                      onSubmitted: (_) => onCommit?.call(),
                      onEditingComplete: onCommit,
                    )
                  : Text(
                      '$quantity',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
            ),
          ),
          _StepperButton(
            icon: Icons.add,
            onPressed: quantity < 99
                ? () => onChanged(quantity + 1)
                : null,
          ),
        ],
      ),
    );
  }
}

class _StepperButton extends StatelessWidget {
  const _StepperButton({required this.icon, required this.onPressed});

  final IconData icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Icon(
            icon,
            size: 20,
            color: onPressed != null
                ? AppColors.primary
                : Colors.grey.shade400,
          ),
        ),
      ),
    );
  }
}
