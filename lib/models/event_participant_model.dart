class EventParticipant {
  int? id;
  int eventId;
  int userId;
  String userName;
  String userEmail;
  DateTime registeredAt;
  bool hasReceivedReminder;

  EventParticipant({
    this.id,
    required this.eventId,
    required this.userId,
    required this.userName,
    required this.userEmail,
    required this.registeredAt,
    this.hasReceivedReminder = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'eventId': eventId,
      'userId': userId,
      'userName': userName,
      'userEmail': userEmail,
      'registeredAt': registeredAt.millisecondsSinceEpoch,
      'hasReceivedReminder': hasReceivedReminder ? 1 : 0,
    };
  }

  factory EventParticipant.fromMap(Map<String, dynamic> map) {
    return EventParticipant(
      id: map['id'],
      eventId: map['eventId'],
      userId: map['userId'],
      userName: map['userName'],
      userEmail: map['userEmail'],
      registeredAt: DateTime.fromMillisecondsSinceEpoch(map['registeredAt']),
      hasReceivedReminder: map['hasReceivedReminder'] == 1,
    );
  }
}