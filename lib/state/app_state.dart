import 'package:flutter/foundation.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import '../models/models.dart';
import '../services/csv_parser.dart';
import '../services/mock_case.dart';

class AppState with ChangeNotifier {
  String _caseName = 'No Active Case';
  String _caseDescription = '';
  List<CdrRecord> _cdrRecords = [];
  List<SdrProfile> _sdrDatabase = [];
  final Map<String, List<TowerDumpRecord>> _tdrData = {};
  String? _selectedNumber;

  // Selected towers for TDR intersection
  final Set<String> _selectedTowers = {};
  List<Map<String, dynamic>> _intersectionResults = [];

  // Getters
  String get caseName => _caseName;
  String get caseDescription => _caseDescription;
  List<CdrRecord> get cdrRecords => _cdrRecords;
  List<SdrProfile> get sdrDatabase => _sdrDatabase;
  Map<String, List<TowerDumpRecord>> get tdrData => _tdrData;
  String? get selectedNumber => _selectedNumber;
  Set<String> get selectedTowers => _selectedTowers;
  List<Map<String, dynamic>> get intersectionResults => _intersectionResults;

  // Set suspect under investigation
  void setSelectedNumber(String? number) {
    _selectedNumber = number;
    notifyListeners();
  }

  // Load standard mock heist case study
  void loadMockCase() {
    _caseName = MockCaseData.caseName;
    _caseDescription = MockCaseData.description;

    // Parse CDR
    final parsedCdr = CsvParserService.parseCsv(MockCaseData.cdrCsv);
    _cdrRecords = parsedCdr.map((map) => CdrRecord.fromMap(map)).toList();

    // Parse SDR
    _sdrDatabase = MockCaseData.sdrDatabase.map((map) => SdrProfile.fromMap(map)).toList();

    // Parse TDR
    _tdrData.clear();
    _selectedTowers.clear();
    for (var t in MockCaseData.tdrTowers) {
      final tId = t['id'].toString();
      final parsedTdr = CsvParserService.parseCsv(t['dumpCsv'].toString());
      _tdrData[tId] = parsedTdr.map((map) => TowerDumpRecord.fromMap(map)).toList();
      _selectedTowers.add(tId); // Check by default
    }

    _intersectionResults.clear();
    _selectedNumber = "+1-555-0199"; // Default trace to getaway driver

    notifyListeners();
  }

  // Clear case
  void clearCase() {
    _caseName = 'No Active Case';
    _caseDescription = '';
    _cdrRecords.clear();
    _sdrDatabase.clear();
    _tdrData.clear();
    _selectedTowers.clear();
    _intersectionResults.clear();
    _selectedNumber = null;
    notifyListeners();
  }

  // Toggle tower selection for intersection
  void toggleTowerSelection(String towerId) {
    if (_selectedTowers.contains(towerId)) {
      _selectedTowers.remove(towerId);
    } else {
      _selectedTowers.add(towerId);
    }
    notifyListeners();
  }

  // Run TDR Intersection Analysis
  void runIntersection() {
    if (_selectedTowers.length < 2) return;

    final Map<String, Set<String>> phonePresence = {};

    for (var tId in _selectedTowers) {
      final records = _tdrData[tId] ?? [];
      for (var rec in records) {
        final phone = rec.phoneNumber;
        if (phone.isNotEmpty) {
          phonePresence.putIfAbsent(phone, () => {}).add(tId);
        }
      }
    }

    final List<Map<String, dynamic>> results = [];
    phonePresence.forEach((phone, presenceSet) {
      if (presenceSet.length == _selectedTowers.length) {
        // Find SDR profile
        final sdr = _sdrDatabase.firstWhere(
          (s) => s.phone == phone,
          orElse: () => SdrProfile(
            phone: phone,
            name: 'Unknown',
            age: 'N/A',
            gender: 'N/A',
            address: 'Unknown',
            idType: 'None',
            idNumber: 'N/A',
            activationDate: 'N/A',
            alternatePhone: 'None',
            avatarSeed: '',
            role: 'Unknown',
            notes: 'No matching SDR profile found.',
          ),
        );

        results.add({
          'phone': phone,
          'sdr': sdr,
          'matches': presenceSet.length,
        });
      }
    });

    _intersectionResults = results;
    notifyListeners();
  }

  // Import uploaded CDR
  void importCdr(String csvText) {
    final parsed = CsvParserService.parseCsv(csvText);
    _cdrRecords = parsed.map((m) => CdrRecord.fromMap(m)).toList();
    notifyListeners();
  }

  // Import uploaded SDR
  void importSdr(String csvText) {
    final parsed = CsvParserService.parseCsv(csvText);
    _sdrDatabase = parsed.map((m) => SdrProfile.fromMap(m)).toList();
    notifyListeners();
  }

  // Import uploaded TDR
  void importTdr(String towerId, String csvText) {
    final parsed = CsvParserService.parseCsv(csvText);
    _tdrData[towerId] = parsed.map((m) => TowerDumpRecord.fromMap(m)).toList();
    _selectedTowers.add(towerId);
    notifyListeners();
  }

  // Import uploaded cell tower coordinates registry
  void importTowerRegistry(String csvText) {
    final parsed = CsvParserService.parseCsv(csvText);
    for (var row in parsed) {
      final idKey = row.keys.firstWhere(
        (k) => k.toLowerCase() == 'cell_tower_id' || k.toLowerCase() == 'tower_id' || k.toLowerCase() == 'id',
        orElse: () => '',
      );
      final nameKey = row.keys.firstWhere(
        (k) => k.toLowerCase() == 'tower_name' || k.toLowerCase() == 'name',
        orElse: () => '',
      );
      final latKey = row.keys.firstWhere(
        (k) => k.toLowerCase() == 'latitude' || k.toLowerCase() == 'lat',
        orElse: () => '',
      );
      final lngKey = row.keys.firstWhere(
        (k) => k.toLowerCase() == 'longitude' || k.toLowerCase() == 'lng' || k.toLowerCase() == 'lon',
        orElse: () => '',
      );

      if (idKey.isNotEmpty && latKey.isNotEmpty && lngKey.isNotEmpty) {
        final id = row[idKey] ?? '';
        final name = nameKey.isNotEmpty ? (row[nameKey] ?? '') : 'Tower $id';
        final lat = double.tryParse(row[latKey] ?? '');
        final lng = double.tryParse(row[lngKey] ?? '');
        if (id.isNotEmpty && lat != null && lng != null) {
          MockCaseData.towerRegistry[id] = {
            'name': name,
            'lat': lat,
            'lng': lng,
          };
        }
      }
    }
    notifyListeners();
  }

  // Import uploaded PDF
  void importPdf(List<int> bytes) {
    try {
      final PdfDocument document = PdfDocument(inputBytes: bytes);
      final PdfTextExtractor extractor = PdfTextExtractor(document);
      final String fullText = extractor.extractText();
      document.dispose();
      
      final parsed = _parseCdrFromText(fullText);
      if (parsed.isNotEmpty) {
        _cdrRecords = parsed.map((m) => CdrRecord.fromMap(m)).toList();
        _selectedNumber = "+1-555-0199"; // Default trace to getaway driver
        notifyListeners();
      }
    } catch (err) {
      print("Error extracting PDF text: $err");
    }
  }

  List<Map<String, String>> _parseCdrFromText(String text) {
    final lines = text.split('\n');
    final List<Map<String, String>> records = [];
    
    final dateRegex = RegExp(
      r'\b\d{1,4}[-/.]\d{1,2}[-/.]\d{1,4}\b|\b\d{1,2}[-/.\s](?:Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)[a-z]*[-/.\s]\d{2,4}\b|\b(?:Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)[a-z]*[-/.\s]\d{1,2}[-,/.\s]+\d{2,4}\b',
      caseSensitive: false,
    );
    final timeRegex = RegExp(r'\b\d{1,2}:\d{2}(?::\d{2})?(?:\s*[APap][Mm])?\b');
    final candidateRegex = RegExp(r'\+?[\d\s-]{7,20}');

    for (var line in lines) {
      final trimmed = line.trim();
      if (trimmed.isEmpty) continue;
      
      final dateMatch = dateRegex.firstMatch(trimmed);
      final timeMatch = timeRegex.firstMatch(trimmed);
      if (dateMatch == null || timeMatch == null) continue;
      
      final timestamp = "${dateMatch.group(0)} ${timeMatch.group(0)}";
      
      // Remove date and time to prevent collision
      var lineForPhones = trimmed
          .replaceAll(dateMatch.group(0)!, ' ')
          .replaceAll(timeMatch.group(0)!, ' ');
      
      final Iterable<RegExpMatch> phoneMatches = candidateRegex.allMatches(lineForPhones);
      final List<String> cleanPhones = [];
      for (var m in phoneMatches) {
        final val = m.group(0) ?? '';
        final digits = val.replaceAll(RegExp(r'\D'), '');
        if (digits.length >= 7 && digits.length <= 14) {
          cleanPhones.add(val.trim());
        }
      }
      if (cleanPhones.isEmpty) continue;
      
      final caller = cleanPhones[0];
      final recipient = cleanPhones.length > 1 ? cleanPhones[1] : 'Unknown';
      
      // Duration
      int durationSec = 45;
      final durationWordMatch = RegExp(r'\b(\d+)\s*(?:s|sec|seconds)\b', caseSensitive: false).firstMatch(trimmed);
      if (durationWordMatch != null) {
        durationSec = int.tryParse(durationWordMatch.group(1) ?? '45') ?? 45;
      } else {
        final possibleNums = RegExp(r'\b\d{1,4}\b').allMatches(lineForPhones).map((m) => m.group(0) ?? '').toList();
        for (var num in possibleNums) {
          final parsedNum = int.tryParse(num) ?? 0;
          if (parsedNum > 0 && parsedNum < 7200) {
            durationSec = parsedNum;
            break;
          }
        }
      }
      
      // Type
      String type = 'Voice';
      if (RegExp(r'\b(SMS|TEXT|MESSAGE|MSG)\b', caseSensitive: false).hasMatch(trimmed)) {
        type = 'SMS';
      }
      
      // Tower ID
      String towerId = 'TWR-Unknown';
      final towerMatch = RegExp(r'\b(TWR-[\w-]+|Cell-[\w-]+)\b', caseSensitive: false).firstMatch(trimmed);
      if (towerMatch != null) {
        towerId = towerMatch.group(0) ?? 'TWR-Unknown';
      } else {
        // Fallback checks
        for (var key in MockCaseData.towerRegistry.keys) {
          if (trimmed.contains(key)) {
            towerId = key;
            break;
          }
        }
      }
      
      records.add({
        'Timestamp': timestamp,
        'Caller': caller,
        'Recipient': recipient,
        'Duration_Sec': durationSec.toString(),
        'Type': type,
        'Cell_Tower_ID': towerId,
        'IMEI': 'N/A',
        'IMSI': 'N/A'
      });
    }
    
    return records;
  }
}
