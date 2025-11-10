import 'package:flutter/material.dart';
import 'package:compusflow/models/departement.dart';
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

class AddEditDepartementScreen extends StatefulWidget {
  final Departement? departement;

  const AddEditDepartementScreen({Key? key, this.departement}) : super(key: key);

  @override
  State<AddEditDepartementScreen> createState() => _AddEditDepartementScreenState();
}

class _AddEditDepartementScreenState extends State<AddEditDepartementScreen> {
  final _formKey = GlobalKey<FormState>();
  final _departementRepository = DepartementRepository();

  final _nomController = TextEditingController();
  final _chefController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.departement != null) {
      _nomController.text = widget.departement!.nom;
      _chefController.text = widget.departement!.chefDepartement;
    }
  }

  Future<void> _saveDepartement() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      final departement = Departement(
        id: widget.departement?.id,
        nom: _nomController.text.trim(),
        chefDepartement: _chefController.text.trim(),
      );

      try {
        if (widget.departement == null) {
          await _departementRepository.insertDepartement(departement);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('Département créé avec succès'),
                backgroundColor: AppColors.success,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            );
          }
        } else {
          await _departementRepository.updateDepartement(departement);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('Département modifié avec succès'),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundSecondary,
      appBar: AppBar(
        title: Text(
          widget.departement == null ? 'Nouveau Département' : 'Modifier le Département',
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
      body: SingleChildScrollView(
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
                        Icons.business,
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
                            widget.departement == null
                                ? 'Créer un nouveau département'
                                : 'Modifier le département',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            widget.departement == null
                                ? 'Remplissez les informations pour créer un nouveau département'
                                : 'Mettez à jour les informations du département existant',
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

              // Section informations
              const Text(
                'Informations du Département',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Définissez les caractéristiques principales du département',
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),

              const SizedBox(height: 20),

              // Champ Nom du département
              _buildFormField(
                label: 'Nom du département *',
                icon: Icons.business,
                controller: _nomController,
                hintText: 'Ex: Informatique, Mathématiques, Physique...',
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Le nom du département est obligatoire';
                  }
                  if (value.length < 3) {
                    return 'Le nom doit contenir au moins 3 caractères';
                  }
                  return null;
                },
              ),

              // Champ Chef de département
              _buildFormField(
                label: 'Chef de département *',
                icon: Icons.person,
                controller: _chefController,
                hintText: 'Ex: Dr. Jean Dupont, Prof. Marie Martin...',
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Le nom du chef de département est obligatoire';
                  }
                  if (value.length < 3) {
                    return 'Le nom doit contenir au moins 3 caractères';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 32),

              // Informations supplémentaires
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.accent.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.accent.withOpacity(0.1),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: AppColors.accent,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Les départements vous permettent d\'organiser vos cours par domaine d\'étude.',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
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
                  onPressed: _saveDepartement,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.background,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    widget.departement == null ? 'Créer le Département' : 'Modifier le Département',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 8),

              // Bouton annuler
              if (widget.departement != null)
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
    _chefController.dispose();
    super.dispose();
  }
}