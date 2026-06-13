import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/app_state.dart';
import '../theme.dart';

class NetworkScreen extends StatefulWidget {
  const NetworkScreen({Key? key}) : super(key: key);

  @override
  State<NetworkScreen> createState() => _NetworkScreenState();
}

class _NetworkScreenState extends State<NetworkScreen> {
  // Store node positions in coordinates relative to canvas center
  final Map<String, Offset> _nodePositions = {};
  String? _draggedNode;
  bool _initialized = false;

  void _initializeNodePositions(AppState state, Size size) {
    if (_initialized && _nodePositions.length == _getUniqueNumbers(state).length) return;

    final numbers = _getUniqueNumbers(state);
    if (numbers.isEmpty) return;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) * 0.35;

    for (int i = 0; i < numbers.length; i++) {
      final number = numbers[i];
      // Arrange in a circle
      final angle = (2 * math.pi * i) / numbers.length;
      final x = center.dx + radius * math.cos(angle);
      final y = center.dy + radius * math.sin(angle);
      _nodePositions[number] = Offset(x, y);
    }
    _initialized = true;
  }

  List<String> _getUniqueNumbers(AppState state) {
    final Set<String> numbers = {};
    for (var r in state.cdrRecords) {
      numbers.add(r.caller);
      numbers.add(r.recipient);
    }
    return numbers.toList();
  }

  @override
  Widget build(BuildContext context) {
    final state = Provider.of<AppState>(context);
    
    // Find all links between nodes
    final Map<String, int> links = {};
    for (var r in state.cdrRecords) {
      final edgeId = [r.caller, r.recipient].toList()..sort();
      final key = edgeId.join('-');
      links[key] = (links[key] ?? 0) + 1;
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(constraints.maxWidth, constraints.maxHeight);
        _initializeNodePositions(state, size);

        return GestureDetector(
          onPanStart: (details) {
            // Find which node is touched
            final localPos = details.localPosition;
            String? touchedNode;
            
            _nodePositions.forEach((number, pos) {
              if ((pos - localPos).distance < 24.0) {
                touchedNode = number;
              }
            });

            if (touchedNode != null) {
              setState(() {
                _draggedNode = touchedNode;
              });
            }
          },
          onPanUpdate: (details) {
            final node = _draggedNode;
            if (node != null) {
              setState(() {
                _nodePositions[node] = details.localPosition;
              });
            }
          },
          onPanEnd: (_) {
            setState(() {
              _draggedNode = null;
            });
          },
          onTapUp: (details) {
            // Check if node tapped to change suspect
            final localPos = details.localPosition;
            String? tappedNode;
            _nodePositions.forEach((number, pos) {
              if ((pos - localPos).distance < 24.0) {
                tappedNode = number;
              }
            });

            if (tappedNode != null) {
              state.setSelectedNumber(tappedNode);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text("Traced suspect: $tappedNode"),
                  duration: const Duration(seconds: 1),
                ),
              );
            }
          },
          child: Container(
            color: TacticalTheme.bgPrimary,
            child: Stack(
              children: [
                // Paint edges and nodes
                CustomPaint(
                  size: size,
                  painter: NetworkPainter(
                    nodePositions: _nodePositions,
                    links: links,
                    selectedNumber: state.selectedNumber,
                    sdrProfiles: state.sdrDatabase,
                  ),
                ),

                // Map HUD Legend
                Positioned(
                  bottom: 20,
                  left: 20,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: TacticalTheme.bgSecondary.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.white10),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "NODE INDEX",
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 10, letterSpacing: 0.5, color: TacticalTheme.accentCyan),
                        ),
                        const SizedBox(height: 8),
                        _buildLegendItem(Colors.redAccent, "Active suspect"),
                        _buildLegendItem(TacticalTheme.accentOrange, "SDR registered suspect"),
                        _buildLegendItem(TacticalTheme.accentCyan, "Other contacts"),
                      ],
                    ),
                  ),
                ),

                // Drag indicator overlay
                Positioned(
                  top: 20,
                  left: 20,
                  right: 20,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: TacticalTheme.bgSecondary.withOpacity(0.85),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.white10),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.touch_app_rounded, color: TacticalTheme.accentCyan, size: 18),
                        SizedBox(width: 8),
                        Text(
                          "Drag nodes to organize the network. Tap a node to trace that suspect.",
                          style: TextStyle(color: Colors.white, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildLegendItem(Color color, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Text(text, style: const TextStyle(fontSize: 11, color: Colors.white70)),
        ],
      ),
    );
  }
}

class NetworkPainter extends CustomPainter {
  final Map<String, Offset> nodePositions;
  final Map<String, int> links;
  final String? selectedNumber;
  final List<dynamic> sdrProfiles;

  NetworkPainter({
    required this.nodePositions,
    required this.links,
    required this.selectedNumber,
    required this.sdrProfiles,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Draw Links/Edges
    final linePaint = Paint()
      ..color = Colors.white24
      ..strokeCap = StrokeCap.round;

    links.forEach((key, count) {
      final nodes = key.split('-');
      if (nodes.length != 2) return;
      
      final p1 = nodePositions[nodes[0]];
      final p2 = nodePositions[nodes[1]];
      
      if (p1 != null && p2 != null) {
        // Line thickness relative to interaction count
        linePaint.strokeWidth = math.min(1.0 + (count * 1.5), 8.0);
        canvas.drawLine(p1, p2, linePaint);
      }
    });

    // 2. Draw Nodes
    for (var entry in nodePositions.entries) {
      final number = entry.key;
      final pos = entry.value;

      final isTarget = selectedNumber == number;
      final hasSdr = sdrProfiles.any((s) => s.phone == number);

      Color nodeColor = TacticalTheme.accentCyan;
      double radius = 12.0;

      if (isTarget) {
        nodeColor = Colors.redAccent;
        radius = 20.0;
      } else if (hasSdr) {
        nodeColor = TacticalTheme.accentOrange;
        radius = 16.0;
      }

      // Draw shadow glow
      final glowPaint = Paint()
        ..color = nodeColor.withOpacity(0.2)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6.0);
      canvas.drawCircle(pos, radius + 4.0, glowPaint);

      // Draw node circle
      final nodePaint = Paint()
        ..color = nodeColor
        ..style = PaintingStyle.fill;
      canvas.drawCircle(pos, radius, nodePaint);

      // Draw border
      final borderPaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0;
      canvas.drawCircle(pos, radius, borderPaint);

      // 3. Draw Labels
      final sdr = sdrProfiles.cast<dynamic>().firstWhere(
        (s) => s.phone == number, 
        orElse: () => null,
      );
      final String labelText = sdr != null ? "${sdr.name}\n$number" : number;

      final textSpan = TextSpan(
        style: TextStyle(
          color: Colors.white, 
          fontSize: isTarget ? 11 : 9,
          fontWeight: isTarget ? FontWeight.bold : FontWeight.normal,
        ),
        text: labelText,
      );

      final textPainter = TextPainter(
        text: textSpan,
        textDirection: TextDirection.ltr,
        textAlign: TextAlign.center,
      );

      textPainter.layout();
      textPainter.paint(
        canvas, 
        Offset(pos.dx - textPainter.width / 2, pos.dy + radius + 4.0),
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
