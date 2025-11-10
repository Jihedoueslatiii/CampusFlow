import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';

class AIPlanningService {
  // ✅ CORRECTION : Utilisation du modèle gemini-2.0-flash qui fonctionne
  static const String _baseUrl = 'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent';
  static const String _apiKey = 'AIzaSyCoWkm9I37x7jqMYdLWuBbcb6r2BwFiaWs';

  // 🚀 Méthode principale pour générer une timeline IA avec Gemini
  Future<List<Map<String, dynamic>>?> generateProjectTimeline({
    required String projetTitre,
    required String description,
    required String coursAssocie,
    required DateTime dateRendu,
    required int difficulte, // 1-5 échelle de difficulté
  }) async {
    try {
      // Calcul du temps disponible
      final now = DateTime.now();
      final totalDays = dateRendu.difference(now).inDays + 1;

      // Si le projet est trop court, retourner null pour utiliser le fallback
      if (totalDays <= 3) {
        return null;
      }

      // Préparation du prompt pour Gemini
      final prompt = _buildGeminiPrompt(
        projetTitre: projetTitre,
        description: description,
        coursAssocie: coursAssocie,
        dateRendu: dateRendu,
        difficulte: difficulte,
        totalDays: totalDays,
      );

      // Appel à l'API Gemini
      final response = await _callGeminiAPI(prompt);

      if (response != null) {
        return _parseGeminiResponse(response, dateRendu);
      }

      // Fallback vers la méthode locale si Gemini échoue
      return generateLocalAITimeline(
        projetTitre: projetTitre,
        description: description,
        coursAssocie: coursAssocie,
        dateRendu: dateRendu,
        difficulte: difficulte,
      );
    } catch (e) {
      print('Erreur dans generateProjectTimeline: $e');
      // Fallback vers la méthode locale
      return generateLocalAITimeline(
        projetTitre: projetTitre,
        description: description,
        coursAssocie: coursAssocie,
        dateRendu: dateRendu,
        difficulte: difficulte,
      );
    }
  }

  // 🎯 Construction du prompt pour Gemini
  String _buildGeminiPrompt({
    required String projetTitre,
    required String description,
    required String coursAssocie,
    required DateTime dateRendu,
    required int difficulte,
    required int totalDays,
  }) {
    final dateFormat = 'dd/MM/yyyy';
    final formattedDateRendu = '${dateRendu.day}/${dateRendu.month}/${dateRendu.year}';

    return '''
En tant qu'expert en gestion de projet éducatif, génère un plan de travail optimisé pour le projet suivant :

**INFORMATIONS DU PROJET:**
- Titre: $projetTitre
- Cours: $coursAssocie
- Description: $description
- Difficulté: $difficulte/5
- Date de rendu: $formattedDateRendu
- Jours disponibles: $totalDays jours

**CONTRAINTES:**
- Le projet doit être divisé en 3 à 5 phases maximum
- Chaque phase doit avoir une durée proportionnelle à sa complexité
- Inclure des marges de sécurité pour les imprévus
- Adapter la répartition en fonction de la difficulté
- Prioriser les tâches critiques en début de projet

**FORMAT DE RÉPONSE ATTENDU:**
Retourne UNIQUEMENT un JSON valide avec ce format :

{
  "timeline": [
    {
      "task": "Nom de la phase",
      "description": "Description détaillée des activités",
      "duration_percent": 25,
      "priority": "Élevée|Moyenne|Critique",
      "recommendations": ["conseil1", "conseil2"]
    }
  ],
  "rationale": "Explication brève de la répartition choisie"
}

**EXEMPLES DE PHASES POSSIBLES:**
- Recherche documentaire & analyse
- Planification détaillée & structure
- Rédaction/ développement principal
- Révision & améliorations
- Finalisation & préparation présentation

Génère un plan réaliste et adapté au contexte éducatif. Réponds UNIQUEMENT en JSON valide.
''';
  }

  // 📡 Appel à l'API Google Gemini - CORRIGÉ avec le bon modèle
  Future<String?> _callGeminiAPI(String prompt) async {
    try {
      final url = Uri.parse('$_baseUrl?key=$_apiKey');

      print('🔗 Appel API Gemini vers: $url');
      print('📝 Prompt envoyé: ${prompt.substring(0, 100)}...');

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
            'maxOutputTokens': 1500,
            'topP': 0.8,
            'topK': 40,
          }
        }),
      );

      print('📡 Réponse API - Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('✅ Succès API Gemini');

        // Extraction du texte de la réponse Gemini
        if (data['candidates'] != null &&
            data['candidates'].isNotEmpty &&
            data['candidates'][0]['content'] != null &&
            data['candidates'][0]['content']['parts'] != null &&
            data['candidates'][0]['content']['parts'].isNotEmpty) {

          final responseText = data['candidates'][0]['content']['parts'][0]['text'];
          print('📄 Réponse IA reçue: ${responseText.substring(0, 100)}...');
          return responseText;
        } else {
          print('❌ Structure de réponse invalide');
          print('Données reçues: $data');
        }
      } else {
        print('❌ Erreur API Gemini: ${response.statusCode}');
        print('Corps de l\'erreur: ${response.body}');
      }
    } catch (e) {
      print('❌ Erreur lors de l\'appel Gemini: $e');
    }
    return null;
  }

  // 🔄 Parsing de la réponse Gemini avec meilleure gestion d'erreurs
  List<Map<String, dynamic>> _parseGeminiResponse(String geminiResponse, DateTime dateRendu) {
    try {
      print('🔄 Début du parsing de la réponse Gemini');

      // Nettoyer la réponse pour extraire le JSON
      String cleanResponse = geminiResponse.replaceAll('```json', '').replaceAll('```', '').trim();
      print('🧹 Réponse nettoyée: ${cleanResponse.substring(0, 100)}...');

      // Parfois Gemini ajoute du texte avant/après le JSON, essayons de l'extraire
      final jsonStart = cleanResponse.indexOf('{');
      final jsonEnd = cleanResponse.lastIndexOf('}');

      if (jsonStart != -1 && jsonEnd != -1) {
        cleanResponse = cleanResponse.substring(jsonStart, jsonEnd + 1);
        print('📋 JSON extrait: ${cleanResponse.substring(0, 100)}...');
      }

      final Map<String, dynamic> data = jsonDecode(cleanResponse);
      print('✅ JSON décodé avec succès');

      final List<dynamic> timelineData = data['timeline'];
      final now = DateTime.now();

      // Calcul des dates basé sur les pourcentages
      final totalDuration = dateRendu.difference(now).inDays + 1;
      int currentOffset = 0;

      final List<Map<String, dynamic>> timeline = [];

      for (final phase in timelineData) {
        final int phaseDuration = ((phase['duration_percent'] as num) / 100 * totalDuration).round();

        if (phaseDuration > 0 && currentOffset + phaseDuration <= totalDuration) {
          final DateTime startDate = now.add(Duration(days: currentOffset));
          final DateTime endDate = startDate.add(Duration(days: phaseDuration - 1));

          timeline.add({
            'task': phase['task'],
            'start': startDate,
            'end': endDate,
            'color': _getPhaseColor(phase['task']),
            'description': phase['description'],
            'priority': phase['priority'] ?? 'Moyenne',
            'duration_days': phaseDuration,
            'recommendations': phase['recommendations'] ?? [],
            'isAI': true, // Marquer comme généré par IA
          });

          currentOffset += phaseDuration;
        }
      }

      print('📅 Timeline générée: ${timeline.length} phases');
      return timeline;
    } catch (e) {
      print('❌ Erreur parsing réponse Gemini: $e');
      print('📄 Réponse reçue: $geminiResponse');
      return [];
    }
  }

  // 🎨 Attribution des couleurs par type de phase
  Color _getPhaseColor(String taskName) {
    final lowerTask = taskName.toLowerCase();

    if (lowerTask.contains('recherche') || lowerTask.contains('analyse') || lowerTask.contains('documentation')) {
      return const Color(0xFF4285F4); // Bleu Google
    } else if (lowerTask.contains('planification') || lowerTask.contains('structure') || lowerTask.contains('conception')) {
      return const Color(0xFF34A853); // Vert Google
    } else if (lowerTask.contains('rédaction') || lowerTask.contains('développement') || lowerTask.contains('réalisation')) {
      return const Color(0xFFFBBC05); // Jaune Google
    } else if (lowerTask.contains('révision') || lowerTask.contains('amélioration') || lowerTask.contains('correction')) {
      return const Color(0xFFEA4335); // Rouge Google
    } else if (lowerTask.contains('finalisation') || lowerTask.contains('présentation') || lowerTask.contains('soumission')) {
      return const Color(0xFF8E44AD); // Violet
    }

    return const Color(0xFF95A5A6); // Gris par défaut
  }

  // 🎯 Méthode alternative avec modèle local/fallback
  List<Map<String, dynamic>> generateLocalAITimeline({
    required String projetTitre,
    required String description,
    required String coursAssocie,
    required DateTime dateRendu,
    required int difficulte,
  }) {
    final now = DateTime.now();
    final totalDays = dateRendu.difference(now).inDays + 1;

    if (totalDays <= 3) return [];

    // Logique intelligente basée sur la difficulté et le type de projet
    final Map<String, double> phaseDistribution = _calculatePhaseDistribution(
      difficulte: difficulte,
      projetTitre: projetTitre,
      description: description,
      totalDays: totalDays,
    );

    return _buildTimelineFromDistribution(phaseDistribution, now, dateRendu);
  }

  // 📊 Calcul de la distribution des phases basé sur l'analyse
  Map<String, double> _calculatePhaseDistribution({
    required int difficulte,
    required String projetTitre,
    required String description,
    required int totalDays,
  }) {
    final Map<String, double> baseDistribution = {
      'recherche': 0.30,
      'planification': 0.20,
      'developpement': 0.35,
      'revision': 0.15,
    };

    // Ajustements basés sur la difficulté
    if (difficulte >= 4) {
      baseDistribution['recherche'] = 0.35;
      baseDistribution['planification'] = 0.25;
      baseDistribution['developpement'] = 0.30;
      baseDistribution['revision'] = 0.10;
    } else if (difficulte <= 2) {
      baseDistribution['recherche'] = 0.25;
      baseDistribution['planification'] = 0.15;
      baseDistribution['developpement'] = 0.45;
      baseDistribution['revision'] = 0.15;
    }

    // Ajustements basés sur le type de projet
    final lowerDescription = description.toLowerCase();
    final lowerTitre = projetTitre.toLowerCase();

    if (lowerDescription.contains('programmation') ||
        lowerDescription.contains('code') ||
        lowerTitre.contains('app') ||
        lowerTitre.contains('logiciel')) {
      baseDistribution['developpement'] = 0.50;
      baseDistribution['recherche'] = 0.20;
      baseDistribution['revision'] = 0.20;
      baseDistribution['planification'] = 0.10;
    } else if (lowerDescription.contains('mémoire') ||
        lowerDescription.contains('thèse') ||
        lowerTitre.contains('recherche')) {
      baseDistribution['recherche'] = 0.40;
      baseDistribution['planification'] = 0.25;
      baseDistribution['developpement'] = 0.25;
      baseDistribution['revision'] = 0.10;
    } else if (lowerDescription.contains('présentation') ||
        lowerDescription.contains('exposé') ||
        lowerTitre.contains('oral')) {
      baseDistribution['planification'] = 0.30;
      baseDistribution['revision'] = 0.25;
      baseDistribution['developpement'] = 0.35;
      baseDistribution['recherche'] = 0.10;
    } else if (lowerDescription.contains('rapport') ||
        lowerDescription.contains('compte-rendu')) {
      baseDistribution['recherche'] = 0.25;
      baseDistribution['planification'] = 0.20;
      baseDistribution['developpement'] = 0.40;
      baseDistribution['revision'] = 0.15;
    }

    return baseDistribution;
  }

  // 🏗️ Construction de la timeline à partir de la distribution
  List<Map<String, dynamic>> _buildTimelineFromDistribution(
      Map<String, double> distribution,
      DateTime start,
      DateTime end,
      ) {
    final totalDays = end.difference(start).inDays + 1;
    final List<Map<String, dynamic>> timeline = [];
    int currentDay = 0;

    final phases = [
      {
        'key': 'recherche',
        'name': 'Recherche & Analyse',
        'description': 'Phase de recherche documentaire et analyse des requirements. Collecte des sources et compréhension du sujet.',
        'color': const Color(0xFF4285F4),
        'priority': 'Élevée',
      },
      {
        'key': 'planification',
        'name': 'Planification Détaillée',
        'description': 'Élaboration de la structure détaillée, plan de travail et organisation des ressources nécessaires.',
        'color': const Color(0xFF34A853),
        'priority': 'Élevée',
      },
      {
        'key': 'developpement',
        'name': 'Développement Principal',
        'description': 'Phase de réalisation et production du contenu principal. Mise en œuvre des solutions.',
        'color': const Color(0xFFFBBC05),
        'priority': 'Moyenne',
      },
      {
        'key': 'revision',
        'name': 'Révision & Finalisation',
        'description': 'Relecture approfondie, corrections finales et préparation de la soumission.',
        'color': const Color(0xFFEA4335),
        'priority': 'Critique',
      },
    ];

    for (final phase in phases) {
      final String key = phase['key'] as String;
      if (distribution.containsKey(key)) {
        final phaseDays = (distribution[key]! * totalDays).round();

        if (phaseDays > 0 && currentDay < totalDays) {
          final phaseStart = start.add(Duration(days: currentDay));
          final phaseEnd = phaseStart.add(Duration(days: phaseDays - 1));

          // Ajuster la fin de phase si elle dépasse la date de rendu
          final adjustedEnd = phaseEnd.isAfter(end) ? end : phaseEnd;

          timeline.add({
            'task': phase['name'],
            'start': phaseStart,
            'end': adjustedEnd,
            'color': phase['color'] as Color,
            'description': phase['description'],
            'priority': phase['priority'],
            'duration_days': phaseDays,
            'recommendations': _generatePhaseRecommendations(key),
            'isAI': false, // Marquer comme généré localement
          });

          currentDay += phaseDays;
        }
      }
    }

    return timeline;
  }

  // 💡 Génération de recommandations par phase
  List<String> _generatePhaseRecommendations(String phaseKey) {
    switch (phaseKey) {
      case 'recherche':
        return [
          'Utilisez Google Scholar et les bases de données académiques',
          'Consultez les ressources recommandées par le professeur',
          'Prenez des notes organisées avec des références précises',
          'Évaluez la crédibilité de vos sources',
        ];
      case 'planification':
        return [
          'Créez un plan détaillé avec les sections principales',
          'Estimez le temps nécessaire pour chaque sous-tâche',
          'Identifiez les dépendances entre les différentes parties',
          'Prévoyez des marges pour les imprévus',
        ];
      case 'developpement':
        return [
          'Travaillez par sessions concentrées de 45-60 minutes',
          'Testez régulièrement votre travail',
          'Sauvegardez fréquemment vos progrès',
          'Documentez votre processus de travail',
        ];
      case 'revision':
        return [
          'Relisez-vous à haute voix pour détecter les erreurs',
          'Faites relire par un pair si possible',
          'Vérifiez le respect des consignes et du format demandé',
          'Contrôlez la cohérence globale du travail',
        ];
      default:
        return [
          'Planifiez des sessions de travail régulières',
          'Prenez des pauses pour maintenir la concentration',
          'Fixez des objectifs réalisables chaque jour',
        ];
    }
  }

  // 🎪 Méthode pour analyser la complexité du projet - CORRIGÉE
  Map<String, dynamic> analyzeProjectComplexity({
    required String titre,
    required String description,
    required String cours,
  }) {
    final analysis = <String, dynamic>{
      'complexity_score': 3,
      'recommended_phases': 4,
      'key_focus_areas': <String>[], // ✅ CORRECTION: Typage explicite
      'risk_factors': <String>[],    // ✅ CORRECTION: Typage explicite
    };

    final text = '$titre $description $cours'.toLowerCase();

    // Analyse basique de la complexité
    if (text.contains('mémoire') || text.contains('thèse') || text.contains('recherche approfondie')) {
      analysis['complexity_score'] = 5;
      analysis['recommended_phases'] = 5;
      (analysis['key_focus_areas'] as List<String>).addAll(['Recherche approfondie', 'Analyse critique', 'Rédaction académique']);
    }

    if (text.contains('programmation') || text.contains('développement') || text.contains('code')) {
      analysis['complexity_score'] = _max(analysis['complexity_score'] as int, 4);
      (analysis['key_focus_areas'] as List<String>).addAll(['Tests unitaires', 'Documentation', 'Optimisation']);
    }

    if (text.contains('présentation') || text.contains('oral') || text.contains('exposé')) {
      (analysis['key_focus_areas'] as List<String>).addAll(['Préparation visuelle', 'Entraînement oral', 'Gestion du temps']);
    }

    // Détection des facteurs de risque
    if (text.contains('urgence') || text.contains('délai court')) {
      (analysis['risk_factors'] as List<String>).add('Délai serré');
    }

    if (text.contains('complexe') || text.contains('difficile') || text.contains('challenge')) {
      (analysis['risk_factors'] as List<String>).add('Complexité élevée');
    }

    if (text.contains('nouveau') || text.contains('inconnu')) {
      (analysis['risk_factors'] as List<String>).add('Technologie/Concept nouveau');
    }

    return analysis;
  }

  // Méthode utilitaire pour max
  int _max(int a, int b) => a > b ? a : b;

  // 🆕 Méthode pour obtenir des conseils IA spécifiques au projet
  Future<String?> getProjectAdvice({
    required String projetTitre,
    required String description,
    required String coursAssocie,
    required int difficulte,
  }) async {
    try {
      final prompt = '''
En tant qu'assistant pédagogique, donne 3 conseils spécifiques pour réussir ce projet :

Projet: $projetTitre
Cours: $coursAssocie
Description: $description
Difficulté estimée: $difficulte/5

Donne des conseils pratiques, concrets et adaptés au contexte éducatif. Réponds en français.
''';

      final response = await _callGeminiAPI(prompt);
      return response;
    } catch (e) {
      print('Erreur lors de la génération de conseils: $e');
      return null;
    }
  }
}