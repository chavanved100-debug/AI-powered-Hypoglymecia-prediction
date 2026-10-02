import 'package:flutter/material.dart';

import '../models/clinical_features.dart';
import '../theme/app_theme.dart';

class ClinicalFeaturesCard extends StatelessWidget {
  const ClinicalFeaturesCard({super.key, required this.features});

  final ClinicalFeatures features;

  @override
  Widget build(BuildContext context) {
    final groups = <String, List<MapEntry<String, String>>>{
      'Glucose history': [
        _e('Current_Glucose', '${features.currentGlucose} mg/dL'),
        _e('Glucose_5min_ago', '${features.glucose5minAgo}'),
        _e('Glucose_10min_ago', '${features.glucose10minAgo}'),
        _e('Glucose_15min_ago', '${features.glucose15minAgo}'),
        _e('Glucose_30min_ago', '${features.glucose30minAgo}'),
        _e('Glucose_45min_ago', '${features.glucose45minAgo}'),
        _e('Glucose_60min_ago', '${features.glucose60minAgo}'),
        _e('Glucose_90min_ago', '${features.glucose90minAgo}'),
        _e('Glucose_120min_ago', '${features.glucose120minAgo}'),
      ],
      'Glucose change': [
        _e('Glucose_Change_5min', '${features.glucoseChange5min}'),
        _e('Glucose_Change_10min', '${features.glucoseChange10min}'),
        _e('Glucose_Change_15min', '${features.glucoseChange15min}'),
        _e('Glucose_Change_30min', '${features.glucoseChange30min}'),
        _e('Glucose_Change_60min', '${features.glucoseChange60min}'),
        _e('Glucose_Rate_Change_15min', '${features.glucoseRateChange15min}'),
        _e('Glucose_Rate_Change_30min', '${features.glucoseRateChange30min}'),
        _e('Glucose_Rate_Change_60min', '${features.glucoseRateChange60min}'),
      ],
      'Glucose stats': [
        _e('Glucose_Mean_15min', '${features.glucoseMean15min}'),
        _e('Glucose_Mean_30min', '${features.glucoseMean30min}'),
        _e('Glucose_Mean_60min', '${features.glucoseMean60min}'),
        _e('Glucose_Min_30min', '${features.glucoseMin30min}'),
        _e('Glucose_Min_60min', '${features.glucoseMin60min}'),
        _e('Glucose_Max_30min', '${features.glucoseMax30min}'),
        _e('Glucose_Max_60min', '${features.glucoseMax60min}'),
        _e('Glucose_Std_30min', '${features.glucoseStd30min}'),
        _e('Glucose_Std_60min', '${features.glucoseStd60min}'),
      ],
      'Insulin': [
        _e('Insulin_Last_15min', '${features.insulinLast15min} U'),
        _e('Insulin_Last_30min', '${features.insulinLast30min} U'),
        _e('Insulin_Last_60min', '${features.insulinLast60min} U'),
        _e('Insulin_Last_120min', '${features.insulinLast120min} U'),
        _e('Total_Insulin_Last_2Hours', '${features.totalInsulinLast2Hours} U'),
        _e('Total_Insulin_Last_4Hours', '${features.totalInsulinLast4Hours} U'),
        _e('Basal_Insulin_Last_30min', '${features.basalInsulinLast30min} U'),
        _e('Basal_Insulin_Last_60min', '${features.basalInsulinLast60min} U'),
        _e('Bolus_Insulin_Last_30min', '${features.bolusInsulinLast30min} U'),
        _e('Bolus_Insulin_Last_60min', '${features.bolusInsulinLast60min} U'),
        _e('Time_Since_Last_Insulin', '${features.timeSinceLastInsulin} min'),
      ],
      'Carbs & time': [
        _e('Carbs_Last_Meal', '${features.carbsLastMeal} g'),
        _e('Carbs_Last_2_Hours', '${features.carbsLast2Hours} g'),
        _e('Carbs_Last_4_Hours', '${features.carbsLast4Hours} g'),
        _e('Time_Since_Last_Meal', '${features.timeSinceLastMeal} min'),
        _e('Hour_Of_Day', '${features.hourOfDay.round()}'),
        _e('Day_Of_Week', '${features.dayOfWeek.round()}'),
      ],
      'Exercise': [
        _e('Exercise_Duration', '${features.exerciseDuration} min'),
        _e('Exercise_Intensity', '${features.exerciseIntensity}'),
        _e('Time_Since_Exercise', '${features.timeSinceExercise} min'),
      ],
      'Sleep': [
        _e('Sleep_Hours', '${features.sleepHours} h'),
        _e('Sleep_Quality', features.sleepQualityLabel),
        _e('Sleep_Cycles', '${features.sleepCycles}'),
        _e('Sleep_Cycle_Type', features.sleepCycleLabel),
        _e('Time_Since_Wake', '${features.timeSinceWake} min'),
      ],
    };

    return Card(
      child: ExpansionTile(
        initiallyExpanded: false,
        tilePadding: const EdgeInsets.symmetric(horizontal: 16),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        title: const Text('All clinical features'),
        subtitle: Text(
          features.sourceLabel,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
              ),
        ),
        children: [
          for (final group in groups.entries) ...[
            Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: const EdgeInsets.only(top: 8, bottom: 6),
                child: Text(
                  group.key,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: AppColors.primary,
                      ),
                ),
              ),
            ),
            ...group.value.map(
              (row) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        row.key,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                    Text(
                      row.value,
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  MapEntry<String, String> _e(String name, String value) =>
      MapEntry(name, value);
}
