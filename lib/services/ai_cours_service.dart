import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/cours.dart';
import '../models/cours_content.dart';

class AICoursService {
  // ⭐ VOTRE CLÉ API
  static const String _apiKey = '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';
  static const String _baseUrl = 'https://api.openai.com/v1/chat/completions';

  // Générer un résumé du cours
  static Future<CoursContent> generateSummary(Cours cours) async {
    final prompt = """
Génère un résumé concis et structuré pour le cours suivant:

NOM: ${cours.nom}
DESCRIPTION: ${cours.description}
CRÉDITS: ${cours.credits}
SEMESTRE: ${cours.semestre}

Le résumé doit être en français et inclure:
• Les objectifs d'apprentissage
• Les compétences acquises  
• Les débouchés professionnels
• Le public cible

Format: Markdown avec des titres et listes
""";

    final response = await _makeAIRequest(prompt, cours);

    return CoursContent(
      coursId: cours.id ?? 0,
      content: response,
      contentType: 'summary',
      aiConfidence: 0.95,
    );
  }

  // Générer des exercices pratiques
  static Future<CoursContent> generateExercises(Cours cours) async {
    final prompt = """
Crée 3 exercices pratiques pour le cours: "${cours.nom}"

Description du cours: ${cours.description}

Pour chaque exercice, fournis:
1. Un énoncé clair
2. Les objectifs pédagogiques
3. Le niveau de difficulté (⭐ à ⭐⭐⭐)
4. La durée estimée
5. Des conseils pour la résolution

Format: Markdown avec des sections claires
""";

    final response = await _makeAIRequest(prompt, cours);

    return CoursContent(
      coursId: cours.id ?? 0,
      content: response,
      contentType: 'exercises',
      aiConfidence: 0.90,
    );
  }

  // Générer un quiz
  static Future<CoursContent> generateQuiz(Cours cours) async {
    final prompt = """
Crée un quiz de 5 questions à choix multiples pour le cours: "${cours.nom}"

Pour chaque question:
- Une question claire
- 4 options (A, B, C, D)
- La bonne réponse
- Une explication détaillée

Thèmes à couvrir: les concepts principaux du cours

Format: Markdown avec des sections distinctes
""";

    final response = await _makeAIRequest(prompt, cours);

    return CoursContent(
      coursId: cours.id ?? 0,
      content: response,
      contentType: 'quiz',
      aiConfidence: 0.85,
    );
  }

  // Méthode améliorée pour appeler l'API OpenAI
  static Future<String> _makeAIRequest(String prompt, Cours cours) async {
    try {
      // Vérifier d'abord si la clé API est valide
      if (_apiKey.isEmpty || _apiKey.contains('VOTRE_CLÉ') || _apiKey.length < 20) {
        return _getSimulatedResponse(prompt, cours);
      }

      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
        },
        body: jsonEncode({
          'model': 'gpt-3.5-turbo',
          'messages': [
            {
              'role': 'system',
              'content': 'Tu es un expert pédagogique francophone.'
            },
            {'role': 'user', 'content': prompt}
          ],
          'max_tokens': 1000, // Réduit pour économiser
          'temperature': 0.7,
        }),
      ).timeout(Duration(seconds: 30)); // Timeout de 30s

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['choices'][0]['message']['content'];
      } else if (response.statusCode == 429) {
        // ⭐ SOLUTION ALTERNATIVE EN CAS DE LIMITE
        return _getSimulatedResponse(prompt, cours);
      } else {
        return "🔄 Mode simulation activé (Erreur ${response.statusCode})\n\n${_getSimulatedResponse(prompt, cours)}";
      }
    } catch (e) {
      return "🔄 Mode simulation activé\n\n${_getSimulatedResponse(prompt, cours)}";
    }
  }

  // Contenu de fallback intelligent avec contexte du cours
  static String _getSimulatedResponse(String prompt, Cours cours) {
    if (prompt.contains('résumé') || prompt.contains('summary')) {
      return """
# 📚 Résumé du Cours : ${cours.nom}

## 📋 Description
${cours.description}

## 🎯 Objectifs d'Apprentissage
- Maîtriser les concepts fondamentaux de ${cours.nom}
- Développer des compétences pratiques
- Appliquer les connaissances en situations réelles
- Préparer les évaluations et projets

## 💪 Compétences Acquises
✅ **Analyse critique** - Évaluer les concepts de manière objective
✅ **Résolution de problèmes** - Trouver des solutions efficaces  
✅ **Communication technique** - Présenter clairement ses idées
✅ **Travail d'équipe** - Collaborer sur des projets complexes

## 🚀 Débouchés Professionnels
- **Spécialiste en ${cours.nom}** - Expertise sectorielle
- **Consultant** - Conseil stratégique
- **Chef de projet** - Gestion d'initiatives
- **Formateur** - Transmission des savoirs

## 📅 Structure du Cours
1. **Introduction** - Présentation des concepts clés
2. **Développement** - Approfondissement théorique et pratique
3. **Applications** - Études de cas concrets
4. **Évaluation** - Validation des acquis

## ℹ️ Informations Pratiques
- **Crédits** : ${cours.credits}
- **Semestre** : ${cours.semestre}
- **Charge de travail** : Modérée à intensive

*💡 Contenu simulé - Connectez une clé API OpenAI pour un contenu personnalisé et dynamique*
""";
    } else if (prompt.contains('exercice') || prompt.contains('exercise')) {
      return """
# 📝 Exercices Pratiques - ${cours.nom}

## 🔍 Exercice 1 - Niveau Débutant ⭐
**📖 Énoncé** : 
Analysez un cas simple lié à ${cours.nom} et identifiez les concepts fondamentaux abordés dans le cours.

**🎯 Objectifs Pédagogiques** :
- Comprendre les bases de ${cours.nom}
- Identifier les concepts clés
- Appliquer une méthodologie d'analyse simple

**⏱️ Durée estimée** : 30 minutes

**💡 Conseils de Résolution** :
- Lisez attentivement l'énoncé
- Identifiez les éléments clés
- Structurez votre réponse logiquement

---

## 🛠️ Exercice 2 - Niveau Intermédiaire ⭐⭐  
**📖 Énoncé** : 
Résolvez un problème complexe impliquant plusieurs concepts de ${cours.nom} et proposez une solution argumentée.

**🎯 Objectifs Pédagogiques** :
- Combiner différents concepts
- Développer un raisonnement critique
- Présenter une solution structurée

**⏱️ Durée estimée** : 1 heure

**💡 Conseils de Résolution** :
- Décomposez le problème en sous-parties
- Utilisez les méthodes vues en cours
- Justifiez chaque étape de votre raisonnement

---

## 🚀 Exercice 3 - Niveau Avancé ⭐⭐⭐
**📖 Énoncé** : 
Concevez un projet intégrateur qui démontre votre maîtrise complète des concepts de ${cours.nom}.

**🎯 Objectifs Pédagogiques** :
- Synthétiser l'ensemble des acquis
- Développer une approche créative
- Présenter un travail professionnel

**⏱️ Durée estimée** : 2-3 heures

**💡 Conseils de Résolution** :
- Planifiez votre travail étape par étape
- Intégrez les feedbacks précédents
- Soignez la présentation finale

*✨ Activez l'IA pour des exercices personnalisés adaptés à votre progression*
""";
    } else if (prompt.contains('quiz') || prompt.contains('qcm')) {
      return """
# ❓ Quiz de Révision - ${cours.nom}

## 📝 Questions à Choix Multiples

### Question 1
**Quel est le concept principal abordé dans le cours "${cours.nom}" ?**
A) Introduction générale  
B) ${cours.nom.split(' ').take(2).join(' ')} fondamentale  
C) Applications avancées  
D) Toutes ces réponses

✅ **Réponse correcte** : B  
**Explication** : Le cours se concentre sur les fondamentaux de ${cours.nom.split(' ').take(2).join(' ')}, qui constituent la base nécessaire pour aborder les concepts plus avancés.

---

### Question 2
**Quelle méthode d'apprentissage est la plus recommandée pour ce cours ?**
A) Apprentissage par cœur  
B) Étude théorique uniquement  
C) Combinaison théorie/pratique  
D) Ignorer les exercices pratiques

✅ **Réponse correcte** : C  
**Explication** : L'approche combinée permet de mieux assimiler les concepts théoriques grâce à leur application concrète.

---

### Question 3
**Quel est l'objectif principal des crédits alloués à ce cours ?**
A) Indiquer la difficulté  
B) Mesurer la charge de travail  
C) Déterminer le salaire futur  
D) Aucune de ces réponses

✅ **Réponse correcte** : B  
**Explication** : Les crédits reflètent le volume de travail et l'importance du cours dans le parcours académique.

---

### Question 4
**Quelle compétence est essentielle pour réussir ce cours ?**
A) Capacité d'analyse  
B) Mémoire photographique  
C) Vitesse de lecture  
D) Connaissances préalables étendues

✅ **Réponse correcte** : A  
**Explication** : La capacité d'analyse permet de comprendre et d'appliquer les concepts complexes de ${cours.nom}.

---

### Question 5
**Comment optimiser votre apprentissage dans ce cours ?**
A) Travailler uniquement avant les examens  
B) Participer activement aux séances  
C) Apprendre sans prendre de notes  
D) Éviter les travaux pratiques

✅ **Réponse correcte** : B  
**Explication** : La participation active favorise une meilleure compréhension et rétention des concepts.

## 📊 Score d'Évaluation
- **5 bonnes réponses** : Excellente compréhension ✅
- **3-4 bonnes réponses** : Bonnes bases à consolider 📚  
- **Moins de 3** : Revision recommandée 🔄

*🔗 Configuration IA requise pour un quiz adaptatif et personnalisé*
""";
    } else {
      return """
# 🤖 Assistant IA - ${cours.nom}

## 📋 Contenu Généré

### Description du Cours
${cours.description}

### Informations Clés
- **Nom** : ${cours.nom}
- **Crédits** : ${cours.credits}
- **Semestre** : ${cours.semestre}
- **Département** : ${cours.departementNom ?? 'Non spécifié'}

### 💡 Fonctionnalités Disponibles
- 📚 **Résumés intelligents**
- 📝 **Exercices personnalisés**  
- ❓ **Quiz adaptatifs**
- 🎯 **Recommandations d'apprentissage**

### 🔧 Configuration Requise
Pour bénéficier de contenu entièrement personnalisé et dynamique, veuillez :
1. Vérifier votre clé API OpenAI
2. Vous assurer d'un solde positif
3. Configurer les paramètres d'API

*✨ Contenu simulé - L'IA réelle offre une expérience bien plus riche et adaptative*
""";
    }
  }
}