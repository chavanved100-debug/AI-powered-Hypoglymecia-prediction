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

    // Insulin is only ever the value the user typed. Nothing is inferred, so a
    // blank field means "no insulin logged" rather than a guessed dose.
    final userBolus = overrides.bolusInsulinUnits ?? 0;
    final userInsulinTime = overrides.timeSinceLastInsulinMinutes;
    final hasInsulin = userBolus > 0;
    final bolus = hasInsulin ? userBolus : 0.0;
    final timeSinceInsulin = hasInsulin
        ? (userInsulinTime ?? 0).clamp(0, 1440).toDouble()
        : 0.0;

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

    final hasUserGlucose = overrides.currentGlucose != null;

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
      // Cumulative insulin straight from the user's logged dose. A dose counts
      // toward every window that still contains it, and nothing is counted if
      // the user did not log insulin.
      totalInsulinLast2Hours: bolus > 0 && timeSinceInsulin <= 120 ? bolus : 0,
      totalInsulinLast4Hours: bolus > 0 && timeSinceInsulin <= 240 ? bolus : 0,
      timeSinceLastInsulin: _r(timeSinceInsulin),
      bolusInsulinUnits: bolus,
      glucoseFromUser: hasUserGlucose,
      insulinFromUser: hasInsulin,
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
