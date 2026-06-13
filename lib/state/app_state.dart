import 'package:flutter/foundation.dart';
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
}
