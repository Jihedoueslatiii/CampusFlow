import 'package:flutter/material.dart';
import '../../services/emploi_temps_service.dart';
import '../../services/matiere_service.dart';
import '../../services/auth_service.dart';
import '../../models/matiere_model.dart';

class GenererEmploiScreen extends StatefulWidget {
  const GenererEmploiScreen({Key? key}) : super(key: key);

  @override
  _GenererEmploiScreenState createState() => _GenererEmploiScreenState();
}

class _GenererEmploiScreenState extends State<GenererEmploiScreen> {
  final EmploiTempsService _emploiService = EmploiTempsService();
  final MatiereService _matiereService = MatiereService();
  final AuthService _authService = AuthService();

  List<Matiere> _toutesMatieres = [];
  Map<int, Map<String, dynamic>> _professeursMatieres = {};
  bool _isLoading = true;
  bool _isGenerating = false;
  String _message = '';

  // Color palette
  static const Color primaryAccent = Color(0xFFE53935); // Vivid Red
  static const Color background = Color(0xFFFFFFFF); // Pure White
  static const Color textPrimary = Color(0xFF212121); // Dark Gray
  static const Color backgroundSecondary = Color(0xFFF5F5F5); // Light Gray

  @override
  void initState() {
    super.initState();
    _chargerDonnees();
  }

  Future<void> _chargerDonnees() async {
    try {
      final matieres = await _matiereService.getMatieres();
      final users = await _authService.getAllUsers();

      // Filtrer les professeurs
      final professeurs = users.where((user) => user['role'] == 'professeur').toList();

      // Assigner aléatoirement les matières aux professeurs
      final Map<int, Map<String, dynamic>> affectations = {};
      final matieresMelangees = List.from(matieres)..shuffle();

      for (int i = 0; i < matieresMelangees.length; i++) {
        final matiere = matieresMelangees[i];
        final professeur = professeurs[i % professeurs.length];

        affectations[matiere.id!] = {
          'matiereId': matiere.id,
          'matiereNom': matiere.nom,
          'profId': professeur['id'],
          'profNom': professeur['name'],
        };
      }

      setState(() {
        _toutesMatieres = matieres;
        _professeursMatieres = affectations;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _message = 'Erreur: $e';
      });
    }
  }

  Future<void> _genererEmploiDuTemps() async {
    setState(() {
      _isGenerating = true;
      _message = 'Génération en cours...';
    });

    try {
      // Convertir les affectations en liste
      final matieresAvecProfs = _professeursMatieres.values.toList();

      await _emploiService.genererEmploiTempsIA(matieresAvecProfs);

      setState(() {
        _message = '✅ Emploi du temps généré avec succès !';
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Emploi du temps de la semaine généré'),
          backgroundColor: primaryAccent,
        ),
      );
    } catch (e) {
      setState(() {
        _message = '❌ Erreur: $e';
      });
    }

    setState(() {
      _isGenerating = false;
    });
  }

  Widget _buildMatiereCard(Matiere matiere) {
    final affectation = _professeursMatieres[matiere.id!];

    return Card(
      color: background,
      margin: EdgeInsets.symmetric(vertical: 4),
      elevation: 2,
      child: ListTile(
        leading: Icon(Icons.school, color: primaryAccent),
        title: Text(
          matiere.nom,
          style: TextStyle(color: textPrimary, fontWeight: FontWeight.w500),
        ),
        subtitle: Text(
          affectation != null
              ? 'Prof: ${affectation['profNom']}'
              : 'Non affectée',
          style: TextStyle(color: textPrimary.withOpacity(0.7)),
        ),
        trailing: affectation != null
            ? Icon(Icons.check_circle, color: primaryAccent)
            : Icon(Icons.error, color: Colors.orange),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundSecondary,
      appBar: AppBar(
        title: Text(
          'Générer Emploi du Temps',
          style: TextStyle(color: background, fontWeight: FontWeight.bold),
        ),
        backgroundColor: primaryAccent,
        elevation: 0,
        iconTheme: IconThemeData(color: background),
      ),
      body: _isLoading
          ? Center(
        child: CircularProgressIndicator(
          color: primaryAccent,
        ),
      )
          : Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // En-tête
            Text(
              'Génération automatique de l\'emploi du temps',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: textPrimary,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'L\'IA va générer un emploi du temps optimal pour la semaine',
              style: TextStyle(color: textPrimary.withOpacity(0.7)),
            ),

            SizedBox(height: 20),

            // Bouton de génération
            Container(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isGenerating ? null : _genererEmploiDuTemps,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryAccent,
                  foregroundColor: background,
                  padding: EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: _isGenerating
                    ? SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    color: background,
                    strokeWidth: 2,
                  ),
                )
                    : Icon(Icons.auto_awesome),
                label: Text(
                  _isGenerating ? 'Génération...' : 'Générer l\'emploi du temps',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            ),

            SizedBox(height: 16),

            // Message
            if (_message.isNotEmpty)
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _message.contains('✅')
                      ? primaryAccent.withOpacity(0.1)
                      : Colors.red[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: _message.contains('✅')
                        ? primaryAccent
                        : Colors.red,
                  ),
                ),
                child: Text(
                  _message,
                  style: TextStyle(
                    color: _message.contains('✅')
                        ? primaryAccent
                        : Colors.red[800],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),

            SizedBox(height: 20),

            // Liste des matières affectées
            Text(
              'Affectations des matières',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: textPrimary,
              ),
            ),
            SizedBox(height: 8),
            Text(
              '${_professeursMatieres.length}/${_toutesMatieres.length} matières affectées',
              style: TextStyle(color: textPrimary.withOpacity(0.7)),
            ),

            SizedBox(height: 12),

            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: background,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListView.builder(
                  itemCount: _toutesMatieres.length,
                  itemBuilder: (context, index) {
                    return _buildMatiereCard(_toutesMatieres[index]);
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}