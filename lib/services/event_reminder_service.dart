import 'package:flutter/material.dart';
import '../models/events_model.dart';
import '../models/event_participant_model.dart';
import 'event_service.dart';

class EventReminderService {
  final EventService _eventService = EventService();

  Future<void> initialize() async {
    // Archivage automatique des événements passés
    await _eventService.autoArchivePastEvents();

    // Vérification des rappels
    await _checkReminders();
  }

  Future<void> _checkReminders() async {
    final events = await _eventService.getUpcomingEvents();
    final now = DateTime.now();

    for (final event in events) {
      // Rappel 24h avant
      if (event.reminderDate != null &&
          event.reminderDate!.isBefore(now) &&
          event.startDate.isAfter(now)) {

        final participants = await _eventService.getEventParticipants(event.id!);

        for (final participant in participants) {
          if (!participant.hasReceivedReminder) {
            await _sendReminderNotification(event, participant);
          }
        }
      }
    }
  }

  Future<void> _sendReminderNotification(Event event, EventParticipant participant) async {
    // Marquer le rappel comme envoyé
    // Implémentation avec votre système de notifications

    print('🔔 Rappel: "${event.title}" pour ${participant.userName}');

    // Ici vous pouvez utiliser:
    // - ScaffoldMessenger pour les notifications in-app
    // - flutter_local_notifications pour les notifications push
    // - Votre propre système de notifications
  }

  // Méthode pour afficher une notification in-app
  static void showInAppNotification(BuildContext context, String title, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(title, style: TextStyle(fontWeight: FontWeight.bold)),
            Text(message),
          ],
        ),
        duration: Duration(seconds: 5),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}