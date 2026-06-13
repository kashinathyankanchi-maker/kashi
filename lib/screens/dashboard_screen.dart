import 'dart:io' show File;
import 'dart:convert' show utf8;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:file_picker/file_picker.dart';
import '../models/models.dart';
import '../state/app_state.dart';
import '../theme.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final state = Provider.of<AppState>(context);

    // Calculate dynamic stats
    final totalCalls = state.cdrRecords.length;
    final totalSdr = state.sdrDatabase.length;
    
    final towers = <String>{};
    for (var c in state.cdrRecords) {
      if (c.towerId.isNotEmpty) towers.add(c.towerId);
    }
    for (var tId in state.tdrData.keys) {
      towers.add(tId);
    }
    final totalTowers = towers.length;
    final totalTdr = state.tdrData.length;

    // Contact frequency sorting
    final Map<String, int> contactCounts = {};
    for (var r in state.cdrRecords) {
      contactCounts[r.caller] = (contactCounts[r.caller] ?? 0) + 1;
      contactCounts[r.recipient] = (contactCounts[r.recipient] ?? 0) + 1;
    }
    final sortedContacts = contactCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final topContacts = sortedContacts.take(5).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Heist Title & Description
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: TacticalTheme.bgSecondary,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white10),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      state.caseName,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: TacticalTheme.accentCyan,
                          ),
                    ),
                    const Chip(
                      label: Text("investigating"),
                      backgroundColor: Colors.redAccent,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  state.caseDescription.isEmpty 
                      ? "No active investigation details loaded. Click 'Load Mock Heist Case' above."
                      : state.caseDescription,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Stats Metrics Row
          LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth;
              final crossAxisCount = width > 900 ? 4 : (width > 600 ? 2 : 1);
              return GridView.count(
                crossAxisCount: crossAxisCount,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                childAspectRatio: 2.2,
                children: [
                  _buildStatCard(
                    title: "CDR Logs",
                    value: totalCalls.toString(),
                    subtitle: "Imported calls",
                    icon: Icons.phone_callback_rounded,
                    accentColor: TacticalTheme.accentCyan,
                  ),
                  _buildStatCard(
                    title: "SDR Profiles",
                    value: totalSdr.toString(),
                    subtitle: "Rostered subscribers",
                    icon: Icons.person_search_rounded,
                    accentColor: TacticalTheme.accentRed,
                  ),
                  _buildStatCard(
                    title: "Active Towers",
                    value: totalTowers.toString(),
                    subtitle: "Tracked cell nodes",
                    icon: Icons.cell_tower_rounded,
                    accentColor: TacticalTheme.accentOrange,
                  ),
                  _buildStatCard(
                    title: "TDR Dumps",
                    value: totalTdr.toString(),
                    subtitle: "Tower dump files",
                    icon: Icons.save_rounded,
                    accentColor: TacticalTheme.accentGreen,
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 24),

          // Main CDR table and right sidebar
          LayoutBuilder(
            builder: (context, constraints) {
              final isDesktop = constraints.maxWidth > 900;
              return Flex(
                direction: isDesktop ? Axis.horizontal : Axis.vertical,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // CDR logs table
                  Expanded(
                    flex: isDesktop ? 3 : 0,
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: TacticalTheme.bgSecondary,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white10),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text("Call Detail Records (CDR)", 
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              Row(
                                children: [
                                  TextButton.icon(
                                    icon: const Icon(Icons.upload_file_rounded, size: 16, color: TacticalTheme.accentCyan),
                                    label: const Text("Upload CSV", style: TextStyle(fontSize: 12, color: Colors.white70)),
                                    onPressed: () async {
                                      FilePickerResult? result = await FilePicker.platform.pickFiles(
                                        type: FileType.custom,
                                        allowedExtensions: ['csv'],
                                        withData: true,
                                      );
                                      if (result != null) {
                                        final file = result.files.single;
                                        if (file.bytes != null) {
                                          final csvText = utf8.decode(file.bytes!);
                                          state.importCdr(csvText);
                                        } else if (file.path != null) {
                                          final csvText = await File(file.path!).readAsString();
                                          state.importCdr(csvText);
                                        }
                                      }
                                    },
                                  ),
                                  const SizedBox(width: 8),
                                  TextButton.icon(
                                    icon: const Icon(Icons.picture_as_pdf_rounded, size: 16, color: TacticalTheme.accentCyan),
                                    label: const Text("Upload PDF", style: TextStyle(fontSize: 12, color: Colors.white70)),
                                    onPressed: () async {
                                      FilePickerResult? result = await FilePicker.platform.pickFiles(
                                        type: FileType.custom,
                                        allowedExtensions: ['pdf'],
                                        withData: true,
                                      );
                                      if (result != null) {
                                        final file = result.files.single;
                                        if (file.bytes != null) {
                                          state.importPdf(file.bytes!);
                                        } else if (file.path != null) {
                                          final pdfBytes = await File(file.path!).readAsBytes();
                                          state.importPdf(pdfBytes);
                                        }
                                      }
                                    },
                                  ),
                                  const SizedBox(width: 8),
                                  TextButton.icon(
                                    icon: const Icon(Icons.cell_tower_rounded, size: 16, color: TacticalTheme.accentCyan),
                                    label: const Text("Upload Towers", style: TextStyle(fontSize: 12, color: Colors.white70)),
                                    onPressed: () async {
                                      FilePickerResult? result = await FilePicker.platform.pickFiles(
                                        type: FileType.custom,
                                        allowedExtensions: ['csv'],
                                        withData: true,
                                      );
                                      if (result != null) {
                                        final file = result.files.single;
                                        if (file.bytes != null) {
                                          final csvText = utf8.decode(file.bytes!);
                                          state.importTowerRegistry(csvText);
                                        } else if (file.path != null) {
                                          final csvText = await File(file.path!).readAsString();
                                          state.importTowerRegistry(csvText);
                                        }
                                      }
                                    },
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          state.cdrRecords.isEmpty
                              ? const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 48.0),
                                  child: Center(
                                    child: Text("No records loaded. Use actions above to load a dataset."),
                                  ),
                                )
                              : SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  child: DataTable(
                                    columns: const [
                                      DataColumn(label: Text('Timestamp')),
                                      DataColumn(label: Text('Caller')),
                                      DataColumn(label: Text('Recipient')),
                                      DataColumn(label: Text('Duration')),
                                      DataColumn(label: Text('Type')),
                                      DataColumn(label: Text('Tower ID')),
                                    ],
                                    rows: state.cdrRecords.map((r) {
                                      final isSuspect = state.selectedNumber != null && 
                                          (r.caller == state.selectedNumber || r.recipient == state.selectedNumber);
                                      return DataRow(
                                        color: MaterialStateProperty.resolveWith<Color?>(
                                          (states) => isSuspect ? Colors.red.withOpacity(0.12) : null,
                                        ),
                                        cells: [
                                          DataCell(Text(DateFormat('yyyy-MM-dd HH:mm:ss').format(r.timestamp))),
                                          DataCell(
                                            GestureDetector(
                                              onTap: () => state.setSelectedNumber(r.caller),
                                              child: Text(
                                                r.caller,
                                                style: const TextStyle(
                                                  color: TacticalTheme.accentCyan,
                                                  fontWeight: FontWeight.bold,
                                                  decoration: TextDecoration.underline,
                                                ),
                                              ),
                                            ),
                                          ),
                                          DataCell(
                                            GestureDetector(
                                              onTap: () => state.setSelectedNumber(r.recipient),
                                              child: Text(
                                                r.recipient,
                                                style: const TextStyle(
                                                  color: TacticalTheme.accentCyan,
                                                  fontWeight: FontWeight.bold,
                                                  decoration: TextDecoration.underline,
                                                ),
                                              ),
                                            ),
                                          ),
                                          DataCell(Text('${r.durationSec}s')),
                                          DataCell(Text(r.type)),
                                          DataCell(Text(r.towerId)),
                                        ],
                                      );
                                    }).toList(),
                                  ),
                                ),
                        ],
                      ),
                    ),
                  ),

                  if (isDesktop) const SizedBox(width: 24),
                  if (!isDesktop) const SizedBox(height: 24),

                  // Right heatlist sidebar
                  Expanded(
                    flex: isDesktop ? 1 : 0,
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: TacticalTheme.bgSecondary,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white10),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Top Contacts Heatlist", 
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 16),
                          topContacts.isEmpty
                              ? const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 20.0),
                                  child: Center(
                                    child: Text("No data"),
                                  ),
                                )
                              : ListView.separated(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemCount: topContacts.length,
                                  separatorBuilder: (_, __) => const Divider(color: Colors.white10),
                                  itemBuilder: (context, idx) {
                                    final number = topContacts[idx].key;
                                    final count = topContacts[idx].value;
                                    final isTarget = state.selectedNumber == number;
                                    
                                    // Cross ref
                                    final sdr = state.sdrDatabase.firstWhere((s) => s.phone == number, orElse: () => SdrProfile(
                                      phone: number, name: 'Unknown Subject', age: '', gender: '', address: '',
                                      idType: '', idNumber: '', activationDate: '', alternatePhone: '', avatarSeed: '', role: 'Contact', notes: '',
                                    ));

                                    return ListTile(
                                      contentPadding: EdgeInsets.zero,
                                      title: Text(number, style: TextStyle(
                                        color: isTarget ? TacticalTheme.accentRed : TacticalTheme.accentCyan,
                                        fontWeight: FontWeight.bold,
                                      )),
                                      subtitle: Text('${sdr.name} (${sdr.role})', style: const TextStyle(fontSize: 12)),
                                      trailing: Chip(
                                        label: Text('$count calls'),
                                        backgroundColor: TacticalTheme.bgCard,
                                      ),
                                      onTap: () => state.setSelectedNumber(number),
                                    );
                                  },
                                ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color accentColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: TacticalTheme.bgSecondary,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: accentColor.withOpacity(0.08),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: accentColor, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title.toUpperCase(),
                  style: const TextStyle(color: TacticalTheme.textMuted, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1),
                ),
                Text(
                  value,
                  style: const TextStyle(color: TacticalTheme.textMain, fontSize: 20, fontWeight: FontWeight.bold),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(color: TacticalTheme.textDim, fontSize: 11),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
