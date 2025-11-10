import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import '../../models/events_model.dart';
import '../../models/event_participant_model.dart';
import '../../models/club_model.dart';
import '../../services/event_service.dart';
import '../../services/auth_service.dart';
import '../../services/club_service.dart';

class EventDetailsScreen extends StatefulWidget {
  final Event event;

  const EventDetailsScreen({Key? key, required this.event}) : super(key: key);

  @override
  _EventDetailsScreenState createState() => _EventDetailsScreenState();
}

class _EventDetailsScreenState extends State<EventDetailsScreen> {
  final EventService _eventService = EventService();
  final AuthService _authService = AuthService();
  final ClubService _clubService = ClubService();

  late Future<List<EventParticipant>> _participantsFuture;
  bool _isRegistered = false;
  bool _isAdmin = false;
  bool _isLoading = false;
  bool _isDateFormatInitialized = false;

  // Color constants based on the palette
  static const Color primaryAccent = Color(0xFFE53935);
  static const Color background = Color(0xFFFFFFFF);
  static const Color textPrimary = Color(0xFF212121);
  static const Color backgroundSecondary = Color(0xFFF5F5F5);

  @override
  void initState() {
    super.initState();
    _initializeDateFormatting();
    _loadData();
  }

  Future<void> _initializeDateFormatting() async {
    await initializeDateFormatting('fr_FR', null);
    setState(() {
      _isDateFormatInitialized = true;
    });
  }

  void _loadData() {
    setState(() {
      _participantsFuture = _eventService.getEventParticipants(widget.event.id!);
    });
    _checkRegistration();
    _checkAdminStatus();
  }

  Future<void> _checkRegistration() async {
    final currentUser = await _authService.getCurrentUser();
    if (currentUser != null) {
      final registered = await _eventService.isUserRegistered(
          widget.event.id!,
          currentUser['id']!
      );
      setState(() {
        _isRegistered = registered;
      });
    }
  }

  Future<void> _checkAdminStatus() async {
    final currentUser = await _authService.getCurrentUser();
    if (currentUser != null) {
      print('=== DEBUG ADMIN CHECK ===');
      print('User ID: ${currentUser['id']}');
      print('Event Club ID: ${widget.event.clubId}');
      print('Event Club Name: ${widget.event.clubName}');

      try {
        Club? club;
        try {
          club = await _clubService.getClub(widget.event.clubId);
        } catch (e) {
          print('Erreur getClub: $e');
        }

        if (club == null) {
          print('Club non trouvé par ID, recherche dans tous les clubs...');
          final allClubs = await _clubService.getClubs();
          club = allClubs.firstWhere(
                (c) => c.nom == widget.event.clubName,
            orElse: () => Club(
              id: 0,
              nom: '',
              type: '',
              responsableId: 0,
              createurId: 0,
              description: '',
              status: '',
              dateCreation: DateTime.now(),
            ),
          );
        }

        if (club != null && club.id != 0) {
          print('✅ Club trouvé: ${club.nom}');
          print('✅ Club Responsable ID: ${club.responsableId}');

          final isAdmin = currentUser['id'] == club.responsableId;
          print('✅ Is Admin: $isAdmin');

          setState(() {
            _isAdmin = isAdmin;
          });
        } else {
          print('❌ Club non trouvé du tout');
          final isCreator = currentUser['id'] == widget.event.clubId;
          setState(() {
            _isAdmin = isCreator;
          });
          print('✅ Fallback - Is Creator: $isCreator');
        }
      } catch (e) {
        print('❌ Erreur récupération club: $e');
        final isCreator = currentUser['id'] == widget.event.clubId;
        setState(() {
          _isAdmin = isCreator;
        });
        print('✅ Fallback final - Is Creator: $isCreator');
      }
    }
  }

  Future<void> _toggleRegistration() async {
    setState(() { _isLoading = true; });

    final currentUser = await _authService.getCurrentUser();
    if (currentUser != null) {
      if (_isRegistered) {
        await _eventService.unregisterFromEvent(
            widget.event.id!,
            currentUser['id']!
        );
      } else {
        final participant = EventParticipant(
          eventId: widget.event.id!,
          userId: currentUser['id']!,
          userName: currentUser['name']!,
          userEmail: currentUser['email']!,
          registeredAt: DateTime.now(),
        );
        await _eventService.registerForEvent(participant);
      }

      await _checkRegistration();
      _loadData();
    }

    setState(() { _isLoading = false; });
  }

  Future<void> _cancelEvent() async {
    TextEditingController reasonController = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: Row(
              children: [
                Icon(Icons.warning, color: primaryAccent),
                SizedBox(width: 8),
                Text(
                  'Annuler l\'événement',
                  style: TextStyle(color: textPrimary),
                ),
              ],
            ),
            backgroundColor: background,
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Veuillez indiquer la raison de l\'annulation :',
                  style: TextStyle(color: textPrimary),
                ),
                SizedBox(height: 12),
                TextField(
                  controller: reasonController,
                  decoration: InputDecoration(
                    hintText: 'Raison de l\'annulation...',
                    border: OutlineInputBorder(),
                    filled: true,
                    fillColor: background,
                    errorText: reasonController.text.isEmpty ? 'Ce champ est obligatoire' : null,
                  ),
                  style: TextStyle(color: textPrimary),
                  maxLines: 3,
                  autofocus: true,
                  onChanged: (value) {
                    setState(() {});
                  },
                ),
                SizedBox(height: 12),
                Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: primaryAccent.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info, color: primaryAccent, size: 16),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Tous les participants seront automatiquement désinscrits',
                          style: TextStyle(fontSize: 12, color: primaryAccent),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(
                  'Retour',
                  style: TextStyle(color: textPrimary),
                ),
              ),
              ElevatedButton(
                onPressed: reasonController.text.trim().isEmpty ? null : () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryAccent,
                  foregroundColor: background,
                ),
                child: Text('Confirmer l\'annulation'),
              ),
            ],
          );
        },
      ),
    );

    if (confirmed == true && reasonController.text.trim().isNotEmpty) {
      setState(() { _isLoading = true; });

      final success = await _eventService.cancelEvent(
          widget.event.id!,
          reason: reasonController.text.trim()
      );

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Événement annulé avec succès'),
            backgroundColor: primaryAccent,
          ),
        );
        _loadData();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de l\'annulation'),
            backgroundColor: primaryAccent,
          ),
        );
      }

      setState(() { _isLoading = false; });
    }
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 20, color: textPrimary.withOpacity(0.6)),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(color: textPrimary),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_isDateFormatInitialized) {
      return Scaffold(
        appBar: AppBar(
          title: Text('Chargement...'),
          backgroundColor: primaryAccent,
          foregroundColor: background,
        ),
        backgroundColor: backgroundSecondary,
        body: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(primaryAccent),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: backgroundSecondary,
      appBar: AppBar(
        title: Text(
          widget.event.title,
          style: TextStyle(color: background),
        ),
        backgroundColor: primaryAccent,
        foregroundColor: background,
        actions: [
          if (_isAdmin && !widget.event.isCanceled && widget.event.isUpcoming)
            IconButton(
              icon: Icon(Icons.cancel),
              onPressed: _cancelEvent,
              tooltip: 'Annuler l\'événement',
            ),
        ],
      ),
      body: _isLoading
          ? Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(primaryAccent),
        ),
      )
          : Column(
        children: [
          // EN-TÊTE
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(16),
            color: widget.event.isCanceled ? primaryAccent.withOpacity(0.1) : Colors.blue.withOpacity(0.1),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (widget.event.isCanceled) ...[
                  Text(
                    'ÉVÉNEMENT ANNULÉ',
                    style: TextStyle(
                      color: primaryAccent,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  SizedBox(height: 8),
                  if (widget.event.cancelReason != null)
                    Container(
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: primaryAccent.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.info, color: primaryAccent, size: 20),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Raison: ${widget.event.cancelReason}',
                              style: TextStyle(
                                color: primaryAccent,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  SizedBox(height: 8),
                ],
                Text(
                  widget.event.title,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: textPrimary,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  widget.event.description,
                  style: TextStyle(
                    fontSize: 16,
                    color: textPrimary.withOpacity(0.8),
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                _loadData();
              },
              backgroundColor: background,
              color: primaryAccent,
              child: ListView(
                padding: EdgeInsets.all(16),
                children: [
                  // INFORMATIONS
                  Card(
                    color: background,
                    elevation: 2,
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Informations',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: textPrimary,
                            ),
                          ),
                          SizedBox(height: 12),
                          _buildInfoRow(
                            Icons.calendar_today,
                            'Début: ${DateFormat('dd/MM/yyyy à HH:mm').format(widget.event.startDate)}',
                          ),
                          _buildInfoRow(
                            Icons.calendar_today,
                            'Fin: ${DateFormat('dd/MM/yyyy à HH:mm').format(widget.event.endDate)}',
                          ),
                          _buildInfoRow(
                            Icons.location_on,
                            'Lieu: ${widget.event.location}',
                          ),
                          _buildInfoRow(
                            Icons.group,
                            'Club: ${widget.event.clubName}',
                          ),
                          if (widget.event.maxParticipants != null)
                            _buildInfoRow(
                              Icons.people,
                              'Participants: ${widget.event.currentParticipants}/${widget.event.maxParticipants}',
                            ),
                          if (widget.event.maxParticipants == null)
                            _buildInfoRow(
                              Icons.people,
                              'Participants: ${widget.event.currentParticipants}',
                            ),
                          if (_isAdmin)
                            _buildInfoRow(
                              Icons.admin_panel_settings,
                              'Vous êtes administrateur de cet événement',
                            ),
                        ],
                      ),
                    ),
                  ),

                  SizedBox(height: 16),

                  // BOUTON D'INSCRIPTION
                  if (!widget.event.isCanceled && widget.event.isUpcoming && !widget.event.isFull)
                    Card(
                      color: background,
                      elevation: 2,
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Column(
                          children: [
                            ElevatedButton(
                              onPressed: _isLoading ? null : _toggleRegistration,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _isRegistered
                                    ? textPrimary.withOpacity(0.6)
                                    : primaryAccent,
                                foregroundColor: background,
                                minimumSize: Size(double.infinity, 50),
                              ),
                              child: _isLoading
                                  ? CircularProgressIndicator(color: background)
                                  : Text(
                                _isRegistered ? 'SE DÉSINSCRIRE' : "S'INSCRIRE",
                                style: TextStyle(fontSize: 16),
                              ),
                            ),
                            if (widget.event.isFull)
                              Padding(
                                padding: EdgeInsets.only(top: 8),
                                child: Text(
                                  'Événement complet',
                                  style: TextStyle(
                                    color: primaryAccent,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),

                  SizedBox(height: 16),

                  // BOUTON D'ANNULATION POUR L'ADMIN
                  if (_isAdmin && !widget.event.isCanceled && widget.event.isUpcoming)
                    Card(
                      color: primaryAccent.withOpacity(0.1),
                      elevation: 2,
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Column(
                          children: [
                            Text(
                              'Gestion de l\'événement',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: primaryAccent,
                              ),
                            ),
                            SizedBox(height: 12),
                            ElevatedButton.icon(
                              onPressed: _cancelEvent,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: primaryAccent,
                                foregroundColor: background,
                                minimumSize: Size(double.infinity, 50),
                              ),
                              icon: Icon(Icons.cancel),
                              label: Text('Annuler l\'événement'),
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Attention : Tous les participants seront désinscrits',
                              style: TextStyle(
                                fontSize: 12,
                                color: primaryAccent,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ),

                  // MESSAGE SI L'UTILISATEUR N'EST PAS ADMIN
                  if (!_isAdmin && widget.event.isUpcoming)
                    Card(
                      color: background,
                      elevation: 2,
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Text(
                          'Seul l\'administrateur du club peut annuler cet événement',
                          style: TextStyle(color: textPrimary.withOpacity(0.6)),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),

                  SizedBox(height: 16),

                  // LISTE DES PARTICIPANTS
                  Card(
                    color: background,
                    elevation: 2,
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Participants (${widget.event.currentParticipants})',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: textPrimary,
                            ),
                          ),
                          SizedBox(height: 12),
                          FutureBuilder<List<EventParticipant>>(
                            future: _participantsFuture,
                            builder: (context, snapshot) {
                              if (snapshot.connectionState == ConnectionState.waiting) {
                                return Center(
                                  child: CircularProgressIndicator(
                                    valueColor: AlwaysStoppedAnimation<Color>(primaryAccent),
                                  ),
                                );
                              }

                              if (snapshot.hasError || snapshot.data == null || snapshot.data!.isEmpty) {
                                return Padding(
                                  padding: EdgeInsets.all(16),
                                  child: Text(
                                    'Aucun participant pour le moment',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(color: textPrimary.withOpacity(0.6)),
                                  ),
                                );
                              }

                              final participants = snapshot.data!;

                              return Column(
                                children: participants.map((participant) => ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor: primaryAccent,
                                    child: Text(
                                      participant.userName[0],
                                      style: TextStyle(color: background),
                                    ),
                                  ),
                                  title: Text(
                                    participant.userName,
                                    style: TextStyle(color: textPrimary),
                                  ),
                                  subtitle: Text(
                                    participant.userEmail,
                                    style: TextStyle(color: textPrimary.withOpacity(0.6)),
                                  ),
                                  trailing: Text(
                                    DateFormat('dd/MM').format(participant.registeredAt),
                                    style: TextStyle(color: textPrimary.withOpacity(0.6)),
                                  ),
                                )).toList(),
                              );
                            },
                          ),
                        ],
                      ),
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