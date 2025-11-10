import 'package:compusflow/models/salle.dart';
import 'package:compusflow/screens/jihed/salle_map_screen.dart';
import 'package:compusflow/services/database_service.dart';
import 'package:flutter/material.dart';

import 'add_edit_salle_screen.dart';

class SalleListScreen extends StatefulWidget {
  const SalleListScreen({super.key});

  @override
  State<SalleListScreen> createState() => _SalleListScreenState();
}

class _SalleListScreenState extends State<SalleListScreen> {
  final DatabaseService db = DatabaseService();
  late Future<List<Salle>> _futureSalles;
  int _currentViewMode = 0; // 0: Grid, 1: List, 2: Compact

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  void _refresh() {
    setState(() {
      _futureSalles = db.getAllSalles();
    });
  }

  Map<String, List<Salle>> _groupByBuilding(List<Salle> salles) {
    final grouped = <String, List<Salle>>{};
    for (final salle in salles) {
      grouped.putIfAbsent(salle.batiment, () => []).add(salle);
    }
    return grouped;
  }

  void _delete(Salle s) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmer la suppression'),
        content: Text('Voulez-vous vraiment supprimer la salle ${s.numero} ?'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red.shade600),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await db.deleteSalle(s.id!);
        _refresh();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('✅ Salle ${s.numero} supprimée'),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('❌ Erreur: ${e.toString()}'),
              backgroundColor: Colors.red.shade600,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    }
  }

  Widget _buildViewModeIcon(int mode) {
    switch (mode) {
      case 0:
        return const Icon(Icons.grid_view);
      case 1:
        return const Icon(Icons.view_list);
      case 2:
        return const Icon(Icons.view_compact);
      default:
        return const Icon(Icons.grid_view);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text(
          'Gestion des Salles',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.red.shade600,
        centerTitle: true,
        elevation: 0,
        actions: [
          IconButton(
            icon: _buildViewModeIcon(_currentViewMode),
            onPressed: () {
              setState(() {
                _currentViewMode = (_currentViewMode + 1) % 3;
              });
            },
            tooltip: 'Changer la vue',
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
                  CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.red.shade600),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Chargement des salles...',
                    style: TextStyle(
                      color: Colors.red.shade600,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Colors.red.shade600,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Erreur de chargement',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey.shade900,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Veuillez réessayer',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _refresh,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.shade600,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Réessayer'),
                  ),
                ],
              ),
            );
          }

          final salles = snapshot.data ?? [];
          if (salles.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.meeting_room_outlined,
                    size: 80,
                    color: Colors.red.shade300,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Aucune Salle',
                    style: TextStyle(
                      fontSize: 24,
                      color: Colors.red.shade600,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Commencez par ajouter votre première salle',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            );
          }

          final groupedSalles = _groupByBuilding(salles);
          final buildingNames = groupedSalles.keys.toList()..sort();

          return Column(
            children: [
              // Statistics Card
              Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.apartment,
                        color: Colors.red.shade600,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Aperçu du Campus',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey.shade900,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${buildingNames.length} bâtiments • ${salles.length} salles',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.red.shade100,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        salles.length.toString(),
                        style: TextStyle(
                          color: Colors.red.shade600,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Buildings List
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: buildingNames.length,
                  itemBuilder: (context, index) {
                    final building = buildingNames[index];
                    final rooms = groupedSalles[building]!;
                    return _BuildingSection(
                      buildingName: building,
                      rooms: rooms,
                      viewMode: _currentViewMode,
                      onRoomTap: (room) async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => AddEditSalleScreen(salle: room),
                          ),
                        );
                        _refresh();
                      },
                      onEdit: (room) async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => AddEditSalleScreen(salle: room),
                          ),
                        );
                        _refresh();
                      },
                      onDelete: _delete,
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => SalleMapScreen()),
              );
            },
            backgroundColor: Colors.grey.shade900,
            foregroundColor: Colors.white,
            heroTag: 'mapBtn',
            child: const Icon(Icons.map),
          ),
          const SizedBox(width: 16),
          FloatingActionButton(
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AddEditSalleScreen()),
              );
              _refresh();
            },
            backgroundColor: Colors.red.shade600,
            foregroundColor: Colors.white,
            heroTag: 'addBtn',
            child: const Icon(Icons.add),
          ),
        ],
      ),
    );
  }
}

class _BuildingSection extends StatelessWidget {
  final String buildingName;
  final List<Salle> rooms;
  final int viewMode;
  final Function(Salle) onRoomTap;
  final Function(Salle) onEdit;
  final Function(Salle) onDelete;

  const _BuildingSection({
    required this.buildingName,
    required this.rooms,
    required this.viewMode,
    required this.onRoomTap,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final tpCount = rooms.where((r) => r.type == 'TP').length;
    final tdCount = rooms.where((r) => r.type == 'TD').length;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Building Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.apartment,
                    color: Colors.red.shade600,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          buildingName,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade900,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${rooms.length} salle${rooms.length > 1 ? 's' : ''}',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (tpCount > 0 || tdCount > 0) ...[
                    if (tpCount > 0)
                      _RoomTypeIndicator(
                        count: tpCount,
                        label: 'TP',
                        color: Colors.orange,
                      ),
                    if (tdCount > 0)
                      _RoomTypeIndicator(
                        count: tdCount,
                        label: 'TD',
                        color: Colors.blue,
                      ),
                  ],
                ],
              ),
            ),

            // Rooms Content
            Padding(
              padding: const EdgeInsets.all(16),
              child: _buildRoomsContent(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRoomsContent() {
    switch (viewMode) {
      case 0: // Grid View
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 1.1,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemCount: rooms.length,
          itemBuilder: (context, index) => _RoomGridCard(
            room: rooms[index],
            onTap: () => onRoomTap(rooms[index]),
            onEdit: () => onEdit(rooms[index]),
            onDelete: () => onDelete(rooms[index]),
          ),
        );
      case 1: // List View
        return Column(
          children: rooms
              .map((room) => _RoomListCard(
            room: room,
            onTap: () => onRoomTap(room),
            onEdit: () => onEdit(room),
            onDelete: () => onDelete(room),
          ))
              .toList(),
        );
      case 2: // Compact View
        return Wrap(
          spacing: 8,
          runSpacing: 8,
          children: rooms
              .map((room) => _RoomCompactCard(
            room: room,
            onTap: () => onRoomTap(room),
          ))
              .toList(),
        );
      default:
        return Container();
    }
  }
}

class _RoomTypeIndicator extends StatelessWidget {
  final int count;
  final String label;
  final Color color;

  const _RoomTypeIndicator({
    required this.count,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(left: 8),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        '$count $label',
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

class _RoomGridCard extends StatelessWidget {
  final Salle room;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _RoomGridCard({
    required this.room,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isTP = room.type == 'TP';
    final color = isTP ? Colors.orange : Colors.blue;

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                isTP ? Icons.computer : Icons.school,
                color: color,
                size: 32,
              ),
              const SizedBox(height: 8),
              Text(
                room.numero,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade900,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  room.type,
                  style: TextStyle(
                    fontSize: 12,
                    color: color,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.people_outline,
                    size: 14,
                    color: Colors.grey.shade600,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${room.capacite}',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade700,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RoomListCard extends StatelessWidget {
  final Salle room;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _RoomListCard({
    required this.room,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isTP = room.type == 'TP';
    final color = isTP ? Colors.orange : Colors.blue;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  isTP ? Icons.computer : Icons.school,
                  color: color,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      room.numero,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade900,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${room.capacite} places',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  room.type,
                  style: TextStyle(
                    fontSize: 12,
                    color: color,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: Icon(
                  Icons.edit,
                  size: 18,
                  color: Colors.grey.shade600,
                ),
                onPressed: onEdit,
              ),
              IconButton(
                icon: Icon(
                  Icons.delete,
                  size: 18,
                  color: Colors.red.shade600,
                ),
                onPressed: onDelete,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RoomCompactCard extends StatelessWidget {
  final Salle room;
  final VoidCallback onTap;

  const _RoomCompactCard({
    required this.room,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isTP = room.type == 'TP';
    final color = isTP ? Colors.orange : Colors.blue;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 80,
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.05),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isTP ? Icons.computer : Icons.school,
              color: color,
              size: 20,
            ),
            const SizedBox(height: 4),
            Text(
              room.numero,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: color.shade700,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              '${room.capacite}',
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}