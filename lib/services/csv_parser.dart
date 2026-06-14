import 'package:csv/csv.dart';

class CsvParserService {
  // CDR header keywords used to detect the real header row
  // (skips metadata lines at the top of Indian telecom CDR files)
  static const _headerKeywords = [
    'sl_no', 'slno', 'serial', 'sno',
    'mobile_no', 'mobileno', 'msisdn', 'cli', 'calling', 'caller',
    'other_par', 'otherpar', 'b_party', 'bparty', 'called', 'dialed', 'recipient',
    'call_type', 'calltype', 'direction',
    'call_date', 'calldate', 'date', 'datetime', 'timestamp',
    'call_initia', 'callinitia', 'call_time', 'calltime', 'time',
    'call_durat', 'calldurat', 'duration',
    'service_ty', 'servicety', 'service_type',
    'first_cell', 'firstcell', 'last_cell', 'lastcell', 'cell_id', 'cellid', 'cgi',
    'imei', 'imsi',
  ];

  static int _scoreRow(List<String> cells) {
    int score = 0;
    for (final cell in cells) {
      final c = cell.toLowerCase().replaceAll(RegExp(r'[^a-z0-9_]'), '');
      for (final kw in _headerKeywords) {
        if (c == kw || c.startsWith(kw) || kw.startsWith(c)) {
          score++;
          break;
        }
      }
    }
    return score;
  }

  static List<Map<String, String>> parseCsv(String csvText) {
    if (csvText.trim().isEmpty) return [];

    // Strip BOM (byte-order mark) present in many Excel-saved CSV files
    final cleaned = csvText.replaceFirst('\uFEFF', '');

    // Normalize all line endings
    final normalized = cleaned.replaceAll('\r\n', '\n').replaceAll('\r', '\n');

    // Detect delimiter using best-split line from first 20 rows
    final allLines = normalized.split('\n').where((l) => l.trim().isNotEmpty).toList();
    if (allLines.isEmpty) return [];

    String fieldDelimiter = ',';
    int maxCount = -1;
    for (final line in allLines.take(20)) {
      for (final d in [',', ';', '\t', '|']) {
        final count = d.allMatches(line).length;
        if (count > maxCount) { maxCount = count; fieldDelimiter = d; }
      }
    }

    // Parse all rows
    final List<List<dynamic>> rows = CsvToListConverter(
      fieldDelimiter: fieldDelimiter,
      eol: '\n',
    ).convert(normalized);

    if (rows.isEmpty) return [];

    // Find the actual header row by scoring each of the first 25 rows
    int headerIndex = 0;
    int bestScore   = -1;
    final scanLimit = rows.length < 25 ? rows.length : 25;
    for (int i = 0; i < scanLimit; i++) {
      final cells = rows[i].map((c) => c?.toString().trim() ?? '').toList();
      final score = _scoreRow(cells);
      if (score > bestScore) { bestScore = score; headerIndex = i; }
      if (score >= 4) break; // confident enough
    }

    final headers = rows[headerIndex].map((h) => h?.toString().trim() ?? '').toList();
    final List<Map<String, String>> results = [];

    for (int i = headerIndex + 1; i < rows.length; i++) {
      final row = rows[i];
      if (row.isEmpty || row.every((c) => (c?.toString() ?? '').trim().isEmpty)) continue;

      final Map<String, String> obj = {};
      for (int j = 0; j < headers.length; j++) {
        if (headers[j].isNotEmpty) {
          final val = j < row.length ? row[j]?.toString() ?? '' : '';
          obj[headers[j]] = val.trim();
        }
      }
      results.add(obj);
    }

    return results;
  }
}
