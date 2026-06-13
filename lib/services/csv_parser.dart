import 'package:csv/csv.dart';

class CsvParserService {
  static List<Map<String, String>> parseCsv(String csvText) {
    if (csvText.trim().isEmpty) return [];

    final List<List<dynamic>> rows = const CsvToListConverter().convert(csvText);
    if (rows.isEmpty) return [];

    final headers = rows[0].map((h) => h.toString().trim()).toList();
    final List<Map<String, String>> results = [];

    for (int i = 1; i < rows.length; i++) {
      final row = rows[i];
      if (row.isEmpty || (row.length == 1 && row[0] == null)) continue;
      
      final Map<String, String> obj = {};
      for (int j = 0; j < headers.length; j++) {
        final val = j < row.length ? row[j]?.toString() ?? '' : '';
        obj[headers[j]] = val.trim();
      }
      results.add(obj);
    }

    return results;
  }
}
