import 'dart:math' as math;

import '../models/clinical_features.dart';
import '../models/meal.dart';

/// Builds the clinical feature vector from estimated CGM / insulin / meal
/// history. Replace by loading a Dataset CSV through [FeatureService].
class FeatureEstimator {
  const FeatureEstimator();

  ClinicalFeatures estimate({
    required DateTime now,
    List<Meal> priorMeals = const [],
    FeatureOverrides overrides = const FeatureOverrides(),
    FeatureSource source = FeatureSource.estimated,
  }) {
    final meals = [...priorMeals]
      ..sort((a, b) => b.dateTime.compareTo(a.dateTime));

    double carbsSince(Duration window) {
      final start = now.subtract(window);
      return meals
          .where((m) => !m.dateTime.isBefore(start) && !m.dateTime.isAfter(now))
          .fold<double>(0, (sum, m) => sum + m.nutrition.carbohydrates);
    }

    final lastMeal = meals.isEmpty ? null : meals.first;
    final carbsLastMeal = lastMeal?.nutrition.carbohydrates ?? 48;
    final timeSinceLastMeal = lastMeal == null
        ? 210.0
        : now
            .difference(lastMeal.dateTime)
            .inMinutes
            .toDouble()
            .clamp(0, 1440)
            .toDouble();
    final carbsLast2Hours = carbsSince(const Duration(hours: 2));
    final carbsLast4Hours = carbsSince(const Duration(hours: 4));

    final hour = now.hour.toDouble();
    final weekday = now.weekday.toDouble();

    final basalPerHour = 0.85;
    final timeSinceInsulin = overrides.timeSinceLastInsulinMinutes ??
        (timeSinceLastMeal < 150 ? timeSinceLastMeal + 5 : 165);
    final bolus = overrides.bolusInsulinUnits ??
        _estimatedBolus(carbsLastMeal, timeSinceInsulin);

    final insulinTimeline = _insulinProfile(
      basalPerHour: basalPerHour,
      bolusUnits: bolus,
      minutesSinceBolus: timeSinceInsulin,
    );

    final exerciseDuration = overrides.exerciseDurationMinutes ?? 0;
    final exerciseIntensity = overrides.exerciseIntensity ?? 0;
    final timeSinceExercise = overrides.timeSinceExerciseMinutes ?? 480;

    final sleepHours = (overrides.sleepHours ?? 7.2).clamp(0, 14).toDouble();
    final sleepQuality = overrides.sleepQuality ?? 2;
    var sleepCycleType = overrides.sleepCycleType;
    sleepCycleType ??= sleepHours < 6
        ? 1
        : (sleepQuality == 0 ? 2 : 0);
    final sleepCycles = sleepHours / 1.5;
    final timeSinceWake = now.hour >= 6
        ? ((now.hour - 6) * 60 + now.minute).toDouble()
        : 30.0;

    final series = _glucoseSeries(
      now: now,
      carbsLastMeal: carbsLastMeal,
      minutesSinceMeal: timeSinceLastMeal,
      bolus: bolus,
      minutesSinceInsulin: timeSinceInsulin,
      exerciseDuration: exerciseDuration,
      exerciseIntensity: exerciseIntensity,
      minutesSinceExercise: timeSinceExercise,
      sleepHours: sleepHours,
      sleepQuality: sleepQuality,
    );

    if (overrides.currentGlucose != null) {
      final shift = overrides.currentGlucose! - series[0];
      for (var i = 0; i < series.length; i++) {
        series[i] = (series[i] + shift).clamp(40, 400);
      }
    }

    double at(int minutesAgo) => _atMinutes(series, minutesAgo);
    List<double> window(int minutes) => _window(series, minutes);

    final current = at(0);
    final g5 = at(5);
    final g10 = at(10);
    final g15 = at(15);
    final g30 = at(30);
    final g45 = at(45);
    final g60 = at(60);
    final g90 = at(90);
    final g120 = at(120);

    final w15 = window(15);
    final w30 = window(30);
    final w60 = window(60);

    return ClinicalFeatures(
      currentGlucose: _r(current),
      glucose5minAgo: _r(g5),
      glucose10minAgo: _r(g10),
      glucose15minAgo: _r(g15),
      glucose30minAgo: _r(g30),
      glucose45minAgo: _r(g45),
      glucose60minAgo: _r(g60),
      glucose90minAgo: _r(g90),
      glucose120minAgo: _r(g120),
      glucoseChange5min: _r(current - g5),
      glucoseChange10min: _r(current - g10),
      glucoseChange15min: _r(current - g15),
      glucoseChange30min: _r(current - g30),
      glucoseChange60min: _r(current - g60),
      glucoseRateChange15min: _r((current - g15) / 15),
      glucoseRateChange30min: _r((current - g30) / 30),
      glucoseRateChange60min: _r((current - g60) / 60),
      glucoseMean15min: _r(_mean(w15)),
      glucoseMean30min: _r(_mean(w30)),
      glucoseMean60min: _r(_mean(w60)),
      glucoseMin30min: _r(w30.reduce(math.min)),
      glucoseMin60min: _r(w60.reduce(math.min)),
      glucoseMax30min: _r(w30.reduce(math.max)),
      glucoseMax60min: _r(w60.reduce(math.max)),
      glucoseStd30min: _r(_std(w30)),
      glucoseStd60min: _r(_std(w60)),
      insulinLast15min: _r(insulinTimeline.last15),
      insulinLast30min: _r(insulinTimeline.last30),
      insulinLast60min: _r(insulinTimeline.last60),
      insulinLast120min: _r(insulinTimeline.last120),
      totalInsulinLast2Hours: _r(insulinTimeline.last120),
      totalInsulinLast4Hours: _r(insulinTimeline.last240),
      basalInsulinLast30min: _r(basalPerHour * 0.5),
      basalInsulinLast60min: _r(basalPerHour),
      bolusInsulinLast30min: _r(timeSinceInsulin <= 30 ? bolus : 0),
      bolusInsulinLast60min: _r(timeSinceInsulin <= 60 ? bolus : 0),
      timeSinceLastInsulin: _r(timeSinceInsulin),
      carbsLastMeal: _r(carbsLastMeal),
      carbsLast2Hours: _r(carbsLast2Hours),
      carbsLast4Hours: _r(carbsLast4Hours),
      timeSinceLastMeal: _r(timeSinceLastMeal),
      hourOfDay: hour,
      dayOfWeek: weekday,
      exerciseDuration: _r(exerciseDuration),
      exerciseIntensity: _r(exerciseIntensity),
      timeSinceExercise: _r(timeSinceExercise),
      sleepHours: _r(sleepHours),
      sleepQuality: _r(sleepQuality),
      sleepCycles: _r(sleepCycles),
      sleepCycleType: _r(sleepCycleType),
      timeSinceWake: _r(timeSinceWake),
      source: source,
    );
  }

  double _estimatedBolus(double carbs, double minutesSince) {
    if (minutesSince > 240) return 0;
    return (carbs / 12).clamp(0, 12);
  }

  _InsulinWindows _insulinProfile({
    required double basalPerHour,
    required double bolusUnits,
    required double minutesSinceBolus,
  }) {
    double bolusIn(double windowMin) {
      if (minutesSinceBolus < 0) return 0;
      if (minutesSinceBolus > windowMin) return 0;
      return bolusUnits;
    }

    return _InsulinWindows(
      last15: basalPerHour * 0.25 + bolusIn(15),
      last30: basalPerHour * 0.5 + bolusIn(30),
      last60: basalPerHour + bolusIn(60),
      last120: basalPerHour * 2 + bolusIn(120),
      last240: basalPerHour * 4 + bolusIn(240),
    );
  }

  /// 5-minute CGM samples from now (index 0) back to 120 minutes (index 24).
  List<double> _glucoseSeries({
    required DateTime now,
    required double carbsLastMeal,
    required double minutesSinceMeal,
    required double bolus,
    required double minutesSinceInsulin,
    required double exerciseDuration,
    required double exerciseIntensity,
    required double minutesSinceExercise,
    required double sleepHours,
    required double sleepQuality,
  }) {
    final points = <double>[];
    for (var ago = 0; ago <= 120; ago += 5) {
      final minutesFromMeal = minutesSinceMeal - ago;
      final minutesFromInsulin = minutesSinceInsulin - ago;
      final minutesFromExercise = minutesSinceExercise - ago;

      var glucose = 112.0;
      if (sleepHours < 6) glucose += 10;
      if (sleepQuality == 0) glucose += 6;
      glucose += 8 * math.sin((now.hour - ago / 60) / 24 * 2 * math.pi);

      if (minutesFromMeal >= 0 && minutesFromMeal <= 180) {
        final peak = math.exp(-math.pow((minutesFromMeal - 50) / 38, 2));
        glucose += carbsLastMeal * 0.55 * peak;
      }

      if (minutesFromInsulin >= 0 && minutesFromInsulin <= 240) {
        final peak = math.exp(-math.pow((minutesFromInsulin - 70) / 45, 2));
        glucose -= bolus * 18 * peak;
      }

      if (exerciseDuration > 0 &&
          minutesFromExercise >= 0 &&
          minutesFromExercise <= 180) {
        final drop = exerciseDuration *
            (0.4 + exerciseIntensity * 0.35) *
            math.exp(-minutesFromExercise / 90);
        glucose -= drop;
      }

      points.add(glucose.clamp(45, 380));
    }
    return points;
  }

  double _atMinutes(List<double> series, int minutesAgo) {
    final index = (minutesAgo / 5).round().clamp(0, series.length - 1);
    return series[index];
  }

  List<double> _window(List<double> series, int minutes) {
    final count = (minutes / 5).round() + 1;
    return series.take(count.clamp(1, series.length)).toList();
  }

  double _mean(List<double> values) {
    if (values.isEmpty) return 0;
    return values.reduce((a, b) => a + b) / values.length;
  }

  double _std(List<double> values) {
    if (values.length < 2) return 0;
    final mean = _mean(values);
    var sum = 0.0;
    for (final value in values) {
      final d = value - mean;
      sum += d * d;
    }
    return math.sqrt(sum / values.length);
  }

  double _r(double value) => double.parse(value.toStringAsFixed(2));
}

class _InsulinWindows {
  const _InsulinWindows({
    required this.last15,
    required this.last30,
    required this.last60,
    required this.last120,
    required this.last240,
  });

  final double last15;
  final double last30;
  final double last60;
  final double last120;
  final double last240;
}
