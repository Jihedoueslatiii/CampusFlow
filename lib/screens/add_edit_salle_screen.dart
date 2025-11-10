import 'package:flutter/material.dart';
import '../models/salle.dart';
import '../db/database_helper.dart';

class AddEditSalleScreen extends StatefulWidget {
  final Salle? salle;
  const AddEditSalleScreen({super.key, this.salle});

  @override
  State<AddEditSalleScreen> createState() => _AddEditSalleScreenState();
}

class _AddEditSalleScreenState extends State<AddEditSalleScreen> {
  final _formKey = GlobalKey<FormState>();
  final _numeroCtrl = TextEditingController();
  final _capCtrl = TextEditingController();
  String _type = 'Cours magistral';
  final _batimentCtrl = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.salle != null) {
      _numeroCtrl.text = widget.salle!.numero;
      _capCtrl.text = widget.salle!.capacite.toString();
      _type = widget.salle!.type;
      _batimentCtrl.text = widget.salle!.batiment;
    }
  }

  @override
  void dispose() {
    _numeroCtrl.dispose();
    _capCtrl.dispose();
    _batimentCtrl.dispose();
    super.dispose();
  }

  void _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final s = Salle(
      id: widget.salle?.id,
      numero: _numeroCtrl.text.trim(),
      capacite: int.parse(_capCtrl.text.trim()),
      type: _type,
      batiment: _batimentCtrl.text.trim(),
    );

    try {
      final db = DatabaseHelper.instance;
      if (widget.salle == null) {
        await db.insertSalle(s);
      } else {
        await db.updateSalle(s);
      }
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.salle == null
                  ? '✅ Salle ajoutée avec succès!'
                  : '✅ Salle mise à jour avec succès!',
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
    final isEdit = widget.salle != null;

    return Scaffold(
      backgroundColor: Colors.grey.shade100, // Light Gray / Neutral
      appBar: AppBar(
        title: Text(
          isEdit ? 'Modifier la Salle' : 'Ajouter une Salle',
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.red.shade600, // Primary Red
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
                    color: Colors.white, // White Background
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
                          color: Colors.red.shade600, // Primary Red
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isEdit ? 'Modifier la Salle' : 'Nouvelle Salle',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey.shade900, // Dark Gray (Text)
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
                  controller: _numeroCtrl,
                  label: 'Numéro de Salle',
                  hint: 'ex: 101, A23, B-12',
                  icon: Icons.meeting_room,
                  validator: (v) => v == null || v.isEmpty ? 'Le numéro est requis' : null,
                ),
                const SizedBox(height: 20),

                _buildTextField(
                  controller: _batimentCtrl,
                  label: 'Bâtiment',
                  hint: 'ex: Bâtiment A, Bloc principal',
                  icon: Icons.apartment,
                  validator: (v) => v == null || v.isEmpty ? 'Le bâtiment est requis' : null,
                ),
                const SizedBox(height: 20),

                _buildTextField(
                  controller: _capCtrl,
                  label: 'Capacité',
                  hint: 'Nombre de places',
                  icon: Icons.people,
                  keyboardType: TextInputType.number,
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'La capacité est requise';
                    final num = int.tryParse(v);
                    if (num == null || num <= 0) {
                      return 'Entrez un nombre valide';
                    }
                    if (num > 1000) {
                      return 'Capacité trop élevée';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                _buildTypeDropdown(),
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
                          backgroundColor: Colors.white, // White Background
                        ),
                        child: Text(
                          'Annuler',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade900, // Dark Gray (Text)
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
                          backgroundColor: Colors.red.shade600, // Primary Red
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

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    required String? Function(String?) validator,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade900, // Dark Gray (Text)
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.grey.shade400),
            prefixIcon: Icon(icon, color: Colors.grey.shade600, size: 20),
            filled: true,
            fillColor: Colors.white, // White Background
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
              borderSide: BorderSide(color: Colors.red.shade600, width: 2), // Primary Red
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.red.shade600), // Primary Red
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.red.shade600, width: 2), // Primary Red
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
          'Type de Salle',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade900, // Dark Gray (Text)
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: _type,
          decoration: InputDecoration(
            prefixIcon: Icon(Icons.category, color: Colors.grey.shade600, size: 20),
            filled: true,
            fillColor: Colors.white, // White Background
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
              borderSide: BorderSide(color: Colors.red.shade600, width: 2), // Primary Red
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          ),
          items: [
            DropdownMenuItem(
              value: 'Cours magistral',
              child: Row(
                children: [
                  Icon(Icons.school, size: 20, color: Colors.blue.shade600),
                  const SizedBox(width: 12),
                  Text(
                    'Cours magistral',
                    style: TextStyle(color: Colors.grey.shade900), // Dark Gray (Text)
                  ),
                ],
              ),
            ),
            DropdownMenuItem(
              value: 'TP',
              child: Row(
                children: [
                  Icon(Icons.computer, size: 20, color: Colors.orange.shade600),
                  const SizedBox(width: 12),
                  Text(
                    'TP - Travaux Pratiques',
                    style: TextStyle(color: Colors.grey.shade900), // Dark Gray (Text)
                  ),
                ],
              ),
            ),
            DropdownMenuItem(
              value: 'TD',
              child: Row(
                children: [
                  Icon(Icons.groups, size: 20, color: Colors.green.shade600),
                  const SizedBox(width: 12),
                  Text(
                    'TD - Travaux Dirigés',
                    style: TextStyle(color: Colors.grey.shade900), // Dark Gray (Text)
                  ),
                ],
              ),
            ),
          ],
          onChanged: (v) => setState(() => _type = v!),
          dropdownColor: Colors.white, // White Background
          style: TextStyle(
            color: Colors.grey.shade900, // Dark Gray (Text)
            fontSize: 16,
          ),
        ),
      ],
    );
  }
}