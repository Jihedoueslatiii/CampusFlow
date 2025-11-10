import 'package:sqflite/sqflite.dart';
import '../models/events_model.dart';
import '../models/event_participant_model.dart';
import 'database_service.dart';
import 'auth_service.dart';

class EventService {
  final DatabaseService _databaseService = DatabaseService();
  final AuthService _authService = AuthService();

  // CRUD pour les événements
  Future<int> createEvent(Event event) async {
    if (event.startDate.isBefore(DateTime.now())) {
      throw Exception("Impossible de créer un événement dans le passé");
    }

    if (!event.isValidDuration) {
      throw Exception("La durée maximale est de 5 heures");
    }

    final db = await _databaseService.database;
    event.reminderDate = event.startDate.subtract(Duration(hours: 24));

    final eventId = await db.insert('events', event.toMap());

    // Notification de création
    _notifyEventCreated(event);

    return eventId;
  }

  Future<List<Event>> getUpcomingEvents() async {
    final db = await _databaseService.database;
    final List<Map<String, dynamic>> maps = await db.query(
        'events',
        where: 'isActive = ? AND isCanceled = ? AND isArchived = ? AND endDate > ?',
        whereArgs: [1, 0, 0, DateTime.now().millisecondsSinceEpoch],
        orderBy: 'startDate ASC'
    );
    return List.generate(maps.length, (i) => Event.fromMap(maps[i]));
  }

  Future<List<Event>> getClubEvents(int clubId) async {
    final db = await _databaseService.database;
    final List<Map<String, dynamic>> maps = await db.query(
        'events',
        where: 'clubId = ? AND isActive = ? AND isCanceled = ?',
        whereArgs: [clubId, 1, 0],
        orderBy: 'startDate ASC'
    );
    return List.generate(maps.length, (i) => Event.fromMap(maps[i]));
  }

  Future<List<Event>> getPastEvents() async {
    final db = await _databaseService.database;
    final List<Map<String, dynamic>> maps = await db.query(
        'events',
        where: 'isActive = ? AND isArchived = ? AND endDate < ?',
        whereArgs: [1, 1, DateTime.now().millisecondsSinceEpoch],
        orderBy: 'startDate DESC'
    );
    return List.generate(maps.length, (i) => Event.fromMap(maps[i]));
  }

  Future<List<Event>> getCanceledEvents() async {
    final db = await _databaseService.database;
    final List<Map<String, dynamic>> maps = await db.query(
        'events',
        where: 'isCanceled = ?',
        whereArgs: [1],
        orderBy: 'startDate DESC'
    );
    return List.generate(maps.length, (i) => Event.fromMap(maps[i]));
  }

  Future<Event?> getEvent(int id) async {
    final db = await _databaseService.database;
    final List<Map<String, dynamic>> maps = await db.query(
        'events',
        where: 'id = ?',
        whereArgs: [id]
    );
    if (maps.isNotEmpty) {
      return Event.fromMap(maps.first);
    }
    return null;
  }

  Future<bool> updateEvent(Event event) async {
    final db = await _databaseService.database;
    final result = await db.update(
        'events',
        event.toMap(),
        where: 'id = ?',
        whereArgs: [event.id]
    );
    return result > 0;
  }

  Future<bool> cancelEvent(int eventId, {String? reason}) async {
    final db = await _databaseService.database;

    final result = await db.update(
        'events',
        {
          'isCanceled': 1,
          'cancelReason': reason ?? 'Annulé par l\'organisateur' // AJOUT
        },
        where: 'id = ?',
        whereArgs: [eventId]
    );

    if (result > 0) {
      await db.delete(
          'event_participants',
          where: 'eventId = ?',
          whereArgs: [eventId]
      );

      final event = await getEvent(eventId);
      if (event != null) {
        _notifyEventCanceled(event, reason);
      }
    }

    return result > 0;
  }
  Future<List<Event>> getUserRegisteredEvents(int userId) async {
    final db = await _databaseService.database;
    final List<Map<String, dynamic>> maps = await db.rawQuery('''
      SELECT e.* FROM events e
      INNER JOIN event_participants ep ON e.id = ep.eventId
      WHERE ep.userId = ?
      ORDER BY e.startDate DESC
    ''', [userId]);

    return List.generate(maps.length, (i) => Event.fromMap(maps[i]));
  }



  // NOUVELLE MÉTHODE : Événements annulés auxquels l'utilisateur était inscrit
  Future<List<Event>> getUserCanceledEvents(int userId) async {
    final db = await _databaseService.database;
    final List<Map<String, dynamic>> maps = await db.rawQuery('''
      SELECT e.* FROM events e
      INNER JOIN event_participants ep ON e.id = ep.eventId
      WHERE ep.userId = ? AND e.isCanceled = 1
      ORDER BY e.startDate DESC
    ''', [userId]);

    return List.generate(maps.length, (i) => Event.fromMap(maps[i]));
  }

  // MODIFIER la notification d'annulation
  void _notifyEventCanceled(Event event, String? reason) {
    print('Notification: Événement "${event.title}" annulé. Raison: $reason');
  }

  // PARTICIPATION
  Future<bool> registerForEvent(EventParticipant participant) async {
    try {
      final db = await _databaseService.database;

      // Vérifier si l'événement existe et n'est pas complet
      final event = await getEvent(participant.eventId);
      if (event == null || event.isCanceled || event.isFull) {
        return false;
      }

      await db.insert('event_participants', participant.toMap());

      // Mettre à jour le compteur de participants
      await db.update(
          'events',
          {'currentParticipants': event.currentParticipants + 1},
          where: 'id = ?',
          whereArgs: [event.id]
      );

      return true;
    } catch (e) {
      return false; // Déjà inscrit
    }
  }

  Future<bool> unregisterFromEvent(int eventId, int userId) async {
    final db = await _databaseService.database;
    final result = await db.delete(
        'event_participants',
        where: 'eventId = ? AND userId = ?',
        whereArgs: [eventId, userId]
    );

    if (result > 0) {
      // Mettre à jour le compteur de participants
      final event = await getEvent(eventId);
      if (event != null) {
        await db.update(
            'events',
            {'currentParticipants': event.currentParticipants - 1},
            where: 'id = ?',
            whereArgs: [event.id]
        );
      }
    }

    return result > 0;
  }

  Future<List<EventParticipant>> getEventParticipants(int eventId) async {
    final db = await _databaseService.database;
    final List<Map<String, dynamic>> maps = await db.query(
        'event_participants',
        where: 'eventId = ?',
        whereArgs: [eventId]
    );
    return List.generate(maps.length, (i) => EventParticipant.fromMap(maps[i]));
  }

  Future<bool> isUserRegistered(int eventId, int userId) async {
    final db = await _databaseService.database;
    final List<Map<String, dynamic>> maps = await db.query(
        'event_participants',
        where: 'eventId = ? AND userId = ?',
        whereArgs: [eventId, userId]
    );
    return maps.isNotEmpty;
  }

  Future<List<Event>> getUserEvents(int userId) async {
    final db = await _databaseService.database;
    final List<Map<String, dynamic>> maps = await db.rawQuery('''
      SELECT e.* FROM events e
      INNER JOIN event_participants ep ON e.id = ep.eventId
      WHERE ep.userId = ? AND e.isActive = 1 AND e.isCanceled = 0
      ORDER BY e.startDate ASC
    ''', [userId]);

    return List.generate(maps.length, (i) => Event.fromMap(maps[i]));
  }

  // ARCHIVAGE AUTOMATIQUE
  Future<void> autoArchivePastEvents() async {
    final db = await _databaseService.database;
    await db.update(
        'events',
        {'isArchived': 1},
        where: 'endDate < ? AND isArchived = ? AND isCanceled = ?',
        whereArgs: [DateTime.now().millisecondsSinceEpoch, 0, 0]
    );
  }

  // NOTIFICATIONS
  void _notifyEventCreated(Event event) {
    // Implémentation des notifications in-app
    // (à connecter avec votre système de notifications)
    print('Notification: Nouvel événement "${event.title}" créé');
  }


  // RAPPELS AUTOMATIQUES
  Future<void> checkReminders() async {
    final events = await getUpcomingEvents();
    final now = DateTime.now();

    for (final event in events) {
      if (event.reminderDate != null &&
          event.reminderDate!.isBefore(now) &&
          event.startDate.isAfter(now)) {

        final participants = await getEventParticipants(event.id!);

        for (final participant in participants) {
          if (!participant.hasReceivedReminder) {
            _sendReminder(event, participant);
          }
        }
      }
    }
  }

  void _sendReminder(Event event, EventParticipant participant) {
    // Envoyer rappel 24h avant
    print('Rappel: ${event.title} pour ${participant.userName}');
  }
}