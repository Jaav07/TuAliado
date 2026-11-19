path = "lib/core/providers/app_state_provider.dart"
with open(path, "r") as f:
    content = f.read()

marker = "  List<Medication> get medications => List.unmodifiable(_medications);"
addition = marker + """

  /// Carga los medicamentos guardados localmente (Hive) al iniciar la app,
  /// si existen datos persistidos previamente en este dispositivo.
  void loadPersistedMedications() {
    final saved = HiveService.loadMedications();
    if (saved.isNotEmpty) {
      _medications
        ..clear()
        ..addAll(saved);
    }
  }

  /// Guarda el estado actual de medicamentos en Hive (disco local).
  void _persistMedications() {
    HiveService.saveAllMedications(_medications);
  }"""

if marker in content and "loadPersistedMedications" not in content:
    content = content.replace(marker, addition, 1)
    with open(path, "w") as f:
        f.write(content)
    print("OK: metodos de carga/guardado agregados")
else:
    print("AVISO: no se aplico (marcador no encontrado o ya existia)")
