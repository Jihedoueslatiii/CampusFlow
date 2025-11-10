class Event {
  final int? id;
  final String title;
  final String description;
  final DateTime dateTime;
  final String location;
  final int maxParticipants;
  final int bibliothequeId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int? currentParticipants; // This is a calculated field, not in database

  Event({
    this.id,
    required this.title,
    required this.description,
    required this.dateTime,
    required this.location,
    required this.maxParticipants,
    required this.bibliothequeId,
    required this.createdAt,
    required this.updatedAt,
    this.currentParticipants, // This should not be in toMap() for updates
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'date_time': dateTime.toIso8601String(),
      'location': location,
      'max_participants': maxParticipants,
      'bibliotheque_id': bibliothequeId,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      // DO NOT include current_participants here - it's not a database column
    };
  }

  factory Event.fromMap(Map<String, dynamic> map) {
    return Event(
      id: map['id'],
      title: map['title'],
      description: map['description'],
      dateTime: DateTime.parse(map['date_time']),
      location: map['location'],
      maxParticipants: map['max_participants'],
      bibliothequeId: map['bibliotheque_id'],
      createdAt: DateTime.parse(map['created_at']),
      updatedAt: DateTime.parse(map['updated_at']),
      currentParticipants: map['current_participants'], // This comes from JOIN query
    );
  }

  bool get isUpcoming => dateTime.isAfter(DateTime.now());
}