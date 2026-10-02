import 'package:flutter/material.dart';

import '../models/clinical_features.dart';
import '../models/meal.dart';
import '../services/feature_service.dart';
import '../services/storage_service.dart';
import '../theme/app_theme.dart';
import '../widgets/meal_card.dart';
import '../widgets/risk_card.dart';
import 'meal_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    required this.onNavigateToAddMeal,
    required this.onNavigateToHealth,
    required this.onNavigateToHistory,
    required this.onNavigateToProfile,
    required this.refreshTrigger,
  });

  final VoidCallback onNavigateToAddMeal;
  final VoidCallback onNavigateToHealth;
  final VoidCallback onNavigateToHistory;
  final VoidCallback onNavigateToProfile;
  final ValueNotifier<int> refreshTrigger;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final StorageService _storage = StorageService();
  List<Meal> _meals = [];
  SavedHealthContext? _health;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    widget.refreshTrigger.addListener(_load);
    _load();
  }

  @override
  void dispose() {
    widget.refreshTrigger.removeListener(_load);
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final meals = await _storage.getMeals();
    final health = await _storage.getHealthContext();
    final snapshot = health?.snapshot ??
        FeatureService.instance.resolve(
          now: DateTime.now(),
          priorMeals: meals,
          overrides: health?.overrides ?? const FeatureOverrides(),
        );
    if (mounted) {
      setState(() {
        _meals = meals;
        _health = health ??
            SavedHealthContext(
              overrides: const FeatureOverrides(),
              snapshot: snapshot,
              updatedAt: DateTime.now(),
            );
        _loading = false;
      });
    }
  }

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context) {
    final todayMeals = _meals.where((m) {
      final now = DateTime.now();
      return m.dateTime.year == now.year &&
          m.dateTime.month == now.month &&
          m.dateTime.day == now.day;
    }).toList();

    final todayRisk = todayMeals.isEmpty
        ? null
        : todayMeals
            .map((m) => m.prediction.riskScore)
            .reduce((a, b) => a > b ? a : b);

    final todayRiskLevel = todayMeals.isEmpty
        ? null
        : todayMeals
            .map((m) => m.prediction.riskLevel)
            .reduce((a, b) => a.index > b.index ? a : b);

    final glucose = _health?.snapshot.currentGlucose;

    return Scaffold(
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: _load,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _greeting(),
                                style: Theme.of(context)
                                    .textTheme
                                    .headlineMedium,
                              ),
                              Text(
                                'Gluco Guide AI',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyLarge
                                    ?.copyWith(color: AppColors.textSecondary),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          tooltip: 'Profile',
                          onPressed: widget.onNavigateToProfile,
                          icon: const Icon(Icons.person_outline),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    _QuickActions(
                      onMeal: widget.onNavigateToAddMeal,
                      onHealth: widget.onNavigateToHealth,
                    ),
                    const SizedBox(height: 16),
                    _StatusRow(
                      glucose: glucose,
                      onHealth: widget.onNavigateToHealth,
                    ),
                    const SizedBox(height: 16),
                    if (todayRisk != null && todayRiskLevel != null)
                      RiskCard(
                        riskScore: todayRisk,
                        riskLevel: todayRiskLevel,
                      )
                    else
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Text(
                            'Log a meal to see today’s risk.',
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                        ),
                      ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Text('Recent',
                            style: Theme.of(context).textTheme.titleLarge),
                        const Spacer(),
                        TextButton(
                          onPressed: widget.onNavigateToHistory,
                          child: const Text('All'),
                        ),
                      ],
                    ),
                    if (_meals.isEmpty)
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Text(
                            'No meals yet.',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ),
                      )
                    else
                      ..._meals.take(2).map(
                            (meal) => MealCard(
                              meal: meal,
                              onTap: () => Navigator.of(context).push(
                                MaterialPageRoute<void>(
                                  builder: (_) => MealDetailScreen(meal: meal),
                                ),
                              ),
                            ),
                          ),
                  ],
                ),
              ),
      ),
    );
  }
}

class _QuickActions extends StatelessWidget {
  const _QuickActions({required this.onMeal, required this.onHealth});

  final VoidCallback onMeal;
  final VoidCallback onHealth;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: FilledButton.icon(
            onPressed: onMeal,
            icon: const Icon(Icons.add),
            label: const Text('Log meal'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: onHealth,
            icon: const Icon(Icons.monitor_heart_outlined),
            label: const Text('Health'),
          ),
        ),
      ],
    );
  }
}

class _StatusRow extends StatelessWidget {
  const _StatusRow({required this.glucose, required this.onHealth});

  final double? glucose;
  final VoidCallback onHealth;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onHealth,
      borderRadius: BorderRadius.circular(AppTheme.borderRadius),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Row(
            children: [
              const Icon(Icons.monitor_heart_outlined,
                  color: AppColors.primary),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  glucose == null
                      ? 'Add health context'
                      : '${glucose!.round()} mg/dL',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              const Icon(Icons.chevron_right, color: AppColors.textSecondary),
            ],
          ),
        ),
      ),
    );
  }
}
