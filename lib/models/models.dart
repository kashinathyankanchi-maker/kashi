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
    // Synonym lookup — exact match first, then partial match
    String findVal(List<String> synonyms) {
      final cleanSyns = synonyms.map((s) => s.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '')).toList();
      // 1. Exact clean match
      for (var key in map.keys) {
        final cleanK = key.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
        if (cleanSyns.contains(cleanK)) return map[key] ?? '';
      }
      // 2. Partial match
      for (var key in map.keys) {
        final kl = key.toLowerCase();
        for (var syn in synonyms) {
          if (kl.contains(syn.toLowerCase().replaceAll(RegExp(r'[^a-z]'), ''))) {
            final v = map[key] ?? '';
            if (v.isNotEmpty) return v;
          }
        }
      }
      return '';
    }

    // ── TIMESTAMP ──────────────────────────────────────────────────────────
    // Handle split date + time columns (common in Indian telecom CDRs)
    final dateStr = findVal(['call_date','calldate','date','call date','start_date','startdate']);
    final timeStr = findVal(['call_initiation_time','call_initia','callinitia','initiation_time','call_time','calltime','time','start_time','starttime']);
    String timestampStr;
    if (dateStr.isNotEmpty && timeStr.isNotEmpty) {
      timestampStr = '$dateStr $timeStr';
    } else {
      timestampStr = findVal(['timestamp','datetime','date_time','date time','call_datetime']);
      if (timestampStr.isEmpty) timestampStr = dateStr.isNotEmpty ? dateStr : timeStr;
    }

    // ── CALLER / RECIPIENT ─────────────────────────────────────────────────
    // Indian CDR: Mobile_No = subscriber, Other_Par = other party
    final mobileNo  = findVal(['mobile_no','mobileno','mobile no','msisdn','cli','a_party','aparty','a_number','anumber','calling_number','calling','caller','caller_num','src','source','from']);
    final otherPar  = findVal(['other_par','otherpar','other_party','otherparty','b_party','bparty','b_number','bnumber','called_number','called','dialed_number','dialled_number','recipient','destination','dest','dst','to']);
    final direction = findVal(['call_type','calltype','call type','direction','type_of_call','typeofcall']);

    final String callerStr;
    final String recipientStr;
    final dirUp = direction.toUpperCase().trim();
    if (dirUp == 'IN' || dirUp == 'INCOMING') {
      callerStr    = otherPar.isNotEmpty ? otherPar : mobileNo;
      recipientStr = mobileNo;
    } else {
      callerStr    = mobileNo;
      recipientStr = otherPar;
    }

    // ── DURATION ───────────────────────────────────────────────────────────
    final durationStr = findVal(['call_duration','callduration','call_durat','calldurat','duration_sec','durationsec','duration_seconds','duration','durat']);

    // ── SERVICE TYPE ───────────────────────────────────────────────────────
    final svcRaw = findVal(['service_type','servicetype','service_ty','servicety','sms_voice']);
    String typeStr;
    if (RegExp(r'sms', caseSensitive: false).hasMatch(svcRaw)) {
      typeStr = 'SMS';
    } else if (RegExp(r'voice|call', caseSensitive: false).hasMatch(svcRaw)) {
      typeStr = 'Voice';
    } else if (RegExp(r'data', caseSensitive: false).hasMatch(svcRaw)) {
      typeStr = 'Data';
    } else if (svcRaw.isNotEmpty) {
      typeStr = svcRaw;
    } else {
      typeStr = 'Voice';
    }

    // ── CELL TOWER ─────────────────────────────────────────────────────────
    final towerIdStr = findVal([
      'first_cell_id','firstcellid','first_cell','firstcell',
      'last_cell_id','lastcellid','last_cell','lastcell',
      'cell_tower_id','celltowerid','tower_id','towerid',
      'cell_id','cellid','cgi','lac','site_id','siteid',
      'location_area','locationarea','bts_id','btsid',
    ]);

    // ── IMEI / IMSI ────────────────────────────────────────────────────────
    final imeiStr = findVal(['imei','imei_number','imeinumber','device_imei','deviceimei','handset_imei']);
    final imsiStr = findVal(['imsi','imsi_number','imsinumber','sim_imsi','simimsi']);

    return CdrRecord(
      timestamp: _parseFlexibleDateTime(timestampStr),
      caller: callerStr,
      recipient: recipientStr,
      durationSec: int.tryParse(durationStr) ?? 0,
      type: typeStr,
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
    // Synonym-based lookup so any real CSV column naming works
    String findVal(List<String> synonyms, {String fallback = ''}) {
      for (var key in map.keys) {
        final cleanK = key.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
        for (var syn in synonyms) {
          if (cleanK == syn.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '')) {
            final val = map[key]?.toString() ?? '';
            if (val.isNotEmpty) return val;
          }
        }
      }
      // Partial match fallback
      for (var key in map.keys) {
        final kl = key.toLowerCase();
        for (var syn in synonyms) {
          if (kl.contains(syn.toLowerCase())) {
            final val = map[key]?.toString() ?? '';
            if (val.isNotEmpty) return val;
          }
        }
      }
      return fallback;
    }

    return SdrProfile(
      phone: findVal(['phone', 'mobile', 'msisdn', 'phone_number', 'contact', 'number', 'phonenumber'], fallback: ''),
      name: findVal(['name', 'subscriber_name', 'full_name', 'fullname', 'subscriber', 'customer_name', 'customername'], fallback: 'Unknown'),
      age: findVal(['age', 'dob', 'date_of_birth', 'dateofbirth', 'birth'], fallback: 'N/A'),
      gender: findVal(['gender', 'sex', 'g'], fallback: 'N/A'),
      address: findVal(['address', 'addr', 'location', 'residence', 'home_address', 'homeaddress'], fallback: 'Unknown'),
      idType: findVal(['idtype', 'id_type', 'identity_type', 'doc_type', 'document_type', 'id_proof'], fallback: 'ID Proof'),
      idNumber: findVal(['idnumber', 'id_number', 'identity_number', 'doc_number', 'document_number', 'id_no'], fallback: 'N/A'),
      activationDate: findVal(['activationdate', 'activation_date', 'sim_activation', 'reg_date', 'registered_date'], fallback: 'N/A'),
      alternatePhone: findVal(['alternatephone', 'alternate_phone', 'alt_phone', 'alt_number', 'secondary_phone'], fallback: 'None'),
      avatarSeed: findVal(['avatarseed', 'avatar_seed', 'avatar', 'photo'], fallback: ''),
      role: findVal(['role', 'type', 'category', 'subject_type', 'relation'], fallback: 'Subject'),
      notes: findVal(['notes', 'remarks', 'comment', 'comments', 'note', 'description', 'details'], fallback: ''),
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
