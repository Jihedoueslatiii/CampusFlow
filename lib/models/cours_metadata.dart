class CoursMetadata {
  int? id;
  int coursId;
  double difficultyLevel; // 1-5
  double estimatedStudyHours;
  List<String> keyTopics;
  List<String> prerequisites;
  List<String> relatedSkills;
  String aiAnalysis;
  DateTime lastAnalyzed;

  CoursMetadata({
    this.id,
    required this.coursId,
    required this.difficultyLevel,
    required this.estimatedStudyHours,
    required this.keyTopics,
    required this.prerequisites,
    required this.relatedSkills,
    required this.aiAnalysis,
    DateTime? lastAnalyzed,
  }) : lastAnalyzed = lastAnalyzed ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'cours_id': coursId,
      'difficulty_level': difficultyLevel,
      'estimated_study_hours': estimatedStudyHours,
      'key_topics': keyTopics.join('|'),
      'prerequisites': prerequisites.join('|'),
      'related_skills': relatedSkills.join('|'),
      'ai_analysis': aiAnalysis,
      'last_analyzed': lastAnalyzed.toIso8601String(),
    };
  }

  factory CoursMetadata.fromMap(Map<String, dynamic> map) {
    return CoursMetadata(
      id: map['id'],
      coursId: map['cours_id'],
      difficultyLevel: map['difficulty_level'],
      estimatedStudyHours: map['estimated_study_hours'],
      keyTopics: (map['key_topics'] as String).split('|'),
      prerequisites: (map['prerequisites'] as String).split('|'),
      relatedSkills: (map['related_skills'] as String).split('|'),
      aiAnalysis: map['ai_analysis'],
      lastAnalyzed: DateTime.parse(map['last_analyzed']),
    );
  }
}