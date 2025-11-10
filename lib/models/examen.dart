class Examen {
  final int? id;
  final String type; // "partiel" or "final"
  final DateTime date;
  final String cours;
  final int dureeMinutes;
  final int? salleId;

  final String? status; // Scheduled, In Progress, Completed, Cancelled
  final String? result; // grade/comments
  final String? notes; // textual notes
  final List<String>? files; // paths to files
  final DateTime? reminder1Day;
  final DateTime? reminder1Hour;

  Examen({
    this.id,
    required this.type,
    required this.date,
    required this.cours,
    required this.dureeMinutes,
    this.salleId,
    this.status,
    this.result,
    this.notes,
    this.files,
    this.reminder1Day,
    this.reminder1Hour,
  });

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'type': type,
      'date': date.toIso8601String(),
      'cours': cours,
      'dureeMinutes': dureeMinutes,
      'salleId': salleId,
      'status': status,
      'result': result,
      'notes': notes,
      'files': files != null ? files!.join(',') : null,
      'reminder1Day': reminder1Day?.toIso8601String(),
      'reminder1Hour': reminder1Hour?.toIso8601String(),
    };
    if (id != null) map['id'] = id;
    return map;
  }

  factory Examen.fromMap(Map<String, dynamic> map) {
    return Examen(
      id: map['id'] as int?,
      type: map['type'] as String,
      date: DateTime.parse(map['date'] as String),
      cours: map['cours'] as String,
      dureeMinutes: map['dureeMinutes'] as int,
      salleId: map['salleId'] as int?,
      status: map['status'] as String?,
      result: map['result'] as String?,
      notes: map['notes'] as String?,
      files: map['files'] != null ? (map['files'] as String).split(',') : null,
      reminder1Day: map['reminder1Day'] != null ? DateTime.parse(map['reminder1Day']) : null,
      reminder1Hour: map['reminder1Hour'] != null ? DateTime.parse(map['reminder1Hour']) : null,
    );
  }
}
