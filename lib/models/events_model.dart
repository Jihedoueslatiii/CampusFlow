import 'dart:convert';

class Event {
  int? id;
  String title;
  String description;
  DateTime startDate;
  DateTime endDate;
  DateTime? reminderDate; // 24h avant
  int clubId;
  String clubName;
  String location;
  int? maxParticipants; // Optionnel
  int currentParticipants;
  DateTime createdAt;
  bool isActive;
  bool isCanceled;
  bool isArchived;
  String? cancelReason;

  Event({
    this.id,
    required this.title,
    required this.description,
    required this.startDate,
    required this.endDate,
    this.reminderDate,
    required this.clubId,
    required this.clubName,
    required this.location,
    this.maxParticipants,
    this.currentParticipants = 0,
    required this.createdAt,
    this.isActive = true,
    this.isCanceled = false,
    this.isArchived = false,
    this.cancelReason,
  });

  // Validation de la durée (max 5 heures)
  bool get isValidDuration {
    final duration = endDate.difference(startDate);
    return duration.inHours <= 5 && duration.inHours >= 1;
  }

  // Vérifie si l'événement est complet
  bool get isFull {
    return maxParticipants != null && currentParticipants >= maxParticipants!;
  }

  // Vérifie si l'événement est à venir
  bool get isUpcoming {
    return startDate.isAfter(DateTime.now());
  }

  // Vérifie si l'événement est passé
  bool get isPast {
    return endDate.isBefore(DateTime.now());
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'startDate': startDate.millisecondsSinceEpoch,
      'endDate': endDate.millisecondsSinceEpoch,
      'reminderDate': reminderDate?.millisecondsSinceEpoch,
      'clubId': clubId,
      'clubName': clubName,
      'location': location,
      'maxParticipants': maxParticipants,
      'currentParticipants': currentParticipants,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'isActive': isActive ? 1 : 0,
      'isCanceled': isCanceled ? 1 : 0,
      'isArchived': isArchived ? 1 : 0,
      'cancelReason': cancelReason,
    };
  }

  factory Event.fromMap(Map<String, dynamic> map) {
    return Event(
      id: map['id'],
      title: map['title'],
      description: map['description'],
      startDate: DateTime.fromMillisecondsSinceEpoch(map['startDate']),
      endDate: DateTime.fromMillisecondsSinceEpoch(map['endDate']),
      reminderDate: map['reminderDate'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['reminderDate'])
          : null,
      clubId: map['clubId'],
      clubName: map['clubName'],
      location: map['location'],
      maxParticipants: map['maxParticipants'],
      currentParticipants: map['currentParticipants'] ?? 0,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt']),
      isActive: map['isActive'] == 1,
      isCanceled: map['isCanceled'] == 1,
      isArchived: map['isArchived'] == 1,
      cancelReason: map['cancelReason'],
    );
  }
}