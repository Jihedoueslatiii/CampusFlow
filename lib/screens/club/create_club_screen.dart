// lib/screens/club/create_club_screen.dart

import 'package:flutter/material.dart';
import '../../services/club_service.dart';
import '../../models/club_model.dart';
import '../../models/club_member_model.dart';

class CreateClubScreen extends StatefulWidget {
  final int userId;

  const CreateClubScreen({Key? key, required this.userId}) : super(key: key);

  @override
  _CreateClubScreenState createState() => _CreateClubScreenState();
}

class _CreateClubScreenState extends State<CreateClubScreen> {
  final _formKey = GlobalKey<FormState>();
  final _clubService = ClubService();

  String _nom = '';
  String _type = 'sport';
  String _description = '';

  // Color palette
  static const Color primaryAccent = Color(0xFFE53935); // Vivid Red
  static const Color background = Color(0xFFFFFFFF); // Pure White
  static const Color textPrimary = Color(0xFF212121); // Dark Gray
  static const Color backgroundSecondary = Color(0xFFF5F5F5); // Light Gray

  // SUPPRIMER les appels createClubTable et createClubMemberTable
  // car les tables sont déjà créées dans DatabaseService

  Future<void> _createClub() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      final newClub = Club(
        nom: _nom,
        type: _type,
        responsableId: widget.userId,
        description: _description,
        status: 'pending', // En attente d'approbation admin
        dateCreation: DateTime.now(),
      );

      try {
        final clubId = await _clubService.createClub(newClub);

        // Ajouter le créateur comme responsable
        final clubMember = ClubMember(
          clubId: clubId,
          userId: widget.userId,
          role: 'responsable',
          status: 'approved',
          dateAdhesion: DateTime.now(),
          canApproveResponsables: true,
        );

        await _clubService.addClubMember(clubMember);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Club créé avec succès! En attente d\'approbation.'),
            backgroundColor: primaryAccent,
          ),
        );

        Navigator.pop(context, true); // Retour avec succès
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
          'Créer un Club',
          style: TextStyle(color: background, fontWeight: FontWeight.bold),
        ),
        backgroundColor: primaryAccent,
        elevation: 0,
        iconTheme: IconThemeData(color: background),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Card(
                color: background,
                elevation: 2,
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    'Créez votre club et devenez son responsable',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: textPrimary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
              SizedBox(height: 20),
              TextFormField(
                decoration: InputDecoration(
                  labelText: 'Nom du club',
                  labelStyle: TextStyle(color: textPrimary),
                  border: OutlineInputBorder(),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: primaryAccent),
                  ),
                  prefixIcon: Icon(Icons.group, color: primaryAccent),
                  filled: true,
                  fillColor: background,
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Veuillez entrer un nom';
                  }
                  if (value.length < 3) {
                    return 'Le nom doit contenir au moins 3 caractères';
                  }
                  return null;
                },
                onSaved: (value) => _nom = value!,
              ),
              SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _type,
                decoration: InputDecoration(
                  labelText: 'Type de club',
                  labelStyle: TextStyle(color: textPrimary),
                  border: OutlineInputBorder(),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: primaryAccent),
                  ),
                  prefixIcon: Icon(Icons.category, color: primaryAccent),
                  filled: true,
                  fillColor: background,
                ),
                dropdownColor: background,
                items: [
                  DropdownMenuItem(
                    value: 'sport',
                    child: Text(
                      '🏆 Sport',
                      style: TextStyle(color: textPrimary),
                    ),
                  ),
                  DropdownMenuItem(
                    value: 'culturel',
                    child: Text(
                      '🎭 Culturel',
                      style: TextStyle(color: textPrimary),
                    ),
                  ),
                ],
                onChanged: (value) => setState(() => _type = value!),
              ),
              SizedBox(height: 16),
              TextFormField(
                decoration: InputDecoration(
                  labelText: 'Description (optionnelle)',
                  labelStyle: TextStyle(color: textPrimary),
                  border: OutlineInputBorder(),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: primaryAccent),
                  ),
                  alignLabelWithHint: true,
                  filled: true,
                  fillColor: background,
                ),
                maxLines: 3,
                onSaved: (value) => _description = value ?? '',
              ),
              SizedBox(height: 30),
              Container(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _createClub,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryAccent,
                    foregroundColor: background,
                    padding: EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Créer le Club',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              SizedBox(height: 10),
              Card(
                color: primaryAccent.withOpacity(0.1),
                child: Padding(
                  padding: EdgeInsets.all(12),
                  child: Text(
                    'Note: Votre club sera soumis à l\'approbation d\'un administrateur avant d\'être visible par les autres étudiants.',
                    style: TextStyle(
                      fontSize: 12,
                      color: textPrimary.withOpacity(0.7),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}