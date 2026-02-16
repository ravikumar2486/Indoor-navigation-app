import 'dart:convert';
import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;


class BLOCKC extends StatefulWidget {
  const BLOCKC({super.key});

  @override
  State<BLOCKC> createState() => _BLOCKCState();
}

class _BLOCKCState extends State<BLOCKC> {
  int selectedIndex = 0;
  TransformationController _transformationController = TransformationController();
  double _currentScale = 1.0;

  List<Node> _shortestPathNodes = [];
  String? selectedSourceNodeId;
  String? selectedDestinationNodeId;

  Building? building;
  Floor? currentFloor;

  @override
  void initState() {
    super.initState();
    loadAdminBuilding().then((loadedBuilding) {
      if (loadedBuilding != null) {
        setState(() {
          building = loadedBuilding;
          currentFloor = building!.floors.first;// Initialize currentFloor
          validateSelectedNodes();
          print('Loaded building: ${building!.name}');
          print('Initial floor: ${currentFloor!.floorName}');
          print('Available nodes: ${currentFloor!.nodes.map((n) => n.nodeId).toList()}');
        });
      } else {
        print('BLOCK C building not found.');
      }
    });
  }
  void validateSelectedNodes() {
    final ids = currentFloor?.nodes.map((n) => n.nodeId).toSet() ?? {};

    if (!ids.contains(selectedSourceNodeId)) {
      selectedSourceNodeId = null;
    }

    if (!ids.contains(selectedDestinationNodeId)) {
      selectedDestinationNodeId = null;
    }
  }

  Future<Building?> loadAdminBuilding() async {
    try {
      final String jsonString = await rootBundle.loadString('assets/data/nodes.json');
      final Map<String, dynamic> jsonMap = json.decode(jsonString);

      List<dynamic> buildingsList = jsonMap['buildings'];
      for (var b in buildingsList) {
        if (b['name'] == 'C') {
          return Building.fromJson(b);
        }
      }
      return null;
    } catch (e) {
      print('Error loading JSON: $e');
      return null;
    }
  }

  // Dijkstra's algorithm implementation
  List<String> dijkstra(String startId, String endId, Map<String, List<String>> graph) {
    if (!graph.containsKey(startId) || !graph.containsKey(endId)) {
      print('Start or end node not found in graph');
      return [];
    }

    final Set<String> visited = {};
    final Map<String, double> distances = {};
    final Map<String, String?> previous = {};

    // Initialize distances
    for (var nodeId in graph.keys) {
      distances[nodeId] = double.infinity;
      previous[nodeId] = null;
    }
    distances[startId] = 0;

    while (visited.length < graph.length) {
      String? current;
      double minDistance = double.infinity;

      // Find unvisited node with minimum distance
      for (var entry in distances.entries) {
        if (!visited.contains(entry.key) && entry.value < minDistance) {
          minDistance = entry.value;
          current = entry.key;
        }
      }

      if (current == null) {
        print('No more reachable nodes');
        break;
      }

      if (current == endId) {
        print('Destination reached!');
        break;
      }

      visited.add(current);

      // Check all neighbors
      for (var neighbor in graph[current] ?? []) {
        if (!visited.contains(neighbor) && distances.containsKey(neighbor)) {
          double alt = distances[current]! + 1; // Assuming weight = 1
          if (alt < distances[neighbor]!) {
            distances[neighbor] = alt;
            previous[neighbor] = current;
          }
        }
      }
    }

    // Backtrack to find path
    List<String> path = [];
    String? current = endId;

    if (distances[endId] == double.infinity) {
      print('No path found from $startId to $endId');
      return [];
    }

    while (current != null) {
      path.insert(0, current);
      current = previous[current];
    }

    print('Final path: $path');
    return path;
  }

  // Convert path of node IDs to actual Node objects
  List<Node> dijkstraPath(List<Node> nodes, String startId, String endId) {
    if (currentFloor == null) return [];

    // Build graph from connections - make it bidirectional
    Map<String, List<String>> graph = {};

    // Initialize graph with all nodes
    for (var node in nodes) {
      graph[node.nodeId] = [];
    }

    // Add connections (make bidirectional for better pathfinding)
    for (var node in nodes) {
      for (String connectedNodeId in node.connections) {
        // Add forward connection
        if (!graph[node.nodeId]!.contains(connectedNodeId)) {
          graph[node.nodeId]!.add(connectedNodeId);
        }
        // Add reverse connection if the connected node exists
        if (graph.containsKey(connectedNodeId)) {
          if (!graph[connectedNodeId]!.contains(node.nodeId)) {
            graph[connectedNodeId]!.add(node.nodeId);
          }
        }
      }
    }

    print('Graph built: $graph');
    print('Finding path from $startId to $endId');

    // Get path as list of node IDs
    List<String> pathIds = dijkstra(startId, endId, graph);
    print('Path found: $pathIds');

    // Convert to Node objects
    List<Node> pathNodes = [];
    for (String nodeId in pathIds) {
      try {
        Node node = nodes.firstWhere((n) => n.nodeId == nodeId);
        pathNodes.add(node);
      } catch (e) {
        print('Node not found: $nodeId');
      }
    }

    return pathNodes;
  }

  void calculateShortestPath() {
    if (currentFloor == null ||
        selectedSourceNodeId == null ||
        selectedDestinationNodeId == null) return;

    print('Calculating path from $selectedSourceNodeId to $selectedDestinationNodeId');
    print('Available nodes: ${currentFloor!.nodes.map((n) => n.nodeId).toList()}');

    _shortestPathNodes = dijkstraPath(
      currentFloor!.nodes,
      selectedSourceNodeId!,
      selectedDestinationNodeId!,
    );

    print('Path nodes found: ${_shortestPathNodes.length}');
    setState(() {});
  }

  void _zoomIn() {
    setState(() {
      _currentScale *= 1.2;
      final focalPoint = Offset(
        MediaQuery.of(context).size.width / 2,
        MediaQuery.of(context).size.height / 2,
      );
      _transformationController.value = _scaleAt(
        Matrix4.copy(_transformationController.value),
        1.2,
        focalPoint,
      );
    });
  }

  void _zoomOut() {
    setState(() {
      _currentScale /= 1.2;
      final focalPoint = Offset(
        MediaQuery.of(context).size.width / 2,
        MediaQuery.of(context).size.height / 2,
      );
      _transformationController.value = _scaleAt(
        Matrix4.copy(_transformationController.value),
        1 / 1.2,
        focalPoint,
      );
    });
  }

  Matrix4 _scaleAt(Matrix4 matrix, double scale, Offset focalPoint) {
    return matrix
      ..translate(focalPoint.dx, focalPoint.dy)
      ..scale(scale)
      ..translate(-focalPoint.dx, -focalPoint.dy);
  }

  // Helper methods for label styling
  Color _getLabelBackgroundColor(String nodeId) {
    if (nodeId == selectedSourceNodeId) {
      return Color(0xFF00FF40);
    } else if (nodeId == selectedDestinationNodeId) {
      return Colors.cyanAccent;
    }
    return Colors.transparent;
  }

  Color _getLabelBorderColor(String nodeId) {
    if (nodeId == selectedSourceNodeId) {
      return Colors.black;
    } else if (nodeId == selectedDestinationNodeId) {
      return Colors.black;
    }
    return Colors.transparent;
  }

  Color _getLabelTextColor(String nodeId) {
    if (nodeId == selectedSourceNodeId || nodeId == selectedDestinationNodeId) {
      return Colors.black;
    }
    return Colors.black;
  }

  @override
  void dispose() {
    _transformationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (building == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    Floor currentFloor = building!.floors[selectedIndex];

    // Update the instance variable to match the current floor
    this.currentFloor = currentFloor;

    return Scaffold(
      appBar: AppBar(
        title: const Text('BLOCK C'),
        backgroundColor: const Color(0xFF0D00A3),
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Floor selection buttons
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: List.generate(building!.floors.length, (index) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                    child: ElevatedButton(
                      onPressed: () {
                        setState(() {
                          selectedIndex = index;
                          currentFloor = building!.floors[index]; // Update currentFloor reference
                          _currentScale = 1.0;
                          _transformationController.value = Matrix4.identity();
                          // Clear selections when switching floors
                          selectedSourceNodeId = null;
                          selectedDestinationNodeId = null;
                          _shortestPathNodes.clear();
                          print('Switched to floor: ${currentFloor!.floorName}');
                          print('Available nodes: ${currentFloor!.nodes.map((n) => n.nodeId).toList()}');
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                        selectedIndex == index ? const Color(0xFF0D00A3) : Colors.black,
                      ),
                      child: Text(
                        building!.floors[index].floorName,
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                  );
                }),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  // SOURCE DROPDOWN
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      isExpanded: true, // <--- add this
        
                      value: (currentFloor?.nodes.any((n) => n.nodeId == selectedSourceNodeId) ?? false)
                          ? selectedSourceNodeId
                          : null,
                      decoration: const InputDecoration(
                        labelText: 'Source',
                        border: OutlineInputBorder(),
                      ),
                      items: (currentFloor?.nodes ?? [])
                          .where((node) => node.label.trim().isNotEmpty)
                          .map<DropdownMenuItem<String>>((node) => DropdownMenuItem<String>(
                        value: node.nodeId,
                        child: Flexible(
                        child: Text(
                        node.label,
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                      ),
                      ))
                          .toList(),
                      onChanged: (value) {
                        setState(() {
                          print('Resetting selection via label, new source: $value');
                          selectedSourceNodeId = value;
                          selectedDestinationNodeId = null;
                          _shortestPathNodes = [];
                        }
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
        
                  // DESTINATION DROPDOWN
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      isExpanded: true, // <--- add this
        
                      value: (currentFloor?.nodes.any((n) => n.nodeId == selectedDestinationNodeId) ?? false)
                          ? selectedDestinationNodeId
                          : null,
                      decoration: const InputDecoration(
                        labelText: 'Destination',
                        border: OutlineInputBorder(),
                      ),
                      items: (currentFloor?.nodes ?? [])
                          .where((node) => node.label.trim().isNotEmpty)
                          .map<DropdownMenuItem<String>>((node) => DropdownMenuItem<String>(
                        value: node.nodeId,
                        child: Flexible(
                          child: Text(
                            node.label,
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ),
                      ))
                          .toList(),
                      onChanged: (value) {
                        setState(() {
                          selectedDestinationNodeId = value;
                          if (selectedSourceNodeId != null && selectedDestinationNodeId != null) {
                            calculateShortestPath();
                          }
                        }
                        );
                      },
                    ),
                  ),
                ],
              ),
        
            ),
        
            // Instructions
            if (selectedSourceNodeId == null)
              Container(
                padding: const EdgeInsets.all(8),
                margin: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'Tap a node to select starting point',
                  style: TextStyle(color: Colors.blue),
                ),
              )
            else if (selectedDestinationNodeId == null)
              Container(
                padding: const EdgeInsets.all(8),
                margin: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'Tap another node to select destination',
                  style: TextStyle(color: Colors.orange),
                ),
              )
            else
              Container(
                padding: const EdgeInsets.all(8),
                margin: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Path found! Tap a new node to reset.',
                  style: TextStyle(color: Colors.green.shade700),
                ),
              ),
        
            const SizedBox(height: 8),
        
            // Floor Image with nodes
            Expanded(
              child: InteractiveViewer(
                transformationController: _transformationController,
                panEnabled: true,
                minScale: 0.3,
                maxScale: 4.0,
                child: Center(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final maxW = constraints.maxWidth;
                      final maxH = constraints.maxHeight;
        
                      final imageAspectRatio = currentFloor.width / currentFloor.height;
                      final containerAspectRatio = maxW / maxH;
        
                      double scale, offsetX = 0, offsetY = 0;
                      double imgWidth, imgHeight;
        
                      if (containerAspectRatio > imageAspectRatio) {
                        // Fit height
                        scale = maxH / currentFloor.height;
                        imgHeight = maxH;
                        imgWidth = currentFloor.width * scale;
                        offsetX = (maxW - imgWidth) / 2;
                      } else {
                        // Fit width
                        scale = maxW / currentFloor.width;
                        imgWidth = maxW;
                        imgHeight = currentFloor.height * scale;
                        offsetY = (maxH - imgHeight) / 2;
                      }
        
                      return GestureDetector(
                        onTapUp: (TapUpDetails details) {
                          final tapPosition = details.localPosition;
        
                          // Convert tap to map coordinates
                          final relativeX = (tapPosition.dx - offsetX) / scale;
                          final relativeY = (tapPosition.dy - offsetY) / scale;
        
                          print('Tap at: (${tapPosition.dx}, ${tapPosition.dy})');
                          print('Relative coordinates: ($relativeX, $relativeY)');
        
                          // Find the closest node within tap range
                          Node? closestNode;
                          double minDistance = double.infinity;
                          final double tapRadius = 50.0 / scale; // Adaptive tap radius based on zoom level
        
                          print('Tap radius: $tapRadius (scale: $scale)');
        
                          for (final node in currentFloor.nodes) {
                            final dx = node.x - relativeX;
                            final dy = node.y - relativeY;
                            final distance = sqrt(dx * dx + dy * dy);
        
                            if (distance < minDistance) {
                              minDistance = distance;
                              if (distance < tapRadius) {
                                closestNode = node;
                              }
                            }
                          }
        
                          // If no node found within tap radius, select the closest one if it's reasonably close
                          if (closestNode == null && minDistance < 100.0 / scale) {
                            for (final node in currentFloor.nodes) {
                              final dx = node.x - relativeX;
                              final dy = node.y - relativeY;
                              final distance = sqrt(dx * dx + dy * dy);
        
                              if (distance == minDistance) {
                                closestNode = node;
                                break;
                              }
                            }
                          }
        
                          print('Closest node distance: $minDistance');
                          print('Selected node: ${closestNode?.nodeId ?? "none"}');
        
                          if (closestNode != null) {
                            final tappedNodeId = closestNode.nodeId;
                            print('Tapped node: $tappedNodeId');
        
                            setState(() {
                              // if (selectedSourceNodeId == null) {
                              //   selectedSourceNodeId = tappedNodeId;
                              //   print('Selected source: $tappedNodeId');
                              // } else if (selectedDestinationNodeId == null &&
                              //     tappedNodeId != selectedSourceNodeId) {
                              //   selectedDestinationNodeId = tappedNodeId;
                              //   print('Selected destination: $tappedNodeId');
                              //   calculateShortestPath();
                              // }
                              if(selectedDestinationNodeId==tappedNodeId){
                                // Reset selection
                                print('Resetting selection, new source: $tappedNodeId');
                                selectedSourceNodeId = tappedNodeId;
                                selectedDestinationNodeId = null;
                                _shortestPathNodes = [];
                              }
                            });
                          } else {
                            print('No node found within tap range');
                          }
                        },
                        child: Stack(
                          children: [
                            // Background map image
                            Positioned(
                              left: offsetX,
                              top: offsetY,
                              width: imgWidth,
                              height: imgHeight,
                              child: Image.asset(
                                currentFloor.img,
                                fit: BoxFit.contain,
                              ),
                            ),
        
                            // Draw paths (below node markers)
                            Positioned(
                              left: offsetX,
                              top: offsetY,
                              width: imgWidth,
                              height: imgHeight,
                              child: CustomPaint(
                                size: Size(imgWidth, imgHeight),
                                painter: PathPainter(
                                  pathNodes: _shortestPathNodes,
                                  scale: scale,
                                ),
                              ),
                            ),
        
                            // Draw selectable nodes
                            Positioned(
                              left: offsetX,
                              top: offsetY,
                              width: imgWidth,
                              height: imgHeight,
                              child: CustomPaint(
                                size: Size(imgWidth, imgHeight),
                                painter: NodePainter(
                                  nodes: currentFloor.nodes,
                                  selectedSourceNodeId: selectedSourceNodeId,
                                  selectedDestinationNodeId: selectedDestinationNodeId,
                                  scale: scale,
                                  offsetX: 0, // Relative to the positioned container
                                  offsetY: 0,
                                ),
                              ),
                            ),
        
                            // Node labels (now clickable)
                            ...currentFloor.nodes.where((node) => node.label.isNotEmpty).map((node) {
        
                              final scaledNodeX = (node.x * scale) + offsetX;
                              final scaledNodeY = (node.y * scale) + offsetY; // Position slightly below the node
        
        
                              return Positioned(
                                left: scaledNodeX - (node.label.length * 2.5), // Center the label
                                top: scaledNodeY + 10, // Position below the node
                                child: GestureDetector(
                                  onTap: () {
                                    final tappedNodeId = node.nodeId;
                                    print('Tapped label for node: $tappedNodeId');
        
                                    setState(() {
                                      if (selectedSourceNodeId == null) {
                                        selectedSourceNodeId = tappedNodeId;
                                        print('Selected source via label: $tappedNodeId');
                                      } else if (selectedDestinationNodeId == null &&
                                          tappedNodeId != selectedSourceNodeId) {
                                        selectedDestinationNodeId = tappedNodeId;
                                        print('Selected destination via label: $tappedNodeId');
                                        calculateShortestPath();
                                      } else {
                                        // Reset selection
                                        print('Resetting selection via label, new source: $tappedNodeId');
                                        selectedSourceNodeId = tappedNodeId;
                                        selectedDestinationNodeId = null;
                                        _shortestPathNodes = [];
                                      }
                                    });
                                  },
                                  child: Container(
                                    constraints: const BoxConstraints(maxWidth: 100),
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: _getLabelBackgroundColor(node.nodeId),
                                      borderRadius: BorderRadius.circular(3),
                                      border: Border.all(
                                          color: _getLabelBorderColor(node.nodeId),
                                          width: 1.0
                                      ),
                                      boxShadow: [
                                        // BoxShadow(
                                        //   color: Colors.black.withOpacity(0.1),
                                        //   blurRadius: 2,
                                        //   offset: const Offset(0, 1),
                                        // ),
                                      ],
                                    ),
                                    child: Text(
                                      node.label,
                                      style: TextStyle(
                                        fontSize: 5,
                                        color: _getLabelTextColor(node.nodeId),
                                        fontWeight: FontWeight.w600,
                                      ),
                                      textAlign: TextAlign.center,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
        
            // Zoom and reset buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0D00A3)),
                  onPressed: _zoomIn,
                  child: const Icon(Icons.zoom_in, color: Colors.white),
                ),
                const SizedBox(width: 20),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0D00A3)),
                  onPressed: _zoomOut,
                  child: const Icon(Icons.zoom_out, color: Colors.white),
                ),
                const SizedBox(width: 20),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  onPressed: () {
                    setState(() {
                      selectedSourceNodeId = null;
                      selectedDestinationNodeId = null;
                      _shortestPathNodes = [];
                    });
                  },
                  child: const Icon(Icons.clear, color: Colors.white),
                ),
              ],
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }
}

// ======================= MODEL CLASSES ======================

class Node {
  final String nodeId;
  final double x;
  final double y;
  final int z;
  final String type;
  final String label;
  final List<String> connections;

  Node({
    required this.nodeId,
    required this.x,
    required this.y,
    required this.z,
    required this.type,
    required this.label,
    required this.connections,
  });

  factory Node.fromJson(Map<String, dynamic> json) {
    String nodeId = (json['node_id'] ?? '').toString().trim(); // Trim whitespace
    return Node(
      nodeId: nodeId,
      x: (json['x'] ?? 0).toDouble(),
      y: (json['y'] ?? 0).toDouble(),
      z: json['z'] ?? 0,
      type: json['type'] ?? '',
      label: json['label'] ?? '',
      connections: List<String>.from(json['connections'] ?? []),
    );
  }
}

class Floor {
  final int floorNumber;
  final String floorName;
  final String img;
  final double width;
  final double height;
  final List<Node> nodes;

  Floor({
    required this.floorNumber,
    required this.floorName,
    required this.img,
    required this.width,
    required this.height,
    required this.nodes,
  });

  factory Floor.fromJson(Map<String, dynamic> json) {
    var nodeList = json['nodes'] as List<dynamic>? ?? [];
    return Floor(
      floorNumber: json['floor_number'] ?? 0,
      floorName: json['floor_name'] ?? '',
      img: json['img'] ?? '',
      width: (json['width'] ?? 0).toDouble(),
      height: (json['height'] ?? 0).toDouble(),
      nodes: nodeList.map((n) => Node.fromJson(n)).toList(),
    );
  }
}

class Building {
  final String name;
  final String buildingId;
  final List<Floor> floors;

  Building({
    required this.name,
    required this.buildingId,
    required this.floors,
  });

  factory Building.fromJson(Map<String, dynamic> json) {
    var floorList = json['floors'] as List<dynamic>? ?? [];
    return Building(
      name: json['name'] ?? 'Unknown',
      buildingId: json['building_id'] ?? 'unknown_id',
      floors: floorList.map((f) => Floor.fromJson(f)).toList(),
    );
  }
}

class NodePainter extends CustomPainter {
  final List<Node> nodes;
  final String? selectedSourceNodeId;
  final String? selectedDestinationNodeId;
  final double scale;
  final double offsetX;
  final double offsetY;

  NodePainter({
    required this.nodes,
    this.selectedSourceNodeId,
    this.selectedDestinationNodeId,
    required this.scale,
    required this.offsetX,
    required this.offsetY,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final normalPaint = Paint()
      ..color = Colors.transparent
      ..style = PaintingStyle.fill;

    final sourcePaint = Paint()
      ..color = Color(0xFF00FF40)
      ..style = PaintingStyle.fill;

    final destinationPaint = Paint()
      ..color = Colors.cyanAccent
      ..style = PaintingStyle.fill;

    for (var node in nodes) {
      final scaledX = node.x * scale + offsetX;
      final scaledY = node.y * scale + offsetY;

      Paint paint = normalPaint;
      if (node.nodeId == selectedSourceNodeId) {
        paint = sourcePaint;
      } else if (node.nodeId == selectedDestinationNodeId) {
        paint = destinationPaint;
      }

      canvas.drawCircle(Offset(scaledX, scaledY), 5.0, paint);

      // Draw white border for better visibility
      final borderPaint = Paint()
        ..color = Colors.transparent
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0;
      canvas.drawCircle(Offset(scaledX, scaledY), 10.0, borderPaint);
    }
  }

  @override
  bool shouldRepaint(covariant NodePainter oldDelegate) {
    return oldDelegate.nodes != nodes ||
        oldDelegate.selectedSourceNodeId != selectedSourceNodeId ||
        oldDelegate.selectedDestinationNodeId != selectedDestinationNodeId ||
        oldDelegate.scale != scale ||
        oldDelegate.offsetX != offsetX ||
        oldDelegate.offsetY != offsetY;
  }
}

class PathPainter extends CustomPainter {
  final List<Node> pathNodes;
  final double scale;

  PathPainter({required this.pathNodes, required this.scale});

  @override
  void paint(Canvas canvas, Size size) {
    if (pathNodes.length < 2) return;

    final paint = Paint()
      ..color = Color(0xFF0D00A3)
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke;

    for (int i = 0; i < pathNodes.length - 1; i++) {
      final p1 = Offset(pathNodes[i].x * scale, pathNodes[i].y * scale);
      final p2 = Offset(pathNodes[i + 1].x * scale, pathNodes[i + 1].y * scale);
      canvas.drawLine(p1, p2, paint);
    }
  }

  @override
  bool shouldRepaint(covariant PathPainter oldDelegate) {
    return oldDelegate.pathNodes != pathNodes || oldDelegate.scale != scale;
  }
}