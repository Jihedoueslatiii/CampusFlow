import 'package:compusflow/models/examen.dart';
import 'package:compusflow/models/salle.dart';
import 'package:compusflow/services/database_service.dart';
import 'package:flutter/material.dart';

import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';

class AddEditExamenScreen extends StatefulWidget {
  final Examen? examen;
  const AddEditExamenScreen({super.key, this.examen});

  @override
  State<AddEditExamenScreen> createState() => _AddEditExamenScreenState();
}

class _AddEditExamenScreenState extends State<AddEditExamenScreen> {
  final _formKey = GlobalKey<FormState>();
  final _coursCtrl = TextEditingController();
  final _dureeCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  final _resultCtrl = TextEditingController();

  String _type = 'partiel';
  String _status = 'Scheduled';
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = const TimeOfDay(hour: 9, minute: 0);
  int? _selectedSalleId;
  List<Salle> _salles = [];
  List<String> _files = [];
  bool _isLoading = false;
  bool _isDateFormatInitialized = false;

  // CORRECTION: Instance correcte de DatabaseService
  final DatabaseService _db = DatabaseService();

  @override
  void initState() {
    super.initState();
    _initializeDateFormatting();
    _loadSalles();
    if (widget.examen != null) {
      final e = widget.examen!;
      _coursCtrl.text = e.cours;
      _dureeCtrl.text = e.dureeMinutes.toString();
      _type = e.type;
      _status = e.status ?? 'Scheduled';
      _selectedDate = e.date;
      _selectedTime = TimeOfDay(hour: e.date.hour, minute: e.date.minute);
      _selectedSalleId = e.salleId;
      _notesCtrl.text = e.notes ?? '';
      _resultCtrl.text = e.result ?? '';
      _files = e.files ?? [];
    }
  }

  Future<void> _initializeDateFormatting() async {
    await initializeDateFormatting('fr_FR', null).then((_) {
      setState(() {
        _isDateFormatInitialized = true;
      });
    });
  }

  Future _loadSalles() async {
    final all = await _db.getAllSalles(); // CORRECTION: Utilisation de _db
    setState(() => _salles = all);
  }

  DateTime get _combinedDateTime =>
      DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day,
          _selectedTime.hour, _selectedTime.minute);

  Future _pickDateTime() async {
    final d = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Colors.red.shade600,
              onPrimary: Colors.white,
              onSurface: Colors.grey.shade900,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: Colors.red.shade600,
              ),
            ),
          ),
          child: child!,
        );
      },
    );
    if (d == null) return;

    final t = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Colors.red.shade600,
              onPrimary: Colors.white,
              onSurface: Colors.grey.shade900,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: Colors.red.shade600,
              ),
            ),
          ),
          child: child!,
        );
      },
    );
    if (t == null) return;

    setState(() {
      _selectedDate = d;
      _selectedTime = t;
    });
  }

  Future _pickFiles() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        allowMultiple: true,
        type: FileType.any,
      );

      if (result != null && result.files.isNotEmpty) {
        final newFiles = result.files
            .map((f) => f.path)
            .where((path) => path != null)
            .cast<String>()
            .toList();

        setState(() => _files.addAll(newFiles));

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ ${newFiles.length} fichier(s) ajouté(s)'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.fixed,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Erreur: $e'),
          backgroundColor: Colors.red.shade600,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      );
    }
  }

  void _removeFile(int index) {
    setState(() {
      _files.removeAt(index);
    });
  }

  void _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final start = _combinedDateTime;
    final duration = int.parse(_dureeCtrl.text);

    final examen = Examen(
      id: widget.examen?.id,
      type: _type,
      date: start,
      cours: _coursCtrl.text.trim(),
      dureeMinutes: duration,
      salleId: _selectedSalleId,
      status: _status,
      notes: _notesCtrl.text.trim(),
      result: _resultCtrl.text.trim(),
      files: _files,
      reminder1Day: start.subtract(const Duration(days: 1)),
      reminder1Hour: start.subtract(const Duration(hours: 1)),
    );

    try {
      if (widget.examen == null) {
        // CORRECTION: Appel correct de la méthode insertExamen
        await _db.insertExamen(examen);
      } else {
        await _db.updateExamen(examen);
      }
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.examen == null
                  ? '✅ Examen créé avec succès!'
                  : '✅ Examen mis à jour avec succès!',
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Erreur: ${e.toString()}'),
            backgroundColor: Colors.red.shade600,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.examen != null;

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: Text(
          isEdit ? 'Modifier l\'Examen' : 'Ajouter un Examen',
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.red.shade600,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header Card
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          isEdit ? Icons.edit : Icons.add,
                          color: Colors.red.shade600,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isEdit ? 'Modifier l\'Examen' : 'Nouvel Examen',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey.shade900,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              isEdit
                                  ? 'Mettez à jour les informations'
                                  : 'Remplissez les détails ci-dessous',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Form Fields
                _buildTextField(
                  controller: _coursCtrl,
                  label: 'Nom du Cours',
                  hint: 'ex: Mathématiques, Physique, Informatique',
                  icon: Icons.school,
                  validator: (v) => v == null || v.isEmpty ? 'Le nom du cours est requis' : null,
                ),
                const SizedBox(height: 20),

                _buildTextField(
                  controller: _dureeCtrl,
                  label: 'Durée (minutes)',
                  hint: 'Durée de l\'examen en minutes',
                  icon: Icons.timer,
                  keyboardType: TextInputType.number,
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'La durée est requise';
                    final num = int.tryParse(v);
                    if (num == null || num <= 0) {
                      return 'Entrez un nombre valide';
                    }
                    if (num > 480) {
                      return 'Durée trop longue (max 8 heures)';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                _buildTypeDropdown(),
                const SizedBox(height: 20),

                _buildStatusDropdown(),
                const SizedBox(height: 20),

                // Date & Time Section
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Date & Heure',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade900,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.calendar_today,
                            color: Colors.grey.shade600,
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _isDateFormatInitialized
                                      ? DateFormat('EEEE dd MMMM yyyy', 'fr_FR').format(_combinedDateTime)
                                      : _getFallbackDate(_combinedDateTime),
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.black87,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'à ${_selectedTime.format(context)}',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          ElevatedButton(
                            onPressed: _pickDateTime,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red.shade600,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              elevation: 0,
                            ),
                            child: const Text(
                              'Changer',
                              style: TextStyle(fontSize: 14),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                _buildRoomDropdown(),
                const SizedBox(height: 20),

                _buildTextField(
                  controller: _notesCtrl,
                  label: 'Notes (optionnel)',
                  hint: 'Notes supplémentaires sur l\'examen...',
                  icon: Icons.note,
                  maxLines: 3,
                  validator: (v) => null,
                ),
                const SizedBox(height: 20),

                _buildTextField(
                  controller: _resultCtrl,
                  label: 'Résultat / Note (optionnel)',
                  hint: 'ex: 15.5/20, A+, Réussi',
                  icon: Icons.grade,
                  validator: (v) => null,
                ),
                const SizedBox(height: 20),

                // Files Section
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Fichiers joints',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade900,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton.icon(
                      onPressed: _pickFiles,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.grey.shade700,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(color: Colors.grey.shade300),
                        ),
                        elevation: 0,
                      ),
                      icon: Icon(Icons.attach_file, color: Colors.grey.shade600, size: 20),
                      label: const Text('Ajouter des fichiers'),
                    ),
                    if (_files.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Text(
                        'Fichiers sélectionnés (${_files.length})',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ..._files.asMap().entries.map((entry) {
                        final index = entry.key;
                        final file = entry.value;
                        final fileName = file.split('/').last;
                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.insert_drive_file,
                                color: Colors.grey.shade600,
                                size: 20,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  fileName,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey.shade800,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              IconButton(
                                icon: Icon(
                                  Icons.delete,
                                  color: Colors.red.shade400,
                                  size: 20,
                                ),
                                onPressed: () => _removeFile(index),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ],
                  ],
                ),
                const SizedBox(height: 32),

                // Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _isLoading ? null : () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.grey.shade700,
                          side: BorderSide(color: Colors.grey.shade300),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          backgroundColor: Colors.white,
                        ),
                        child: Text(
                          'Annuler',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade900,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _save,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red.shade600,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                          shadowColor: Colors.transparent,
                        ),
                        child: _isLoading
                            ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                            : Text(
                          isEdit ? 'Mettre à jour' : 'Ajouter',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _getFallbackDate(DateTime dateTime) {
    final days = ['Lundi', 'Mardi', 'Mercredi', 'Jeudi', 'Vendredi', 'Samedi', 'Dimanche'];
    final months = ['janvier', 'février', 'mars', 'avril', 'mai', 'juin', 'juillet', 'août', 'septembre', 'octobre', 'novembre', 'décembre'];

    final dayName = days[dateTime.weekday - 1];
    final monthName = months[dateTime.month - 1];

    return '$dayName ${dateTime.day} $monthName ${dateTime.year}';
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    required String? Function(String?) validator,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade900,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.grey.shade400),
            prefixIcon: Icon(icon, color: Colors.grey.shade600, size: 20),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.red.shade600, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.red.shade600),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.red.shade600, width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          ),
          validator: validator,
        ),
      ],
    );
  }

  Widget _buildTypeDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Type d\'examen',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade900,
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: _type,
          decoration: InputDecoration(
            prefixIcon: Icon(Icons.category, color: Colors.grey.shade600, size: 20),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.red.shade600, width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          ),
          items: [
            DropdownMenuItem(
              value: 'partiel',
              child: Row(
                children: [
                  Icon(Icons.assignment, size: 20, color: Colors.orange.shade600),
                  const SizedBox(width: 12),
                  const Text('Partiel'),
                ],
              ),
            ),
            DropdownMenuItem(
              value: 'final',
              child: Row(
                children: [
                  Icon(Icons.school, size: 20, color: Colors.red.shade600),
                  const SizedBox(width: 12),
                  const Text('Final'),
                ],
              ),
            ),
          ],
          onChanged: (v) => setState(() => _type = v!),
        ),
      ],
    );
  }

  Widget _buildStatusDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Statut',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade900,
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: _status,
          decoration: InputDecoration(
            prefixIcon: Icon(Icons.circle, color: _getStatusColor(_status), size: 20),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.red.shade600, width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          ),
          items: [
            DropdownMenuItem(
              value: 'Scheduled',
              child: Row(
                children: [
                  Icon(Icons.schedule, size: 20, color: Colors.blue.shade600),
                  const SizedBox(width: 12),
                  const Text('Planifié'),
                ],
              ),
            ),
            DropdownMenuItem(
              value: 'In Progress',
              child: Row(
                children: [
                  Icon(Icons.play_circle, size: 20, color: Colors.orange.shade600),
                  const SizedBox(width: 12),
                  const Text('En cours'),
                ],
              ),
            ),
            DropdownMenuItem(
              value: 'Completed',
              child: Row(
                children: [
                  Icon(Icons.check_circle, size: 20, color: Colors.green.shade600),
                  const SizedBox(width: 12),
                  const Text('Terminé'),
                ],
              ),
            ),
            DropdownMenuItem(
              value: 'Cancelled',
              child: Row(
                children: [
                  Icon(Icons.cancel, size: 20, color: Colors.red.shade600),
                  const SizedBox(width: 12),
                  const Text('Annulé'),
                ],
              ),
            ),
          ],
          onChanged: (v) => setState(() => _status = v!),
        ),
      ],
    );
  }

  Widget _buildRoomDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Salle d\'examen',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade900,
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<int?>(
          value: _selectedSalleId,
          decoration: InputDecoration(
            prefixIcon: Icon(Icons.meeting_room, color: Colors.grey.shade600, size: 20),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.red.shade600, width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          ),
          items: [
            const DropdownMenuItem<int?>(
              value: null,
              child: Row(
                children: [
                  Icon(Icons.meeting_room_outlined, size: 20, color: Colors.grey),
                  SizedBox(width: 12),
                  Text('Aucune salle sélectionnée'),
                ],
              ),
            ),
            ..._salles.map((s) => DropdownMenuItem<int?>(
              value: s.id,
              child: Row(
                children: [
                  Icon(
                    s.type == 'TP' ? Icons.computer : Icons.school,
                    size: 20,
                    color: s.type == 'TP' ? Colors.orange.shade600 : Colors.blue.shade600,
                  ),
                  const SizedBox(width: 12),
                  Text('Salle ${s.numero} - ${s.batiment}'),
                ],
              ),
            )),
          ],
          onChanged: (v) => setState(() => _selectedSalleId = v),
        ),
      ],
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Scheduled':
        return Colors.blue.shade600;
      case 'In Progress':
        return Colors.orange.shade600;
      case 'Completed':
        return Colors.green.shade600;
      case 'Cancelled':
        return Colors.red.shade600;
      default:
        return Colors.grey.shade600;
    }
  }
}