import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/events_model.dart';
import '../../models/event_participant_model.dart';
import '../../services/event_service.dart';
import '../../services/auth_service.dart';
import 'event_details_screen.dart';

class EventListScreen extends StatefulWidget {
  @override
  _EventListScreenState createState() => _EventListScreenState();
}

class _EventListScreenState extends State<EventListScreen> with SingleTickerProviderStateMixin {
  final EventService _eventService = EventService();
  final AuthService _authService = AuthService();
  late TabController _tabController;

  // Color constants based on the palette
  static const Color primaryAccent = Color(0xFFE53935);
  static const Color background = Color(0xFFFFFFFF);
  static const Color textPrimary = Color(0xFF212121);
  static const Color backgroundSecondary = Color(0xFFF5F5F5);

  late Future<List<Event>> _upcomingEvents;
  late Future<List<Event>> _pastEvents;
  late Future<List<Event>> _canceledEvents;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadEvents();
  }

  void _loadEvents() {
    setState(() {
      _upcomingEvents = _eventService.getUpcomingEvents();
      _pastEvents = _eventService.getPastEvents();
      _canceledEvents = _eventService.getCanceledEvents();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundSecondary,
      appBar: AppBar(
        title: Text(
          'Événements',
          style: TextStyle(color: background),
        ),
        backgroundColor: primaryAccent,
        foregroundColor: background,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: background,
          labelColor: background,
          unselectedLabelColor: background.withOpacity(0.7),
          tabs: [
            Tab(text: 'À venir'),
            Tab(text: 'Passés'),
            Tab(text: 'Annulés'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // TAB À VENIR
          FutureBuilder<List<Event>>(
            future: _upcomingEvents,
            builder: (context, snapshot) {
              return _buildEventsList(snapshot, 'Aucun événement à venir');
            },
          ),
          // TAB PASSÉS
          FutureBuilder<List<Event>>(
            future: _pastEvents,
            builder: (context, snapshot) {
              return _buildEventsList(snapshot, 'Aucun événement passé');
            },
          ),
          // TAB ANNULÉS
          FutureBuilder<List<Event>>(
            future: _canceledEvents,
            builder: (context, snapshot) {
              return _buildEventsList(snapshot, 'Aucun événement annulé');
            },
          ),
        ],
      ),
    );
  }

  Widget _buildEventsList(AsyncSnapshot<List<Event>> snapshot, String emptyMessage) {
    if (snapshot.connectionState == ConnectionState.waiting) {
      return Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(primaryAccent),
        ),
      );
    }

    if (snapshot.hasError) {
      return Center(
        child: Text(
          'Erreur: ${snapshot.error}',
          style: TextStyle(color: textPrimary),
        ),
      );
    }

    final events = snapshot.data!;

    if (events.isEmpty) {
      return Center(
        child: Text(
          emptyMessage,
          style: TextStyle(color: textPrimary.withOpacity(0.6)),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async => _loadEvents(),
      backgroundColor: background,
      color: primaryAccent,
      child: ListView.builder(
        itemCount: events.length,
        itemBuilder: (context, index) {
          final event = events[index];
          return EventCard(
            event: event,
            onRefresh: _loadEvents,
          );
        },
      ),
    );
  }
}

class EventCard extends StatefulWidget {
  final Event event;
  final VoidCallback onRefresh;

  const EventCard({Key? key, required this.event, required this.onRefresh}) : super(key: key);

  @override
  _EventCardState createState() => _EventCardState();
}

class _EventCardState extends State<EventCard> {
  final EventService _eventService = EventService();
  final AuthService _authService = AuthService();

  // Color constants
  static const Color primaryAccent = Color(0xFFE53935);
  static const Color background = Color(0xFFFFFFFF);
  static const Color textPrimary = Color(0xFF212121);
  static const Color backgroundSecondary = Color(0xFFF5F5F5);

  bool _isRegistered = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _checkRegistration();
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
      widget.onRefresh();
    }

    setState(() { _isLoading = false; });
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      color: background,
      elevation: 2,
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: widget.event.isCanceled
                ? primaryAccent.withOpacity(0.2)
                : primaryAccent.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            widget.event.isCanceled ? Icons.cancel : Icons.event,
            color: widget.event.isCanceled ? primaryAccent : primaryAccent.withOpacity(0.8),
          ),
        ),
        title: Text(
          widget.event.title,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: textPrimary,
            decoration: widget.event.isCanceled ? TextDecoration.lineThrough : null,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${DateFormat('dd/MM/yyyy à HH:mm').format(widget.event.startDate)}',
              style: TextStyle(color: textPrimary.withOpacity(0.7)),
            ),
            Text(
              widget.event.clubName,
              style: TextStyle(color: textPrimary.withOpacity(0.7)),
            ),
            if (widget.event.isCanceled) ...[
              SizedBox(height: 4),
              Text(
                'ANNULÉ',
                style: TextStyle(
                  color: primaryAccent,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
              if (widget.event.cancelReason != null)
                Text(
                  'Raison: ${widget.event.cancelReason}',
                  style: TextStyle(
                    color: primaryAccent,
                    fontSize: 12,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
            ],
            if (widget.event.maxParticipants != null)
              Text(
                '${widget.event.currentParticipants}/${widget.event.maxParticipants} participants',
                style: TextStyle(
                  color: textPrimary.withOpacity(0.7),
                  fontSize: 12,
                ),
              ),
          ],
        ),
        trailing: widget.event.isCanceled ? null : _buildActionButton(),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => EventDetailsScreen(event: widget.event),
            ),
          ).then((_) => widget.onRefresh());
        },
      ),
    );
  }

  Widget _buildActionButton() {
    if (_isLoading) {
      return SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(primaryAccent),
        ),
      );
    }

    if (!widget.event.isUpcoming || widget.event.isFull) {
      return SizedBox.shrink();
    }

    return ElevatedButton(
      onPressed: _toggleRegistration,
      style: ElevatedButton.styleFrom(
        backgroundColor: _isRegistered
            ? textPrimary.withOpacity(0.6)
            : primaryAccent,
        foregroundColor: background,
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        minimumSize: Size(0, 0),
      ),
      child: Text(
        _isRegistered ? 'Inscrit' : 'S\'inscrire',
        style: TextStyle(fontSize: 12),
      ),
    );
  }
}