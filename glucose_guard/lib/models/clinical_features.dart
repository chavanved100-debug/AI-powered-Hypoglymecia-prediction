/// Clinical / CGM features used for risk. Names match a future CSV header row.
class ClinicalFeatures {
  const ClinicalFeatures({
    required this.currentGlucose,
    required this.glucose5minAgo,
    required this.glucose10minAgo,
    required this.glucose15minAgo,
    required this.glucose30minAgo,
    required this.glucose45minAgo,
    required this.glucose60minAgo,
    required this.glucose90minAgo,
    required this.glucose120minAgo,
    required this.glucoseChange5min,
    required this.glucoseChange10min,
    required this.glucoseChange15min,
    required this.glucoseChange30min,
    required this.glucoseChange60min,
    required this.glucoseRateChange15min,
    required this.glucoseRateChange30min,
    required this.glucoseRateChange60min,
    required this.glucoseMean15min,
    required this.glucoseMean30min,
    required this.glucoseMean60min,
    required this.glucoseMin30min,
    required this.glucoseMin60min,
    required this.glucoseMax30min,
    required this.glucoseMax60min,
    required this.glucoseStd30min,
    required this.glucoseStd60min,
    required this.insulinLast15min,
    required this.insulinLast30min,
    required this.insulinLast60min,
    required this.insulinLast120min,
    required this.totalInsulinLast2Hours,
    required this.totalInsulinLast4Hours,
    required this.basalInsulinLast30min,
    required this.basalInsulinLast60min,
    required this.bolusInsulinLast30min,
    required this.bolusInsulinLast60min,
    required this.timeSinceLastInsulin,
    required this.carbsLastMeal,
    required this.carbsLast2Hours,
    required this.carbsLast4Hours,
    required this.timeSinceLastMeal,
    required this.hourOfDay,
    required this.dayOfWeek,
    required this.exerciseDuration,
    required this.exerciseIntensity,
    required this.timeSinceExercise,
    this.sleepHours = 7.2,
    this.sleepQuality = 2,
    this.sleepCycles = 4.8,
    this.sleepCycleType = 0,
    this.timeSinceWake = 180,
    this.source = FeatureSource.estimated,
  });

  final double currentGlucose;
  final double glucose5minAgo;
  final double glucose10minAgo;
  final double glucose15minAgo;
  final double glucose30minAgo;
  final double glucose45minAgo;
  final double glucose60minAgo;
  final double glucose90minAgo;
  final double glucose120minAgo;

  final double glucoseChange5min;
  final double glucoseChange10min;
  final double glucoseChange15min;
  final double glucoseChange30min;
  final double glucoseChange60min;

  final double glucoseRateChange15min;
  final double glucoseRateChange30min;
  final double glucoseRateChange60min;

  final double glucoseMean15min;
  final double glucoseMean30min;
  final double glucoseMean60min;

  final double glucoseMin30min;
  final double glucoseMin60min;
  final double glucoseMax30min;
  final double glucoseMax60min;

  final double glucoseStd30min;
  final double glucoseStd60min;

  final double insulinLast15min;
  final double insulinLast30min;
  final double insulinLast60min;
  final double insulinLast120min;

  final double totalInsulinLast2Hours;
  final double totalInsulinLast4Hours;

  final double basalInsulinLast30min;
  final double basalInsulinLast60min;

  final double bolusInsulinLast30min;
  final double bolusInsulinLast60min;

  final double timeSinceLastInsulin;

  final double carbsLastMeal;
  final double carbsLast2Hours;
  final double carbsLast4Hours;

  final double timeSinceLastMeal;

  final double hourOfDay;
  final double dayOfWeek;

  final double exerciseDuration;
  final double exerciseIntensity;
  final double timeSinceExercise;
  final double sleepHours;
  final double sleepQuality;
  final double sleepCycles;
  final double sleepCycleType;
  final double timeSinceWake;

  final FeatureSource source;

  static const csvHeaders = [
    'Current_Glucose',
    'Glucose_5min_ago',
    'Glucose_10min_ago',
    'Glucose_15min_ago',
    'Glucose_30min_ago',
    'Glucose_45min_ago',
    'Glucose_60min_ago',
    'Glucose_90min_ago',
    'Glucose_120min_ago',
    'Glucose_Change_5min',
    'Glucose_Change_10min',
    'Glucose_Change_15min',
    'Glucose_Change_30min',
    'Glucose_Change_60min',
    'Glucose_Rate_Change_15min',
    'Glucose_Rate_Change_30min',
    'Glucose_Rate_Change_60min',
    'Glucose_Mean_15min',
    'Glucose_Mean_30min',
    'Glucose_Mean_60min',
    'Glucose_Min_30min',
    'Glucose_Min_60min',
    'Glucose_Max_30min',
    'Glucose_Max_60min',
    'Glucose_Std_30min',
    'Glucose_Std_60min',
    'Insulin_Last_15min',
    'Insulin_Last_30min',
    'Insulin_Last_60min',
    'Insulin_Last_120min',
    'Total_Insulin_Last_2Hours',
    'Total_Insulin_Last_4Hours',
    'Basal_Insulin_Last_30min',
    'Basal_Insulin_Last_60min',
    'Bolus_Insulin_Last_30min',
    'Bolus_Insulin_Last_60min',
    'Time_Since_Last_Insulin',
    'Carbs_Last_Meal',
    'Carbs_Last_2_Hours',
    'Carbs_Last_4_Hours',
    'Time_Since_Last_Meal',
    'Hour_Of_Day',
    'Day_Of_Week',
    'Exercise_Duration',
    'Exercise_Intensity',
    'Time_Since_Exercise',
    'Sleep_Hours',
    'Sleep_Quality',
    'Sleep_Cycles',
    'Sleep_Cycle_Type',
    'Time_Since_Wake',
  ];

  Map<String, num> toCsvMap() => {
        'Current_Glucose': currentGlucose,
        'Glucose_5min_ago': glucose5minAgo,
        'Glucose_10min_ago': glucose10minAgo,
        'Glucose_15min_ago': glucose15minAgo,
        'Glucose_30min_ago': glucose30minAgo,
        'Glucose_45min_ago': glucose45minAgo,
        'Glucose_60min_ago': glucose60minAgo,
        'Glucose_90min_ago': glucose90minAgo,
        'Glucose_120min_ago': glucose120minAgo,
        'Glucose_Change_5min': glucoseChange5min,
        'Glucose_Change_10min': glucoseChange10min,
        'Glucose_Change_15min': glucoseChange15min,
        'Glucose_Change_30min': glucoseChange30min,
        'Glucose_Change_60min': glucoseChange60min,
        'Glucose_Rate_Change_15min': glucoseRateChange15min,
        'Glucose_Rate_Change_30min': glucoseRateChange30min,
        'Glucose_Rate_Change_60min': glucoseRateChange60min,
        'Glucose_Mean_15min': glucoseMean15min,
        'Glucose_Mean_30min': glucoseMean30min,
        'Glucose_Mean_60min': glucoseMean60min,
        'Glucose_Min_30min': glucoseMin30min,
        'Glucose_Min_60min': glucoseMin60min,
        'Glucose_Max_30min': glucoseMax30min,
        'Glucose_Max_60min': glucoseMax60min,
        'Glucose_Std_30min': glucoseStd30min,
        'Glucose_Std_60min': glucoseStd60min,
        'Insulin_Last_15min': insulinLast15min,
        'Insulin_Last_30min': insulinLast30min,
        'Insulin_Last_60min': insulinLast60min,
        'Insulin_Last_120min': insulinLast120min,
        'Total_Insulin_Last_2Hours': totalInsulinLast2Hours,
        'Total_Insulin_Last_4Hours': totalInsulinLast4Hours,
        'Basal_Insulin_Last_30min': basalInsulinLast30min,
        'Basal_Insulin_Last_60min': basalInsulinLast60min,
        'Bolus_Insulin_Last_30min': bolusInsulinLast30min,
        'Bolus_Insulin_Last_60min': bolusInsulinLast60min,
        'Time_Since_Last_Insulin': timeSinceLastInsulin,
        'Carbs_Last_Meal': carbsLastMeal,
        'Carbs_Last_2_Hours': carbsLast2Hours,
        'Carbs_Last_4_Hours': carbsLast4Hours,
        'Time_Since_Last_Meal': timeSinceLastMeal,
        'Hour_Of_Day': hourOfDay,
        'Day_Of_Week': dayOfWeek,
        'Exercise_Duration': exerciseDuration,
        'Exercise_Intensity': exerciseIntensity,
        'Time_Since_Exercise': timeSinceExercise,
        'Sleep_Hours': sleepHours,
        'Sleep_Quality': sleepQuality,
        'Sleep_Cycles': sleepCycles,
        'Sleep_Cycle_Type': sleepCycleType,
        'Time_Since_Wake': timeSinceWake,
      };

  factory ClinicalFeatures.fromCsvMap(
    Map<String, dynamic> map, {
    FeatureSource source = FeatureSource.dataset,
  }) {
    double n(String key, [double fallback = 0]) {
      final value = map[key];
      if (value is num) return value.toDouble();
      return double.tryParse('$value') ?? fallback;
    }

    return ClinicalFeatures(
      currentGlucose: n('Current_Glucose', 110),
      glucose5minAgo: n('Glucose_5min_ago', 110),
      glucose10minAgo: n('Glucose_10min_ago', 110),
      glucose15minAgo: n('Glucose_15min_ago', 110),
      glucose30minAgo: n('Glucose_30min_ago', 110),
      glucose45minAgo: n('Glucose_45min_ago', 110),
      glucose60minAgo: n('Glucose_60min_ago', 110),
      glucose90minAgo: n('Glucose_90min_ago', 110),
      glucose120minAgo: n('Glucose_120min_ago', 110),
      glucoseChange5min: n('Glucose_Change_5min'),
      glucoseChange10min: n('Glucose_Change_10min'),
      glucoseChange15min: n('Glucose_Change_15min'),
      glucoseChange30min: n('Glucose_Change_30min'),
      glucoseChange60min: n('Glucose_Change_60min'),
      glucoseRateChange15min: n('Glucose_Rate_Change_15min'),
      glucoseRateChange30min: n('Glucose_Rate_Change_30min'),
      glucoseRateChange60min: n('Glucose_Rate_Change_60min'),
      glucoseMean15min: n('Glucose_Mean_15min', 110),
      glucoseMean30min: n('Glucose_Mean_30min', 110),
      glucoseMean60min: n('Glucose_Mean_60min', 110),
      glucoseMin30min: n('Glucose_Min_30min', 110),
      glucoseMin60min: n('Glucose_Min_60min', 110),
      glucoseMax30min: n('Glucose_Max_30min', 110),
      glucoseMax60min: n('Glucose_Max_60min', 110),
      glucoseStd30min: n('Glucose_Std_30min'),
      glucoseStd60min: n('Glucose_Std_60min'),
      insulinLast15min: n('Insulin_Last_15min'),
      insulinLast30min: n('Insulin_Last_30min'),
      insulinLast60min: n('Insulin_Last_60min'),
      insulinLast120min: n('Insulin_Last_120min'),
      totalInsulinLast2Hours: n('Total_Insulin_Last_2Hours'),
      totalInsulinLast4Hours: n('Total_Insulin_Last_4Hours'),
      basalInsulinLast30min: n('Basal_Insulin_Last_30min'),
      basalInsulinLast60min: n('Basal_Insulin_Last_60min'),
      bolusInsulinLast30min: n('Bolus_Insulin_Last_30min'),
      bolusInsulinLast60min: n('Bolus_Insulin_Last_60min'),
      timeSinceLastInsulin: n('Time_Since_Last_Insulin', 180),
      carbsLastMeal: n('Carbs_Last_Meal'),
      carbsLast2Hours: n('Carbs_Last_2_Hours'),
      carbsLast4Hours: n('Carbs_Last_4_Hours'),
      timeSinceLastMeal: n('Time_Since_Last_Meal', 180),
      hourOfDay: n('Hour_Of_Day'),
      dayOfWeek: n('Day_Of_Week', 1),
      exerciseDuration: n('Exercise_Duration'),
      exerciseIntensity: n('Exercise_Intensity'),
      timeSinceExercise: n('Time_Since_Exercise', 720),
      sleepHours: n('Sleep_Hours', 7.2),
      sleepQuality: n('Sleep_Quality', 2),
      sleepCycles: n('Sleep_Cycles', 4.8),
      sleepCycleType: n('Sleep_Cycle_Type'),
      timeSinceWake: n('Time_Since_Wake', 180),
      source: source,
    );
  }

  Map<String, dynamic> toJson() => {
        ...toCsvMap(),
        'source': source.name,
      };

  factory ClinicalFeatures.fromJson(Map<String, dynamic> json) {
    final sourceName = json['source'] as String?;
    return ClinicalFeatures.fromCsvMap(
      json,
      source: FeatureSource.values.firstWhere(
        (s) => s.name == sourceName,
        orElse: () => FeatureSource.estimated,
      ),
    );
  }

  String get trendLabel {
    if (glucoseRateChange15min <= -1) return 'Falling';
    if (glucoseRateChange15min >= 1) return 'Rising';
    return 'Stable';
  }

  String get sourceLabel => source == FeatureSource.dataset
      ? 'From Dataset CSV'
      : 'Estimated (placeholder)';

  String get sleepQualityLabel {
    switch (sleepQuality.round()) {
      case 0:
        return 'Poor';
      case 1:
        return 'Fair';
      default:
        return 'Good';
    }
  }

  String get sleepCycleLabel => sleepCycleName(sleepCycleType);

  static String sleepCycleName(double type) {
    switch (type.round()) {
      case 1:
        return 'Short night';
      case 2:
        return 'Fragmented';
      case 3:
        return 'Shift work';
      default:
        return 'Regular';
    }
  }

  bool get hasUserGlucose => currentGlucose > 0;
}

enum FeatureSource { estimated, dataset }

class SavedHealthContext {
  const SavedHealthContext({
    required this.overrides,
    required this.snapshot,
    required this.updatedAt,
  });

  final FeatureOverrides overrides;
  final ClinicalFeatures snapshot;
  final DateTime updatedAt;

  Map<String, dynamic> toJson() => {
        'overrides': overrides.toJson(),
        'snapshot': snapshot.toJson(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory SavedHealthContext.fromJson(Map<String, dynamic> json) =>
      SavedHealthContext(
        overrides: FeatureOverrides.fromJson(
          json['overrides'] as Map<String, dynamic>? ?? const {},
        ),
        snapshot: ClinicalFeatures.fromJson(
          json['snapshot'] as Map<String, dynamic>,
        ),
        updatedAt: DateTime.parse(json['updatedAt'] as String),
      );
}

/// Optional user-entered values. Blank fields stay estimated.
class FeatureOverrides {
  const FeatureOverrides({
    this.currentGlucose,
    this.bolusInsulinUnits,
    this.timeSinceLastInsulinMinutes,
    this.exerciseDurationMinutes,
    this.exerciseIntensity,
    this.timeSinceExerciseMinutes,
    this.sleepHours,
    this.sleepQuality,
    this.sleepCycleType,
  });

  final double? currentGlucose;
  final double? bolusInsulinUnits;
  final double? timeSinceLastInsulinMinutes;
  final double? exerciseDurationMinutes;
  final double? exerciseIntensity;
  final double? timeSinceExerciseMinutes;
  final double? sleepHours;
  final double? sleepQuality;
  final double? sleepCycleType;

  bool get isEmpty =>
      currentGlucose == null &&
      bolusInsulinUnits == null &&
      timeSinceLastInsulinMinutes == null &&
      exerciseDurationMinutes == null &&
      (exerciseIntensity == null || exerciseIntensity == 0) &&
      timeSinceExerciseMinutes == null &&
      sleepHours == null &&
      sleepQuality == null &&
      sleepCycleType == null;

  Map<String, dynamic> toJson() => {
        'currentGlucose': currentGlucose,
        'bolusInsulinUnits': bolusInsulinUnits,
        'timeSinceLastInsulinMinutes': timeSinceLastInsulinMinutes,
        'exerciseDurationMinutes': exerciseDurationMinutes,
        'exerciseIntensity': exerciseIntensity,
        'timeSinceExerciseMinutes': timeSinceExerciseMinutes,
        'sleepHours': sleepHours,
        'sleepQuality': sleepQuality,
        'sleepCycleType': sleepCycleType,
      };

  factory FeatureOverrides.fromJson(Map<String, dynamic> json) {
    double? n(String key) {
      final value = json[key];
      if (value == null) return null;
      if (value is num) return value.toDouble();
      return double.tryParse('$value');
    }

    return FeatureOverrides(
      currentGlucose: n('currentGlucose'),
      bolusInsulinUnits: n('bolusInsulinUnits'),
      timeSinceLastInsulinMinutes: n('timeSinceLastInsulinMinutes'),
      exerciseDurationMinutes: n('exerciseDurationMinutes'),
      exerciseIntensity: n('exerciseIntensity'),
      timeSinceExerciseMinutes: n('timeSinceExerciseMinutes'),
      sleepHours: n('sleepHours'),
      sleepQuality: n('sleepQuality'),
      sleepCycleType: n('sleepCycleType'),
    );
  }
}
