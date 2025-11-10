class Quiz {
  final String id;
  final String courseName;
  final List<QuizQuestion> questions;
  final DateTime createdAt;
  int score;
  final int totalQuestions;

  Quiz({
    required this.id,
    required this.courseName,
    required this.questions,
    required this.createdAt,
    this.score = 0,
    required this.totalQuestions,
  });

  double get percentage => totalQuestions > 0 ? (score / totalQuestions * 100) : 0;
}

class QuizQuestion {
  final String question;
  final List<String> options;
  final int correctAnswerIndex;
  int? selectedAnswerIndex;

  QuizQuestion({
    required this.question,
    required this.options,
    required this.correctAnswerIndex,
    this.selectedAnswerIndex,
  });

  bool get isCorrect => selectedAnswerIndex == correctAnswerIndex;
}