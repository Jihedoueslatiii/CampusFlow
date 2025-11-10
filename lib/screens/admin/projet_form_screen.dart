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

  // Nouvelles couleurs selon la charte
  static const Color primaryColor = Color(0xFFF53935); // Vivid Red
  static const Color backgroundColor = Color(0xFFF5F5F5); // Light Gray
  static const Color cardBackgroundColor = Color(0xFFFFFFFF); // Pure White
  static const Color primaryTextColor = Color(0xFF212121); // Dark Gray

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
              onPrimary: cardBackgroundColor,
              onSurface: primaryTextColor, // Couleur du texte du calendrier
            ),
            dialogBackgroundColor: cardBackgroundColor,
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
        SnackBar(
          content: const Text('Veuillez sélectionner une date de rendu.'),
          backgroundColor: primaryColor,
        ),
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
        backgroundColor: primaryColor,
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
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: Text(
          isEditing ? 'Modifier le Projet' : 'Ajouter un Projet',
          style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: cardBackgroundColor
          ),
        ),
        backgroundColor: primaryColor,
        iconTheme: const IconThemeData(color: cardBackgroundColor),
      ),
      body: Container(
        padding: const EdgeInsets.all(16),
        color: backgroundColor,
        child: Center(
          child: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Card(
                elevation: 8,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                margin: const EdgeInsets.all(8),
                color: cardBackgroundColor,
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Champ Titre
                      TextFormField(
                        controller: _titreController,
                        style: TextStyle(color: primaryTextColor),
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
                        style: TextStyle(color: primaryTextColor),
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
                            style: TextStyle(color: primaryTextColor),
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
                        style: TextStyle(color: primaryTextColor),
                        maxLines: 4,
                        decoration: _inputDecoration('Description (Optionnel)', Icons.description),
                      ),
                      const SizedBox(height: 30),

                      // Bouton de soumission
                      _isLoading
                          ? CircularProgressIndicator(color: primaryColor)
                          : ElevatedButton.icon(
                        onPressed: _submitForm,
                        icon: Icon(
                            isEditing ? Icons.save : Icons.add,
                            color: cardBackgroundColor
                        ),
                        label: Text(
                          isEditing ? 'Mettre à jour le Projet' : 'Créer le Projet',
                          style: TextStyle(color: cardBackgroundColor),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          textStyle: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                          elevation: 3,
                          shadowColor: primaryColor.withOpacity(0.3),
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
      labelStyle: TextStyle(color: primaryTextColor.withOpacity(0.7)),
      prefixIcon: Icon(icon, color: primaryColor),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: primaryTextColor.withOpacity(0.3)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: primaryTextColor.withOpacity(0.3)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: primaryColor, width: 2),
      ),
      filled: true,
      fillColor: cardBackgroundColor,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    );
  }
}