import 'clinical_features.dart';

enum RiskLevel { low, moderate, high }

extension RiskLevelX on RiskLevel {
  String get label {
    switch (this) {
      case RiskLevel.low:
        return 'LOW';
      case RiskLevel.moderate:
        return 'MODERATE';
      case RiskLevel.high:
        return 'HIGH';
    }
  }

  String get displayLabel {
    switch (this) {
      case RiskLevel.low:
        return 'Low Risk';
      case RiskLevel.moderate:
        return 'Moderate Risk';
      case RiskLevel.high:
        return 'High Risk';
    }
  }

  static RiskLevel fromScore(int score) {
    if (score <= 30) return RiskLevel.low;
    if (score <= 60) return RiskLevel.moderate;
    return RiskLevel.high;
  }
}

class RiskFactor {
  const RiskFactor({required this.name, required this.value});

  final String name;
  final String value;

  Map<String, dynamic> toJson() => {'name': name, 'value': value};

  factory RiskFactor.fromJson(Map<String, dynamic> json) => RiskFactor(
        name: json['name'] as String,
        value: json['value'] as String,
      );
}

class PredictionResult {
  const PredictionResult({
    required this.riskScore,
    required this.riskLevel,
    required this.riskFactors,
    required this.recommendation,
    this.features,
  });

  final int riskScore;
  final RiskLevel riskLevel;
  final List<RiskFactor> riskFactors;
  final String recommendation;
  final ClinicalFeatures? features;

  String get demoLabel => features == null
      ? 'Estimated from Dataset CSVs'
      : '${features!.sourceLabel} + meal Dataset';

  Map<String, dynamic> toJson() => {
        'riskScore': riskScore,
        'riskLevel': riskLevel.index,
        'riskFactors': riskFactors.map((f) => f.toJson()).toList(),
        'recommendation': recommendation,
        if (features != null) 'features': features!.toJson(),
      };

  factory PredictionResult.fromJson(Map<String, dynamic> json) =>
      PredictionResult(
        riskScore: json['riskScore'] as int,
        riskLevel: RiskLevel.values[json['riskLevel'] as int],
        riskFactors: (json['riskFactors'] as List<dynamic>)
            .map((e) => RiskFactor.fromJson(e as Map<String, dynamic>))
            .toList(),
        recommendation: json['recommendation'] as String,
        features: json['features'] is Map<String, dynamic>
            ? ClinicalFeatures.fromJson(
                json['features'] as Map<String, dynamic>,
              )
            : null,
      );
}
