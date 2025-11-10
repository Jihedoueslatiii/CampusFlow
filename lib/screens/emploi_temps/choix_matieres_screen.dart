import 'package:flutter/material.dart';
import '../../services/matiere_service.dart';
import '../../services/auth_service.dart';
import '../../services/periode_service.dart'; // NOUVEAU
import '../../models/matiere_model.dart';

class ChoixMatieresScreen extends StatefulWidget {
  final int userId;

  const ChoixMatieresScreen({Key? key, required this.userId}) : super(key: key);

  @override
  _ChoixMatieresScreenState createState() => _ChoixMatieresScreenState();
}

class _ChoixMatieresScreenState extends State<ChoixMatieresScreen> {
  final MatiereService _matiereService = MatiereService();
  final AuthService _authService = AuthService();
  final PeriodeService _periodeService = PeriodeService(); // NOUVEAU

  List<Matiere> _toutesMatieres = [];
  List<int> _matieresSelectionnees = [];
  bool _isLoading = true;
  bool _isSaving = false;
  bool _periodeActive = true; // NOUVEAU

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
      // Vérifier la période
      _periodeActive = await _periodeService.estPeriodeModificationActive();

      final matieres = await _matiereService.getMatieres();
      setState(() {
        _toutesMatieres = matieres;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showError('Erreur: $e');
    }
  }

  Future<void> _sauvegarderChoix() async {
    if (_matieresSelectionnees.isEmpty) {
      _showError('Veuillez sélectionner au moins une matière');
      return;
    }

    setState(() { _isSaving = true; });

    try {
      await _matiereService.inscrireEtudiantMatieres(
          widget.userId,
          _matieresSelectionnees
      );

      _showSuccess('Matières enregistrées avec succès !');
      Navigator.pop(context, true);
    } catch (e) {
      _showError('Erreur: $e');
    }

    setState(() { _isSaving = false; });
  }

  void _toggleMatiere(int matiereId) {
    if (!_periodeActive) return; // BLOQUÉ si période inactive

    setState(() {
      if (_matieresSelectionnees.contains(matiereId)) {
        _matieresSelectionnees.remove(matiereId);
      } else {
        _matieresSelectionnees.add(matiereId);
      }
    });
  }

  // NOUVEAU: Ouvrir formulaire d'urgence
  void _ouvrirFormulaireUrgence() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: background,
        title: Text(
          'Modification Exceptionnelle',
          style: TextStyle(color: textPrimary),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'La période normale de modification est terminée.\n',
              style: TextStyle(fontWeight: FontWeight.bold, color: textPrimary),
            ),
            Text(
              'Prochaine période: ${_periodeService.getProchainePeriode()}',
              style: TextStyle(color: textPrimary),
            ),
            SizedBox(height: 16),
            Text(
              'Pour une modification urgente, veuillez:',
              style: TextStyle(color: textPrimary),
            ),
            SizedBox(height: 8),
            Text(
              '1. Remplir le formulaire de demande',
              style: TextStyle(color: textPrimary),
            ),
            Text(
              '2. Fournir une justification valable',
              style: TextStyle(color: textPrimary),
            ),
            Text(
              '3. Attendre la validation administrative',
              style: TextStyle(color: textPrimary),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Annuler',
              style: TextStyle(color: textPrimary),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _contacterAdministration();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryAccent,
              foregroundColor: background,
            ),
            child: Text('Formulaire de demande'),
          ),
        ],
      ),
    );
  }

  void _contacterAdministration() {
    // Ici tu peux ouvrir un email, un formulaire, etc.
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: background,
        title: Text(
          'Contact Administration',
          style: TextStyle(color: textPrimary),
        ),
        content: Text(
          'Veuillez envoyer un email à: admin@campus.edu\n'
              'avec pour objet: "Modification matières - URGENT"\n\n'
              'Merci de joindre votre justification.',
          style: TextStyle(color: textPrimary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Fermer',
              style: TextStyle(color: textPrimary),
            ),
          ),
        ],
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: primaryAccent,
      ),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: primaryAccent,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundSecondary,
      appBar: AppBar(
        title: Text(
          _periodeActive ? 'Choisir mes matières' : 'Mes matières',
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
            // MESSAGE DE PÉRIODE
            if (!_periodeActive)
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: primaryAccent.withOpacity(0.1),
                  border: Border.all(color: primaryAccent),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.warning, color: primaryAccent),
                        SizedBox(width: 8),
                        Text(
                          'Période de modification terminée',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: primaryAccent,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Prochaine période: ${_periodeService.getProchainePeriode()}',
                      style: TextStyle(color: textPrimary.withOpacity(0.7)),
                    ),
                  ],
                ),
              ),

            SizedBox(height: 16),

            Text(
              _periodeActive
                  ? 'Sélectionnez vos matières'
                  : 'Mes matières actuelles',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: textPrimary,
              ),
            ),

            SizedBox(height: 8),

            Text(
              _periodeActive
                  ? 'Choisissez les matières que vous souhaitez suivre cette année'
                  : 'Consultation seule - période de modification terminée',
              style: TextStyle(color: textPrimary.withOpacity(0.7)),
            ),

            SizedBox(height: 20),

            // LISTE DES MATIÈRES
            Expanded(
              child: ListView.builder(
                itemCount: _toutesMatieres.length,
                itemBuilder: (context, index) {
                  final matiere = _toutesMatieres[index];
                  final isSelected = _matieresSelectionnees.contains(matiere.id);

                  return Card(
                    color: background,
                    margin: EdgeInsets.symmetric(vertical: 4),
                    elevation: 1,
                    child: ListTile(
                      leading: _periodeActive
                          ? Checkbox(
                        value: isSelected,
                        onChanged: (value) => _toggleMatiere(matiere.id!),
                        activeColor: primaryAccent,
                      )
                          : Icon(
                        isSelected ? Icons.check_circle : Icons.circle_outlined,
                        color: isSelected ? primaryAccent : textPrimary.withOpacity(0.3),
                      ),
                      title: Text(
                        matiere.nom,
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          color: textPrimary,
                        ),
                      ),
                      subtitle: Text(
                        matiere.description,
                        style: TextStyle(color: textPrimary.withOpacity(0.7)),
                      ),
                      onTap: _periodeActive
                          ? () => _toggleMatiere(matiere.id!)
                          : null, // DÉSACTIVÉ
                    ),
                  );
                },
              ),
            ),

            // BOUTON CONDITIONNEL
            Container(
              width: double.infinity,
              child: _periodeActive
                  ? ElevatedButton(
                onPressed: _isSaving ? null : _sauvegarderChoix,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryAccent,
                  foregroundColor: background,
                  padding: EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isSaving
                    ? SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    color: background,
                    strokeWidth: 2,
                  ),
                )
                    : Text(
                  'Enregistrer (${_matieresSelectionnees.length})',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              )
                  : OutlinedButton(
                onPressed: _ouvrirFormulaireUrgence,
                style: OutlinedButton.styleFrom(
                  foregroundColor: primaryAccent,
                  side: BorderSide(color: primaryAccent),
                  padding: EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text('Demande Exceptionnelle'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}