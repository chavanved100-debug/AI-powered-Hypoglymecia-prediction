import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class HealthContextForm extends StatelessWidget {
  const HealthContextForm({
    super.key,
    required this.glucoseController,
    required this.insulinController,
    required this.insulinMinutesController,
    required this.exerciseDurationController,
    required this.exerciseMinutesController,
    required this.exerciseIntensity,
    required this.onIntensityChanged,
    required this.sleepHoursController,
    required this.sleepQuality,
    required this.onSleepQualityChanged,
    required this.sleepCycleType,
    required this.onSleepCycleChanged,
  });

  final TextEditingController glucoseController;
  final TextEditingController insulinController;
  final TextEditingController insulinMinutesController;
  final TextEditingController exerciseDurationController;
  final TextEditingController exerciseMinutesController;
  final double exerciseIntensity;
  final ValueChanged<double> onIntensityChanged;
  final TextEditingController sleepHoursController;
  final double sleepQuality;
  final ValueChanged<double> onSleepQualityChanged;
  final double sleepCycleType;
  final ValueChanged<double> onSleepCycleChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Section(
          title: 'Glucose',
          child: _numberField(
            glucoseController,
            label: 'Current glucose',
            hint: 'mg/dL',
            suffix: 'mg/dL',
          ),
        ),
        const SizedBox(height: 16),
        _Section(
          title: 'Insulin',
          child: Column(
            children: [
              _numberField(
                insulinController,
                label: 'Last bolus',
                hint: 'units',
                suffix: 'U',
              ),
              const SizedBox(height: 12),
              _numberField(
                insulinMinutesController,
                label: 'Time since last insulin',
                hint: 'minutes ago',
                suffix: 'min',
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _Section(
          title: 'Exercise',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _numberField(
                exerciseDurationController,
                label: 'Duration',
                hint: 'minutes',
                suffix: 'min',
              ),
              const SizedBox(height: 12),
              _numberField(
                exerciseMinutesController,
                label: 'Time since exercise',
                hint: 'minutes ago',
                suffix: 'min',
              ),
              const SizedBox(height: 16),
              Text(
                'Intensity',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 8),
              SegmentedButton<double>(
                showSelectedIcon: false,
                segments: const [
                  ButtonSegment(value: 0, label: Text('None')),
                  ButtonSegment(value: 1, label: Text('Low')),
                  ButtonSegment(value: 2, label: Text('Med')),
                  ButtonSegment(value: 3, label: Text('High')),
                ],
                selected: {exerciseIntensity},
                onSelectionChanged: (set) => onIntensityChanged(set.first),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _Section(
          title: 'Sleep cycle',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _numberField(
                sleepHoursController,
                label: 'Hours slept last night',
                hint: 'e.g. 7.5',
                suffix: 'h',
              ),
              const SizedBox(height: 16),
              Text('Sleep quality', style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 8),
              SegmentedButton<double>(
                showSelectedIcon: false,
                segments: const [
                  ButtonSegment(value: 0, label: Text('Poor')),
                  ButtonSegment(value: 1, label: Text('Fair')),
                  ButtonSegment(value: 2, label: Text('Good')),
                ],
                selected: {sleepQuality},
                onSelectionChanged: (set) => onSleepQualityChanged(set.first),
              ),
              const SizedBox(height: 16),
              Text('Cycle type', style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 8),
              DropdownButtonFormField<double>(
                initialValue: sleepCycleType,
                decoration: const InputDecoration(labelText: 'Sleep cycle'),
                items: const [
                  DropdownMenuItem(value: 0, child: Text('Regular night')),
                  DropdownMenuItem(value: 1, child: Text('Short night')),
                  DropdownMenuItem(value: 2, child: Text('Fragmented')),
                  DropdownMenuItem(value: 3, child: Text('Shift work')),
                ],
                onChanged: (value) {
                  if (value != null) onSleepCycleChanged(value);
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _numberField(
    TextEditingController controller, {
    required String label,
    required String hint,
    required String suffix,
  }) {
    return TextField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
      ],
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        suffixText: suffix,
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }
}
