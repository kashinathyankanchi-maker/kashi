import 'dart:io' show File;
import 'dart:convert' show utf8;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import '../state/app_state.dart';
import '../theme.dart';

class TdrScreen extends StatelessWidget {
  const TdrScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final state = Provider.of<AppState>(context);
    final towerIds = state.tdrData.keys.toList();

    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth > 800;
        return Flex(
          direction: isDesktop ? Axis.horizontal : Axis.vertical,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Left sidebar: Tower Selectors + Upload
            Expanded(
              flex: isDesktop ? 1 : 0,
              child: Padding(
                padding: const EdgeInsets.all(24.0),
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
                      Text("Tower Dumps (TDR)", style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 12),
                      const Text(
                        "Select two or more tower log sets to find burner devices present at all locations.",
                        style: TextStyle(fontSize: 12, color: TacticalTheme.textMuted),
                      ),
                      const SizedBox(height: 18),

                      towerIds.isEmpty
                          ? const Text("No TDR datasets loaded. Load a case or upload CSV/Excel dumps.", style: TextStyle(color: TacticalTheme.textDim))
                          : ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: towerIds.length,
                              itemBuilder: (context, idx) {
                                final tId = towerIds[idx];
                                final isChecked = state.selectedTowers.contains(tId);
                                return CheckboxListTile(
                                  contentPadding: EdgeInsets.zero,
                                  title: Text(tId, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                  subtitle: Text("${state.tdrData[tId]?.length ?? 0} active devices", style: const TextStyle(fontSize: 11)),
                                  value: isChecked,
                                  activeColor: TacticalTheme.accentCyan,
                                  onChanged: (_) => state.toggleTowerSelection(tId),
                                );
                              },
                            ),
                      const SizedBox(height: 20),

                      // Upload TDR CSV
                      SizedBox(
                        width: double.infinity,
                        child: TextButton.icon(
                          icon: const Icon(Icons.upload_file_rounded, size: 16, color: TacticalTheme.accentCyan),
                          label: const Text("Upload TDR CSV", style: TextStyle(fontSize: 12, color: Colors.white70)),
                          onPressed: () async {
                            FilePickerResult? result = await FilePicker.platform.pickFiles(
                              type: FileType.custom,
                              allowedExtensions: ['csv'],
                              withData: true,
                            );
                            if (result != null) {
                              final file = result.files.single;
                              String csvText = '';
                              if (file.bytes != null) {
                                csvText = utf8.decode(file.bytes!);
                              } else if (file.path != null) {
                                csvText = await File(file.path!).readAsString();
                              }
                              if (csvText.isNotEmpty) {
                                final towerId = file.name.replaceAll(RegExp(r'\.(csv|txt)$', caseSensitive: false), '');
                                state.importTdr(towerId, csvText);
                              }
                            }
                          },
                          style: TextButton.styleFrom(alignment: Alignment.centerLeft),
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Upload TDR Excel (.xlsx / .xls)
                      SizedBox(
                        width: double.infinity,
                        child: TextButton.icon(
                          icon: const Icon(Icons.table_chart_rounded, size: 16, color: TacticalTheme.accentGreen),
                          label: const Text("Upload TDR Excel (.xlsx)", style: TextStyle(fontSize: 12, color: Colors.white70)),
                          onPressed: () async {
                            FilePickerResult? result = await FilePicker.platform.pickFiles(
                              type: FileType.custom,
                              allowedExtensions: ['xlsx', 'xls'],
                              withData: true,
                            );
                            if (result != null) {
                              final file = result.files.single;
                              List<int>? bytes = file.bytes;
                              if (bytes == null && file.path != null) {
                                bytes = await File(file.path!).readAsBytes();
                              }
                              if (bytes != null) {
                                final towerId = file.name.replaceAll(RegExp(r'\.(xlsx|xls)$', caseSensitive: false), '');
                                state.importExcel(bytes, 'tdr', towerId: towerId);
                              }
                            }
                          },
                          style: TextButton.styleFrom(alignment: Alignment.centerLeft),
                        ),
                      ),

                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: state.selectedTowers.length < 2
                            ? null
                            : () => state.runIntersection(),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: TacticalTheme.accentCyan,
                          foregroundColor: Colors.black,
                          minimumSize: const Size.fromHeight(45),
                          disabledBackgroundColor: Colors.white10,
                        ),
                        child: const Text("⚡ Run Intersection"),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Right side: Intersection output list
            Expanded(
              flex: isDesktop ? 2 : 0,
              child: Padding(
                padding: EdgeInsets.fromLTRB(isDesktop ? 0 : 24, 24, 24, 24),
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
                      Text("Intersection Analysis Results", style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 16),

                      state.intersectionResults.isEmpty
                          ? Container(
                              padding: const EdgeInsets.symmetric(vertical: 80.0),
                              alignment: Alignment.center,
                              child: const Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.compare_arrows_rounded, size: 64, color: TacticalTheme.textDim),
                                  SizedBox(height: 16),
                                  Text("Analyze Tower Dump Intersection", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                  SizedBox(height: 8),
                                  Text(
                                    "Click 'Run Intersection' on the left to discover overlapping numbers.",
                                    textAlign: TextAlign.center,
                                    style: TextStyle(fontSize: 12, color: TacticalTheme.textMuted),
                                  ),
                                ],
                              ),
                            )
                          : ListView.separated(
                              shrinkWrap: true,
                              itemCount: state.intersectionResults.length,
                              separatorBuilder: (_, __) => const Divider(color: Colors.white10),
                              itemBuilder: (context, idx) {
                                final res = state.intersectionResults[idx];
                                final phone = res['phone'] as String;
                                final sdr = res['sdr'];
                                final matches = res['matches'] as int;

                                final hasNotes = sdr != null && sdr.notes.isNotEmpty;

                                return ListTile(
                                  contentPadding: EdgeInsets.zero,
                                  title: Row(
                                    children: [
                                      Text(phone, style: const TextStyle(
                                        color: TacticalTheme.accentRed,
                                        fontWeight: FontWeight.bold,
                                        fontFamily: 'monospace',
                                      )),
                                      const SizedBox(width: 12),
                                      if (sdr != null && sdr.name != 'Unknown')
                                        Text(sdr.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                                    ],
                                  ),
                                  subtitle: Padding(
                                    padding: const EdgeInsets.only(top: 4.0),
                                    child: Text(
                                      hasNotes ? sdr.notes : "No case notes filed for this subscriber.",
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                  ),
                                  trailing: Chip(
                                    label: Text("Present in all $matches towers"),
                                    backgroundColor: Colors.red.withOpacity(0.12),
                                    side: const BorderSide(color: Colors.redAccent),
                                  ),
                                  onTap: () => state.setSelectedNumber(phone),
                                );
                              },
                            ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
