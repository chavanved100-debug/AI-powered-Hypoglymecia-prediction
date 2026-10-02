import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/food_item.dart';
import '../models/meal.dart';
import '../models/prediction.dart';
import '../services/notification_service.dart';
import '../services/storage_service.dart';
import '../theme/app_theme.dart';
import '../widgets/clinical_features_card.dart';
import '../widgets/nutrition_card.dart';
import '../widgets/risk_card.dart';

class PredictionScreen extends StatefulWidget {
  const PredictionScreen({
    super.key,
    required this.entries,
    required this.nutrition,
    required this.prediction,
    required this.mealName,
    required this.onMealSaved,
  });

  final List<SelectedFoodEntry> entries;
  final NutritionTotals nutrition;
  final PredictionResult prediction;
  final String mealName;
  final VoidCallback onMealSaved;

  @override
  State<PredictionScreen> createState() => _PredictionScreenState();
}

class _PredictionScreenState extends State<PredictionScreen>
    with SingleTickerProviderStateMixin {
  final StorageService _storage = StorageService();
  late AnimationController _animController;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..forward();
    NotificationService.instance.notifyIfHigherRisk(widget.prediction);
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _saveMeal() async {
    setState(() => _saving = true);
    final meal = Meal(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: widget.mealName,
      dateTime: DateTime.now(),
      entries: widget.entries,
      nutrition: widget.nutrition,
      prediction: widget.prediction,
    );
    await _storage.saveMeal(meal);
    widget.onMealSaved();
    if (!mounted) return;
    setState(() => _saving = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Meal saved successfully!'),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.borderRadius),
        ),
      ),
    );
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final visual = riskVisualFromLevel(widget.prediction.riskLevel);
    final color = AppColors.riskColor(visual);

    return Scaffold(
      appBar: AppBar(title: const Text('Meal Risk Analysis')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Center(
            child: AnimatedBuilder(
              animation: _animController,
              builder: (context, child) {
                return SizedBox(
                  width: 200,
                  height: 200,
                  child: CustomPaint(
                    painter: _RiskRingPainter(
                      progress: _animController.value *
                          widget.prediction.riskScore /
                          100,
                      color: color,
                    ),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '${(widget.prediction.riskScore * _animController.value).round()}%',
                            style: Theme.of(context)
                                .textTheme
                                .headlineLarge
                                ?.copyWith(
                                  color: color,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 40,
                                ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${widget.prediction.riskLevel.label} RISK',
                            style: TextStyle(
                              color: color,
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: Text(
              widget.prediction.demoLabel,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontStyle: FontStyle.italic,
                  ),
            ),
          ),
          const SizedBox(height: 24),
          NutritionCard(
            title: 'Meal',
            carbohydrates: widget.nutrition.carbohydrates,
            calories: widget.nutrition.calories,
            protein: widget.nutrition.protein,
            fiber: widget.nutrition.fiber,
            compact: true,
          ),
          if (widget.prediction.features != null) ...[
            const SizedBox(height: 16),
            ClinicalFeaturesCard(features: widget.prediction.features!),
          ],
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Risk Factors',
                      style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 16),
                  ...widget.prediction.riskFactors.map(
                    (factor) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              factor.name,
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Flexible(
                            child: Text(
                              factor.value,
                              textAlign: TextAlign.end,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(color: AppColors.primary),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            color: AppColors.primary.withValues(alpha: 0.06),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.lightbulb_outline,
                          color: AppColors.primary, size: 22),
                      const SizedBox(width: 8),
                      Text('Recommendation',
                          style: Theme.of(context).textTheme.titleMedium),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    widget.prediction.recommendation,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.riskModerateBg,
              borderRadius: BorderRadius.circular(AppTheme.borderRadius),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.info_outline,
                    size: 20, color: AppColors.riskModerate),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'For educational and demonstration purposes only. '
                    'This tool does not replace professional medical advice.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontSize: 13,
                        ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: _saving ? null : _saveMeal,
            child: _saving
                ? const SizedBox(
                    height: 22,
                    width: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text('Save Meal'),
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Back to Dashboard'),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

class _RiskRingPainter extends CustomPainter {
  _RiskRingPainter({required this.progress, required this.color});

  final double progress;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 12;
    const strokeWidth = 14.0;

    final bgPaint = Paint()
      ..color = color.withValues(alpha: 0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final fgPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, bgPaint);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi * progress,
      false,
      fgPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _RiskRingPainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.color != color;
}
