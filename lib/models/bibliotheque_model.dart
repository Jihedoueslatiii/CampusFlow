// models/bibliotheque_model.dart
class Bibliotheque {
  final int? id;
  final String name;
  final String description;
  final String location;
  final String contactInfo;
  final DateTime createdAt;
  final DateTime updatedAt;

  Bibliotheque({
    this.id,
    required this.name,
    required this.description,
    required this.location,
    required this.contactInfo,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'location': location,
      'contact_info': contactInfo,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory Bibliotheque.fromMap(Map<String, dynamic> map) {
    return Bibliotheque(
      id: map['id'],
      name: map['name'],
      description: map['description'],
      location: map['location'],
      contactInfo: map['contact_info'],
      createdAt: DateTime.parse(map['created_at']),
      updatedAt: DateTime.parse(map['updated_at']),
    );
  }
}