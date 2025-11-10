class Cours {
  int? id;
  String nom;
  String description;
  String semestre;
  int credits;
  int? departementId;
  String createdAt;
  String? departementNom;
  String? pdfPath; // ⭐ NOUVEAU: Chemin du fichier PDF
  String? pdfName; // ⭐ NOUVEAU: Nom du fichier PDF

  Cours({
    this.id,
    required this.nom,
    required this.description,
    required this.semestre,
    required this.credits,
    this.departementId,
    this.departementNom,
    this.pdfPath, // ⭐ NOUVEAU
    this.pdfName, // ⭐ NOUVEAU
    String? createdAt,
  }) : createdAt = createdAt ?? DateTime.now().toIso8601String();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nom': nom,
      'description': description,
      'semestre': semestre,
      'credits': credits,
      'departement_id': departementId,
      'pdf_path': pdfPath, // ⭐ NOUVEAU
      'pdf_name': pdfName, // ⭐ NOUVEAU
      'created_at': createdAt,
    };
  }

  factory Cours.fromMap(Map<String, dynamic> map) {
    return Cours(
      id: map['id'],
      nom: map['nom'],
      description: map['description'],
      semestre: map['semestre'],
      credits: map['credits'],
      departementId: map['departement_id'],
      pdfPath: map['pdf_path'], // ⭐ NOUVEAU
      pdfName: map['pdf_name'], // ⭐ NOUVEAU
      createdAt: map['created_at'],
    );
  }

  @override
  String toString() {
    return 'Cours{id: $id, nom: $nom, département: $departementId}';
  }

  // Méthode pour vérifier si un PDF est attaché
  bool get hasPdf => pdfPath != null && pdfPath!.isNotEmpty;
}