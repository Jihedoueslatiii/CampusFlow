import 'package:flutter/material.dart';
import 'package:compusflow/models/event_model.dart';
import 'package:compusflow/models/bibliotheque_model.dart';
import 'package:compusflow/repositories/event_repository.dart';
import 'package:compusflow/repositories/bibliotheque_repository.dart';
import 'package:compusflow/services/database_service.dart';
import 'package:compusflow/services/auth_service.dart';
import 'package:compusflow/widgets/ai_ticket_dialog.dart';
import 'package:compusflow/models/event_ticket.dart';

class EventScreen extends StatefulWidget {
  const EventScreen({super.key});

  @override
  State<EventScreen> createState() => _EventScreenState();
}

class _EventScreenState extends State<EventScreen> {
  final DatabaseService _databaseService = DatabaseService();
  final AuthService _authService = AuthService();
  late EventRepository _eventRepository;
  late BibliothequeRepository _bibliothequeRepository;
  List<Event> _events = [];
  List<Bibliotheque> _bibliotheques = [];
  bool _isLoading = true;
  String _userRole = 'etudiant';
  int? _userId;

  @override
  void initState() {
    super.initState();
    _eventRepository = EventRepository(_databaseService);
    _bibliothequeRepository = BibliothequeRepository(_databaseService);
    _loadUserData();
    _loadData();
  }

  Future<void> _loadUserData() async {
    try {
      final userData = await _authService.getCurrentUser();
      if (userData != null) {
        setState(() {
          _userRole = userData['role'] ?? 'etudiant';
          _userId = userData['id']; // This uses SharedPreferences user ID
        });
      }
    } catch (e) {
      print('Error loading user data: $e');
    }
  }

  Future<void> _loadData() async {
    try {
      final events = await _eventRepository.getEvents();
      final bibliotheques = await _bibliothequeRepository.getBibliotheques();

      setState(() {
        _events = events;
        _bibliotheques = bibliotheques;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showErrorSnackBar('Erreur de chargement: $e');
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _showAddEventDialog() {
    if (_bibliotheques.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Aucune bibliothèque disponible')),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => EventDialog(
        onEventSaved: _loadData,
        repository: _eventRepository,
        bibliotheques: _bibliotheques,
      ),
    );
  }

  void _showEditEventDialog(Event event) {
    if (_bibliotheques.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Aucune bibliothèque disponible')),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => EventDialog(
        onEventSaved: _loadData,
        repository: _eventRepository,
        bibliotheques: _bibliotheques,
        event: event,
      ),
    );
  }

  void _showDeleteConfirmation(int id, String title) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer l\'événement'),
        content: Text('Êtes-vous sûr de vouloir supprimer "$title"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _deleteEvent(id);
            },
            child: const Text('Supprimer', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteEvent(int id) async {
    try {
      await _eventRepository.deleteEvent(id);
      _loadData();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Événement supprimé avec succès')),
      );
    } catch (e) {
      _showErrorSnackBar('Erreur de suppression: $e');
    }
  }

  Future<void> _handleParticipation(Event event) async {
    try {
      if (_userId == null) {
        _showErrorSnackBar('Impossible de participer: utilisateur non connecté');
        return;
      }

      // Check if already participating
      final isParticipating = await _eventRepository.isUserParticipating(event.id!, _userId!);

      if (isParticipating) {
        // Already participating - show cancel option
        _showCancelParticipationDialog(event);
      } else {
        // Show AI ticket selection dialog
        _showAITicketDialog(event);
      }
    } catch (e) {
      _showErrorSnackBar('Erreur: $e');
    }
  }

  void _showAITicketDialog(Event event) {
    showDialog(
      context: context,
      builder: (context) => AITicketDialog(
        event: event,
        onTicketSelected: (selectedTicket) async {
          // User selected a ticket - proceed with participation
          await _finalizeParticipation(event, selectedTicket);
        },
      ),
    );
  }

  Future<void> _finalizeParticipation(Event event, EventTicket selectedTicket) async {
    try {
      // Check if event is full
      if ((event.currentParticipants ?? 0) >= event.maxParticipants) {
        _showErrorSnackBar('Désolé, cet événement est complet');
        return;
      }

      await _eventRepository.participateInEvent(event.id!, _userId!);

      // Show success message with ticket details
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('🎉 Participation confirmée à "${event.title}"'),
              Text(
                'Billet: ${selectedTicket.ticketType}',
                style: const TextStyle(fontSize: 12),
              ),
            ],
          ),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 4),
        ),
      );

      _loadData(); // Refresh the event list
    } catch (e) {
      _showErrorSnackBar('Erreur lors de la participation: $e');
    }
  }

  void _showCancelParticipationDialog(Event event) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Annuler la participation'),
        content: const Text('Voulez-vous vraiment annuler votre participation à cet événement ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Non'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _eventRepository.cancelParticipation(event.id!, _userId!);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Participation annulée'), backgroundColor: Colors.orange),
              );
              _loadData();
            },
            child: const Text('Oui, annuler'),
          ),
        ],
      ),
    );
  }

  String _getBibliothequeName(int bibliothequeId) {
    final bibliotheque = _bibliotheques.firstWhere(
          (b) => b.id == bibliothequeId,
      orElse: () => Bibliotheque(
        id: -1,
        name: 'Inconnue',
        description: '',
        location: '',
        contactInfo: '',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    );
    return bibliotheque.name;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Événements'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        actions: [
          if (_userRole == 'admin' || _userRole == 'professeur')
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: _showAddEventDialog,
              tooltip: 'Ajouter un événement',
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _events.isEmpty
          ? const Center(
        child: Text(
          'Aucun événement disponible',
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      )
          : ListView.builder(
        itemCount: _events.length,
        itemBuilder: (context, index) {
          final event = _events[index];
          return EventCard(
            event: event,
            bibliothequeName: _getBibliothequeName(event.bibliothequeId),
            onEdit: () => _showEditEventDialog(event),
            onDelete: () => _showDeleteConfirmation(event.id!, event.title),
            userRole: _userRole,
            userId: _userId,
            onParticipate: () => _handleParticipation(event),
          );
        },
      ),
    );
  }
}

class EventCard extends StatelessWidget {
  final Event event;
  final String bibliothequeName;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final String userRole;
  final int? userId;
  final VoidCallback? onParticipate;

  const EventCard({
    super.key,
    required this.event,
    required this.bibliothequeName,
    required this.onEdit,
    required this.onDelete,
    required this.userRole,
    this.userId,
    this.onParticipate,
  });

  @override
  Widget build(BuildContext context) {
    final isUpcoming = event.isUpcoming;
    final isStudent = userRole == 'etudiant';

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      child: ListTile(
        leading: Icon(
          isUpcoming ? Icons.event_available : Icons.event_busy,
          color: isUpcoming ? Colors.green : Colors.grey,
        ),
        title: Text(
          event.title,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: isUpcoming ? null : Colors.grey,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              event.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 4),
            Text(
              '${event.dateTime.day}/${event.dateTime.month}/${event.dateTime.year} à ${event.dateTime.hour}:${event.dateTime.minute.toString().padLeft(2, '0')}',
              style: const TextStyle(fontSize: 12, color: Colors.blue),
            ),
            const SizedBox(height: 4),
            Text(
              event.location,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 4),
            Text(
              'Bibliothèque: $bibliothequeName',
              style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
            ),
            const SizedBox(height: 4),
            Text(
              'Participants: ${event.currentParticipants ?? 0}/${event.maxParticipants}',
              style: const TextStyle(fontSize: 12, color: Colors.orange),
            ),
            if (isStudent && isUpcoming && userId != null) ...[
              const SizedBox(height: 4),
              _buildParticipationStatus(),
            ],
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (userRole == 'admin' || userRole == 'professeur') ...[
              IconButton(
                icon: const Icon(Icons.edit, color: Colors.blue),
                onPressed: onEdit,
                tooltip: 'Modifier',
              ),
              IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                onPressed: onDelete,
                tooltip: 'Supprimer',
              ),
            ],
            if (isStudent && isUpcoming && userId != null) ...[
              const SizedBox(width: 8),
              _buildParticipateButton(),
            ],
          ],
        ),
        onTap: () {
          // Navigate to event details
        },
      ),
    );
  }

  // UPDATED: Build participation status
  Widget _buildParticipationStatus() {
    return FutureBuilder<bool>(
      future: _getParticipationStatus(),
      builder: (context, snapshot) {
        final isParticipating = snapshot.data ?? false;
        return Text(
          isParticipating ? '✅ Vous participez' : '❌ Non inscrit',
          style: TextStyle(
            fontSize: 11,
            color: isParticipating ? Colors.green : Colors.red,
            fontWeight: FontWeight.bold,
          ),
        );
      },
    );
  }

  // UPDATED: Get participation status
  Future<bool> _getParticipationStatus() async {
    if (userId == null) return false;
    try {
      final repository = EventRepository(DatabaseService());
      return await repository.isUserParticipating(event.id!, userId!);
    } catch (e) {
      return false;
    }
  }

  // UPDATED: Build participate button
  Widget _buildParticipateButton() {
    return FutureBuilder<bool>(
      future: _getParticipationStatus(),
      builder: (context, snapshot) {
        final isParticipating = snapshot.data ?? false;
        final isEventFull = (event.currentParticipants ?? 0) >= event.maxParticipants;

        if (isEventFull && !isParticipating) {
          return Tooltip(
            message: 'Événement complet',
            child: IconButton(
              icon: const Icon(Icons.event_busy, color: Colors.grey),
              onPressed: null,
            ),
          );
        }

        return IconButton(
          icon: Icon(
            isParticipating ? Icons.event_available : Icons.event,
            color: isParticipating ? Colors.green : Colors.blue,
          ),
          onPressed: onParticipate,
          tooltip: isParticipating ? 'Se désinscrire' : 'Participer',
        );
      },
    );
  }
}

class EventDialog extends StatefulWidget {
  final VoidCallback onEventSaved;
  final EventRepository repository;
  final List<Bibliotheque> bibliotheques;
  final Event? event;

  const EventDialog({
    super.key,
    required this.onEventSaved,
    required this.repository,
    required this.bibliotheques,
    this.event,
  });

  @override
  State<EventDialog> createState() => _EventDialogState();
}

class _EventDialogState extends State<EventDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();
  final _participantsController = TextEditingController(text: '50');
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));
  TimeOfDay _selectedTime = const TimeOfDay(hour: 18, minute: 0);
  int? _selectedBibliothequeId;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    if (widget.event != null) {
      _titleController.text = widget.event!.title;
      _descriptionController.text = widget.event!.description;
      _locationController.text = widget.event!.location;
      _participantsController.text = widget.event!.maxParticipants.toString();
      _selectedDate = widget.event!.dateTime;
      _selectedTime = TimeOfDay.fromDateTime(widget.event!.dateTime);
      _selectedBibliothequeId = widget.event!.bibliothequeId;
    }
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _selectTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    if (picked != null && picked != _selectedTime) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.event != null;

    return AlertDialog(
      title: Text(isEditing ? 'Modifier l\'Événement' : 'Nouvel Événement'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Titre',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Veuillez entrer un titre';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Veuillez entrer une description';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _locationController,
                decoration: const InputDecoration(
                  labelText: 'Lieu',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Veuillez entrer un lieu';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _participantsController,
                      decoration: const InputDecoration(
                        labelText: 'Participants max',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Veuillez entrer un nombre';
                        }
                        if (int.tryParse(value) == null) {
                          return 'Nombre invalide';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<int>(
                value: _selectedBibliothequeId,
                decoration: const InputDecoration(
                  labelText: 'Bibliothèque',
                  border: OutlineInputBorder(),
                ),
                items: widget.bibliotheques.map((bibliotheque) {
                  return DropdownMenuItem<int>(
                    value: bibliotheque.id,
                    child: Text(bibliotheque.name),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedBibliothequeId = value;
                  });
                },
                validator: (value) {
                  if (value == null) {
                    return 'Veuillez sélectionner une bibliothèque';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _selectDate,
                      child: Text(
                        'Date: ${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _selectTime,
                      child: Text(
                        'Heure: ${_selectedTime.format(context)}',
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSubmitting ? null : () => Navigator.pop(context),
          child: const Text('Annuler'),
        ),
        ElevatedButton(
          onPressed: _isSubmitting ? null : _submitForm,
          child: _isSubmitting
              ? const SizedBox(
            height: 16,
            width: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
              : Text(isEditing ? 'Modifier' : 'Ajouter'),
        ),
      ],
    );
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isSubmitting = true;
      });

      try {
        final eventDateTime = DateTime(
          _selectedDate.year,
          _selectedDate.month,
          _selectedDate.day,
          _selectedTime.hour,
          _selectedTime.minute,
        );

        final newEvent = Event(
          id: widget.event?.id,
          title: _titleController.text,
          description: _descriptionController.text,
          dateTime: eventDateTime,
          location: _locationController.text,
          maxParticipants: int.parse(_participantsController.text),
          bibliothequeId: _selectedBibliothequeId!,
          createdAt: widget.event?.createdAt ?? DateTime.now(),
          updatedAt: DateTime.now(),
        );

        if (widget.event == null) {
          await widget.repository.createEvent(newEvent);
        } else {
          await widget.repository.updateEvent(newEvent);
        }

        widget.onEventSaved();
        Navigator.pop(context);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.event == null
                ? 'Événement ajouté avec succès'
                : 'Événement modifié avec succès'
            ),
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
        );
      } finally {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    _participantsController.dispose();
    super.dispose();
  }
}