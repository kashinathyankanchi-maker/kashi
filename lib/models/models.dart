// Dart Models for Forensic Analyzer

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
    return CdrRecord(
      timestamp: DateTime.tryParse(map['Timestamp'] ?? '') ?? DateTime.now(),
      caller: map['Caller'] ?? '',
      recipient: map['Recipient'] ?? '',
      durationSec: int.tryParse(map['Duration_Sec'] ?? '0') ?? 0,
      type: map['Type'] ?? 'Voice',
      towerId: map['Cell_Tower_ID'] ?? '',
      imei: map['IMEI'] ?? '',
      imsi: map['IMSI'] ?? '',
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
    return TowerDumpRecord(
      timestamp: DateTime.tryParse(map['Timestamp'] ?? '') ?? DateTime.now(),
      phoneNumber: map['Phone_Number'] ?? '',
      imsi: map['IMSI'] ?? '',
      signalDbm: int.tryParse(map['Signal_DBm'] ?? '0') ?? 0,
    );
  }
}
