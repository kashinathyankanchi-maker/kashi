// Dart Models for Forensic Analyzer

DateTime _parseFlexibleDateTime(String input) {
  final clean = input.trim();
  if (clean.isEmpty) return DateTime.now();

  final parsed = DateTime.tryParse(clean);
  if (parsed != null) return parsed;

  try {
    final parts = clean.split(RegExp(r'\s+'));
    if (parts.isNotEmpty) {
      final datePart = parts[0];
      final timePart = parts.length > 1 ? parts[1] : '00:00:00';
      
      final datePieces = datePart.split(RegExp(r'[-/.]'));
      if (datePieces.length == 3) {
        String year, month, day;
        if (datePieces[0].length == 4) {
          year = datePieces[0];
          month = datePieces[1];
          day = datePieces[2];
        } else {
          day = datePieces[0].padLeft(2, '0');
          month = datePieces[1];
          year = datePieces[2];
          if (year.length == 2) {
            year = "20$year";
          }
        }
        
        final monthsMap = {
          'jan': '01', 'feb': '02', 'mar': '03', 'apr': '04', 'may': '05', 'jun': '06',
          'jul': '07', 'aug': '08', 'sep': '09', 'oct': '10', 'nov': '11', 'dec': '12'
        };
        final mLower = month.toLowerCase();
        for (var entry in monthsMap.entries) {
          if (mLower.startsWith(entry.key)) {
            month = entry.value;
            break;
          }
        }
        month = month.padLeft(2, '0');
        
        final normalizedIso = "$year-$month-$day $timePart";
        final finalParsed = DateTime.tryParse(normalizedIso);
        if (finalParsed != null) return finalParsed;
      }
    }
  } catch (_) {}

  return DateTime.now();
}

class CdrRecord {
  final DateTime timestamp;
  final String caller;
  final String recipient;
  final int durationSec;
  final String type;
  final String towerId;
  final String imei;
  final String imsi;

  CdrRecord({
    required this.timestamp,
    required this.caller,
    required this.recipient,
    required this.durationSec,
    required this.type,
    required this.towerId,
    required this.imei,
    required this.imsi,
  });

  factory CdrRecord.fromMap(Map<String, String> map) {
    String findVal(List<String> synonyms) {
      for (var key in map.keys) {
        final cleanK = key.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
        for (var syn in synonyms) {
          if (cleanK == syn.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '')) {
            return map[key] ?? '';
          }
        }
      }
      return '';
    }

    var timestampStr = findVal(['timestamp', 'datetime', 'date_time', 'date time', 'date', 'time', 'call_time', 'call date', 'calldate', 'setup_time', 'start_time', 'start time']);
    if (timestampStr.isEmpty) {
      for (var key in map.keys) {
        if (key.toLowerCase().contains('date') || key.toLowerCase().contains('time')) {
          timestampStr = map[key] ?? '';
          break;
        }
      }
    }

    var callerStr = findVal(['caller', 'calling_number', 'calling number', 'calling', 'caller_num', 'src', 'source', 'source_number', 'from', 'a_number', 'msisdn_a', 'msisdn']);
    if (callerStr.isEmpty) {
      for (var key in map.keys) {
        if (key.toLowerCase().contains('call') || key.toLowerCase().contains('from') || key.toLowerCase().contains('src')) {
          callerStr = map[key] ?? '';
          break;
        }
      }
    }

    var recipientStr = findVal(['recipient', 'recipient_number', 'recipient number', 'dialed_number', 'dialed number', 'dialled_number', 'dialled number', 'dst', 'destination', 'dest', 'to', 'b_number', 'msisdn_b']);
    if (recipientStr.isEmpty) {
      for (var key in map.keys) {
        if (key.toLowerCase().contains('recip') || key.toLowerCase().contains('to') || key.toLowerCase().contains('dest') || key.toLowerCase().contains('dst')) {
          recipientStr = map[key] ?? '';
          break;
        }
      }
    }

    final durationSecStr = findVal(['duration_sec', 'duration sec', 'duration', 'duration_seconds', 'duration seconds', 'duration_min', 'duration(sec)', 'call_duration', 'call duration']);
    final typeStr = findVal(['type', 'call_type', 'call type', 'event_type', 'event type', 'sms/call', 'direction']);
    final towerIdStr = findVal(['cell_tower_id', 'cell tower id', 'tower_id', 'tower id', 'cell_id', 'cell id', 'cgi', 'lac', 'location', 'site_id', 'site id', 'tower', 'cell']);
    final imeiStr = findVal(['imei', 'imei_number', 'device_imei']);
    final imsiStr = findVal(['imsi', 'imsi_number', 'sim_imsi']);

    return CdrRecord(
      timestamp: _parseFlexibleDateTime(timestampStr),
      caller: callerStr,
      recipient: recipientStr,
      durationSec: int.tryParse(durationSecStr) ?? 0,
      type: typeStr.isEmpty ? 'Voice' : typeStr,
      towerId: towerIdStr.isEmpty ? 'TWR-Unknown' : towerIdStr,
      imei: imeiStr.isEmpty ? 'N/A' : imeiStr,
      imsi: imsiStr.isEmpty ? 'N/A' : imsiStr,
    );
  }
}

class SdrProfile {
  final String phone;
  final String name;
  final String age;
  final String gender;
  final String address;
  final String idType;
  final String idNumber;
  final String activationDate;
  final String alternatePhone;
  final String avatarSeed;
  final String role;
  final String notes;

  SdrProfile({
    required this.phone,
    required this.name,
    required this.age,
    required this.gender,
    required this.address,
    required this.idType,
    required this.idNumber,
    required this.activationDate,
    required this.alternatePhone,
    required this.avatarSeed,
    required this.role,
    required this.notes,
  });

  factory SdrProfile.fromMap(Map<String, dynamic> map) {
    return SdrProfile(
      phone: map['phone']?.toString() ?? '',
      name: map['name']?.toString() ?? 'Unknown',
      age: map['age']?.toString() ?? 'N/A',
      gender: map['gender']?.toString() ?? 'N/A',
      address: map['address']?.toString() ?? 'Unknown',
      idType: map['idType']?.toString() ?? 'ID Proof',
      idNumber: map['idNumber']?.toString() ?? 'N/A',
      activationDate: map['activationDate']?.toString() ?? 'N/A',
      alternatePhone: map['alternatePhone']?.toString() ?? 'None',
      avatarSeed: map['avatarSeed']?.toString() ?? '',
      role: map['role']?.toString() ?? 'Subject',
      notes: map['notes']?.toString() ?? '',
    );
  }
}

class TowerDumpRecord {
  final DateTime timestamp;
  final String phoneNumber;
  final String imsi;
  final int signalDbm;

  TowerDumpRecord({
    required this.timestamp,
    required this.phoneNumber,
    required this.imsi,
    required this.signalDbm,
  });

  factory TowerDumpRecord.fromMap(Map<String, String> map) {
    String findVal(List<String> synonyms) {
      for (var key in map.keys) {
        final cleanK = key.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
        for (var syn in synonyms) {
          if (cleanK == syn.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '')) {
            return map[key] ?? '';
          }
        }
      }
      return '';
    }

    final timestampStr = findVal(['timestamp', 'datetime', 'date_time', 'date time', 'date', 'time', 'call_time']);
    final phoneStr = findVal(['phone_number', 'phone number', 'phone', 'number', 'mobile', 'msisdn']);
    final imsiStr = findVal(['imsi', 'imsi_number']);
    final signalStr = findVal(['signal_dbm', 'signal dbm', 'signal', 'power', 'dbm']);

    return TowerDumpRecord(
      timestamp: _parseFlexibleDateTime(timestampStr),
      phoneNumber: phoneStr,
      imsi: imsiStr.isEmpty ? 'N/A' : imsiStr,
      signalDbm: int.tryParse(signalStr) ?? -70,
    );
  }
}
