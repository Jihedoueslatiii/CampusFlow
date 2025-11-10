import 'package:sqflite/sqflite.dart';
import '../models/event_model.dart';
import '../services/database_service.dart';

class EventRepository {
  final DatabaseService databaseService;

  EventRepository(this.databaseService);

  Future<int> createEvent(Event event) async {
    final db = await databaseService.database;
    return await db.insert('events', event.toMap());
  }

  // UPDATED: Get events with participant count
  Future<List<Event>> getEvents() async {
    try {
      final db = await databaseService.database;

      // Check if event_participants table exists
      final tableExists = await _checkTableExists('event_participants');
      if (!tableExists) {
        // If table doesn't exist, return events without participant count
        final List<Map<String, dynamic>> maps = await db.query('events');
        return List.generate(maps.length, (i) {
          final eventMap = maps[i];
          return Event.fromMap({
            ...eventMap,
            'current_participants': 0, // Default to 0
          });
        });
      }

      final List<Map<String, dynamic>> maps = await db.rawQuery('''
        SELECT e.*, COUNT(ep.user_id) as current_participants
        FROM events e
        LEFT JOIN event_participants ep ON e.id = ep.event_id
        GROUP BY e.id
        ORDER BY e.date_time ASC
      ''');
      return List.generate(maps.length, (i) => Event.fromMap(maps[i]));
    } catch (e) {
      print('Error in getEvents: $e');
      // Fallback: return events without participant count
      final db = await databaseService.database;
      final List<Map<String, dynamic>> maps = await db.query('events');
      return List.generate(maps.length, (i) {
        final eventMap = maps[i];
        return Event.fromMap({
          ...eventMap,
          'current_participants': 0,
        });
      });
    }
  }

  Future<List<Event>> getEventsByBibliotheque(int bibliothequeId) async {
    final db = await databaseService.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'events',
      where: 'bibliotheque_id = ?',
      whereArgs: [bibliothequeId],
    );
    return List.generate(maps.length, (i) {
      final eventMap = maps[i];
      return Event.fromMap({
        ...eventMap,
        'current_participants': 0, // Default value
      });
    });
  }

  // UPDATED: Update event - only update actual database columns
  Future<int> updateEvent(Event event) async {
    final db = await databaseService.database;

    // Create a map without the calculated field
    final updateData = {
      'title': event.title,
      'description': event.description,
      'date_time': event.dateTime.toIso8601String(),
      'location': event.location,
      'max_participants': event.maxParticipants,
      'bibliotheque_id': event.bibliothequeId,
      'updated_at': DateTime.now().toIso8601String(),
      // Keep the original created_at
      'created_at': event.createdAt.toIso8601String(),
    };

    return await db.update(
      'events',
      updateData, // Use the clean map without calculated fields
      where: 'id = ?',
      whereArgs: [event.id],
    );
  }

  Future<int> deleteEvent(int id) async {
    final db = await databaseService.database;
    return await db.delete(
      'events',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Participation methods
  Future<void> participateInEvent(int eventId, int userId) async {
    try {
      final db = await databaseService.database;
      final tableExists = await _checkTableExists('event_participants');

      if (!tableExists) {
        await _createEventParticipantsTable(db);
      }

      await db.insert('event_participants', {
        'event_id': eventId,
        'user_id': userId,
        'participation_date': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      print('Error in participateInEvent: $e');
      throw Exception('Impossible de participer à l\'événement');
    }
  }

  Future<void> cancelParticipation(int eventId, int userId) async {
    try {
      final db = await databaseService.database;
      final tableExists = await _checkTableExists('event_participants');

      if (!tableExists) {
        return; // Table doesn't exist, nothing to cancel
      }

      await db.delete(
        'event_participants',
        where: 'event_id = ? AND user_id = ?',
        whereArgs: [eventId, userId],
      );
    } catch (e) {
      print('Error in cancelParticipation: $e');
      throw Exception('Impossible d\'annuler la participation');
    }
  }

  Future<bool> isUserParticipating(int eventId, int userId) async {
    try {
      final db = await databaseService.database;
      final tableExists = await _checkTableExists('event_participants');

      if (!tableExists) {
        return false; // Table doesn't exist, user is not participating
      }

      final List<Map<String, dynamic>> maps = await db.query(
        'event_participants',
        where: 'event_id = ? AND user_id = ?',
        whereArgs: [eventId, userId],
      );
      return maps.isNotEmpty;
    } catch (e) {
      print('Error in isUserParticipating: $e');
      return false;
    }
  }

  // Helper methods
  Future<bool> _checkTableExists(String tableName) async {
    final db = await databaseService.database;
    final List<Map<String, dynamic>> result = await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type='table' AND name=?",
      [tableName],
    );
    return result.isNotEmpty;
  }

  Future<void> _createEventParticipantsTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS event_participants (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        event_id INTEGER NOT NULL,
        user_id INTEGER NOT NULL,
        participation_date DATETIME DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (event_id) REFERENCES events (id) ON DELETE CASCADE,
        UNIQUE(event_id, user_id)
      )
    ''');
  }
}