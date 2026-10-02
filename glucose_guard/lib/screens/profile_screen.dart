import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/meal.dart';
import '../services/auth_service.dart';
import '../services/storage_service.dart';
import '../theme/app_theme.dart';
import 'auth_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key, required this.refreshTrigger});

  final ValueNotifier<int> refreshTrigger;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final StorageService _storage = StorageService();
  final TextEditingController _goalController = TextEditingController();
  double _carbGoal = 180;
  NutritionTotals _todayTotals = const NutritionTotals();
  String _userName = 'User';
  String _userEmail = '';
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    widget.refreshTrigger.addListener(_loadData);
    _loadData();
  }

  @override
  void dispose() {
    widget.refreshTrigger.removeListener(_loadData);
    _goalController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    final goal = await _storage.getCarbGoal();
    final meals = await _storage.getMeals();
    final user = await AuthService.instance.currentUser();
    final now = DateTime.now();
    final todayMeals = meals.where((m) {
      return m.dateTime.year == now.year &&
          m.dateTime.month == now.month &&
          m.dateTime.day == now.day;
    });
    final totals = todayMeals.fold(
      const NutritionTotals(),
      (prev, m) => prev + m.nutrition,
    );
    if (mounted) {
      setState(() {
        _carbGoal = goal;
        _goalController.text = goal.round().toString();
        _todayTotals = totals;
        _userName = user?.name ?? 'User';
        _userEmail = user?.email ?? '';
        _loading = false;
      });
    }
  }

  Future<void> _saveGoal() async {
    final value = double.tryParse(_goalController.text);
    if (value == null || value <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid carb goal')),
      );
      return;
    }
    await _storage.setCarbGoal(value);
    setState(() => _carbGoal = value);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Carb goal updated')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final progress = _carbGoal > 0
        ? (_todayTotals.carbohydrates / _carbGoal).clamp(0.0, 1.0)
        : 0.0;

    return Scaffold(
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  Text('Profile',
                      style: Theme.of(context).textTheme.headlineMedium),
                  const SizedBox(height: 24),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 32,
                            backgroundColor:
                                AppColors.primary.withValues(alpha: 0.12),
                            child: const Icon(Icons.person,
                                size: 36, color: AppColors.primary),
                          ),
                          const SizedBox(width: 16),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(_userName,
                                  style:
                                      Theme.of(context).textTheme.titleLarge),
                              Text(
                                _userEmail.isEmpty
                                    ? 'T1D Diet Tracker'
                                    : _userEmail,
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Daily Nutrition Summary',
                              style: Theme.of(context).textTheme.titleLarge),
                          const SizedBox(height: 16),
                          _SummaryRow(
                            label: 'Carbohydrates',
                            value:
                                '${_todayTotals.carbohydrates.round()} / ${_carbGoal.round()} g',
                          ),
                          const SizedBox(height: 12),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: LinearProgressIndicator(
                              value: progress,
                              minHeight: 8,
                              backgroundColor: Colors.grey.shade200,
                              color: progress > 0.9
                                  ? AppColors.riskHigh
                                  : AppColors.primary,
                            ),
                          ),
                          const SizedBox(height: 16),
                          _SummaryRow(
                            label: 'Calories',
                            value: '${_todayTotals.calories.round()} kcal',
                          ),
                          const SizedBox(height: 8),
                          _SummaryRow(
                            label: 'Protein',
                            value: '${_todayTotals.protein.round()} g',
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Carbohydrate Goal',
                              style: Theme.of(context).textTheme.titleLarge),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _goalController,
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                            decoration: const InputDecoration(
                              suffixText: 'g/day',
                              labelText: 'Daily carb goal',
                            ),
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton(
                              onPressed: _saveGoal,
                              child: const Text('Save Goal'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Card(
                    child: Column(
                      children: [
                        ListTile(
                          leading: const Icon(Icons.straighten),
                          title: const Text('Units'),
                          subtitle: const Text('Grams (g), Kilocalories (kcal)'),
                        ),
                        const Divider(height: 1),
                        ListTile(
                          leading: const Icon(Icons.info_outline),
                          title: const Text('About'),
                          subtitle: const Text(
                            'Gluco Guide AI — meal risk with health context '
                            'for Indian T1D diets. Demo only.',
                          ),
                        ),
                        const Divider(height: 1),
                        ListTile(
                          leading: const Icon(Icons.warning_amber_outlined),
                          title: const Text('Disclaimer'),
                          subtitle: const Text(
                            'For educational and demonstration purposes only. '
                            'This tool does not replace professional medical advice.',
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  OutlinedButton(
                    onPressed: () async {
                      await AuthService.instance.logout();
                      if (!context.mounted) return;
                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute<void>(
                          builder: (_) => const AuthScreen(),
                        ),
                        (_) => false,
                      );
                    },
                    child: const Text('Log out'),
                  ),
                  const SizedBox(height: 80),
                ],
              ),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: Theme.of(context).textTheme.bodyMedium),
        Text(value, style: Theme.of(context).textTheme.titleMedium),
      ],
    );
  }
}
