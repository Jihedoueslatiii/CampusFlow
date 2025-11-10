import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/club_model.dart';
import '../../models/events_model.dart';
import '../../services/event_service.dart';

class CreateEventScreen extends StatefulWidget {
  final Club club;

  const CreateEventScreen({Key? key, required this.club}) : super(key: key);

  @override
  _CreateEventScreenState createState() => _CreateEventScreenState();
}

class _CreateEventScreenState extends State<CreateEventScreen> {
  final _formKey = GlobalKey<FormState>();
  final EventService _eventService = EventService();

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _maxParticipantsController = TextEditingController();

  DateTime _selectedStartDate = DateTime.now().add(Duration(days: 1));
  TimeOfDay _selectedStartTime = TimeOfDay(hour: 18, minute: 0);
  DateTime _selectedEndDate = DateTime.now().add(Duration(days: 1));
  TimeOfDay _selectedEndTime = TimeOfDay(hour: 20, minute: 0);

  bool _hasMaxParticipants = false;

  // Color constants based on the palette
  static const Color primaryAccent = Color(0xFFE53935);
  static const Color background = Color(0xFFFFFFFF);
  static const Color textPrimary = Color(0xFF212121);
  static const Color backgroundSecondary = Color(0xFFF5F5F5);

  Future<void> _selectStartDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedStartDate,
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );
    if (picked != null && picked != _selectedStartDate) {
      setState(() {
        _selectedStartDate = picked;
        _selectedEndDate = picked; // Synchroniser la date de fin
      });
    }
  }

  Future<void> _selectStartTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedStartTime,
    );
    if (picked != null) {
      setState(() {
        _selectedStartTime = picked;
      });
    }
  }

  Future<void> _selectEndDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedEndDate,
      firstDate: _selectedStartDate,
      lastDate: DateTime(2100),
    );
    if (picked != null && picked != _selectedEndDate) {
      setState(() {
        _selectedEndDate = picked;
      });
    }
  }

  Future<void> _selectEndTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedEndTime,
    );
    if (picked != null) {
      setState(() {
        _selectedEndTime = picked;
      });
    }
  }

  DateTime _combineDateTime(DateTime date, TimeOfDay time) {
    return DateTime(
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
    );
  }

  Duration _calculateDuration() {
    final start = _combineDateTime(_selectedStartDate, _selectedStartTime);
    final end = _combineDateTime(_selectedEndDate, _selectedEndTime);
    return end.difference(start);
  }

  String _getDurationText() {
    final duration = _calculateDuration();
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);

    if (hours > 0 && minutes > 0) {
      return '$hours heures $minutes minutes';
    } else if (hours > 0) {
      return '$hours heures';
    } else {
      return '$minutes minutes';
    }
  }

  Future<void> _createEvent() async {
    if (_formKey.currentState!.validate()) {
      final startDateTime = _combineDateTime(_selectedStartDate, _selectedStartTime);
      final endDateTime = _combineDateTime(_selectedEndDate, _selectedEndTime);

      // Validation de la date
      if (startDateTime.isBefore(DateTime.now())) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('La date de début ne peut pas être dans le passé'),
            backgroundColor: primaryAccent,
          ),
        );
        return;
      }

      // Validation de la durée
      final duration = endDateTime.difference(startDateTime);
      if (duration.inHours > 5) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('La durée maximale est de 5 heures'),
            backgroundColor: primaryAccent,
          ),
        );
        return;
      }

      if (duration.inMinutes <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('La date de fin doit être après la date de début'),
            backgroundColor: primaryAccent,
          ),
        );
        return;
      }

      final event = Event(
        title: _titleController.text,
        description: _descriptionController.text,
        startDate: startDateTime,
        endDate: endDateTime,
        clubId: widget.club.id!,
        clubName: widget.club.nom,
        location: _locationController.text,
        maxParticipants: _hasMaxParticipants ?
        int.tryParse(_maxParticipantsController.text) : null,
        createdAt: DateTime.now(),
      );

      try {
        await _eventService.createEvent(event);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Événement créé avec succès!'),
            backgroundColor: Colors.green,
          ),
        );

        Navigator.pop(context, true);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de la création: $e'),
            backgroundColor: primaryAccent,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundSecondary,
      appBar: AppBar(
        title: Text(
          'Créer un événement',
          style: TextStyle(color: background),
        ),
        backgroundColor: primaryAccent,
        foregroundColor: background,
        actions: [
          IconButton(
            icon: Icon(Icons.check),
            onPressed: _createEvent,
          ),
        ],
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              // TITRE
              TextFormField(
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: 'Titre de l\'événement',
                  labelStyle: TextStyle(color: textPrimary),
                  border: OutlineInputBorder(),
                  filled: true,
                  fillColor: background,
                ),
                style: TextStyle(color: textPrimary),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Veuillez entrer un titre';
                  }
                  if (value.length < 3) {
                    return 'Le titre doit faire au moins 3 caractères';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),

              // DESCRIPTION
              TextFormField(
                controller: _descriptionController,
                decoration: InputDecoration(
                  labelText: 'Description',
                  labelStyle: TextStyle(color: textPrimary),
                  border: OutlineInputBorder(),
                  filled: true,
                  fillColor: background,
                ),
                style: TextStyle(color: textPrimary),
                maxLines: 4,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Veuillez entrer une description';
                  }
                  if (value.length < 10) {
                    return 'La description doit faire au moins 10 caractères';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),

              // LIEU
              TextFormField(
                controller: _locationController,
                decoration: InputDecoration(
                  labelText: 'Lieu',
                  labelStyle: TextStyle(color: textPrimary),
                  border: OutlineInputBorder(),
                  filled: true,
                  fillColor: background,
                ),
                style: TextStyle(color: textPrimary),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Veuillez entrer un lieu';
                  }
                  return null;
                },
              ),
              SizedBox(height: 20),

              // DATE ET HEURE DE DÉBUT
              Card(
                color: background,
                elevation: 2,
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Début',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: textPrimary,
                        ),
                      ),
                      SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: _selectStartDate,
                              style: OutlinedButton.styleFrom(
                                foregroundColor: primaryAccent,
                                side: BorderSide(color: primaryAccent),
                              ),
                              child: Text(
                                DateFormat('dd/MM/yyyy').format(_selectedStartDate),
                                style: TextStyle(color: textPrimary),
                              ),
                            ),
                          ),
                          SizedBox(width: 8),
                          Expanded(
                            child: OutlinedButton(
                              onPressed: _selectStartTime,
                              style: OutlinedButton.styleFrom(
                                foregroundColor: primaryAccent,
                                side: BorderSide(color: primaryAccent),
                              ),
                              child: Text(
                                _selectedStartTime.format(context),
                                style: TextStyle(color: textPrimary),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              SizedBox(height: 16),

              // DATE ET HEURE DE FIN
              Card(
                color: background,
                elevation: 2,
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Fin',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: textPrimary,
                        ),
                      ),
                      SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: _selectEndDate,
                              style: OutlinedButton.styleFrom(
                                foregroundColor: primaryAccent,
                                side: BorderSide(color: primaryAccent),
                              ),
                              child: Text(
                                DateFormat('dd/MM/yyyy').format(_selectedEndDate),
                                style: TextStyle(color: textPrimary),
                              ),
                            ),
                          ),
                          SizedBox(width: 8),
                          Expanded(
                            child: OutlinedButton(
                              onPressed: _selectEndTime,
                              style: OutlinedButton.styleFrom(
                                foregroundColor: primaryAccent,
                                side: BorderSide(color: primaryAccent),
                              ),
                              child: Text(
                                _selectedEndTime.format(context),
                                style: TextStyle(color: textPrimary),
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Durée: ${_getDurationText()}',
                        style: TextStyle(
                          color: _calculateDuration().inHours > 5 ? primaryAccent : Colors.green,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              SizedBox(height: 20),

              // LIMITE DE PARTICIPANTS
              Card(
                color: background,
                elevation: 2,
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Checkbox(
                            value: _hasMaxParticipants,
                            onChanged: (value) {
                              setState(() {
                                _hasMaxParticipants = value!;
                              });
                            },
                            activeColor: primaryAccent,
                          ),
                          Text(
                            'Limiter le nombre de participants',
                            style: TextStyle(color: textPrimary),
                          ),
                        ],
                      ),
                      if (_hasMaxParticipants) ...[
                        SizedBox(height: 8),
                        TextFormField(
                          controller: _maxParticipantsController,
                          decoration: InputDecoration(
                            labelText: 'Nombre maximum',
                            labelStyle: TextStyle(color: textPrimary),
                            border: OutlineInputBorder(),
                            filled: true,
                            fillColor: background,
                          ),
                          style: TextStyle(color: textPrimary),
                          keyboardType: TextInputType.number,
                          validator: (value) {
                            if (_hasMaxParticipants) {
                              if (value == null || value.isEmpty) {
                                return 'Veuillez entrer un nombre';
                              }
                              final number = int.tryParse(value);
                              if (number == null || number < 1) {
                                return 'Nombre invalide';
                              }
                            }
                            return null;
                          },
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              SizedBox(height: 20),

              // BOUTON DE CRÉATION
              ElevatedButton(
                onPressed: _createEvent,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryAccent,
                  foregroundColor: background,
                  padding: EdgeInsets.symmetric(vertical: 16),
                ),
                child: Text(
                  'Créer l\'événement',
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}