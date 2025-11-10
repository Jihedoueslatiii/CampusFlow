import 'dart:convert';
import 'package:compusflow/models/quiz.dart';
import 'package:http/http.dart' as http;

class GeminiService {
  static const String _apiKey = 'AIzaSyAaVgNCZPXkkdNZOHIVR03u-dgmJ0uAvcg';
  static const String _baseUrl = 'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash-exp:generateContent';

  Future<List<QuizQuestion>> generateQuiz({
    required String courseContent,
    required int numberOfQuestions,
    required String courseName,
  }) async {
    try {
      final prompt = '''
Tu es un expert en création de quiz éducatif. Génère un quiz avec exactement $numberOfQuestions questions à choix multiples basé sur le contenu de cours suivant.

CONTENU DU COURS:
$courseContent

EXIGENCES:
- Génère exactement $numberOfQuestions questions
- Chaque question doit avoir 4 options (A, B, C, D)
- Marque clairement la bonne réponse
- Les questions doivent couvrir différents aspects du contenu
- Les questions doivent être claires et sans ambiguïté
- Le niveau de difficulté doit être varié

FORMAT DE RÉPONSE (JSON uniquement):
{
  "questions": [
    {
      "question": "Texte de la question ici?",
      "options": ["Option A", "Option B", "Option C", "Option D"],
      "correctAnswer": 0
    }
  ]
}

- correctAnswer doit être l'index (0-3) de l'option correcte
- Ne renvoie QUE le JSON, sans texte supplémentaire
''';

      final response = await http.post(
        Uri.parse('$_baseUrl?key=$_apiKey'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'contents': [
            {
              'parts': [
                {'text': prompt}
              ]
            }
          ],
          'generationConfig': {
            'temperature': 0.7,
            'topK': 40,
            'topP': 0.95,
            'maxOutputTokens': 2048,
          }
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['candidates'] == null || data['candidates'].isEmpty) {
          throw Exception('Réponse vide de l\'API Gemini');
        }

        final generatedText = data['candidates'][0]['content']['parts'][0]['text'];

        // Extract JSON from the response
        final jsonMatch = RegExp(r'\{[\s\S]*\}').firstMatch(generatedText);
        if (jsonMatch != null) {
          final jsonString = jsonMatch.group(0);
          final quizData = jsonDecode(jsonString!);

          if (quizData['questions'] == null || quizData['questions'].isEmpty) {
            throw Exception('Aucune question trouvée dans la réponse');
          }

          return _parseQuizQuestions(quizData['questions']);
        } else {
          throw Exception('Impossible de parser les données du quiz depuis la réponse API');
        }
      } else {
        try {
          final errorData = jsonDecode(response.body);
          throw Exception('Échec de la génération du quiz: ${errorData['error']['message']}');
        } catch (e) {
          throw Exception('Erreur API (${response.statusCode}): ${response.body}');
        }
      }
    } catch (e) {
      throw Exception('Erreur lors de la génération du quiz: $e');
    }
  }

  List<QuizQuestion> _parseQuizQuestions(List<dynamic> questionsData) {
    try {
      return questionsData.map<QuizQuestion>((q) {
        int correctAnswerIndex;
        if (q['correctAnswer'] is String) {
          correctAnswerIndex = int.parse(q['correctAnswer'] as String);
        } else {
          correctAnswerIndex = q['correctAnswer'] as int;
        }

        // Validate correctAnswer is within range
        if (correctAnswerIndex < 0 || correctAnswerIndex >= (q['options'] as List).length) {
          correctAnswerIndex = 0;
        }

        return QuizQuestion(
          question: q['question'] as String,
          options: List<String>.from(q['options']),
          correctAnswerIndex: correctAnswerIndex,
        );
      }).toList();
    } catch (e) {
      throw Exception('Erreur lors du parsing des questions: $e');
    }
  }
}