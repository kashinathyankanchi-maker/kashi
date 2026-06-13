// Forensic Analyzer Mock Case Data ("Case Alpha" - Bank Robbery Heist)
// Contains raw CSV strings and structured objects representing CDR, TDR, and SDR data.

const MOCK_DATA = {
  // Case info
  caseName: "Case Alpha: Downtown Bank Vault Heist",
  dateOfOccurrence: "2026-06-10",
  description: "Armed robbery of $2.4M cash transit at Downtown Bank Vault on June 10, 2026 at 14:30. Getaway car spotted fleeing north via Highway 4.",

  // Raw CDR Data (Call Detail Records) as CSV
  cdrCsv: `Timestamp,Caller,Recipient,Duration_Sec,Type,Cell_Tower_ID,IMEI,IMSI
2026-06-10 13:02:11,+1-555-0199,+1-555-0102,45,Voice,TWR-Downtown-01,IMEI-883902,IMSI-40401
2026-06-10 13:10:45,+1-555-0102,+1-555-0188,120,Voice,TWR-Downtown-01,IMEI-112233,IMSI-40402
2026-06-10 14:15:30,+1-555-0199,+1-555-0102,18,Voice,TWR-Downtown-01,IMEI-883902,IMSI-40401
2026-06-10 14:20:05,+1-555-0199,+1-555-0144,30,SMS,TWR-Downtown-01,IMEI-883902,IMSI-40401
2026-06-10 14:38:12,+1-555-0199,+1-555-0155,90,Voice,TWR-Highway-04,IMEI-883902,IMSI-40401
2026-06-10 14:45:00,+1-555-0102,+1-555-0188,60,SMS,TWR-Downtown-01,IMEI-112233,IMSI-40402
2026-06-10 15:42:19,+1-555-0199,+1-555-0155,240,Voice,TWR-Industrial-09,IMEI-883902,IMSI-40401
2026-06-10 16:10:05,+1-555-0155,+1-555-0177,15,SMS,TWR-Industrial-09,IMEI-998877,IMSI-40403
2026-06-10 16:15:40,+1-555-0155,+1-555-0199,35,Voice,TWR-Industrial-09,IMEI-998877,IMSI-40403
2026-06-10 17:30:12,+1-555-0199,+1-555-0111,80,Voice,TWR-NorthSuburb-12,IMEI-883902,IMSI-40401
2026-06-10 18:05:44,+1-555-0102,+1-555-0199,10,Voice,TWR-NorthSuburb-12,IMEI-112233,IMSI-40402`,

  // Raw Tower Dump Data (TDR) for the 3 locations
  tdrTowers: [
    {
      id: "TWR-Downtown-01",
      name: "Downtown Bank Tower",
      location: [40.7128, -74.0060],
      dumpCsv: `Timestamp,Phone_Number,IMSI,Signal_DBm
2026-06-10 14:05:12,+1-555-0102,IMSI-40402,-65
2026-06-10 14:10:33,+1-555-0199,IMSI-40401,-70
2026-06-10 14:15:30,+1-555-0199,IMSI-40401,-58
2026-06-10 14:15:30,+1-555-0102,IMSI-40402,-60
2026-06-10 14:20:05,+1-555-0199,IMSI-40401,-62
2026-06-10 14:22:11,+1-555-0104,IMSI-90104,-78
2026-06-10 14:25:50,+1-555-0105,IMSI-90105,-82
2026-06-10 14:30:00,+1-555-0106,IMSI-90106,-75`
    },
    {
      id: "TWR-Highway-04",
      name: "Highway 4 Exit Tollgate",
      location: [40.7850, -73.9682],
      dumpCsv: `Timestamp,Phone_Number,IMSI,Signal_DBm
2026-06-10 14:35:10,+1-555-0108,IMSI-90108,-80
2026-06-10 14:38:12,+1-555-0199,IMSI-40401,-60
2026-06-10 14:41:40,+1-555-0109,IMSI-90109,-85
2026-06-10 14:45:22,+1-555-0110,IMSI-90110,-72`
    },
    {
      id: "TWR-Industrial-09",
      name: "Industrial Area Safehouse",
      location: [40.8322, -73.9120],
      dumpCsv: `Timestamp,Phone_Number,IMSI,Signal_DBm
2026-06-10 15:38:50,+1-555-0112,IMSI-90112,-82
2026-06-10 15:42:19,+1-555-0199,IMSI-40401,-55
2026-06-10 15:42:19,+1-555-0155,IMSI-40403,-57
2026-06-10 16:10:05,+1-555-0155,IMSI-40403,-60
2026-06-10 16:15:40,+1-555-0155,IMSI-40403,-58
2026-06-10 16:15:40,+1-555-0199,IMSI-40401,-59`
    }
  ],

  // Extra tower locations to support mapping path movement
  towerRegistry: {
    "TWR-Downtown-01": { name: "Downtown Bank Tower", lat: 40.7128, lng: -74.0060 },
    "TWR-Highway-04": { name: "Highway 4 Exit Tollgate", lat: 40.7850, lng: -73.9682 },
    "TWR-Industrial-09": { name: "Industrial Area Safehouse", lat: 40.8322, lng: -73.9120 },
    "TWR-NorthSuburb-12": { name: "North Suburb Residential", lat: 40.8992, lng: -73.8744 }
  },

  // Raw SDR Data (Subscriber Detail Records) as array of objects
  sdrDatabase: [
    {
      phone: "+1-555-0199",
      name: "John Doe",
      age: 42,
      gender: "Male",
      address: "42 Elm Street, New York, NY",
      idType: "Passport",
      idNumber: "US-A9840294",
      activationDate: "2024-02-12",
      alternatePhone: "+1-555-9811",
      avatarSeed: "john_doe_avatar",
      role: "Primary Suspect (Getaway Driver)",
      notes: "Prior records of robbery. Matching GPS tower dump presence at all heist locations."
    },
    {
      phone: "+1-555-0102",
      name: "Jane Smith",
      age: 29,
      gender: "Female",
      address: "88 Pine Ave, Apartment 4B, New York, NY",
      idType: "Driver License",
      idNumber: "NY-DL88301",
      activationDate: "2025-05-20",
      alternatePhone: "+1-555-3810",
      avatarSeed: "jane_smith_avatar",
      role: "Suspect B (Inside Informant / Teller)",
      notes: "Bank vault teller. CDR shows communication with getaway driver 15 minutes before the heist."
    },
    {
      phone: "+1-555-0155",
      name: "Robert Chen",
      age: 48,
      gender: "Male",
      address: "12 Maple Blvd, Queens, NY",
      idType: "National ID Card",
      idNumber: "SSN-229-30-221",
      activationDate: "2023-11-05",
      alternatePhone: "+1-555-4019",
      avatarSeed: "robert_chen_avatar",
      role: "Suspect C (The Mastermind)",
      notes: "Financed the safehouse. Met driver right after the escape at Industrial Safehouse."
    },
    {
      phone: "+1-555-0111",
      name: "Pizza Palace Downtown",
      age: "N/A",
      gender: "Business",
      address: "50 Broadway, New York, NY",
      idType: "Business License",
      idNumber: "BUS-88390",
      activationDate: "2018-09-01",
      alternatePhone: "N/A",
      avatarSeed: "pizza_avatar",
      role: "Witness / Regular contact",
      notes: "Local business. Called by driver after the heist for delivery order."
    },
    {
      phone: "+1-555-0144",
      name: "Alice Green",
      age: 31,
      gender: "Female",
      address: "712 Oak Road, Brooklyn, NY",
      idType: "Passport",
      idNumber: "US-B849202",
      activationDate: "2022-04-14",
      alternatePhone: "+1-555-2200",
      avatarSeed: "alice_green_avatar",
      role: "Suspect Associate",
      notes: "Received SMS from John Doe right before the heist. Under investigation."
    },
    {
      phone: "+1-555-0188",
      name: "Mark Johnson",
      age: 35,
      gender: "Male",
      address: "24 Aspen Court, Staten Island, NY",
      idType: "Driver License",
      idNumber: "NY-DL94029",
      activationDate: "2021-08-30",
      alternatePhone: "N/A",
      avatarSeed: "mark_johnson_avatar",
      role: "Unrelated contact",
      notes: "Friend of teller Jane Smith. Called her during the day; no heist links detected."
    }
  ]
};

// Export to window scope if running in browser
if (typeof window !== "undefined") {
  window.MOCK_DATA = MOCK_DATA;
}
