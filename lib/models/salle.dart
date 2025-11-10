// lib/models/salle.dart
class Salle {
  final int? id;
  final String numero;
  final int capacite;
  final String type; // "TP" or "Cours magistral"
  final String batiment;

  Salle({
    this.id,
    required this.numero,
    required this.capacite,
    required this.type,
    required this.batiment,
  });

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'numero': numero,
      'capacite': capacite,
      'type': type,
      'batiment': batiment,
    };
    if (id != null) map['id'] = id;
    return map;
  }

  factory Salle.fromMap(Map<String, dynamic> map) {
    return Salle(
      id: map['id'] as int?,
      numero: map['numero'] as String,
      capacite: map['capacite'] as int,
      type: map['type'] as String,
      batiment: map['batiment'] as String,
    );
  }
}
