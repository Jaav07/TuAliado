path = "lib/core/providers/app_state_provider.dart"
with open(path, "r") as f:
    content = f.read()

old_import = "import '../services/supabase_service.dart';"
new_import = """import '../services/supabase_service.dart';
import '../services/gemini_vision_service.dart';"""

if new_import not in content:
    content = content.replace(old_import, new_import, 1)
    print("OK: import agregado")
else:
    print("Import ya presente")

old_method = """  void addMedication(Medication med) {
    _medications.insert(0, med);
    notifyListeners();
  }"""

new_method = """  void addMedication(Medication med) {
    _medications.insert(0, med);
    notifyListeners();
  }

  /// Fusiona una lista de medicamentos detectados por la IA con los ya
  /// existentes: si un medicamento con el mismo nombre ya existe, actualiza
  /// su dosis/proposito/fecha; si no existe, lo agrega como nuevo.
  void mergeMedicationsFromCapture(
    List<MedicationExtract> extracted, {
    String? orderedBy,
  }) {
    for (final item in extracted) {
      final existingIndex = _medications.indexWhere(
        (m) => m.name.toLowerCase().trim() == item.name.toLowerCase().trim(),
      );
      if (existingIndex != -1) {
        final existing = _medications[existingIndex];
        _medications[existingIndex] = existing.copyWith(
          dosage: item.dosage ?? existing.dosage,
          purpose: item.purpose ?? existing.purpose,
          orderedBy: orderedBy ?? existing.orderedBy,
          lastUpdated: DateTime.now(),
          status: 'active',
        );
      } else {
        _medications.insert(
          0,
          Medication(
            id: DateTime.now().millisecondsSinceEpoch + _medications.length,
            name: item.name,
            dosage: item.dosage != null && item.dosage!.trim().isNotEmpty
                ? item.dosage!.trim()
                : (item.frequency ?? 'Dosis no detectada, verificar con tu medico'),
            stockDays: 30,
            deliveryDate: '30 dias',
            status: 'active',
            purpose: item.purpose,
            orderedBy: orderedBy,
            lastUpdated: DateTime.now(),
          ),
        );
      }
    }
    notifyListeners();
  }"""

if old_method not in content:
    print("AVISO: no se encontro addMedication original")
else:
    content = content.replace(old_method, new_method, 1)
    print("OK: mergeMedicationsFromCapture agregado")

with open(path, "w") as f:
    f.write(content)
print("Guardado")
