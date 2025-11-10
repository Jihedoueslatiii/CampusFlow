import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:compusflow/models/quiz.dart';
import 'package:http/http.dart' as http;


class GeminiService {
  static const String _baseUrl = 'https://generativelanguage.googleapis.com/v1beta/models';

  // IMPORTANT: Replace this with your NEW API key from Google AI Studio
  // Get it from: https://aistudio.google.com/app/apikey
  static const String _apiKey = 'AIzaSyCoWkm9I37x7jqMYdLWuBbcb6r2BwFiaWs';

  // Try these model names in order if one doesn't work:
  // 1. gemini-2.0-flash-001 (stable, recommended)
  // 2. gemini-1.5-flash (fallback)
  // 3. gemini-2.0-flash-exp (experimental)
  static const String _modelName = 'gemini-2.0-flash-001';

  Future<List<QuizQuestion>> generateQuiz({
    required String courseContent,
    required int numberOfQuestions,
    required String courseName,
  }) async {
    try {
      final prompt = '''
Tu es un expert en création de quiz éducatif. Génère un quiz avec exactement $numberOfQuestions questions à choix multiples basé sur le contenu de cours suivant.

COURS: $courseName
CONTENU DU COURS:
$courseContent

EXIGENCES:
- Génère exactement $numberOfQuestions questions
- Chaque question doit avoir 4 options (A, B, C, D)
- Marque clairement la bonne réponse avec l'index (0-3)
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

IMPORTANT: 
- correctAnswer doit être l'index (0-3) de l'option correcte
- Ne renvoie QUE le JSON, sans texte supplémentaire
- Pas de markdown, pas de backticks, juste le JSON brut
''';

      print('📡 Envoi de la requête à Gemini API...');
      print('🔗 URL: $_baseUrl/$_modelName:generateContent');

      final url = Uri.parse('$_baseUrl/$_modelName:generateContent?key=$_apiKey');

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
        },
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
            'responseMimeType': 'application/json', // Request JSON response
          },
          'safetySettings': [
            {
              'category': 'HARM_CATEGORY_HARASSMENT',
              'threshold': 'BLOCK_NONE'
            },
            {
              'category': 'HARM_CATEGORY_HATE_SPEECH',
              'threshold': 'BLOCK_NONE'
            },
            {
              'category': 'HARM_CATEGORY_SEXUALLY_EXPLICIT',
              'threshold': 'BLOCK_NONE'
            },
            {
              'category': 'HARM_CATEGORY_DANGEROUS_CONTENT',
              'threshold': 'BLOCK_NONE'
            }
          ]
        }),
      ).timeout(const Duration(seconds: 45));

      print('📥 Statut de la réponse: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('📦 Réponse complète: ${jsonEncode(data)}');

        if (data['candidates'] == null || data['candidates'].isEmpty) {
          throw Exception('Réponse vide de l\'API Gemini - Aucun candidat trouvé');
        }

        final candidate = data['candidates'][0];

        // Check for blocked content
        if (candidate['finishReason'] == 'SAFETY') {
          throw Exception('Le contenu a été bloqué par les filtres de sécurité. Essayez avec un contenu différent.');
        }

        final content = candidate['content'];
        if (content == null || content['parts'] == null || content['parts'].isEmpty) {
          throw Exception('Réponse incomplète de l\'API Gemini - Structure de contenu invalide');
        }

        final generatedText = content['parts'][0]['text'];
        print('📝 Réponse brute: $generatedText');

        // Nettoyer et extraire le JSON
        final cleanedText = _cleanJsonResponse(generatedText);
        final quizData = jsonDecode(cleanedText);

        if (quizData['questions'] == null) {
          throw Exception('Clé "questions" manquante dans la réponse JSON');
        }

        final questionsList = quizData['questions'] as List;
        if (questionsList.isEmpty) {
          throw Exception('Aucune question trouvée dans la réponse');
        }

        if (questionsList.length != numberOfQuestions) {
          print('⚠️ Nombre de questions générées (${questionsList.length}) différent de celui demandé ($numberOfQuestions)');
        }

        return _parseQuizQuestions(questionsList);

      } else if (response.statusCode == 400) {
        final errorData = jsonDecode(response.body);
        print('❌ Erreur 400: ${jsonEncode(errorData)}');
        throw Exception('Requête invalide (400): ${_parseErrorResponse(response)}');

      } else if (response.statusCode == 403) {
        print('❌ Erreur 403 - Vérifiez:');
        print('   1. Votre clé API est correcte');
        print('   2. L\'API Generative Language est activée dans Google Cloud Console');
        print('   3. Obtenez une nouvelle clé sur: https://aistudio.google.com/app/apikey');
        throw Exception('Accès refusé (403). Vérifiez votre clé API et les permissions.');

      } else if (response.statusCode == 404) {
        print('❌ Erreur 404 - Le modèle "$_modelName" n\'existe pas');
        print('   Essayez: gemini-1.5-flash ou gemini-2.0-flash-exp');
        throw Exception('Modèle non trouvé (404). Vérifiez le nom du modèle.');

      } else if (response.statusCode == 429) {
        throw Exception('Quota API dépassé (429). Veuillez réessayer dans quelques instants.');

      } else if (response.statusCode == 500 || response.statusCode == 503) {
        throw Exception('Erreur serveur Google (${response.statusCode}). Réessayez dans quelques instants.');

      } else {
        final errorMessage = _parseErrorResponse(response);
        print('❌ Erreur ${response.statusCode}: $errorMessage');
        throw Exception('Erreur API (${response.statusCode}): $errorMessage');
      }

    } on SocketException catch (e) {
      throw Exception('Erreur de connexion réseau: Vérifiez votre connexion Internet');
    } on http.ClientException catch (e) {
      throw Exception('Erreur de connexion: ${e.message}');
    } on TimeoutException catch (e) {
      throw Exception('Timeout de la requête API (45s dépassées)');
    } on FormatException catch (e) {
      print('❌ Erreur de format JSON: $e');
      throw Exception('Erreur de format JSON: $e');
    } catch (e) {
      print('❌ Erreur inattendue: $e');
      throw Exception('Erreur lors de la génération du quiz: $e');
    }
  }

  String _cleanJsonResponse(String text) {
    // Supprimer les backticks et marqueurs JSON
    String cleaned = text
        .replaceAll('```json', '')
        .replaceAll('```', '')
        .replaceAll('\n', ' ')
        .trim();

    // Essayer de parser directement
    try {
      jsonDecode(cleaned);
      return cleaned;
    } catch (e) {
      // Si échec, essayer d'extraire avec regex
      final jsonMatch = RegExp(r'\{[\s\S]*\}').firstMatch(cleaned);
      if (jsonMatch != null) {
        final extractedJson = jsonMatch.group(0)!;
        try {
          jsonDecode(extractedJson);
          return extractedJson;
        } catch (e) {
          throw Exception('JSON extrait invalide: $extractedJson');
        }
      }
      throw Exception('Aucun JSON valide trouvé dans la réponse: $cleaned');
    }
  }

  String _parseErrorResponse(http.Response response) {
    try {
      final errorData = jsonDecode(response.body);
      if (errorData['error'] != null) {
        final error = errorData['error'];
        if (error['message'] != null) {
          return error['message'];
        }
        // Return full error object as string
        return jsonEncode(error);
      }
    } catch (e) {
      // Si le parsing JSON échoue, retourner le body brut
    }
    return response.body.isNotEmpty ? response.body : 'Erreur inconnue';
  }

  List<QuizQuestion> _parseQuizQuestions(List<dynamic> questionsData) {
    try {
      return questionsData.asMap().entries.map<QuizQuestion>((entry) {
        final index = entry.key;
        final q = entry.value;

        // Validation des champs requis
        if (q['question'] == null) {
          throw Exception('Question $index: champ "question" manquant');
        }

        if (q['options'] == null || (q['options'] as List).length != 4) {
          throw Exception('Question $index: doit avoir exactement 4 options');
        }

        if (q['correctAnswer'] == null) {
          throw Exception('Question $index: champ "correctAnswer" manquant');
        }

        // Conversion de correctAnswer
        int correctAnswerIndex;
        if (q['correctAnswer'] is String) {
          correctAnswerIndex = int.tryParse(q['correctAnswer'] as String) ?? 0;
        } else {
          correctAnswerIndex = (q['correctAnswer'] as num).toInt();
        }

        // Validation de l'index
        if (correctAnswerIndex < 0 || correctAnswerIndex >= 4) {
          print('⚠️ Index de réponse correcte ($correctAnswerIndex) hors limites pour la question $index, utilisation de 0 par défaut');
          correctAnswerIndex = 0;
        }

        return QuizQuestion(
          question: q['question'].toString(),
          options: List<String>.from(q['options'].map((opt) => opt.toString())),
          correctAnswerIndex: correctAnswerIndex,
        );
      }).toList();
    } catch (e) {
      throw Exception('Erreur lors du parsing des questions: $e');
    }
  }
}

// Add this import at the top if not already present:
// import 'dart:io'; // For SocketException