import 'dart:io';
import 'package:file_picker/file_picker.dart';

class FileService {
  static Future<String?> pickAndReadFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['txt', 'pdf', 'doc', 'docx'],
        allowMultiple: false,
      );

      if (result != null && result.files.single.path != null) {
        File file = File(result.files.single.path!);
        String fileName = result.files.single.name;

        // For text files, read directly
        if (fileName.endsWith('.txt')) {
          return await file.readAsString();
        }

        // For other formats, show instruction
        if (fileName.endsWith('.pdf') || fileName.endsWith('.doc') || fileName.endsWith('.docx')) {
          return '''
FICHIER: $fileName

⚠️ CONVERSION REQUISE

Ce fichier est au format ${fileName.substring(fileName.lastIndexOf('.'))}

Pour utiliser ce fichier:
1. Convertissez-le en format TXT ou copiez le texte
2. Collez le contenu dans le champ "Contenu du Cours"

Alternatives:
- Utilisez Google Docs → Télécharger en tant que → TXT
- Utilisez LibreOffice → Enregistrer comme → TXT
- Utilisez un convertisseur en ligne (CloudConvert, Zamzar, etc.)

Après conversion, réessayez d'uploader le fichier TXT.
''';
        }

        return null;
      }
      return null;
    } catch (e) {
      throw Exception('Erreur lors de la sélection du fichier: $e');
    }
  }

  static Future<String> extractTextViaAPI(File file) async {
    // Placeholder for future API-based extraction
    throw Exception('Extraction via API non implémentée');
  }
}