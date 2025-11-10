class Matiere {
  int? id;
  String nom;
  String description;

  Matiere({
    this.id,
    required this.nom,
    required this.description,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nom': nom,
      'description': description,
    };
  }

  factory Matiere.fromMap(Map<String, dynamic> map) {
    return Matiere(
      id: map['id'],
      nom: map['nom'],
      description: map['description'],
    );
  }
}