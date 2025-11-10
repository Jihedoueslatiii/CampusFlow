import 'package:flutter/material.dart';
import 'package:compusflow/services/projet_service.dart';
import 'package:intl/intl.dart';

class ProjetFormScreen extends StatefulWidget {
  // Le projet existant à modifier (null si nouveau projet)
  final Map<String, dynamic>? projet;

  const ProjetFormScreen({Key? key, this.projet}) : super(key: key);

  @override
  State<ProjetFormScreen> createState() => _ProjetFormScreenState();
}

class _ProjetFormScreenState extends State<ProjetFormScreen> {
  final ProjetService _projetService = ProjetService();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  // Contrôleurs de formulaire
  final TextEditingController _titreController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _coursAssocieController = TextEditingController();
  final TextEditingController _dateRenduController = TextEditingController();

  // Variables internes
  DateTime? _selectedDateRendu;
  bool _isLoading = false;

  // Couleurs
  static const Color primaryColor = Color(0xFF2575FC);
  static const Color accentColor = Color(0xFFFFA500);

  @override
  void initState() {
    super.initState();
    // Pré-remplir les champs si on est en mode édition
    if (widget.projet != null) {
      _titreController.text = widget.projet!['titre'] as String;
      _descriptionController.text = widget.projet!['description'] as String? ?? '';
      _coursAssocieController.text = widget.projet!['cours_associe'] as String? ?? '';

      final dateString = widget.projet!['date_rendu'] as String?;
      if (dateString != null) {
        _selectedDateRendu = DateTime.tryParse(dateString);
        if (_selectedDateRendu != null) {
          // Formatage de la date pour l'affichage dans le champ texte
          _dateRenduController.text = DateFormat('dd MMM yyyy').format(_selectedDateRendu!);
        }
      }
    }
  }

  @override
  void dispose() {
    _titreController.dispose();
    _descriptionController.dispose();
    _coursAssocieController.dispose();
    _dateRenduController.dispose();
    super.dispose();
  }

  // Sélecteur de date
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDateRendu ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(
              primary: primaryColor, // Couleur d'en-tête et de sélecteur
              onPrimary: Colors.white,
              onSurface: primaryColor, // Couleur du texte du calendrier
            ),
            dialogBackgroundColor: Colors.white,
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _selectedDateRendu = picked;
        _dateRenduController.text = DateFormat('dd MMM yyyy').format(picked);
      });
    }
  }

  // Soumission du formulaire (Ajout/Modification)
  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedDateRendu == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez sélectionner une date de rendu.'), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final int? id = widget.projet?['id'] as int?;
    String message;
    int result;

    if (id == null) {
      // AJOUTER un nouveau projet
      result = await _projetService.addProjet(
        titre: _titreController.text.trim(),
        description: _descriptionController.text.trim(),
        coursAssocie: _coursAssocieController.text.trim(),
        // Stocker la date au format ISO8601 pour la base de données
        dateRendu: _selectedDateRendu!.toIso8601String(),
      );
      message = (result > 0) ? 'Projet ajouté avec succès!' : 'Échec de l\'ajout du projet.';
    } else {
      // MODIFIER un projet existant
      result = await _projetService.updateProjet(
        id: id,
        titre: _titreController.text.trim(),
        description: _descriptionController.text.trim(),
        coursAssocie: _coursAssocieController.text.trim(),
        dateRendu: _selectedDateRendu!.toIso8601String(),
      );
      message = (result > 0) ? 'Projet mis à jour avec succès!' : 'Échec de la mise à jour du projet.';
    }

    setState(() {
      _isLoading = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: (result > 0) ? Colors.green : Colors.red,
      ),
    );

    if (result > 0) {
      // Retourner à l'écran précédent (ProjetListScreen)
      Navigator.of(context).pop();
    }
  }


  @override
  Widget build(BuildContext context) {
    final bool isEditing = widget.projet != null;
    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Modifier le Projet' : 'Ajouter un Projet',
            style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: primaryColor,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Container(
        padding: const EdgeInsets.all(16),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF6A11CB), primaryColor],
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Card(
                elevation: 8,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                margin: const EdgeInsets.all(8),
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Champ Titre
                      TextFormField(
                        controller: _titreController,
                        decoration: _inputDecoration('Titre du Projet', Icons.book),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Veuillez entrer un titre';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),

                      // Champ Cours Associé
                      TextFormField(
                        controller: _coursAssocieController,
                        decoration: _inputDecoration('Cours Associé', Icons.school),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Veuillez spécifier le cours';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),

                      // Champ Date de Rendu
                      GestureDetector(
                        onTap: _isLoading ? null : () => _selectDate(context),
                        child: AbsorbPointer(
                          child: TextFormField(
                            controller: _dateRenduController,
                            decoration: _inputDecoration('Date de Rendu', Icons.calendar_today),
                            validator: (value) {
                              if (_selectedDateRendu == null) {
                                return 'Veuillez sélectionner la date de rendu';
                              }
                              return null;
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Champ Description
                      TextFormField(
                        controller: _descriptionController,
                        maxLines: 4,
                        decoration: _inputDecoration('Description (Optionnel)', Icons.description),
                      ),
                      const SizedBox(height: 30),

                      // Bouton de soumission
                      _isLoading
                          ? const CircularProgressIndicator(color: primaryColor)
                          : ElevatedButton.icon(
                        onPressed: _submitForm,
                        icon: Icon(isEditing ? Icons.save : Icons.add, color: Colors.white),
                        label: Text(isEditing ? 'Mettre à jour le Projet' : 'Créer le Projet'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Style de décoration pour les champs de texte
  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: primaryColor),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: primaryColor),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: primaryColor.withOpacity(0.5)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: accentColor, width: 2),
      ),
    );
  }
}