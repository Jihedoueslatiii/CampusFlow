import 'package:flutter/material.dart';
import '../models/event_ticket.dart';
import '../models/event_model.dart';
import '../services/ai_ticket_service.dart';

class AITicketDialog extends StatefulWidget {
  final Event event;
  final Function(EventTicket) onTicketSelected;

  const AITicketDialog({
    Key? key,
    required this.event,
    required this.onTicketSelected,
  }) : super(key: key);

  @override
  State<AITicketDialog> createState() => _AITicketDialogState();
}

class _AITicketDialogState extends State<AITicketDialog> {
  late Future<List<EventTicket>> _ticketsFuture;
  int _selectedTicketIndex = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _ticketsFuture = _loadTickets();
  }

  Future<List<EventTicket>> _loadTickets() async {
    try {
      final tickets = await AITicketService.generateAITickets(widget.event);
      setState(() => _isLoading = false);
      return tickets;
    } catch (e) {
      setState(() => _isLoading = false);
      rethrow;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 700),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.blue.shade50, Colors.purple.shade50],
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 20),
            _buildEventInfo(),
            const SizedBox(height: 24),
            Expanded(
              child: _buildTicketSelection(),
            ),
            const SizedBox(height: 24),
            _buildActionButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        const Icon(Icons.auto_awesome, size: 32, color: Colors.blue),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '🎟️ Billets IA Personnalisés',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue.shade800,
                ),
              ),
              FutureBuilder<List<EventTicket>>(
                future: _ticketsFuture,
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return _buildStatusBadge('🔄 Mode Secours', Colors.orange);
                  }
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return _buildStatusBadge('🤖 Connexion à OpenAI...', Colors.blue);
                  }
                  return _buildStatusBadge('✅ IA Active - Réponses Réelles', Colors.green);
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatusBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.circle, size: 8, color: color),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEventInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.event.title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            widget.event.description,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTicketSelection() {
    return FutureBuilder<List<EventTicket>>(
      future: _ticketsFuture,
      builder: (context, snapshot) {
        if (_isLoading) {
          return _buildLoadingState();
        }

        if (snapshot.hasError) {
          return _buildErrorState(snapshot.error.toString());
        }

        if (snapshot.hasData) {
          final tickets = snapshot.data!;
          return ListView.builder(
            shrinkWrap: true,
            itemCount: tickets.length,
            itemBuilder: (context, index) {
              return _buildTicketCard(tickets[index], index);
            },
          );
        }

        return _buildLoadingState();
      },
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 16),
          Text(
            'IA génère vos billets...',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Création d\'offres personnalisées',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 48, color: Colors.red),
          const SizedBox(height: 16),
          const Text(
            'Erreur de génération IA',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Utilisation des billets par défaut',
            style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => setState(() {
              _ticketsFuture = _loadTickets();
              _isLoading = true;
            }),
            child: const Text('Réessayer'),
          ),
        ],
      ),
    );
  }

  Widget _buildTicketCard(EventTicket ticket, int index) {
    final isSelected = index == _selectedTicketIndex;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: isSelected ? 4 : 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isSelected ? Colors.blue : Colors.transparent,
          width: isSelected ? 2 : 0,
        ),
      ),
      child: InkWell(
        onTap: () => setState(() => _selectedTicketIndex = index),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Ticket Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      ticket.ticketType,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isSelected ? Colors.blue.shade800 : Colors.black,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: ticket.isFree ? Colors.green.shade100 : Colors.blue.shade100,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      ticket.formattedPrice,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: ticket.isFree ? Colors.green.shade800 : Colors.blue.shade800,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Description
              Text(
                ticket.description,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade700,
                  fontStyle: FontStyle.italic,
                ),
              ),
              const SizedBox(height: 16),

              // Included Features
              _buildFeatureList(
                'Inclus:',
                ticket.includedFeatures,
                Colors.green.shade700,
              ),
              const SizedBox(height: 12),

              // Excluded Features
              _buildFeatureList(
                'Non inclus:',
                ticket.excludedFeatures,
                Colors.red.shade700,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureList(String title, List<String> features, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        ...features.map((feature) => Padding(
          padding: const EdgeInsets.only(left: 8.0, bottom: 2),
          child: Text(
            '• $feature',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
          ),
        )),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: FutureBuilder<List<EventTicket>>(
            future: _ticketsFuture,
            builder: (context, snapshot) {
              return ElevatedButton(
                onPressed: snapshot.hasData ? _confirmSelection : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue.shade600,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Confirmer la Sélection'),
              );
            },
          ),
        ),
      ],
    );
  }

  void _confirmSelection() async {
    final tickets = await _ticketsFuture;
    final selectedTicket = tickets[_selectedTicketIndex];

    // Show confirmation
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Participation Confirmée!'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Vous avez sélectionné:',
              style: TextStyle(fontSize: 16, color: Colors.grey.shade700),
            ),
            const SizedBox(height: 8),
            Text(
              selectedTicket.ticketType,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Prix: ${selectedTicket.formattedPrice}',
              style: TextStyle(
                fontSize: 16,
                color: selectedTicket.isFree ? Colors.green : Colors.blue,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Retour'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context); // Close confirmation
              Navigator.pop(context); // Close ticket dialog
              widget.onTicketSelected(selectedTicket);
            },
            child: const Text('Finaliser'),
          ),
        ],
      ),
    );
  }
}