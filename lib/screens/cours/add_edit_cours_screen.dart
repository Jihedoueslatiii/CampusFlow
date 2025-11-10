import 'package:flutter/material.dart';
import 'package:compusflow/models/cours.dart';
import 'package:compusflow/models/departement.dart';
import 'package:compusflow/repositories/cours_repository.dart';
import 'package:compusflow/repositories/departement_repository.dart';

class AppColors {
  static const Color primary = Color(0xFFE53935);      // Vivid Red - Main brand color
  static const Color background = Color(0xFFFFFFFF);   // Pure White - Card backgrounds
  static const Color textPrimary = Color(0xFF212121);  // Dark Gray - Main text content
  static const Color backgroundSecondary = Color(0xFFF5F5F5); // Light Gray - Screen background
  static const Color textSecondary = Color(0xFF757575); // Medium Gray - Secondary text
  static const Color accent = Color(0xFF1976D2);       // Blue accent for secondary actions
  static const Color success = Color(0xFF4CAF50);      // Green for positive states
  static const Color warning = Color(0xFFFF9800);      // Orange for warnings
  static const Color surface = Color(0xFFFAFAFA);      // Surface color for cards
}

class AddEditCoursScreen extends StatefulWidget {
  final Cours? cours;

  const AddEditCoursScreen({Key? key, this.cours}) : super(key: key);

  @override
  State<AddEditCoursScreen> createState() => _AddEditCoursScreenState();
}

class _AddEditCoursScreenState extends State<AddEditCoursScreen> {
  final _formKey = GlobalKey<FormState>();
  final _coursRepository = CoursRepository();
  final _departementRepository = DepartementRepository();

  final _nomController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _creditsController = TextEditingController();

  final List<String> _semestres = [
    'Premier Semestre',
    'Deuxième Semestre',
    'Troisième Semestre',
    'Quatrième Semestre',
    'Cinquième Semestre',
    'Sixième Semestre'
  ];

  List<Departement> _departements = [];
  String _selectedSemestre = 'Premier Semestre';
  int? _selectedDepartementId;
  bool _isLoading = false;
  bool _loadingDepartements = true;

  @override
  void initState() {
    super.initState();
    _loadDepartements();
    if (widget.cours != null) {
      _nomController.text = widget.cours!.nom;
      _descriptionController.text = widget.cours!.description;
      _selectedSemestre = widget.cours!.semestre;
      _creditsController.text = widget.cours!.credits.toString();
      _selectedDepartementId = widget.cours!.departementId;
    }
  }

  Future<void> _loadDepartements() async {
    try {
      final departements = await _departementRepository.getAllDepartements();
      setState(() {
        _departements = departements;
        _loadingDepartements = false;
      });
    } catch (e) {
      setState(() {
        _loadingDepartements = false;
      });
    }
  }

  Future<void> _saveCours() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      final cours = Cours(
        id: widget.cours?.id,
        nom: _nomController.text.trim(),
        description: _descriptionController.text.trim(),
        semestre: _selectedSemestre,
        credits: int.tryParse(_creditsController.text) ?? 0,
        departementId: _selectedDepartementId,
      );

      try {
        if (widget.cours == null) {
          await _coursRepository.insertCours(cours);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('Cours créé avec succès'),
                backgroundColor: AppColors.success,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            );
          }
        } else {
          await _coursRepository.updateCours(cours);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('Cours modifié avec succès'),
                backgroundColor: AppColors.success,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            );
          }
        }

        if (mounted) {
          Navigator.pop(context);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erreur: $e'),
              backgroundColor: AppColors.primary,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  Widget _buildFormField({
    required String label,
    required IconData icon,
    required TextEditingController controller,
    required String? Function(String?) validator,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
    String? hintText,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: controller,
            decoration: InputDecoration(
              hintText: hintText,
              prefixIcon: Container(
                margin: const EdgeInsets.only(right: 12),
                child: Icon(icon, color: AppColors.textSecondary, size: 20),
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppColors.backgroundSecondary.withOpacity(0.8)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppColors.backgroundSecondary.withOpacity(0.8)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.primary, width: 2),
              ),
              filled: true,
              fillColor: AppColors.background,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            ),
            maxLines: maxLines,
            keyboardType: keyboardType,
            validator: validator,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdownField({
    required String label,
    required IconData icon,
    required List<dynamic> items,
    required dynamic value,
    required Function(dynamic) onChanged,
    required String Function(dynamic) displayText,
    bool isDepartement = false,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.backgroundSecondary.withOpacity(0.8)),
            ),
            child: DropdownButtonFormField<dynamic>(
              value: value,
              decoration: InputDecoration(
                prefixIcon: Container(
                  margin: const EdgeInsets.only(right: 12),
                  child: Icon(icon, color: AppColors.textSecondary, size: 20),
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              ),
              items: [
                if (isDepartement)
                  DropdownMenuItem<dynamic>(
                    value: null,
                    child: Text(
                      'Aucun département',
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                  ),
                ...items.map((item) {
                  return DropdownMenuItem<dynamic>(
                    value: isDepartement ? (item as Departement).id : item,
                    child: Text(
                      displayText(item),
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  );
                }).toList(),
              ],
              onChanged: onChanged,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textPrimary,
              ),
              dropdownColor: AppColors.background,
              icon: Icon(Icons.arrow_drop_down, color: AppColors.textSecondary),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundSecondary,
      appBar: AppBar(
        title: Text(
          widget.cours == null ? 'Nouveau Cours' : 'Modifier le Cours',
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            color: AppColors.background,
            fontSize: 18,
          ),
        ),
        backgroundColor: AppColors.primary,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: AppColors.background),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, size: 24),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _loadingDepartements
          ? const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: AppColors.primary),
            SizedBox(height: 16),
            Text(
              'Chargement des départements...',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ],
        ),
      )
          : SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // En-tête
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppColors.primary.withOpacity(0.1),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.school,
                        color: AppColors.primary,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.cours == null
                                ? 'Créer un nouveau cours'
                                : 'Modifier le cours',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            widget.cours == null
                                ? 'Remplissez les informations pour créer un nouveau cours'
                                : 'Mettez à jour les informations du cours existant',
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // Section informations de base
              const Text(
                'Informations de Base',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Définissez les caractéristiques principales du cours',
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),

              const SizedBox(height: 20),

              _buildFormField(
                label: 'Nom du cours *',
                icon: Icons.title,
                controller: _nomController,
                hintText: 'Ex: Algorithmes et Structures de Données',
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Le nom du cours est obligatoire';
                  }
                  if (value.length < 3) {
                    return 'Le nom doit contenir au moins 3 caractères';
                  }
                  return null;
                },
              ),

              _buildFormField(
                label: 'Description *',
                icon: Icons.description,
                controller: _descriptionController,
                hintText: 'Décrivez le contenu et les objectifs du cours...',
                maxLines: 4,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'La description est obligatoire';
                  }
                  if (value.length < 10) {
                    return 'La description doit être plus détaillée';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 8),

              // Section organisation
              const Text(
                'Organisation',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Définissez le contexte académique du cours',
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),

              const SizedBox(height: 20),

              _buildDropdownField(
                label: 'Département',
                icon: Icons.business,
                items: _departements,
                value: _selectedDepartementId,
                onChanged: (newValue) {
                  setState(() {
                    _selectedDepartementId = newValue;
                  });
                },
                displayText: (dept) => (dept as Departement).nom,
                isDepartement: true,
              ),

              _buildDropdownField(
                label: 'Semestre *',
                icon: Icons.calendar_today,
                items: _semestres,
                value: _selectedSemestre,
                onChanged: (newValue) {
                  setState(() {
                    _selectedSemestre = newValue.toString();
                  });
                },
                displayText: (semestre) => semestre.toString(),
              ),

              _buildFormField(
                label: 'Crédits *',
                icon: Icons.credit_score,
                controller: _creditsController,
                hintText: 'Ex: 3',
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Le nombre de crédits est obligatoire';
                  }
                  if (int.tryParse(value) == null) {
                    return 'Veuillez entrer un nombre valide';
                  }
                  final credits = int.parse(value);
                  if (credits <= 0 || credits > 10) {
                    return 'Les crédits doivent être entre 1 et 10';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 32),

              // Bouton de soumission
              _isLoading
                  ? SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.background,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.background,
                        ),
                      ),
                      SizedBox(width: 12),
                      Text(
                        'Enregistrement...',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              )
                  : SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: _saveCours,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.background,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    widget.cours == null ? 'Créer le Cours' : 'Modifier le Cours',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 8),

              // Bouton annuler
              if (widget.cours != null)
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.textSecondary,
                      side: BorderSide(color: AppColors.backgroundSecondary),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Annuler',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nomController.dispose();
    _descriptionController.dispose();
    _creditsController.dispose();
    super.dispose();
  }
}