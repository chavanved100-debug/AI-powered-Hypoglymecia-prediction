import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';

import '../models/food_item.dart';
import '../services/dataset_service.dart';

/// Labels loaded from assets/models/labels.json
class FoodLabel {
  final int index;
  final String imageClass;
  final String foodId;
  final String foodName;

  FoodLabel({
    required this.index,
    required this.imageClass,
    required this.foodId,
    required this.foodName,
  });

  factory FoodLabel.fromJson(Map<String, dynamic> json) => FoodLabel(
        index: json['index'] as int,
        imageClass: json['image_class'] as String,
        foodId: json['food_id'] as String,
        foodName: json['food_name'] as String,
      );
}

/// Result of food classification
class FoodClassificationResult {
  final FoodLabel label;
  final double confidence;
  final FoodItem? matchedFood;

  FoodClassificationResult({
    required this.label,
    required this.confidence,
    this.matchedFood,
  });
}

/// Service to classify food images using TFLite model
class FoodClassifierService {
  FoodClassifierService._();

  static final FoodClassifierService instance = FoodClassifierService._();

  Interpreter? _interpreter;
  List<FoodLabel> _labels = [];
  bool _initialized = false;
  static const int _inputSize = 128;

  Future<void> initialize() async {
    if (_initialized) return;

    // Load labels
    final labelsJson = await rootBundle.loadString('assets/models/labels.json');
    final labelsList = (json.decode(labelsJson) as List)
        .map((e) => FoodLabel.fromJson(e as Map<String, dynamic>))
        .toList();
    _labels = labelsList;

    // Load TFLite model
    _interpreter = await Interpreter.fromAsset('assets/models/food_classifier.tflite');
    _initialized = true;
  }

  bool get isInitialized => _initialized;

  /// Classify an image file
  Future<FoodClassificationResult?> classifyImage(File imageFile) async {
    if (!_initialized) await initialize();
    final bytes = await imageFile.readAsBytes();
    return _classifyBytes(bytes);
  }

  /// Classify image from camera bytes
  Future<FoodClassificationResult?> classifyCameraImage(Uint8List bytes) async {
    if (!_initialized) await initialize();
    return _classifyBytes(bytes);
  }

  Future<FoodClassificationResult?> _classifyBytes(Uint8List bytes) async {
    try {
      final image = img.decodeImage(bytes);
      if (image == null) return null;

      // Resize to 128x128
      final resized = img.copyResize(image, width: _inputSize, height: _inputSize);

      // Convert to float32 [0,1] and add batch dimension
      final input = Float32List(_inputSize * _inputSize * 3);
      int idx = 0;
      for (int y = 0; y < _inputSize; y++) {
        for (int x = 0; x < _inputSize; x++) {
          final pixel = resized.getPixel(x, y);
          input[idx++] = pixel.r / 255.0;
          input[idx++] = pixel.g / 255.0;
          input[idx++] = pixel.b / 255.0;
        }
      }

      // Run inference
      final output = [Float32List(_labels.length)];
      _interpreter!.run(input.buffer.asUint8List(), output);

      // Get top prediction
      final probs = output[0];
      int maxIdx = 0;
      double maxProb = probs[0];
      for (int i = 1; i < probs.length; i++) {
        if (probs[i] > maxProb) {
          maxProb = probs[i];
          maxIdx = i;
        }
      }

      if (maxIdx >= _labels.length) return null;
      final label = _labels[maxIdx];
      return FoodClassificationResult(label: label, confidence: maxProb);
    } catch (e) {
      return null;
    }
  }

  /// Match classified food to database FoodItem
  FoodItem? matchToFoodDatabase(FoodLabel label) {
    return DatasetService.instance.findFoodById(label.foodId);
  }

  void dispose() {
    _interpreter?.close();
    _interpreter = null;
    _initialized = false;
  }
}