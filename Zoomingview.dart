import 'package:flutter/material.dart';


class BasicZoomDemo extends StatefulWidget {
  @override
  _BasicZoomDemoState createState() => _BasicZoomDemoState();
}

class _BasicZoomDemoState extends State<BasicZoomDemo> {
  final TransformationController _controller = TransformationController();
  double _currentScale = 1.0;
  String? activeBuilding;

  static const double imageWidth = 11040.0;
  static const double imageHeight = 12861.0;

  // 🔷 Define dummy building data
  //
  Map<String, Map<String, dynamic>> buildings = {
    'Academic Block A': {
      'x': 7100.0,
      'y': 6870.0,
      'width': 2475.0,
      'height': 3706.0,
      'indoorMapAsset': 'assets/maps/BLOCKAUPPER.png',
    },
    'Academic Block B': {
      'x': 4450.0,
      'y': 1050.0,
      'width': 3549.0,
      'height': 3270.0,
      'indoorMapAsset': 'assets/maps/BLOCKB.png',
    },
    'Academic Block C':{
      'x': 1650.0,
      'y': 7370.0,
      'width': 2323.0,
      'height': 2889.0,
      'indoorMapAsset': 'assets/maps/BLOCKCUPPER.png',
    },
    'Admin Block':{
      'x': 4700.0,
      'y': 6940.0,
      'width': 2279.0,
      'height': 3669.0,
      'indoorMapAsset': 'assets/maps/ADMINBLOCKUPPER.png',
    },
    // ➔ Add other buildings similarly
  };

  @override
  void initState() {
    super.initState();
    _controller.addListener(() {
      setState(() {
        _currentScale = _controller.value.getMaxScaleOnAxis();
      });
    });
  }

  void _checkBuildingZoomAndPosition(Offset focalPoint) {
    if (_currentScale > 2.0) {
      // Basic direct mapping without translation/scroll complications

      double adjustedX = focalPoint.dx / _currentScale;
      double adjustedY = focalPoint.dy / _currentScale;

      print("Scale: $_currentScale | AdjustedX: $adjustedX | AdjustedY: $adjustedY");

      bool found = false;
      buildings.forEach((id, data) {
        Rect rect = Rect.fromLTWH(
          data['x'],
          data['y'],
          data['width'],
          data['height'],
        );
        if (rect.contains(Offset(adjustedX, adjustedY))) {
          setState(() {
            activeBuilding = id;
          });
          print("✅ Over building: $id");
          found = true;
        }
      });

      if (!found) {
        setState(() {
          activeBuilding = null;
        });
      }
    } else {
      setState(() {
        activeBuilding = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Basic Zoom Building Detection")),
      body: Center(
        child: InteractiveViewer(
          transformationController: _controller,
          minScale: 0.5,
          maxScale: 5.0,
          onInteractionUpdate: (details) {
            _checkBuildingZoomAndPosition(details.focalPoint);
          },
          child: Stack(
            children: [
              Container(
                width: imageWidth,
                height: imageHeight,
                color: Colors.grey[300],
              ),
              // 🔷 Draw all buildings as colored containers
              ...buildings.entries.map((entry) {
                final data = entry.value;
                return Positioned(
                  left: data['x'],
                  top: data['y'],
                  child: Container(
                    width: data['width'],
                    height: data['height'],
                    color: data['color'],
                    child: Center(
                      child: Text(entry.key, style: TextStyle(color: Colors.white)),
                    ),
                  ),
                );
              }).toList(),

              // 🔷 Overlay if activeBuilding detected
              if (activeBuilding != null)
                Positioned(
                  bottom: 50,
                  left: 50,
                  child: Container(
                    color: Colors.black,
                    padding: EdgeInsets.all(8),
                    child: Text(
                      "You are over: $activeBuilding",
                      style: TextStyle(color: Colors.white, fontSize: 20),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

