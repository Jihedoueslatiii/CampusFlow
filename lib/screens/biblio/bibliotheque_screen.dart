import 'package:flutter/material.dart';
import 'package:compusflow/models/bibliotheque_model.dart';
import 'package:compusflow/repositories/bibliotheque_repository.dart';
import 'package:compusflow/services/database_service.dart';

class BibliothequeScreen extends StatefulWidget {
  const BibliothequeScreen({super.key});

  @override
  State<BibliothequeScreen> createState() => _BibliothequeScreenState();
}

class _BibliothequeScreenState extends State<BibliothequeScreen> {
  final DatabaseService _databaseService = DatabaseService();
  late BibliothequeRepository _bibliothequeRepository;
  List<Bibliotheque> _bibliotheques = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _bibliothequeRepository = BibliothequeRepository(_databaseService);
    _loadBibliotheques();
  }

  Future<void> _loadBibliotheques() async {
    try {
      final bibliotheques = await _bibliothequeRepository.getBibliotheques();
      setState(() {
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

  void _showAddBibliothequeDialog() {
    showDialog(
      context: context,
      builder: (context) => BibliothequeDialog(
        onBibliothequeSaved: _loadBibliotheques,
        repository: _bibliothequeRepository,
      ),
    );
  }

  void _showEditBibliothequeDialog(Bibliotheque bibliotheque) {
    showDialog(
      context: context,
      builder: (context) => BibliothequeDialog(
        onBibliothequeSaved: _loadBibliotheques,
        repository: _bibliothequeRepository,
        bibliotheque: bibliotheque,
      ),
    );
  }

  void _showDeleteConfirmation(int id, String name) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer la bibliothèque'),
        content: Text('Êtes-vous sûr de vouloir supprimer "$name"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _deleteBibliotheque(id);
            },
            child: const Text('Supprimer', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteBibliotheque(int id) async {
    try {
      await _bibliothequeRepository.deleteBibliotheque(id);
      _loadBibliotheques();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bibliothèque supprimée avec succès')),
      );
    } catch (e) {
      _showErrorSnackBar('Erreur de suppression: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bibliothèques'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _showAddBibliothequeDialog,
            tooltip: 'Ajouter une bibliothèque',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _bibliotheques.isEmpty
          ? const Center(
        child: Text(
          'Aucune bibliothèque disponible',
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      )
          : ListView.builder(
        itemCount: _bibliotheques.length,
        itemBuilder: (context, index) {
          final bibliotheque = _bibliotheques[index];
          return BibliothequeCard(
            bibliotheque: bibliotheque,
            onEdit: () => _showEditBibliothequeDialog(bibliotheque),
            onDelete: () => _showDeleteConfirmation(
              bibliotheque.id!,
              bibliotheque.name,
            ),
          );
        },
      ),
    );
  }
}

class BibliothequeCard extends StatelessWidget {
  final Bibliotheque bibliotheque;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const BibliothequeCard({
    super.key,
    required this.bibliotheque,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      child: ListTile(
        leading: const Icon(Icons.library_books, color: Colors.indigo),
        title: Text(
          bibliotheque.name,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              bibliotheque.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 4),
            Text(
              bibliotheque.location,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 4),
            Text(
              bibliotheque.contactInfo,
              style: const TextStyle(fontSize: 12, color: Colors.blue),
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
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
        ),
      ),
    );
  }
}

class BibliothequeDialog extends StatefulWidget {
  final VoidCallback onBibliothequeSaved;
  final BibliothequeRepository repository;
  final Bibliotheque? bibliotheque;

  const BibliothequeDialog({
    super.key,
    required this.onBibliothequeSaved,
    required this.repository,
    this.bibliotheque,
  });

  @override
  State<BibliothequeDialog> createState() => _BibliothequeDialogState();
}

class _BibliothequeDialogState extends State<BibliothequeDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();
  final _contactController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    // Pre-fill fields if editing
    if (widget.bibliotheque != null) {
      _nameController.text = widget.bibliotheque!.name;
      _descriptionController.text = widget.bibliotheque!.description;
      _locationController.text = widget.bibliotheque!.location;
      _contactController.text = widget.bibliotheque!.contactInfo;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.bibliotheque != null;

    return AlertDialog(
      title: Text(isEditing ? 'Modifier la Bibliothèque' : 'Nouvelle Bibliothèque'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Nom',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Veuillez entrer un nom';
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
                  labelText: 'Localisation',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Veuillez entrer une localisation';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _contactController,
                decoration: const InputDecoration(
                  labelText: 'Contact',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Veuillez entrer les informations de contact';
                  }
                  return null;
                },
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
        final bibliotheque = Bibliotheque(
          id: widget.bibliotheque?.id,
          name: _nameController.text,
          description: _descriptionController.text,
          location: _locationController.text,
          contactInfo: _contactController.text,
          createdAt: widget.bibliotheque?.createdAt ?? DateTime.now(),
          updatedAt: DateTime.now(),
        );

        if (widget.bibliotheque == null) {
          await widget.repository.createBibliotheque(bibliotheque);
        } else {
          await widget.repository.updateBibliotheque(bibliotheque);
        }

        widget.onBibliothequeSaved();
        Navigator.pop(context);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.bibliotheque == null
                ? 'Bibliothèque ajoutée avec succès'
                : 'Bibliothèque modifiée avec succès'
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
    _nameController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    _contactController.dispose();
    super.dispose();
  }
}