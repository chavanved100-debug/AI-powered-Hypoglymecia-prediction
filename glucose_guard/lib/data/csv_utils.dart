class CsvTable {
  const CsvTable({required this.headers, required this.rows});

  final List<String> headers;
  final List<List<String>> rows;

  static CsvTable parse(String raw) {
    final lines = raw.split(RegExp(r'\r?\n'));
    List<String>? headers;
    final rows = <List<String>>[];

    for (final line in lines) {
      if (line.trim().isEmpty) continue;
      final cells = line.split(',').map((c) => c.trim()).toList();
      if (cells.every((c) => c.isEmpty)) continue;
      if (headers == null) {
        headers = cells;
        continue;
      }
      if (_isRepeatHeader(headers, cells)) continue;
      rows.add(cells);
    }

    return CsvTable(headers: headers ?? const [], rows: rows);
  }

  static bool _isRepeatHeader(List<String> headers, List<String> cells) {
    if (headers.isEmpty || cells.isEmpty) return false;
    return cells.first.toLowerCase() == headers.first.toLowerCase();
  }

  int indexOf(String column) {
    final lower = column.toLowerCase();
    return headers.indexWhere((h) => h.toLowerCase() == lower);
  }

  String value(List<String> row, String column) {
    final index = indexOf(column);
    if (index < 0 || index >= row.length) return '';
    return row[index];
  }

  double number(List<String> row, String column, {double fallback = 0}) {
    return double.tryParse(value(row, column)) ?? fallback;
  }
}

enum DatasetKind { foodNutrition, mealReference, quantityMapping, unknown }

DatasetKind classifyCsv(CsvTable table) {
  final headers = table.headers.map((h) => h.toLowerCase()).toSet();
  if (headers.contains('food_id') && headers.contains('food_name')) {
    return DatasetKind.foodNutrition;
  }
  if (headers.contains('meal_id') && headers.contains('glycemic_load')) {
    return DatasetKind.mealReference;
  }
  if (headers.contains('quantity_id') && headers.contains('multiplier')) {
    return DatasetKind.quantityMapping;
  }
  return DatasetKind.unknown;
}

String servingUnitFrom(String servingSize) {
  final parts = servingSize.toLowerCase().trim().split(RegExp(r'\s+'));
  if (parts.isEmpty) return 'serving';
  var unit = parts.last;
  const singular = {
    'pieces': 'piece',
    'bowls': 'bowl',
    'plates': 'plate',
    'cups': 'cup',
    'glasses': 'glass',
    'slices': 'slice',
    'servings': 'serving',
    'portions': 'portion',
    'handfuls': 'handful',
    'spoons': 'spoon',
    'tablespoons': 'tbsp',
    'teaspoons': 'tsp',
    'ladles': 'ladle',
    'scoops': 'scoop',
    'mugs': 'mug',
    'bottles': 'bottle',
    'packets': 'packet',
    'grams': 'gram',
    'g': 'gram',
  };
  unit = singular[unit] ?? unit;
  if (unit == 'medium' || unit == 'small' || unit == 'large') {
    return 'piece';
  }
  return unit;
}
