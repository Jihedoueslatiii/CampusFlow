import 'package:flutter/material.dart';
import '../../services/emploi_temps_service.dart';
import '../../services/auth_service.dart';
import '../../models/emploi_temps_model.dart';

class ConsulterEmploiScreen extends StatefulWidget {
  final String userRole;
  final int userId;

  const ConsulterEmploiScreen({
    Key? key,
    required this.userRole,
    required this.userId,
  }) : super(key: key);

  @override
  _ConsulterEmploiScreenState createState() => _ConsulterEmploiScreenState();
}

class _ConsulterEmploiScreenState extends State<ConsulterEmploiScreen> {
  final EmploiTempsService _emploiService = EmploiTempsService();
  final AuthService _authService = AuthService();

  List<EmploiTemps> _emploiDuTemps = [];
  bool _isLoading = true;
  String _errorMessage = '';

  // Color constants based on the palette
  static const Color primaryAccent = Color(0xFFE53935);
  static const Color background = Color(0xFFFFFFFF);
  static const Color textPrimary = Color(0xFF212121);
  static const Color backgroundSecondary = Color(0xFFF5F5F5);

  @override
  void initState() {
    super.initState();
    _chargerEmploiDuTemps();
  }

  Future<void> _chargerEmploiDuTemps() async {
    try {
      List<EmploiTemps> emplois;

      if (widget.userRole == 'etudiant') {
        emplois = await _emploiService.getEmploiTempsEtudiant(widget.userId);
      } else if (widget.userRole == 'professeur') {
        emplois = await _emploiService.getEmploiTempsProfesseur(widget.userId);
      } else {
        throw Exception('Rôle non supporté');
      }

      setState(() {
        _emploiDuTemps = emplois;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString();
      });
    }
  }

  Widget _buildCoursCard(EmploiTemps cours) {
    return Card(
      elevation: 2,
      margin: EdgeInsets.symmetric(vertical: 4),
      color: background,
      child: ListTile(
        leading: Container(
          width: 4,
          color: _getCouleurMatiere(cours.matiereNom),
        ),
        title: Text(
          cours.matiereNom,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: textPrimary,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${cours.heureDebut.format(context)} - ${cours.heureFin.format(context)}',
              style: TextStyle(color: textPrimary.withOpacity(0.7)),
            ),
            Text(
              'Salle: ${cours.salle}',
              style: TextStyle(color: textPrimary.withOpacity(0.7)),
            ),
            if (widget.userRole == 'etudiant')
              Text(
                'Prof: ${cours.professeurNom}',
                style: TextStyle(color: textPrimary.withOpacity(0.7)),
              ),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              cours.duree,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: primaryAccent,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getCouleurMatiere(String matiere) {
    final colors = [
      primaryAccent,
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.teal,
      Colors.pink,
      Colors.indigo,
      Colors.amber,
      Colors.cyan
    ];
    return colors[matiere.hashCode % colors.length];
  }

  Map<String, List<EmploiTemps>> _grouperParJour(List<EmploiTemps> emplois) {
    final Map<String, List<EmploiTemps>> grouped = {};

    for (final cours in emplois) {
      if (!grouped.containsKey(cours.jour)) {
        grouped[cours.jour] = [];
      }
      grouped[cours.jour]!.add(cours);
    }

    // Trier les cours par heure
    for (final jour in grouped.keys) {
      grouped[jour]!.sort((a, b) {
        final aMinutes = a.heureDebut.hour * 60 + a.heureDebut.minute;
        final bMinutes = b.heureDebut.hour * 60 + b.heureDebut.minute;
        return aMinutes.compareTo(bMinutes);
      });
    }

    return grouped;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundSecondary,
      appBar: AppBar(
        title: Text(
          'Mon Emploi du Temps',
          style: TextStyle(color: background),
        ),
        backgroundColor: primaryAccent,
        foregroundColor: background,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _isLoading ? null : _chargerEmploiDuTemps,
            tooltip: 'Actualiser',
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(primaryAccent)))
          : _errorMessage.isNotEmpty
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: textPrimary.withOpacity(0.5)),
            SizedBox(height: 16),
            Text(
              'Aucun emploi du temps disponible',
              style: TextStyle(fontSize: 18, color: textPrimary.withOpacity(0.7)),
            ),
            SizedBox(height: 8),
            Text(
              _errorMessage,
              style: TextStyle(color: textPrimary.withOpacity(0.6)),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: _chargerEmploiDuTemps,
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryAccent,
                foregroundColor: background,
              ),
              child: Text('Réessayer'),
            ),
          ],
        ),
      )
          : _emploiDuTemps.isEmpty
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.schedule, size: 64, color: textPrimary.withOpacity(0.5)),
            SizedBox(height: 16),
            Text(
              'Aucun cours cette semaine',
              style: TextStyle(fontSize: 18, color: textPrimary.withOpacity(0.7)),
            ),
            SizedBox(height: 8),
            Text(
              'Votre emploi du temps sera disponible prochainement',
              style: TextStyle(color: textPrimary.withOpacity(0.6)),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      )
          : RefreshIndicator(
        onRefresh: _chargerEmploiDuTemps,
        backgroundColor: background,
        color: primaryAccent,
        child: ListView(
          padding: EdgeInsets.all(16),
          children: _buildEmploiParJour(),
        ),
      ),
    );
  }

  List<Widget> _buildEmploiParJour() {
    final grouped = _grouperParJour(_emploiDuTemps);
    final joursOrdre = ['Lundi', 'Mardi', 'Mercredi', 'Jeudi', 'Vendredi'];
    final widgets = <Widget>[];

    for (final jour in joursOrdre) {
      if (grouped.containsKey(jour)) {
        widgets.addAll([
          SizedBox(height: 16),
          Text(
            jour,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: primaryAccent,
            ),
          ),
          SizedBox(height: 8),
          ...grouped[jour]!.map(_buildCoursCard).toList(),
        ]);
      }
    }

    return widgets;
  }
}