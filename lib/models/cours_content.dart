class CoursContent {
  int? id;
  int coursId;
  String content;
  String contentType;
  double aiConfidence;
  String generatedBy;
  DateTime createdAt;

  CoursContent({
    this.id,
    required this.coursId,
    required this.content,
    required this.contentType,
    this.aiConfidence = 1.0,
    this.generatedBy = 'ai_generated',
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'cours_id': coursId,
      'content': content,
      'content_type': contentType,
      'ai_confidence': aiConfidence,
      'generated_by': generatedBy,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory CoursContent.fromMap(Map<String, dynamic> map) {
    return CoursContent(
      id: map['id'],
      coursId: map['cours_id'],
      content: map['content'],
      contentType: map['content_type'],
      aiConfidence: map['ai_confidence'],
      generatedBy: map['generated_by'],
      createdAt: DateTime.parse(map['created_at']),
    );
  }
}