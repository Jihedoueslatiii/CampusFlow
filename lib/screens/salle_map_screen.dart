import 'package:flutter/material.dart';
import '../db/database_helper.dart';
import '../models/salle.dart';
import 'add_edit_salle_screen.dart';

class SalleMapScreen extends StatefulWidget {
  const SalleMapScreen({super.key});

  @override
  State<SalleMapScreen> createState() => _SalleMapScreenState();
}

class _SalleMapScreenState extends State<SalleMapScreen> {
  final db = DatabaseHelper.instance;
  late Future<List<Salle>> _futureSalles;
  double _scale = 1.0;
  double _previousScale = 1.0;
  Offset _offset = Offset.zero;
  final double _baseMapWidth = 600;
  final double _baseMapHeight = 600;

  // Color Palette
  static const Color primaryRed = Color(0xFFE53935);
  static const Color backgroundWhite = Color(0xFFFFFFFF);
  static const Color textDark = Color(0xFF212121);
  static const Color neutralGray = Color(0xFFF5F5F5);

  @override
  void initState() {
    super.initState();
    _loadSalles();
  }

  void _loadSalles() {
    setState(() {
      _futureSalles = db.getAllSalles();
    });
  }

  void _resetView() {
    setState(() {
      _scale = 1.0;
      _offset = Offset.zero;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: neutralGray,
      appBar: AppBar(
        title: const Text(
          "Campus Map Overview",
          style: TextStyle(color: backgroundWhite, fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
        backgroundColor: primaryRed,
        elevation: 4,
        iconTheme: const IconThemeData(color: backgroundWhite),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh Data',
            onPressed: _loadSalles,
          ),
          IconButton(
            icon: const Icon(Icons.zoom_out_map),
            tooltip: 'Reset Zoom',
            onPressed: _resetView,
          ),
        ],
      ),
      body: FutureBuilder<List<Salle>>(
        future: _futureSalles,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: primaryRed),
                  const SizedBox(height: 16),
                  Text('Loading campus map...', style: TextStyle(color: textDark)),
                ],
              ),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, color: primaryRed, size: 64),
                  const SizedBox(height: 16),
                  Text('Error loading map: ${snapshot.error}', style: TextStyle(color: textDark)),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _loadSalles,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryRed,
                      foregroundColor: backgroundWhite,
                    ),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.map_outlined, color: Colors.grey.shade400, size: 64),
                  const SizedBox(height: 16),
                  Text('No buildings available', style: TextStyle(color: textDark)),
                  const SizedBox(height: 8),
                  Text('Add rooms to see them on the map',
                      style: TextStyle(color: Colors.grey.shade600)),
                ],
              ),
            );
          }

          final salles = snapshot.data!;
          final buildings = _groupByBuilding(salles);

          return Stack(
            children: [
              // Background with subtle pattern
              Container(
                width: double.infinity,
                height: double.infinity,
                color: neutralGray,
                child: CustomPaint(
                  painter: _GridPainter(),
                ),
              ),

              // Interactive Map
              Center(
                child: GestureDetector(
                  onScaleStart: (details) {
                    _previousScale = _scale;
                  },
                  onScaleUpdate: (details) {
                    setState(() {
                      _scale = (_previousScale * details.scale).clamp(0.5, 3.0);
                      _offset += details.focalPointDelta;
                    });
                  },
                  onDoubleTap: _resetView,
                  child: ClipRect(
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.easeInOut,
                      child: Transform(
                        transform: Matrix4.identity()
                          ..translate(_offset.dx, _offset.dy)
                          ..scale(_scale),
                        alignment: Alignment.center,
                        child: Container(
                          width: _baseMapWidth,
                          height: _baseMapHeight,
                          decoration: BoxDecoration(
                            color: backgroundWhite,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.15),
                                blurRadius: 20,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: Stack(
                            children: [
                              _buildCampusInfrastructure(),
                              ..._buildBuildings(buildings),
                              _buildMapLegend(),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // Zoom controls
              Positioned(
                bottom: 20,
                right: 20,
                child: Container(
                  decoration: BoxDecoration(
                    color: backgroundWhite,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.add, color: primaryRed),
                        onPressed: () {
                          setState(() {
                            _scale = (_scale + 0.2).clamp(0.5, 3.0);
                          });
                        },
                      ),
                      Container(
                        width: 30,
                        height: 1,
                        color: Colors.grey.shade300,
                      ),
                      IconButton(
                        icon: const Icon(Icons.remove, color: primaryRed),
                        onPressed: () {
                          setState(() {
                            _scale = (_scale - 0.2).clamp(0.5, 3.0);
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ),

              // Current zoom level indicator
              Positioned(
                top: 20,
                left: 20,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: backgroundWhite,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 5,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.zoom_in_map, size: 16, color: primaryRed),
                      const SizedBox(width: 4),
                      Text(
                        '${(_scale * 100).round()}%',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: primaryRed,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Building count indicator
              Positioned(
                top: 20,
                right: 20,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: textDark,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Buildings: ${buildings.length}',
                    style: const TextStyle(
                      color: backgroundWhite,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildCampusInfrastructure() {
    return Stack(
      children: [
        // Main roads
        Positioned(
          left: 0,
          right: 0,
          top: _baseMapHeight / 2,
          child: Container(
            height: 40,
            color: Colors.grey.shade200,
            child: Center(
              child: Container(
                height: 2,
                color: Colors.grey.shade400,
              ),
            ),
          ),
        ),
        Positioned(
          top: 0,
          bottom: 0,
          left: _baseMapWidth / 2,
          child: Container(
            width: 40,
            color: Colors.grey.shade200,
            child: Center(
              child: Container(
                width: 2,
                color: Colors.grey.shade400,
              ),
            ),
          ),
        ),

        // Green areas
        Positioned(
          top: 50,
          left: 50,
          child: Container(
            width: 120,
            height: 100,
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.green.shade200),
            ),
          ),
        ),
        Positioned(
          bottom: 50,
          right: 50,
          child: Container(
            width: 150,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.green.shade200),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMapLegend() {
    return Positioned(
      bottom: 10,
      left: 10,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: backgroundWhite,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Legend', style: TextStyle(
              fontWeight: FontWeight.bold,
              color: primaryRed,
              fontSize: 12,
            )),
            const SizedBox(height: 8),
            _buildLegendItem('TD Room', Icons.school, primaryRed),
            _buildLegendItem('TP Lab', Icons.computer, textDark),
            _buildLegendItem('Building', Icons.apartment, primaryRed),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendItem(String text, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(text, style: TextStyle(fontSize: 10, color: textDark)),
        ],
      ),
    );
  }

  Map<String, List<Salle>> _groupByBuilding(List<Salle> salles) {
    final grouped = <String, List<Salle>>{};
    for (final s in salles) {
      if (s.batiment.isNotEmpty) {
        grouped.putIfAbsent(s.batiment, () => []).add(s);
      }
    }
    return grouped;
  }

  List<Widget> _buildBuildings(Map<String, List<Salle>> buildings) {
    final buildingNames = buildings.keys.toList();
    List<Widget> widgets = [];

    for (int i = 0; i < buildingNames.length; i++) {
      final name = buildingNames[i];
      final rooms = buildings[name]!;

      final row = i ~/ 2;
      final col = i % 2;
      final posX = 100.0 + (col * 200.0);
      final posY = 100.0 + (row * 150.0);

      final floors = _calculateFloors(rooms.length);
      final tdCount = rooms.where((r) => r.type == 'TD').length;
      final tpCount = rooms.where((r) => r.type == 'TP').length;

      widgets.add(
        Positioned(
          left: posX,
          top: posY,
          child: GestureDetector(
            onTap: () => _showBuildingDetails(name, rooms),
            child: MouseRegion(
              cursor: SystemMouseCursors.click,
              child: Hero(
                tag: 'building_$name',
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: 100,
                  height: 70 + (floors * 10),
                  decoration: BoxDecoration(
                    color: primaryRed,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: primaryRed.withOpacity(0.3),
                        blurRadius: 12,
                        offset: const Offset(4, 4),
                      ),
                    ],
                  ),
                  child: Stack(
                    children: [
                      // Building floors
                      ...List.generate(floors, (index) => Positioned(
                        top: 5 + (index * 15),
                        left: 5,
                        right: 5,
                        child: Container(
                          height: 8,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      )),

                      // Building info
                      Positioned(
                        bottom: 4,
                        left: 0,
                        right: 0,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Bât. $name',
                              style: const TextStyle(
                                color: backgroundWhite,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            Text(
                              '${rooms.length} rooms',
                              style: const TextStyle(
                                color: backgroundWhite,
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Room type indicators
                      if (tdCount > 0)
                        Positioned(
                          top: 5,
                          left: 5,
                          child: Tooltip(
                            message: '$tdCount TD Rooms',
                            child: const Icon(Icons.school, color: backgroundWhite, size: 12),
                          ),
                        ),
                      if (tpCount > 0)
                        Positioned(
                          top: 5,
                          right: 5,
                          child: Tooltip(
                            message: '$tpCount TP Labs',
                            child: const Icon(Icons.computer, color: backgroundWhite, size: 12),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }

    return widgets;
  }

  int _calculateFloors(int roomCount) {
    if (roomCount <= 5) return 1;
    if (roomCount <= 10) return 2;
    if (roomCount <= 15) return 3;
    return 4;
  }

  void _showBuildingDetails(String building, List<Salle> rooms) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          margin: const EdgeInsets.all(20),
          child: DraggableScrollableSheet(
            expand: false,
            initialChildSize: 0.7,
            minChildSize: 0.4,
            maxChildSize: 0.9,
            builder: (_, controller) => Container(
              decoration: BoxDecoration(
                color: backgroundWhite,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    // Drag handle
                    Container(
                      width: 40,
                      height: 5,
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),

                    // Header
                    Row(
                      children: [
                        const Icon(Icons.apartment, color: primaryRed, size: 28),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Building $building',
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: textDark,
                                ),
                              ),
                              Text(
                                '${rooms.length} rooms available',
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: primaryRed.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${rooms.length} rooms',
                            style: const TextStyle(
                              color: primaryRed,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),
                    const Divider(),
                    const SizedBox(height: 16),

                    // Room statistics
                    _buildRoomStatistics(rooms),
                    const SizedBox(height: 20),

                    // Rooms list
                    Expanded(
                      child: rooms.isEmpty
                          ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.meeting_room, size: 64, color: Colors.grey.shade400),
                            const SizedBox(height: 16),
                            Text(
                              'No rooms in this building',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      )
                          : ListView.builder(
                        controller: controller,
                        itemCount: rooms.length,
                        itemBuilder: (_, i) {
                          final room = rooms[i];
                          return Card(
                            elevation: 1,
                            margin: const EdgeInsets.symmetric(vertical: 6),
                            color: backgroundWhite,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(color: neutralGray, width: 1),
                            ),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: primaryRed.withOpacity(0.1),
                                child: Icon(
                                  room.type == 'TP' ? Icons.computer : Icons.school,
                                  color: primaryRed,
                                ),
                              ),
                              title: Text(
                                'Room ${room.numero}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: textDark,
                                ),
                              ),
                              subtitle: Text(
                                '${room.capacite} seats • ${room.type}',
                                style: TextStyle(color: Colors.grey.shade600),
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: neutralGray,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      '${room.capacite}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                        color: textDark,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  IconButton(
                                    icon: const Icon(Icons.edit, color: primaryRed, size: 20),
                                    onPressed: () {
                                      Navigator.pop(context);
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => AddEditSalleScreen(salle: room),
                                        ),
                                      ).then((_) {
                                        _loadSalles();
                                      });
                                    },
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildRoomStatistics(List<Salle> rooms) {
    final totalCapacity = rooms.fold(0, (sum, room) => sum + room.capacite);
    final tdCount = rooms.where((r) => r.type == 'TD').length;
    final tpCount = rooms.where((r) => r.type == 'TP').length;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _buildStatItem('Total Capacity', '$totalCapacity', Icons.people),
        _buildStatItem('TD Rooms', '$tdCount', Icons.school),
        _buildStatItem('TP Labs', '$tpCount', Icons.computer),
      ],
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: primaryRed.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: primaryRed, size: 20),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: textDark,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.grey.shade600,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.grey.shade300
      ..strokeWidth = 0.5;

    for (double x = 0; x < size.width; x += 20) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }

    for (double y = 0; y < size.height; y += 20) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}