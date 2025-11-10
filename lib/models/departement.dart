class Departement {
  int? id;
  String nom;
  String chefDepartement;
  String createdAt;

  Departement({
    this.id,
    required this.nom,
    required this.chefDepartement,
    String? createdAt,
  }) : createdAt = createdAt ?? DateTime.now().toIso8601String();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nom': nom,
      'chef_departement': chefDepartement,
      'created_at': createdAt, // ⭐ Doit correspondre au nom dans la base
    };
  }

  factory Departement.fromMap(Map<String, dynamic> map) {
    return Departement(
      id: map['id'],
      nom: map['nom'],
      chefDepartement: map['chef_departement'],
      createdAt: map['created_at'], // ⭐ Doit correspondre au nom dans la base
    );
  }

  @override
  String toString() {
    return 'Departement{id: $id, nom: $nom, chefDepartement: $chefDepartement, createdAt: $createdAt}';
  }
}