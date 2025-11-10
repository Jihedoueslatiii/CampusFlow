import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../services/file_service.dart';

class CoursAIScreen extends StatefulWidget {
  @override
  _CoursAIScreenState createState() => _CoursAIScreenState();
}

class _CoursAIScreenState extends State<CoursAIScreen> {
  String? _fileName;
  String _extractedText = '';

  // Choisir un PDF
  Future<void> _pickPDF() async {
    FilePickerResult? result = await FileService.pickPDF();

    if (result != null) {
      setState(() {
        _fileName = result.files.single.name;
      });

      // Simuler l'extraction du texte
      _simulateTextExtraction();

      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('PDF $_fileName chargé avec succès!'))
      );
    }
  }

  void _simulateTextExtraction() {
    // Simulation - remplacer par vraie extraction
    setState(() {
      _extractedText = '''
Cours d'Arabe - Niveau Débutant

Chapitre 1: L'alphabet arabe
L'alphabet arabe comporte 28 lettres écrites de droite à gauche...
      ''';
    });
  }

  // Générer résumé
  void _generateResume() {
    if (_extractedText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Veuillez d\'abord charger un PDF'))
      );
      return;
    }

    // Appeler ton service IA ici
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Résumé Généré'),
        content: Text('📋 Résumé du cours...'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Assistant IA - Cours Arabe'),
        backgroundColor: Colors.green,
      ),
      body: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          children: [
            // Bouton Upload PDF
            ElevatedButton.icon(
              onPressed: _pickPDF,
              icon: Icon(Icons.upload_file),
              label: Text('📁 Choisir un PDF'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                minimumSize: Size(double.infinity, 50),
              ),
            ),
            SizedBox(height: 20),

            // Statut fichier
            Text(
              _fileName ?? 'Aucun fichier sélectionné',
              style: TextStyle(
                color: _fileName != null ? Colors.green : Colors.grey,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 30),

            // Boutons fonctionnalités IA
            Expanded(
              child: ListView(
                children: [
                  _buildFunctionButton(
                    '📝 Générer Résumé',
                    Colors.green,
                    _generateResume,
                  ),
                  _buildFunctionButton(
                    '✏️ Générer Exercices',
                    Colors.orange,
                        () {},
                  ),
                  _buildFunctionButton(
                    '❓ Générer Quiz',
                    Colors.purple,
                        () {},
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFunctionButton(String text, Color color, VoidCallback onPressed) {
    return Container(
      margin: EdgeInsets.only(bottom: 15),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          minimumSize: Size(double.infinity, 60),
        ),
        child: Text(
          text,
          style: TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}