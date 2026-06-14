import 'package:csv/csv.dart';

class CsvParserService {
  static List<Map<String, String>> parseCsv(String csvText) {
    if (csvText.trim().isEmpty) return [];

    // Strip BOM (byte-order mark) present in many Excel-saved CSV files
    final cleaned = csvText.replaceFirst('\uFEFF', '');

    // Delimiter autodetection on first line
    final firstLine = cleaned.split(RegExp(r'\r\n|\r|\n')).first;
    String fieldDelimiter = ',';
    int maxCount = -1;
    for (var d in [',', ';', '\t', '|']) {
      final count = d.allMatches(firstLine).length;
      if (count > maxCount) {
        maxCount = count;
        fieldDelimiter = d;
      }
    }

    final List<List<dynamic>> rows = CsvToListConverter(
      fieldDelimiter: fieldDelimiter,
      eol: '\n',
    ).convert(cleaned.replaceAll('\r\n', '\n').replaceAll('\r', '\n'));

    
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
