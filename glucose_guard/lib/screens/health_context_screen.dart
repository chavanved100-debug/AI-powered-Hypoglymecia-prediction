import 'package:flutter/material.dart';

import '../models/clinical_features.dart';
import '../services/feature_service.dart';
import '../services/storage_service.dart';
import '../theme/app_theme.dart';
import '../widgets/health_context_form.dart';

class HealthContextScreen extends StatefulWidget {
  const HealthContextScreen({super.key, required this.refreshTrigger});

  final ValueNotifier<int> refreshTrigger;

  @override
  State<HealthContextScreen> createState() => _HealthContextScreenState();
}

class _HealthContextScreenState extends State<HealthContextScreen> {
  final StorageService _storage = StorageService();
  final _glucoseController = TextEditingController();
  final _insulinController = TextEditingController();
  final _insulinMinutesController = TextEditingController();
  final _exerciseDurationController = TextEditingController();
  final _exerciseMinutesController = TextEditingController();
  final _sleepHoursController = TextEditingController();

  ClinicalFeatures? _snapshot;
  double _exerciseIntensity = 0;
  double _sleepQuality = 2;
  double _sleepCycleType = 0;
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    widget.refreshTrigger.addListener(_load);
    _load();
  }

  @override
  void dispose() {
    widget.refreshTrigger.removeListener(_load);
    _glucoseController.dispose();
    _insulinController.dispose();
    _insulinMinutesController.dispose();
    _exerciseDurationController.dispose();
    _exerciseMinutesController.dispose();
    _sleepHoursController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final saved = await _storage.getHealthContext();
    final meals = await _storage.getMeals();
    final snapshot = saved?.snapshot ??
        FeatureService.instance.resolve(
          now: DateTime.now(),
          priorMeals: meals,
        );
    if (!mounted) return;
    final overrides = saved?.overrides ?? const FeatureOverrides();
    setState(() {
      _snapshot = snapshot;
      _fill(overrides);
      _loading = false;
    });
  }

  void _fill(FeatureOverrides overrides) {
    _glucoseController.text = _fmt(overrides.currentGlucose);
    _insulinController.text = _fmt(overrides.bolusInsulinUnits);
    _insulinMinutesController.text =
        _fmt(overrides.timeSinceLastInsulinMinutes);
    _exerciseDurationController.text = _fmt(overrides.exerciseDurationMinutes);
    _exerciseMinutesController.text = _fmt(overrides.timeSinceExerciseMinutes);
    _exerciseIntensity = overrides.exerciseIntensity ?? 0;
    _sleepHoursController.text = _fmt(overrides.sleepHours);
    _sleepQuality = overrides.sleepQuality ?? 2;
    _sleepCycleType = overrides.sleepCycleType ?? 0;
  }

  String _fmt(double? value) =>
      value == null ? '' : value.toString().replaceAll(RegExp(r'\.0$'), '');

  FeatureOverrides _overrides() {
    final hasExercise = _exerciseIntensity > 0 ||
        _exerciseDurationController.text.trim().isNotEmpty ||
        _exerciseMinutesController.text.trim().isNotEmpty;
    return FeatureOverrides(
      currentGlucose: double.tryParse(_glucoseController.text.trim()),
      bolusInsulinUnits: double.tryParse(_insulinController.text.trim()),
      timeSinceLastInsulinMinutes:
          double.tryParse(_insulinMinutesController.text.trim()),
      exerciseDurationMinutes:
          double.tryParse(_exerciseDurationController.text.trim()),
      exerciseIntensity: hasExercise ? _exerciseIntensity : null,
      timeSinceExerciseMinutes:
          double.tryParse(_exerciseMinutesController.text.trim()),
      sleepHours: double.tryParse(_sleepHoursController.text.trim()),
      sleepQuality: _sleepQuality,
      sleepCycleType: _sleepCycleType,
    );
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final meals = await _storage.getMeals();
    final overrides = _overrides();
    final snapshot = FeatureService.instance.resolve(
      now: DateTime.now(),
      priorMeals: meals,
      overrides: overrides,
    );
    await _storage.saveHealthContext(
      SavedHealthContext(
        overrides: overrides,
        snapshot: snapshot,
        updatedAt: DateTime.now(),
      ),
    );
    widget.refreshTrigger.value++;
    if (!mounted) return;
    setState(() {
      _snapshot = snapshot;
      _saving = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Health context saved')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final snapshot = _snapshot;
    return Scaffold(
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
                children: [
                  Text(
                    'Health context',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Used for every meal risk estimate',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                  ),
                  const SizedBox(height: 20),
                  if (snapshot != null) _GlucoseHero(features: snapshot),
                  const SizedBox(height: 20),
                  HealthContextForm(
                    glucoseController: _glucoseController,
                    insulinController: _insulinController,
                    insulinMinutesController: _insulinMinutesController,
                    exerciseDurationController: _exerciseDurationController,
                    exerciseMinutesController: _exerciseMinutesController,
                    exerciseIntensity: _exerciseIntensity,
                    onIntensityChanged: (value) =>
                        setState(() => _exerciseIntensity = value),
                    sleepHoursController: _sleepHoursController,
                    sleepQuality: _sleepQuality,
                    onSleepQualityChanged: (value) =>
                        setState(() => _sleepQuality = value),
                    sleepCycleType: _sleepCycleType,
                    onSleepCycleChanged: (value) =>
                        setState(() => _sleepCycleType = value),
                  ),
                  const SizedBox(height: 20),
                  FilledButton(
                    onPressed: _saving ? null : _save,
                    child: _saving
                        ? const SizedBox(
                            height: 22,
                            width: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text('Save health context'),
                  ),
                ],
              ),
      ),
    );
  }
}

class _GlucoseHero extends StatelessWidget {
  const _GlucoseHero({required this.features});

  final ClinicalFeatures features;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(AppTheme.borderRadius),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Now',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${features.currentGlucose.round()}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 40,
                    fontWeight: FontWeight.bold,
                    height: 1.1,
                  ),
                ),
                const Text(
                  'mg/dL',
                  style: TextStyle(color: Colors.white, fontSize: 14),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                features.trendLabel,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${features.totalInsulinLast2Hours.toStringAsFixed(1)} U · 2h',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.85),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
