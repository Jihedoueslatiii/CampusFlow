import 'package:flutter/material.dart';
import '../models/quiz.dart';

class QuizScreen extends StatefulWidget {
  final Quiz quiz;

  const QuizScreen({super.key, required this.quiz});

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> with SingleTickerProviderStateMixin {
  int _currentQuestionIndex = 0;
  bool _quizCompleted = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  // Color Palette
  static const Color primaryRed = Color(0xFFE53935);
  static const Color backgroundWhite = Color(0xFFFFFFFF);
  static const Color textDark = Color(0xFF212121);
  static const Color neutralGray = Color(0xFFF5F5F5);

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _selectAnswer(int answerIndex) {
    setState(() {
      widget.quiz.questions[_currentQuestionIndex].selectedAnswerIndex = answerIndex;
    });
  }

  void _nextQuestion() {
    if (_currentQuestionIndex < widget.quiz.questions.length - 1) {
      setState(() {
        _currentQuestionIndex++;
        _animationController.reset();
        _animationController.forward();
      });
    } else {
      _completeQuiz();
    }
  }

  void _previousQuestion() {
    if (_currentQuestionIndex > 0) {
      setState(() {
        _currentQuestionIndex--;
        _animationController.reset();
        _animationController.forward();
      });
    }
  }

  void _completeQuiz() {
    final score = widget.quiz.questions.where((q) => q.isCorrect).length;

    setState(() {
      _quizCompleted = true;
      widget.quiz.score = score;
      _animationController.reset();
      _animationController.forward();
    });
  }

  void _restartQuiz() {
    setState(() {
      _currentQuestionIndex = 0;
      _quizCompleted = false;
      for (var question in widget.quiz.questions) {
        question.selectedAnswerIndex = null;
      }
      widget.quiz.score = 0;
      _animationController.reset();
      _animationController.forward();
    });
  }

  Widget _buildQuestionCard() {
    final question = widget.quiz.questions[_currentQuestionIndex];

    return FadeTransition(
      opacity: _fadeAnimation,
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Question Number and Progress
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: primaryRed.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'Question ${_currentQuestionIndex + 1}/${widget.quiz.questions.length}',
                      style: const TextStyle(
                        fontSize: 14,
                        color: primaryRed,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Progress Bar
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(
                  value: (_currentQuestionIndex + 1) / widget.quiz.questions.length,
                  backgroundColor: neutralGray,
                  valueColor: const AlwaysStoppedAnimation<Color>(primaryRed),
                  minHeight: 8,
                ),
              ),
              const SizedBox(height: 32),

              // Question Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: backgroundWhite,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 20,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: primaryRed.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.quiz,
                            color: primaryRed,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text(
                            'Choisissez la bonne réponse',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Question Text
                    Text(
                      question.question,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: textDark,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Options
              Column(
                children: List.generate(question.options.length, (index) {
                  final isSelected = question.selectedAnswerIndex == index;
                  final isAnswered = question.selectedAnswerIndex != null;
                  final isCorrect = index == question.correctAnswerIndex;

                  Color getBorderColor() {
                    if (!isAnswered) {
                      return isSelected ? primaryRed : Colors.grey.shade300;
                    }
                    if (isCorrect) return Colors.green.shade600;
                    if (isSelected && !isCorrect) return Colors.red.shade600;
                    return Colors.grey.shade300;
                  }

                  Color getBackgroundColor() {
                    if (!isAnswered) {
                      return isSelected ? primaryRed.withOpacity(0.05) : backgroundWhite;
                    }
                    if (isCorrect) return Colors.green.shade50;
                    if (isSelected && !isCorrect) return Colors.red.shade50;
                    return backgroundWhite;
                  }

                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: getBackgroundColor(),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: getBorderColor(),
                        width: isSelected ? 2.5 : 1.5,
                      ),
                      boxShadow: isSelected && !isAnswered
                          ? [
                        BoxShadow(
                          color: primaryRed.withOpacity(0.2),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ]
                          : [],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: isAnswered ? null : () => _selectAnswer(index),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              // Option Letter
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: isSelected && !isAnswered
                                      ? primaryRed
                                      : isCorrect && isAnswered
                                      ? Colors.green.shade600
                                      : isSelected && !isCorrect && isAnswered
                                      ? Colors.red.shade600
                                      : neutralGray,
                                ),
                                child: Center(
                                  child: Text(
                                    String.fromCharCode(65 + index),
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                      color: isSelected || (isCorrect && isAnswered)
                                          ? backgroundWhite
                                          : textDark,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),

                              // Option Text
                              Expanded(
                                child: Text(
                                  question.options[index],
                                  style: TextStyle(
                                    color: textDark,
                                    fontSize: 16,
                                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                                  ),
                                ),
                              ),

                              // Result Icon
                              if (isAnswered && isCorrect)
                                const Icon(
                                  Icons.check_circle_rounded,
                                  color: Colors.green,
                                  size: 28,
                                )
                              else if (isAnswered && isSelected && !isCorrect)
                                const Icon(
                                  Icons.cancel_rounded,
                                  color: Colors.red,
                                  size: 28,
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 100), // Space for bottom navigation
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResultsScreen() {
    final correctAnswers = widget.quiz.score;
    final totalQuestions = widget.quiz.questions.length;
    final percentage = widget.quiz.percentage;

    Color getScoreColor() {
      if (percentage >= 80) return Colors.green.shade600;
      if (percentage >= 60) return Colors.orange.shade600;
      return primaryRed;
    }

    String getScoreMessage() {
      if (percentage >= 80) return 'Excellent travail!';
      if (percentage >= 60) return 'Bon travail!';
      return 'Continuez à étudier!';
    }

    IconData getScoreIcon() {
      if (percentage >= 80) return Icons.emoji_events;
      if (percentage >= 60) return Icons.thumb_up;
      return Icons.school;
    }

    return FadeTransition(
      opacity: _fadeAnimation,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Score Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: backgroundWhite,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 20,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Trophy Icon
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: getScoreColor().withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      getScoreIcon(),
                      size: 64,
                      color: getScoreColor(),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Score Message
                  Text(
                    getScoreMessage(),
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: textDark,
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Score Circle
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        width: 160,
                        height: 160,
                        child: CircularProgressIndicator(
                          value: percentage / 100,
                          strokeWidth: 12,
                          backgroundColor: neutralGray,
                          valueColor: AlwaysStoppedAnimation<Color>(getScoreColor()),
                        ),
                      ),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '${percentage.round()}%',
                            style: TextStyle(
                              fontSize: 48,
                              fontWeight: FontWeight.bold,
                              color: textDark,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '$correctAnswers/$totalQuestions',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  Text(
                    'réponses correctes',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Review Section
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: backgroundWhite,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 20,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: primaryRed.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.summarize,
                          color: primaryRed,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'Résumé des réponses',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: textDark,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Question Results
                  ...widget.quiz.questions.asMap().entries.map((entry) {
                    final idx = entry.key;
                    final q = entry.value;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: q.isCorrect
                            ? Colors.green.shade50
                            : Colors.red.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: q.isCorrect
                              ? Colors.green.shade200
                              : Colors.red.shade200,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: q.isCorrect
                                  ? Colors.green.shade600
                                  : Colors.red.shade600,
                            ),
                            child: Center(
                              child: Text(
                                '${idx + 1}',
                                style: const TextStyle(
                                  color: backgroundWhite,
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              q.isCorrect ? 'Réponse correcte' : 'Réponse incorrecte',
                              style: TextStyle(
                                color: textDark,
                                fontWeight: FontWeight.w600,
                                fontSize: 15,
                              ),
                            ),
                          ),
                          Icon(
                            q.isCorrect
                                ? Icons.check_circle_rounded
                                : Icons.cancel_rounded,
                            color: q.isCorrect
                                ? Colors.green.shade600
                                : Colors.red.shade600,
                            size: 24,
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _restartQuiz,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: primaryRed,
                      side: const BorderSide(color: primaryRed, width: 2),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Recommencer',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryRed,
                      foregroundColor: backgroundWhite,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Terminer',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: neutralGray,
      appBar: AppBar(
        title: Text(
          widget.quiz.courseName,
          style: const TextStyle(
            color: backgroundWhite,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: primaryRed,
        elevation: 0,
        iconTheme: const IconThemeData(color: backgroundWhite),
        actions: [
          if (!_quizCompleted)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: backgroundWhite.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${_currentQuestionIndex + 1}/${widget.quiz.questions.length}',
                    style: const TextStyle(
                      color: backgroundWhite,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
      body: _quizCompleted ? _buildResultsScreen() : _buildQuestionCard(),
      bottomNavigationBar: _quizCompleted
          ? null
          : Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: backgroundWhite,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          child: Row(
            children: [
              // Previous Button
              if (_currentQuestionIndex > 0)
                Expanded(
                  child: OutlinedButton(
                    onPressed: _previousQuestion,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: primaryRed,
                      side: const BorderSide(color: primaryRed, width: 2),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.arrow_back, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'Précédent',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              if (_currentQuestionIndex > 0) const SizedBox(width: 12),

              // Next/Submit Button
              Expanded(
                flex: _currentQuestionIndex == 0 ? 1 : 1,
                child: ElevatedButton(
                  onPressed: widget.quiz.questions[_currentQuestionIndex]
                      .selectedAnswerIndex !=
                      null
                      ? _nextQuestion
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryRed,
                    foregroundColor: backgroundWhite,
                    disabledBackgroundColor: Colors.grey.shade300,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _currentQuestionIndex == widget.quiz.questions.length - 1
                            ? 'Terminer'
                            : 'Suivant',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        _currentQuestionIndex == widget.quiz.questions.length - 1
                            ? Icons.check_circle
                            : Icons.arrow_forward,
                        size: 20,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}