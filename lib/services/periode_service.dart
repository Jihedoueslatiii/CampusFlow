// lib/services/periode_service.dart
import 'package:shared_preferences/shared_preferences.dart';

class PeriodeService {
  static const String _keyPeriodeDebut = 'periode_debut';
  static const String _keyPeriodeFin = 'periode_fin';

  // Définir les périodes de modification
  Future<void> definirPeriodesModification() async {
    final prefs = await SharedPreferences.getInstance();

    // Période 1: 1-15 Septembre
    final debut1 = DateTime(DateTime.now().year, 9, 1);
    final fin1 = DateTime(DateTime.now().year, 9, 15);

    // Période 2: 1-15 Janvier
    final debut2 = DateTime(DateTime.now().year, 1, 1);
    final fin2 = DateTime(DateTime.now().year, 1, 15);

    await prefs.setString(_keyPeriodeDebut, debut1.toIso8601String());
    await prefs.setString(_keyPeriodeFin, fin1.toIso8601String());
  }

  // Vérifier si on est en période de modification
  Future<bool> estPeriodeModificationActive() async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();

    // Période 1: Septembre
    if (now.month == 9 && now.day >= 1 && now.day <= 15) {
      return true;
    }

    // Période 2: Janvier
    if (now.month == 1 && now.day >= 1 && now.day <= 15) {
      return true;
    }

    return false;
  }

  // Prochaine période de modification
  String getProchainePeriode() {
    final now = DateTime.now();

    if (now.month < 9) {
      return '1-15 Septembre ${now.year}';
    } else {
      return '1-15 Janvier ${now.year + 1}';
    }
  }
}