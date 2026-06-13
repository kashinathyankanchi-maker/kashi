import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../state/app_state.dart';
import '../services/mock_case.dart';
import '../theme.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({Key? key}) : super(key: key);

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final MapController _mapController = MapController();
  
  // Playback state
  Timer? _playbackTimer;
  bool _isPlaying = false;
  int _currentIndex = 0;
  int _playbackSpeedMs = 1500;
  List<Map<String, dynamic>> _playbackSteps = [];

  @override
  void dispose() {
    _playbackTimer?.cancel();
    super.dispose();
  }

  void _togglePlayback() {
    if (_isPlaying) {
      _pausePlayback();
    } else {
      _startPlayback();
    }
  }

  void _startPlayback() {
    if (_playbackSteps.isEmpty) return;
    setState(() => _isPlaying = true);

    _playbackTimer = Timer.periodic(Duration(milliseconds: _playbackSpeedMs), (timer) {
      setState(() {
        if (_currentIndex < _playbackSteps.length - 1) {
          _currentIndex++;
        } else {
          _currentIndex = 0; // loop
        }
      });
      _panToStep(_currentIndex);
    });
  }

  void _pausePlayback() {
    _playbackTimer?.cancel();
    setState(() => _isPlaying = false);
  }

  void _stepForward() {
    _pausePlayback();
    if (_playbackSteps.isEmpty) return;
    setState(() {
      _currentIndex = (_currentIndex + 1) % _playbackSteps.length;
    });
    _panToStep(_currentIndex);
  }

  void _stepBackward() {
    _pausePlayback();
    if (_playbackSteps.isEmpty) return;
    setState(() {
      _currentIndex = _currentIndex > 0 ? _currentIndex - 1 : _playbackSteps.length - 1;
    });
    _panToStep(_currentIndex);
  }

  void _panToStep(int idx) {
    if (idx < 0 || idx >= _playbackSteps.length) return;
    final step = _playbackSteps[idx];
    final coord = step['coord'] as LatLng;
    _mapController.move(coord, _mapController.camera.zoom);
  }

  @override
  Widget build(BuildContext context) {
    final state = Provider.of<AppState>(context);
    final suspectNum = state.selectedNumber;

    // Build chronological path of suspect
    _playbackSteps.clear();
    final List<LatLng> pathPoints = [];

    if (suspectNum != null) {
      final suspectCalls = state.cdrRecords
          .where((r) => r.caller == suspectNum || r.recipient == suspectNum)
          .toList()
        ..sort((a, b) => a.timestamp.compareTo(b.timestamp));

      for (var call in suspectCalls) {
        final tRegistry = MockCaseData.towerRegistry[call.towerId];
        if (tRegistry != null) {
          final lat = tRegistry['lat'] as double;
          final lng = tRegistry['lng'] as double;
          final coord = LatLng(lat, lng);
          pathPoints.add(coord);
          
          _playbackSteps.add({
            'coord': coord,
            'time': call.timestamp,
            'towerName': tRegistry['name'],
            'towerId': call.towerId,
            'type': call.type,
            'recipient': call.caller == suspectNum ? call.recipient : call.caller,
            'direction': call.caller == suspectNum ? 'Outgoing' : 'Incoming',
          });
        }
      }
    }

    // Keep index inside bounds
    if (_currentIndex >= _playbackSteps.length) {
      _currentIndex = 0;
    }

    // Build Static Tower Markers
    final List<Marker> markers = [];
    MockCaseData.towerRegistry.forEach((id, val) {
      final lat = val['lat'] as double;
      final lng = val['lng'] as double;
      markers.add(
        Marker(
          point: LatLng(lat, lng),
          width: 30,
          height: 30,
          child: Tooltip(
            message: "${val['name']} ($id)",
            child: const Icon(
              Icons.cell_tower_rounded,
              color: TacticalTheme.accentOrange,
              size: 24,
            ),
          ),
        ),
      );
    });

    // Add moving target marker
    if (_playbackSteps.isNotEmpty && _currentIndex < _playbackSteps.length) {
      final activeStep = _playbackSteps[_currentIndex];
      final coord = activeStep['coord'] as LatLng;
      markers.add(
        Marker(
          point: coord,
          width: 40,
          height: 40,
          child: Container(
            decoration: BoxDecoration(
              color: TacticalTheme.accentRed.withOpacity(0.25),
              shape: BoxShape.circle,
              border: Border.all(color: TacticalTheme.accentRed, width: 2),
            ),
            child: const Center(
              child: Icon(
                Icons.radar_rounded,
                color: TacticalTheme.accentRed,
                size: 18,
              ),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      body: Stack(
        children: [
          // Flutter Map Layer
          FlutterMap(
            mapController: _mapController,
            options: const MapOptions(
              initialCenter: LatLng(40.7600, -73.9600),
              initialZoom: 11.0,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png',
                userAgentPackageName: 'com.sentinel.forensic',
              ),
              if (pathPoints.isNotEmpty)
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: pathPoints,
                      color: TacticalTheme.accentCyan,
                      strokeWidth: 3.0,
                      isDotted: true,
                    ),
                  ],
                ),
              MarkerLayer(markers: markers),
            ],
          ),

          // Overlay HUD banner if no suspect selected
          if (suspectNum == null)
            Positioned(
              top: 20,
              left: 20,
              right: 20,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  color: TacticalTheme.bgSecondary.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.white10),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline, color: TacticalTheme.accentCyan),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        "No suspect under investigation. Please select a suspect number in the Dashboard or SDR Search to trace their route path.",
                        style: TextStyle(color: Colors.white, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Timeline HUD panel at the bottom
          if (suspectNum != null && _playbackSteps.isNotEmpty)
            Positioned(
              bottom: 20,
              left: 20,
              right: 20,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: TacticalTheme.bgSecondary.withOpacity(0.95),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white10),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Playback controls row
                    Row(
                      children: [
                        // Play Pause Button
                        ElevatedButton(
                          onPressed: _togglePlayback,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: TacticalTheme.accentCyan,
                            foregroundColor: Colors.black,
                          ),
                          child: Text(_isPlaying ? "Pause" : "Play"),
                        ),
                        const SizedBox(width: 10),
                        
                        // Prev Next Buttons
                        IconButton(
                          icon: const Icon(Icons.skip_previous_rounded),
                          onPressed: _stepBackward,
                        ),
                        IconButton(
                          icon: const Icon(Icons.skip_next_rounded),
                          onPressed: _stepForward,
                        ),
                        const SizedBox(width: 10),

                        // Time display
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _playbackSteps[_currentIndex]['towerName'],
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                DateFormat('yyyy-MM-dd HH:mm:ss').format(
                                  _playbackSteps[_currentIndex]['time'] as DateTime,
                                ),
                                style: const TextStyle(
                                  color: TacticalTheme.accentCyan, 
                                  fontFamily: 'monospace',
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Speed controller
                        DropdownButton<int>(
                          value: _playbackSpeedMs,
                          dropdownColor: TacticalTheme.bgSecondary,
                          style: const TextStyle(color: Colors.white, fontSize: 12),
                          underline: Container(),
                          onChanged: (val) {
                            if (val != null) {
                              setState(() => _playbackSpeedMs = val);
                              if (_isPlaying) {
                                _pausePlayback();
                                _startPlayback();
                              }
                            }
                          },
                          items: const [
                            DropdownMenuItem(value: 2500, child: Text("Slow (2.5s)")),
                            DropdownMenuItem(value: 1500, child: Text("Normal (1.5s)")),
                            DropdownMenuItem(value: 750, child: Text("Fast (0.7s)")),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Slider row
                    Row(
                      children: [
                        Expanded(
                          child: Slider(
                            value: _currentIndex.toDouble(),
                            min: 0,
                            max: (_playbackSteps.length - 1).toDouble(),
                            divisions: _playbackSteps.length > 1 ? _playbackSteps.length - 1 : 1,
                            activeColor: TacticalTheme.accentCyan,
                            onChanged: (val) {
                              _pausePlayback();
                              setState(() => _currentIndex = val.toInt());
                              _panToStep(_currentIndex);
                            },
                          ),
                        ),
                        Text(
                          "${_currentIndex + 1}/${_playbackSteps.length}",
                          style: const TextStyle(fontSize: 12, color: TacticalTheme.textMuted),
                        ),
                      ],
                    ),
                    
                    // Transaction description details
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        "${_playbackSteps[_currentIndex]['direction']} ${_playbackSteps[_currentIndex]['type']} transaction with phone ${_playbackSteps[_currentIndex]['recipient']}",
                        style: const TextStyle(fontSize: 12, color: TacticalTheme.textMuted, fontStyle: FontStyle.italic),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
