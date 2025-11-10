import 'dart:math';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/event_ticket.dart';
import '../models/event_model.dart';

class AITicketService {
  // Your OpenAI API Key
  static const String _apiKey = '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';
  static const String _baseUrl = 'https://api.openai.com/v1/chat/completions';

  // Cache and rate limiting
  static final Map<String, List<EventTicket>> _cache = {};
  static DateTime? _lastApiCall;
  static const int _minCallInterval = 3000; // 3 seconds between API calls
  static bool _rateLimitHit = false;
  static DateTime? _rateLimitUntil;
  static bool _useTestMode = false; // Set to true for testing without API calls

  static Future<List<EventTicket>> generateAITickets(Event event) async {
    // TEST MODE: Use simulated AI responses while testing
    if (_useTestMode) {
      print('🧪 TEST MODE: Generating simulated AI tickets');
      return _generateTestTickets(event);
    }

    final cacheKey = '${event.id}_${event.title}';

    // Check cache first - avoid duplicate API calls
    if (_cache.containsKey(cacheKey)) {
      print('🎯 USING CACHED AI TICKETS for: ${event.title}');
      return _cache[cacheKey]!;
    }

    // Check if we're currently rate limited
    if (_isRateLimited()) {
      print('⏰ RATE LIMITED: Using fallback tickets');
      return _generateFallbackTickets(event);
    }

    // Rate limiting between calls
    await _enforceRateLimit();

    try {
      print('🚀 CALLING OPENAI API for: ${event.title}');
      _lastApiCall = DateTime.now();

      final tickets = await _callOpenAI(event);
      _cache[cacheKey] = tickets;

      print('✅ AI TICKETS GENERATED SUCCESSFULLY!');
      print('📊 Generated ${tickets.length} unique ticket options');
      _logTickets(tickets);
      return tickets;
    } catch (e) {
      print('❌ AI SERVICE ERROR: $e');
      _handleApiError(e);
      return _generateFallbackTickets(event);
    }
  }

  static bool _isRateLimited() {
    if (_rateLimitHit && _rateLimitUntil != null) {
      final timeUntilReset = _rateLimitUntil!.difference(DateTime.now());
      if (timeUntilReset.inSeconds > 0) {
        print('⏰ RATE LIMITED: Waiting ${timeUntilReset.inSeconds} seconds');
        return true;
      } else {
        _rateLimitHit = false;
        _rateLimitUntil = null;
      }
    }
    return false;
  }

  static Future<void> _enforceRateLimit() async {
    if (_lastApiCall != null) {
      final timeSinceLastCall = DateTime.now().difference(_lastApiCall!);
      if (timeSinceLastCall.inMilliseconds < _minCallInterval) {
        final waitTime = _minCallInterval - timeSinceLastCall.inMilliseconds;
        print('⏰ RATE LIMITING: Waiting ${waitTime}ms before next call');
        await Future.delayed(Duration(milliseconds: waitTime));
      }
    }
  }

  static void _handleApiError(dynamic error) {
    if (error.toString().contains('Rate limit') || error.toString().contains('429')) {
      _rateLimitHit = true;
      _rateLimitUntil = DateTime.now().add(const Duration(minutes: 1));
      print('🚫 RATE LIMIT ACTIVATED: Will use fallback for 1 minute');
    }
  }

  static void _logTickets(List<EventTicket> tickets) {
    tickets.asMap().forEach((index, ticket) {
      print('   ${index + 1}. ${ticket.ticketType} - ${ticket.formattedPrice}');
      print('      Description: ${ticket.description}');
      print('      Features: ${ticket.includedFeatures.length} included, ${ticket.excludedFeatures.length} excluded');
    });
  }

  static Future<List<EventTicket>> _callOpenAI(Event event) async {
    final prompt = _buildPrompt(event);

    try {
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
              'content': '''You are a creative event ticket generator for a university campus app called CompusFlow. 
              Generate exactly 3 different ticket options in French for student events.
              ALWAYS respond with valid JSON format only, no other text.'''
            },
            {
              'role': 'user',
              'content': prompt
            }
          ],
          'temperature': 0.8,
          'max_tokens': 1200,
        }),
      );

      print('🔍 API Response Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final content = data['choices'][0]['message']['content'];
        print('📨 AI Response received successfully');
        return _parseAIResponse(content, event);
      } else if (response.statusCode == 429) {
        final retryAfter = response.headers['retry-after'];
        final waitTime = retryAfter != null ? int.tryParse(retryAfter) ?? 60 : 60;
        print('🚫 RATE LIMIT: Too many requests');
        print('💡 Wait $waitTime seconds before next attempt');
        throw Exception('Rate limit - try again in $waitTime seconds');
      } else if (response.statusCode == 401) {
        print('🔐 INVALID API KEY');
        throw Exception('Invalid API key');
      } else if (response.statusCode == 403) {
        print('💰 QUOTA EXCEEDED');
        throw Exception('Quota exceeded - check your OpenAI account');
      } else {
        print('❌ API ERROR ${response.statusCode}: ${response.body}');
        throw Exception('API Error ${response.statusCode}');
      }
    } catch (e) {
      // FIXED: Removed specific TimeoutException catch since it's not available
      print('❌ NETWORK ERROR: $e');
      throw Exception('Network error: $e');
    }
  }

  static String _buildPrompt(Event event) {
    return '''
Generate exactly 3 creative and appealing ticket options for this university event in French. 
Return ONLY valid JSON, no other text or explanations.

EVENT DETAILS:
- Title: ${event.title}
- Description: ${event.description}
- Location: ${event.location}
- Date: ${event.dateTime}
- Max Participants: ${event.maxParticipants}
- Audience: University students

REQUIRED JSON FORMAT:
{
  "tickets": [
    {
      "ticketType": "Creative name with relevant emoji",
      "suggestedPrice": number between 0-50,
      "includedFeatures": ["feature1", "feature2", "feature3", "feature4"],
      "excludedFeatures": ["feature1", "feature2"],
      "description": "Compelling 1-sentence description in French"
    }
  ]
}

GUIDELINES:
- Make ticket names creative, appealing, and student-friendly with relevant emojis
- Include 3-5 features in includedFeatures
- Include 2-3 features in excludedFeatures for contrast
- Prices: 0 for basic, 10-25 for mid-tier, 25-50 for premium
- Descriptions should be enticing and specifically tailored to students
- Focus on value, experience, and student benefits
- Use French language only
- Ensure JSON is valid and properly formatted
''';
  }

  static List<EventTicket> _parseAIResponse(String content, Event event) {
    try {
      // Clean the response - remove any markdown code blocks
      String cleanedContent = content.replaceAll('```json', '').replaceAll('```', '').trim();
      print('🧹 Cleaned AI Response: $cleanedContent');

      final jsonData = jsonDecode(cleanedContent);
      final ticketsData = jsonData['tickets'] as List;

      final tickets = ticketsData.map((ticketData) {
        return EventTicket(
          ticketType: ticketData['ticketType']?.toString() ?? 'Pass Standard',
          suggestedPrice: (double.tryParse(ticketData['suggestedPrice']?.toString() ?? '0') ?? 0.0),
          includedFeatures: List<String>.from(ticketData['includedFeatures'] ?? []),
          excludedFeatures: List<String>.from(ticketData['excludedFeatures'] ?? []),
          description: ticketData['description']?.toString() ?? 'Accès à l\'événement',
        );
      }).toList();

      print('✅ Successfully parsed ${tickets.length} AI-generated tickets');
      return tickets;
    } catch (e) {
      print('❌ Error parsing AI response: $e');
      print('📄 Problematic content: $content');
      throw Exception('Failed to parse AI response: $e');
    }
  }

  static List<EventTicket> _generateTestTickets(Event event) {
    // Generate realistic AI-like tickets based on event type
    final eventType = _determineEventType(event.title, event.description);

    switch (eventType) {
      case 'workshop':
        return _generateWorkshopTestTickets(event);
      case 'conference':
        return _generateConferenceTestTickets(event);
      case 'social':
        return _generateSocialTestTickets(event);
      case 'academic':
        return _generateAcademicTestTickets(event);
      default:
        return _generateDefaultTestTickets(event);
    }
  }

  static String _determineEventType(String title, String description) {
    final lowerTitle = title.toLowerCase();
    final lowerDesc = description.toLowerCase();

    if (lowerTitle.contains('workshop') || lowerDesc.contains('workshop') ||
        lowerTitle.contains('atelier') || lowerDesc.contains('atelier')) {
      return 'workshop';
    } else if (lowerTitle.contains('conference') || lowerDesc.contains('conference') ||
        lowerTitle.contains('conférence') || lowerDesc.contains('conférence')) {
      return 'conference';
    } else if (lowerTitle.contains('party') || lowerDesc.contains('party') ||
        lowerTitle.contains('social') || lowerDesc.contains('social') ||
        lowerTitle.contains('soirée') || lowerDesc.contains('soirée')) {
      return 'social';
    } else if (lowerTitle.contains('lecture') || lowerDesc.contains('lecture') ||
        lowerTitle.contains('cours') || lowerDesc.contains('cours') ||
        lowerTitle.contains('study') || lowerDesc.contains('study')) {
      return 'academic';
    } else {
      return 'default';
    }
  }

  static List<EventTicket> _generateWorkshopTestTickets(Event event) {
    return [
      EventTicket(
        ticketType: '🎓 Pass Étudiant Premium',
        suggestedPrice: 0.0,
        includedFeatures: [
          'Accès complet au workshop',
          'Support de cours numérique',
          'Certificat de participation',
          'Ressources exclusives',
          'Session Q&A',
        ],
        excludedFeatures: [
          'Matériel pratique fourni',
          'Coaching individuel',
        ],
        description: 'Accès premium avec ressources exclusives pour étudiants motivés',
      ),
      EventTicket(
        ticketType: '⚡ Pass Workshop Intensif',
        suggestedPrice: 25.0,
        includedFeatures: [
          'Tous les avantages du Pass Étudiant',
          'Matériel pratique inclus',
          'Support individuel limité',
          'Réseautage avec experts',
          'Kit participant premium',
        ],
        excludedFeatures: [
          'Accès illimité au formateur',
        ],
        description: 'Expérience immersive avec accompagnement personnalisé',
      ),
      EventTicket(
        ticketType: '🚀 Pass Expert Complet',
        suggestedPrice: 45.0,
        includedFeatures: [
          'Tous les avantages du Pass Workshop',
          'Coaching individuel (30 min)',
          'Accès à vie aux ressources',
          'Certification avancée',
          'Mentorat post-événement',
        ],
        excludedFeatures: [],
        description: 'Solution ultime pour une transformation professionnelle complète',
      ),
    ];
  }

  static List<EventTicket> _generateConferenceTestTickets(Event event) {
    return [
      EventTicket(
        ticketType: '🎫 Pass Auditeur Libre',
        suggestedPrice: 0.0,
        includedFeatures: [
          'Accès à toutes les conférences',
          'Documentation numérique',
          'Espace networking',
          'Participation aux débats',
        ],
        excludedFeatures: [
          'Déjeuner inclus',
          'Accès aux ateliers pratiques',
          'Goodies événement',
        ],
        description: 'Accès complet aux sessions principales de la conférence',
      ),
      EventTicket(
        ticketType: '💼 Pass Professionnel',
        suggestedPrice: 35.0,
        includedFeatures: [
          'Tous les avantages du Pass Auditeur',
          'Déjeuner et pauses café inclus',
          'Accès aux ateliers pratiques',
          'Kit conférencier premium',
          'Réseautage prioritaire',
        ],
        excludedFeatures: [
          'Dîner de gala',
          'Accès backstage',
        ],
        description: 'Expérience complète pour professionnels exigeants',
      ),
      EventTicket(
        ticketType: '🌟 Pass Platinum VIP',
        suggestedPrice: 75.0,
        includedFeatures: [
          'Tous les avantages du Pass Professionnel',
          'Dîner de gala avec speakers',
          'Accès backstage exclusif',
          'Rencontres privées',
          'Transport VIP inclus',
        ],
        excludedFeatures: [],
        description: 'Expérience événementielle ultime avec accès exclusif',
      ),
    ];
  }

  static List<EventTicket> _generateSocialTestTickets(Event event) {
    return [
      EventTicket(
        ticketType: '😊 Pass Basique',
        suggestedPrice: 5.0,
        includedFeatures: [
          'Accès à l\'événement',
          '1 consommation offerte',
          'Participation aux jeux',
          'Espace détente',
        ],
        excludedFeatures: [
          'Buffet à volonté',
          'Goodies exclusifs',
          'Accès zone VIP',
        ],
        description: 'Accès simple pour profiter de l\'ambiance générale',
      ),
      EventTicket(
        ticketType: '🎉 Pass Fête Complète',
        suggestedPrice: 20.0,
        includedFeatures: [
          'Tous les avantages du Pass Basique',
          'Buffet à volonté',
          '3 consommations offertes',
          'Accès zone VIP',
          'Goodies événement',
        ],
        excludedFeatures: [
          'Photos professionnelles',
          'Service prioritaire',
        ],
        description: 'Expérience complète pour vivre la fête à 100%',
      ),
      EventTicket(
        ticketType: '👑 Pass VIP Ultimate',
        suggestedPrice: 40.0,
        includedFeatures: [
          'Tous les avantages du Pass Fête',
          'Consommations illimitées',
          'Service prioritaire',
          'Photos professionnelles',
          'Cadeau surprise VIP',
        ],
        excludedFeatures: [],
        description: 'Expérience premium avec avantages exclusifs illimités',
      ),
    ];
  }

  static List<EventTicket> _generateAcademicTestTickets(Event event) {
    return [
      EventTicket(
        ticketType: '📚 Accès Standard',
        suggestedPrice: 0.0,
        includedFeatures: [
          'Accès à la session académique',
          'Supports de cours numériques',
          'Participation aux exercices',
          'Echanges avec l\'intervenant',
        ],
        excludedFeatures: [
          'Support personnalisé',
          'Ressources avancées',
          'Certification',
        ],
        description: 'Accès basique au contenu académique principal',
      ),
      EventTicket(
        ticketType: '🎯 Accès Complet',
        suggestedPrice: 15.0,
        includedFeatures: [
          'Tous les avantages du Accès Standard',
          'Ressources supplémentaires',
          'Support par email',
          'Exercices avancés',
          'Q&A privé',
        ],
        excludedFeatures: [
          'Tutorat individuel',
          'Certification officielle',
        ],
        description: 'Immersion académique complète avec ressources étendues',
      ),
      EventTicket(
        ticketType: '🏆 Accès Premium',
        suggestedPrice: 35.0,
        includedFeatures: [
          'Tous les avantages du Accès Complet',
          'Certification officielle',
          'Tutorat individuel (1h)',
          'Ressources exclusives',
          'Accès communauté privée',
        ],
        excludedFeatures: [],
        description: 'Expérience académique premium avec certification et accompagnement',
      ),
    ];
  }

  static List<EventTicket> _generateDefaultTestTickets(Event event) {
    return [
      EventTicket(
        ticketType: '🎫 Pass Standard',
        suggestedPrice: 0.0,
        includedFeatures: [
          'Accès à l\'événement',
          'Participation aux activités',
          'Support basique',
          'Documentation',
        ],
        excludedFeatures: [
          'Avantages premium',
          'Goodies exclusifs',
          'Services additionnels',
        ],
        description: 'Accès général pour découvrir l\'événement',
      ),
      EventTicket(
        ticketType: '⭐ Pass Avantage',
        suggestedPrice: 20.0,
        includedFeatures: [
          'Tous les avantages du Pass Standard',
          'Goodies événement',
          'Support prioritaire',
          'Ressources additionnelles',
          'Networking exclusif',
        ],
        excludedFeatures: [
          'Services VIP',
          'Avantages ultimes',
        ],
        description: 'Avantages supplémentaires pour une expérience enrichie',
      ),
      EventTicket(
        ticketType: '👑 Pass Premium',
        suggestedPrice: 45.0,
        includedFeatures: [
          'Tous les avantages du Pass Avantage',
          'Services VIP',
          'Avantages exclusifs',
          'Support dédié',
          'Cadeau surprise premium',
        ],
        excludedFeatures: [],
        description: 'Expérience complète avec tous les avantages exclusifs',
      ),
    ];
  }

  static List<EventTicket> _generateFallbackTickets(Event event) {
    print('🔄 USING FALLBACK TICKETS (AI not available)');
    return _generateDefaultTestTickets(event);
  }

  // Utility methods
  static void enableRealAPI() {
    _useTestMode = false;
    print('🔌 REAL API MODE: Enabled - will make actual OpenAI calls');
  }

  static void enableTestMode() {
    _useTestMode = true;
    print('🧪 TEST MODE: Enabled - using simulated AI responses');
  }

  static void clearCache() {
    _cache.clear();
    print('🧹 AI Ticket cache cleared');
  }

  static void resetRateLimit() {
    _rateLimitHit = false;
    _rateLimitUntil = null;
    print('🔄 Rate limit counter reset');
  }

  static bool get isTestMode => _useTestMode;
  static bool get isRateLimited => _rateLimitHit;
}