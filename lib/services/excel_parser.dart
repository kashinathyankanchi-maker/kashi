import 'package:excel/excel.dart';

/// Service to parse .xlsx / .xls files into a list of row maps.
/// Works the same as CsvParserService so the same column normalizers apply.
class ExcelParserService {
  /// Parses the first sheet of an Excel workbook.
  /// Returns a list of row maps where keys are the header row values.
  static List<Map<String, String>> parseExcel(List<int> bytes) {
    try {
      final excel = Excel.decodeBytes(bytes);

      // Use the first available sheet
      final sheetName = excel.tables.keys.firstOrNull;
      if (sheetName == null) return [];

      final sheet = excel.tables[sheetName];
      if (sheet == null || sheet.rows.isEmpty) return [];

      // First row is headers
      final headerRow = sheet.rows.first;
      final headers = headerRow
          .map((cell) => cell?.value?.toString().trim() ?? '')
          .toList();

      if (headers.isEmpty || headers.every((h) => h.isEmpty)) return [];

      final List<Map<String, String>> results = [];

      // Parse data rows (skip header row at index 0)
      for (int i = 1; i < sheet.rows.length; i++) {
        final row = sheet.rows[i];

        // Skip completely empty rows
        final rowValues = row.map((c) => c?.value?.toString().trim() ?? '').toList();
        if (rowValues.every((v) => v.isEmpty)) continue;

        final Map<String, String> obj = {};
        for (int j = 0; j < headers.length; j++) {
          if (headers[j].isNotEmpty) {
            obj[headers[j]] = j < rowValues.length ? rowValues[j] : '';
          }
        }
        results.add(obj);
      }

      return results;
    } catch (e) {
      // Return empty list on any parse failure
      return [];
    }
  }
}
