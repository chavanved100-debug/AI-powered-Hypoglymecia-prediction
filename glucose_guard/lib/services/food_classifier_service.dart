import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';

import '../models/food_item.dart';
import '../services/dataset_service.dart';

class FoodMapping {
  final String foodId;
  final String foodName;

  const FoodMapping(this.foodId, this.foodName);
}

const Map<String, FoodMapping> _foodMappings = {
  'achar': FoodMapping('F_000', 'Achar'),
  'adhirasam': FoodMapping('F239', 'Rasam'),
  'aloo gobi': FoodMapping('F173', 'Aloo Gobi Sabzi'),
  'aloo matar': FoodMapping('F_003', 'Aloo Matar'),
  'aloo methi': FoodMapping('F_004', 'Aloo Methi'),
  'aloo paratha': FoodMapping('F071', 'Aloo Paratha'),
  'aloo puri': FoodMapping('F_006', 'Aloo Puri'),
  'aloo shimla mirch': FoodMapping('F_007', 'Aloo Shimla Mirch'),
  'aloo tikki': FoodMapping('F119', 'Chaat (Aloo Tikki)'),
  'amritsari kulcha': FoodMapping('F184', 'Amritsari Kulcha'),
  'anarsa': FoodMapping('F_010', 'Anarsa'),
  'anda curry': FoodMapping('F_011', 'Anda Curry'),
  'appam': FoodMapping('F194', 'Appam'),
  'apple': FoodMapping('F014', 'Apple'),
  'apple pie': FoodMapping('F014', 'Apple'),
  'ariselu': FoodMapping('F_015', 'Ariselu'),
  'bagels': FoodMapping('F_016', 'Bagels'),
  'baingan bharta': FoodMapping('F314', 'Baingan Bharta'),
  'balushahi': FoodMapping('F_018', 'Balushahi'),
  'banana': FoodMapping('F013', 'Banana'),
  'banana chips': FoodMapping('F013', 'Banana'),
  'bandar laddu': FoodMapping('F_021', 'Bandar Laddu'),
  'basundi': FoodMapping('F200', 'Basundi'),
  'beetroot': FoodMapping('F148', 'Beetroot Salad'),
  'besan cheela': FoodMapping('F_024', 'Besan Cheela'),
  'besan laddu': FoodMapping('F_025', 'Besan Laddu'),
  'bhatura': FoodMapping('F_026', 'Bhatura'),
  'bhel puri': FoodMapping('F051', 'Bhel Puri'),
  'bhindi masala': FoodMapping('F_028', 'Bhindi Masala'),
  'biryani': FoodMapping('F045', 'Biryani (Veg)'),
  'boondi': FoodMapping('F_030', 'Boondi'),
  'boondi laddu': FoodMapping('F_031', 'Boondi Laddu'),
  'brownie': FoodMapping('F_032', 'Brownie'),
  'burger': FoodMapping('F213', 'Chicken Burger'),
  'butter chicken': FoodMapping('F126', 'Butter Chicken'),
  'butter naan': FoodMapping('F086', 'Naan'),
  'cabbage': FoodMapping('F036', 'Cabbage Sabzi'),
  'cake': FoodMapping('F348', 'Milk Cake'),
  'canned potatoes': FoodMapping('F_038', 'Canned Potatoes'),
  'capsicum': FoodMapping('F335', 'Stuffed Capsicum'),
  'carrots': FoodMapping('F_040', 'Carrots'),
  'cauliflower': FoodMapping('F_041', 'Cauliflower'),
  'chaas': FoodMapping('F_042', 'Chaas'),
  'chai': FoodMapping('F_043', 'Chai'),
  'chak hao kheer': FoodMapping('F099', 'Kheer'),
  'cham cham': FoodMapping('F_045', 'Cham Cham'),
  'chana masala': FoodMapping('F088', 'Chana Masala'),
  'chapati': FoodMapping('F_047', 'Chapati'),
  'chhena kheeri': FoodMapping('F099', 'Kheer'),
  'chicken pizza': FoodMapping('F_049', 'Chicken Pizza'),
  'chicken razala': FoodMapping('F_050', 'Chicken Razala'),
  'chicken rezala': FoodMapping('F_051', 'Chicken Rezala'),
  'chicken tikka': FoodMapping('F090', 'Chicken Tikka'),
  'chicken tikka masala': FoodMapping('F232', 'Chicken Tikka Masala'),
  'chicken wings': FoodMapping('F_054', 'Chicken Wings'),
  'chikki': FoodMapping('F344', 'Peanut Chikki'),
  'chilli pepper': FoodMapping('F_056', 'Chilli Pepper'),
  'chilli potato': FoodMapping('F_057', 'Chilli Potato'),
  'chivda': FoodMapping('F_058', 'Chivda'),
  'chole bhature': FoodMapping('F185', 'Chole Bhature'),
  'chop suey': FoodMapping('F_060', 'Chop Suey'),
  'chow mein': FoodMapping('F_061', 'Chow Mein'),
  'cooked oatmeal': FoodMapping('F_062', 'Cooked Oatmeal'),
  'cooked pasta': FoodMapping('F_063', 'Cooked Pasta'),
  'corn': FoodMapping('F020', 'Cornflakes'),
  'cucumber': FoodMapping('F034', 'Cucumber Salad'),
  'daal baati churma': FoodMapping('F_066', 'Daal Baati Churma'),
  'daal puri': FoodMapping('F_067', 'Daal Puri'),
  'dal khichdi': FoodMapping('F003', 'Dal'),
  'dal makhani': FoodMapping('F157', 'Dal Makhani'),
  'dal tadka': FoodMapping('F003', 'Dal'),
  'dharwad pedha': FoodMapping('F_071', 'Dharwad Pedha'),
  'dhokla': FoodMapping('F055', 'Dhokla'),
  'doodhpak': FoodMapping('F_073', 'Doodhpak'),
  'double ka meetha': FoodMapping('F_074', 'Double Ka Meetha'),
  'doughnut': FoodMapping('F_075', 'Doughnut'),
  'dum aloo': FoodMapping('F407', 'Kashmiri Dum Aloo'),
  'falooda': FoodMapping('F_077', 'Falooda'),
  'fish curry': FoodMapping('F028', 'Fish Curry'),
  'fried chicken': FoodMapping('F_079', 'Fried Chicken'),
  'fried fish': FoodMapping('F_080', 'Fried Fish'),
  'fried rice': FoodMapping('F002', 'Rice'),
  'gajar ka halwa': FoodMapping('F_082', 'Gajar Ka Halwa'),
  'garlic': FoodMapping('F218', 'Garlic Naan'),
  'garlic bread': FoodMapping('F266', 'Cheese Garlic Bread'),
  'garlic naan': FoodMapping('F218', 'Garlic Naan'),
  'gavvalu': FoodMapping('F_086', 'Gavvalu'),
  'ghevar': FoodMapping('F_087', 'Ghevar'),
  'ginger': FoodMapping('F_088', 'Ginger'),
  'gobi manchurian': FoodMapping('F259', 'Gobi Manchurian'),
  'grape': FoodMapping('F_090', 'Grape'),
  'grilled sandwich': FoodMapping('F_091', 'Grilled Sandwich'),
  'gujhia': FoodMapping('F_092', 'Gujhia'),
  'gujiya': FoodMapping('F_093', 'Gujiya'),
  'gulab jamun': FoodMapping('F096', 'Gulab Jamun'),
  'hara bhara kabab': FoodMapping('F_095', 'Hara Bhara Kabab'),
  'hot dogs': FoodMapping('F_096', 'Hot Dogs'),
  'ice cream': FoodMapping('F_097', 'Ice Cream'),
  'idiyappam': FoodMapping('F193', 'Idiyappam'),
  'idli': FoodMapping('F010', 'Idli'),
  'imarti': FoodMapping('F_100', 'Imarti'),
  'jalebi': FoodMapping('F098', 'Jalebi'),
  'kaathi rolls': FoodMapping('F_102', 'Kaathi Rolls'),
  'kachori': FoodMapping('F050', 'Kachori'),
  'kadai paneer': FoodMapping('F_104', 'Kadai Paneer'),
  'kadhi pakoda': FoodMapping('F153', 'Kadhi'),
  'kajjikaya': FoodMapping('F_106', 'Kajjikaya'),
  'kaju katli': FoodMapping('F347', 'Kaju Katli'),
  'kakinada khaja': FoodMapping('F_108', 'Kakinada Khaja'),
  'kalakand': FoodMapping('F_109', 'Kalakand'),
  'karela bharta': FoodMapping('F_110', 'Karela Bharta'),
  'kathi roll': FoodMapping('F283', 'Paneer Kathi Roll'),
  'kebabs': FoodMapping('F_112', 'Kebabs'),
  'khakhra': FoodMapping('F327', 'Khakhra'),
  'khandvi': FoodMapping('F402', 'Vegetable Khandvi'),
  'kheer': FoodMapping('F099', 'Kheer'),
  'khichdi': FoodMapping('F041', 'Khichdi'),
  'khubani ka meetha': FoodMapping('F_117', 'Khubani Ka Meetha'),
  'kiwi': FoodMapping('F_118', 'Kiwi'),
  'kofta': FoodMapping('F171', 'Veg Kofta Curry'),
  'kulfi': FoodMapping('F230', 'Kesar Pista Kulfi'),
  'kuzhi paniyaram': FoodMapping('F250', 'Kuzhi Paniyaram'),
  'lassi': FoodMapping('F018', 'Lassi (Plain)'),
  'ledikeni': FoodMapping('F_123', 'Ledikeni'),
  'lemon': FoodMapping('F042', 'Lemon Rice'),
  'lemonade': FoodMapping('F_125', 'Lemonade'),
  'lettuce': FoodMapping('F_126', 'Lettuce'),
  'litti chokha': FoodMapping('F_127', 'Litti Chokha'),
  'lyangcha': FoodMapping('F_128', 'Lyangcha'),
  'maach jhol': FoodMapping('F_129', 'Maach Jhol'),
  'macaroni salad': FoodMapping('F109', 'Macaroni'),
  'makki di roti sarson da saag': FoodMapping('F001', 'Roti'),
  'malapua': FoodMapping('F_132', 'Malapua'),
  'malpua': FoodMapping('F_133', 'Malpua'),
  'mango': FoodMapping('F079', 'Mango'),
  'margherita pizza': FoodMapping('F_135', 'Margherita Pizza'),
  'masala dosa': FoodMapping('F066', 'Masala Dosa'),
  'masala papad': FoodMapping('F_137', 'Masala Papad'),
  'medu vada': FoodMapping('F068', 'Medu Vada'),
  'misal pav': FoodMapping('F059', 'Misal Pav'),
  'mishti doi': FoodMapping('F_140', 'Mishti Doi'),
  'misi roti': FoodMapping('F001', 'Roti'),
  'missi roti': FoodMapping('F204', 'Missi Roti'),
  'misti doi': FoodMapping('F_143', 'Misti Doi'),
  'modak': FoodMapping('F198', 'Modak'),
  'momos': FoodMapping('F116', 'Vegetable Momos'),
  'moong dal halwa': FoodMapping('F280', 'Moong Dal Halwa'),
  'muffin': FoodMapping('F_147', 'Muffin'),
  'murukku': FoodMapping('F_148', 'Murukku'),
  'mysore pak': FoodMapping('F197', 'Mysore Pak'),
  'naan': FoodMapping('F086', 'Naan'),
  'naan bread': FoodMapping('F086', 'Naan'),
  'navratan korma': FoodMapping('F170', 'Navratan Korma'),
  'neer dosa': FoodMapping('F196', 'Neer Dosa'),
  'omelette': FoodMapping('F025', 'Omelette'),
  'onion': FoodMapping('F_155', 'Onion'),
  'onion pakoda': FoodMapping('F_156', 'Onion Pakoda'),
  'orange': FoodMapping('F080', 'Orange'),
  'paani puri': FoodMapping('F_158', 'Paani Puri'),
  'pakode': FoodMapping('F_159', 'Pakode'),
  'palak paneer': FoodMapping('F039', 'Palak Paneer'),
  'pan cake': FoodMapping('F_161', 'Pan Cake'),
  'pan-fried prawns': FoodMapping('F_162', 'Pan-fried Prawns'),
  'paneer butter masala': FoodMapping('F152', 'Paneer Butter Masala'),
  'paneer masala': FoodMapping('F_164', 'Paneer Masala'),
  'paneer pizza': FoodMapping('F_165', 'Paneer Pizza'),
  'pani puri': FoodMapping('F053', 'Pani Puri'),
  'paniyaram': FoodMapping('F249', 'Neer Paniyaram'),
  'papad': FoodMapping('F_168', 'Papad'),
  'papdi chaat': FoodMapping('F_169', 'Papdi Chaat'),
  'paprika': FoodMapping('F_170', 'Paprika'),
  'paratha': FoodMapping('F070', 'Stuffed Paratha'),
  'patrode': FoodMapping('F_172', 'Patrode'),
  'pav bhaji': FoodMapping('F047', 'Pav Bhaji'),
  'peanut chikki': FoodMapping('F344', 'Peanut Chikki'),
  'pear': FoodMapping('F_175', 'Pear'),
  'peas': FoodMapping('F089', 'Green Peas Curry'),
  'peda': FoodMapping('F_177', 'Peda'),
  'pepperoni pizza': FoodMapping('F_178', 'Pepperoni Pizza'),
  'phirni': FoodMapping('F_179', 'Phirni'),
  'pineapple': FoodMapping('F014', 'Apple'),
  'pithe': FoodMapping('F_181', 'Pithe'),
  'pizza': FoodMapping('F216', 'Pizza Veg'),
  'poha': FoodMapping('F008', 'Poha'),
  'pomegranate': FoodMapping('F180', 'Pomegranate'),
  'pongal': FoodMapping('F443', 'Little Millet Pongal'),
  'poornalu': FoodMapping('F_186', 'Poornalu'),
  'pootharekulu': FoodMapping('F_187', 'Pootharekulu'),
  'popcorn': FoodMapping('F_188', 'Popcorn'),
  'puri bhaji': FoodMapping('F_189', 'Puri Bhaji'),
  'qubani ka meetha': FoodMapping('F_190', 'Qubani Ka Meetha'),
  'rabri': FoodMapping('F_191', 'Rabri'),
  'radish': FoodMapping('F_192', 'Radish'),
  'raj kachori': FoodMapping('F050', 'Kachori'),
  'rajma': FoodMapping('F006', 'Rajma'),
  'rajma chawal': FoodMapping('F006', 'Rajma'),
  'ras malai': FoodMapping('F_196', 'Ras Malai'),
  'rasgulla': FoodMapping('F097', 'Rasgulla'),
  'rava dosa': FoodMapping('F285', 'Rava Dosa'),
  'rice cooked': FoodMapping('F002', 'Rice'),
  'sabudana khichdi': FoodMapping('F058', 'Sabudana Khichdi'),
  'sabudana vada': FoodMapping('F254', 'Sabudana Vada'),
  'samosa': FoodMapping('F049', 'Samosa'),
  'sandesh': FoodMapping('F_203', 'Sandesh'),
  'sandwich': FoodMapping('F069', 'Vegetable Sandwich'),
  'scrambled eggs': FoodMapping('F_205', 'Scrambled Eggs'),
  'seekh kebab': FoodMapping('F294', 'Vegetable Seekh Kebab'),
  'set dosa': FoodMapping('F011', 'Dosa'),
  'sev puri': FoodMapping('F052', 'Sev Puri'),
  'shankarpali': FoodMapping('F_209', 'Shankarpali'),
  'sheer khurma': FoodMapping('F_210', 'Sheer Khurma'),
  'sheer korma': FoodMapping('F_211', 'Sheer Korma'),
  'sheera': FoodMapping('F_212', 'Sheera'),
  'shelled soy bean': FoodMapping('F_213', 'Shelled Soy Bean'),
  'shrikhand': FoodMapping('F100', 'Shrikhand'),
  'sohan halwa': FoodMapping('F_215', 'Sohan Halwa'),
  'sohan papdi': FoodMapping('F_216', 'Sohan Papdi'),
  'solkadhi': FoodMapping('F153', 'Kadhi'),
  'spinach': FoodMapping('F297', 'Spinach Soup'),
  'spring rolls': FoodMapping('F118', 'Spring Roll'),
  'sprouts': FoodMapping('F033', 'Sprouts Salad'),
  'steamed momo': FoodMapping('F_221', 'Steamed Momo'),
  'stuffed karela': FoodMapping('F_222', 'Stuffed Karela'),
  'sunny side up eggs': FoodMapping('F_223', 'Sunny Side Up Eggs'),
  'sutar feni': FoodMapping('F_224', 'Sutar Feni'),
  'sweet potatoes': FoodMapping('F_225', 'Sweet Potatoes'),
  'taco': FoodMapping('F_226', 'Taco'),
  'thali': FoodMapping('F253', 'Thalipeeth'),
  'thukpa': FoodMapping('F191', 'Thukpa (Veg)'),
  'tiramisu': FoodMapping('F_229', 'Tiramisu'),
  'toast': FoodMapping('F162', 'Grilled Cheese Toast'),
  'tomato': FoodMapping('F035', 'Tomato Salad'),
  'turnip': FoodMapping('F_232', 'Turnip'),
  'unni appam': FoodMapping('F194', 'Appam'),
  'uttapam': FoodMapping('F065', 'Uttapam'),
  'vada pav': FoodMapping('F048', 'Vada Pav'),
  'veggie burger': FoodMapping('F_236', 'Veggie Burger'),
  'waffle': FoodMapping('F_237', 'Waffle'),
  'watermelon': FoodMapping('F_238', 'Watermelon'),
};

/// Labels loaded from assets/models/labels.txt
class FoodLabel {
  final int index;
  final String imageClass;
  final String foodId;
  final String foodName;

  const FoodLabel({
    required this.index,
    required this.imageClass,
    required this.foodId,
    required this.foodName,
  });

  factory FoodLabel.fromText({
    required int index,
    required String rawName,
  }) {
    final lower = rawName.trim().toLowerCase();
    final mapping = _foodMappings[lower];
    final foodName = mapping?.foodName ?? _titleCase(lower);
    final foodId = mapping?.foodId ?? 'F_${index.toString().padLeft(3, '0')}';

    return FoodLabel(
      index: index,
      imageClass: lower,
      foodId: foodId,
      foodName: foodName,
    );
  }

  static String _titleCase(String text) {
    if (text.isEmpty) return text;
    return text.split(' ').map((word) {
      if (word.isEmpty) return word;
      return word[0].toUpperCase() + word.substring(1).toLowerCase();
    }).join(' ');
  }
}

/// Result of food classification
class FoodClassificationResult {
  final FoodLabel label;
  final double confidence;
  final FoodItem matchedFood;

  const FoodClassificationResult({
    required this.label,
    required this.confidence,
    required this.matchedFood,
  });
}

/// Service to classify food images using TFLite model
class FoodClassifierService {
  FoodClassifierService._();

  static final FoodClassifierService instance = FoodClassifierService._();

  Interpreter? _interpreter;
  List<FoodLabel> _labels = [];
  bool _initialized = false;
  static const int _inputSize = 224;

  Future<void> initialize() async {
    if (_initialized) return;

    try {
      // Load labels from plain text file (one food name per line)
      final labelsText = await rootBundle.loadString('assets/models/labels.txt');
      final lines = labelsText
          .split('\n')
          .map((line) => line.trim())
          .where((line) => line.isNotEmpty)
          .toList();

      _labels = List.generate(
        lines.length,
        (index) => FoodLabel.fromText(
          index: index,
          rawName: lines[index],
        ),
      );

      // Load TFLite model
      final options = InterpreterOptions()..threads = 2;
      _interpreter = await Interpreter.fromAsset(
        'assets/models/food_model.tflite',
        options: options,
      );
      _initialized = true;
    } catch (e) {
      debugPrint('FoodClassifierService initialize error: $e');
      if (_labels.isNotEmpty) {
        _initialized = true;
      }
    }
  }

  bool get isInitialized => _initialized;

  /// Classify an image file
  Future<FoodClassificationResult?> classifyImage(File imageFile) async {
    if (!_initialized) await initialize();
    try {
      final bytes = await imageFile.readAsBytes();
      return await _classifyBytes(bytes);
    } catch (e) {
      debugPrint('Error reading image file: $e');
      return null;
    }
  }

  /// Classify image from camera bytes
  Future<FoodClassificationResult?> classifyCameraImage(Uint8List bytes) async {
    if (!_initialized) await initialize();
    return await _classifyBytes(bytes);
  }

  Future<FoodClassificationResult?> _classifyBytes(Uint8List bytes) async {
    try {
      final decoded = img.decodeImage(bytes);
      if (decoded == null) return null;

      // Ensure correct orientation from camera EXIF
      final oriented = img.bakeOrientation(decoded);

      // Resize to model input size (224x224)
      final resized = img.copyResize(oriented, width: _inputSize, height: _inputSize);

      if (_interpreter != null) {
        // Model expects float32 [0.0, 255.0] unscaled RGB
        // MobileNetV3Large has an internal Rescaling layer ((x / 127.5) - 1.0)
        final input = Float32List(_inputSize * _inputSize * 3);
        int idx = 0;
        for (int y = 0; y < _inputSize; y++) {
          for (int x = 0; x < _inputSize; x++) {
            final pixel = resized.getPixel(x, y);
            input[idx++] = pixel.r.toDouble();
            input[idx++] = pixel.g.toDouble();
            input[idx++] = pixel.b.toDouble();
          }
        }

        // Output tensor shape is [1, num_classes] (239)
        final output = [List<double>.filled(_labels.length, 0.0)];

        try {
          _interpreter!.run(input.buffer, output);
        } catch (runErr) {
          debugPrint('Direct buffer run failed, trying multi-dimensional input: $runErr');
          final input4D = [
            List.generate(
              _inputSize,
              (y) => List.generate(
                _inputSize,
                (x) {
                  final base = (y * _inputSize + x) * 3;
                  return [input[base], input[base + 1], input[base + 2]];
                },
              ),
            ),
          ];
          _interpreter!.run(input4D, output);
        }

        final probs = output[0];
        int maxIdx = 0;
        double maxProb = probs[0];
        for (int i = 1; i < probs.length; i++) {
          if (probs[i] > maxProb) {
            maxProb = probs[i];
            maxIdx = i;
          }
        }

        if (maxIdx < _labels.length) {
          final label = _labels[maxIdx];
          final matchedFood = matchToFoodDatabase(label);
          return FoodClassificationResult(
            label: label,
            confidence: maxProb,
            matchedFood: matchedFood,
          );
        }
      }

      return null;
    } catch (e) {
      debugPrint('Error classifying bytes: $e');
      return null;
    }
  }

  /// Match classified food to database FoodItem
  FoodItem matchToFoodDatabase(FoodLabel label) {
    // 1. First try lookup by food ID in DatasetService
    if (label.foodId.isNotEmpty && !label.foodId.startsWith('F_')) {
      final food = DatasetService.instance.findFoodById(label.foodId);
      if (food != null) return food;
    }

    // 2. Try exact name match against loaded foods
    final lowerName = label.foodName.toLowerCase();
    for (final food in DatasetService.instance.foods) {
      if (food.name.toLowerCase() == lowerName) return food;
    }

    // 3. Try partial / search lookup by food name
    final searchMatches = DatasetService.instance.searchFoods(label.foodName);
    if (searchMatches.isNotEmpty) return searchMatches.first;

    final classMatches = DatasetService.instance.searchFoods(label.imageClass);
    if (classMatches.isNotEmpty) return classMatches.first;

    // 4. Reliable fallback: Always return a complete FoodItem with the identified food name
    return FoodItem(
      id: label.foodId.isNotEmpty ? label.foodId : 'FOOD_${label.index}',
      name: label.foodName,
      servingSize: '1 serving',
      weightGrams: 100,
      carbohydrates: 25,
      protein: 5,
      fat: 5,
      fiber: 2,
      calories: 165,
      glycemicIndex: 55,
      glycemicLabel: 'Medium',
    );
  }

  void dispose() {
    _interpreter?.close();
    _interpreter = null;
    _initialized = false;
  }
}
