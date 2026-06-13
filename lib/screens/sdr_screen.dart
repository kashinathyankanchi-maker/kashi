import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/app_state.dart';
import '../models/models.dart';
import '../theme.dart';

class SdrScreen extends StatefulWidget {
  const SdrScreen({Key? key}) : super(key: key);

  @override
  State<SdrScreen> createState() => _SdrScreenState();
}

class _SdrScreenState extends State<SdrScreen> {
  final TextEditingController _searchController = TextEditingController();
  SdrProfile? _foundProfile;
  bool _searched = false;

  void _performSearch(AppState state) {
    final query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) {
      setState(() {
        _foundProfile = null;
        _searched = false;
      });
      return;
    }

    final match = state.sdrDatabase.firstWhere(
      (s) => s.phone.contains(query) || 
             s.name.toLowerCase().contains(query) || 
             s.alternatePhone.contains(query) ||
             s.idNumber.toLowerCase().contains(query),
      orElse: () => SdrProfile(
        phone: '', name: '', age: '', gender: '', address: '',
        idType: '', idNumber: '', activationDate: '', alternatePhone: '', avatarSeed: '', role: '', notes: '',
      ),
    );

    setState(() {
      _foundProfile = match.phone.isNotEmpty ? match : null;
      _searched = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = Provider.of<AppState>(context);

    // Sync selected number if searched from dashboard
    if (state.selectedNumber != null && !_searched && _searchController.text.isEmpty) {
      _searchController.text = state.selectedNumber!;
      _performSearch(state);
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Search Card
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
                Text(
                  "SDR Subscriber Directory Search",
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: "Enter phone number, name, alternate phone, or passport ID...",
                          filled: true,
                          fillColor: TacticalTheme.bgPrimary,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(color: Colors.white10),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(color: TacticalTheme.accentCyan),
                          ),
                        ),
                        onSubmitted: (_) => _performSearch(state),
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: () => _performSearch(state),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: TacticalTheme.accentCyan,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                      ),
                      child: const Text("Search"),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Dossier details sheet
          if (_foundProfile != null)
            _buildDossierCard(_foundProfile!, state)
          else if (_searched)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 60),
              alignment: Alignment.center,
              child: Column(
                children: [
                  const Icon(Icons.person_off_rounded, size: 64, color: TacticalTheme.textDim),
                  const SizedBox(height: 16),
                  const Text("No Registry Records Found", style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text("The query '${_searchController.text}' yielded no matches in the subscriber database.", style: const TextStyle(color: TacticalTheme.textMuted)),
                ],
              ),
            )
          else
            Container(
              padding: const EdgeInsets.symmetric(vertical: 60),
              alignment: Alignment.center,
              child: const Column(
                children: [
                  Icon(Icons.person_search_rounded, size: 64, color: TacticalTheme.textDim),
                  const SizedBox(height: 16),
                  Text("Lookup Subscriber Profile", style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text("Search above to view official registration details and case notes.", style: TextStyle(color: TacticalTheme.textMuted)),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDossierCard(SdrProfile profile, AppState state) {
    final isSuspect = profile.role.toLowerCase().contains("suspect");
    final isFemale = profile.gender.toLowerCase() == "female";

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: TacticalTheme.bgSecondary,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Avatar
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: TacticalTheme.bgPrimary,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.white10),
                ),
                child: Icon(
                  isFemale ? Icons.woman_rounded : Icons.man_rounded,
                  size: 64,
                  color: isFemale ? Colors.pinkAccent : TacticalTheme.accentCyan,
                ),
              ),
              const SizedBox(width: 20),

              // Title and Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(profile.name, style: Theme.of(context).textTheme.titleLarge),
                        Chip(
                          label: Text(profile.role.toUpperCase(), style: const TextStyle(fontSize: 10)),
                          backgroundColor: isSuspect ? Colors.red.withOpacity(0.12) : Colors.white12,
                          side: BorderSide(color: isSuspect ? Colors.redAccent : Colors.white24),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      profile.phone,
                      style: const TextStyle(
                        color: TacticalTheme.accentCyan, 
                        fontWeight: FontWeight.bold, 
                        fontFamily: 'monospace',
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.radar_rounded, size: 16),
                      label: const Text("Set Target Suspect"),
                      onPressed: () {
                        state.setSelectedNumber(profile.phone);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text("Trace target locked to ${profile.phone}")),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: TacticalTheme.accentCyan,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Divider(color: Colors.white10),
          const SizedBox(height: 16),

          // Details Grid
          LayoutBuilder(
            builder: (context, constraints) {
              final isDesktop = constraints.maxWidth > 600;
              return GridView.count(
                crossAxisCount: isDesktop ? 2 : 1,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                childAspectRatio: isDesktop ? 3.5 : 4.5,
                children: [
                  _buildDetailItem("Age / Gender", "${profile.age} / ${profile.gender}"),
                  _buildDetailItem("Identity Document", "${profile.idType}: ${profile.idNumber}"),
                  _buildDetailItem("SIM Activation Date", profile.activationDate),
                  _buildDetailItem("Alternate Phone Link", profile.alternatePhone),
                  _buildDetailItem("Billing Address", profile.address, isSpan: true),
                ],
              );
            },
          ),
          const SizedBox(height: 24),
          const Divider(color: Colors.white10),
          const SizedBox(height: 16),

          // Notes Dossier
          const Text("CASE FILES & INVESTIGATOR LOGS", style: TextStyle(fontWeight: FontWeight.bold, color: TacticalTheme.textMuted, fontSize: 11, letterSpacing: 0.5)),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(16),
            width: double.infinity,
            decoration: BoxDecoration(
              color: TacticalTheme.bgPrimary,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.white10),
            ),
            child: Text(
              profile.notes.isEmpty 
                  ? "No official reports filed for this subscriber registry entry."
                  : profile.notes,
              style: const TextStyle(fontSize: 13, height: 1.45, color: Colors.white70),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailItem(String label, String value, {bool isSpan = false}) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label.toUpperCase(), style: const TextStyle(color: TacticalTheme.textDim, fontSize: 10, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 13)),
        ],
      ),
    );
  }
}
