path = "lib/core/providers/app_state_provider.dart"
with open(path, "r") as f:
    content = f.read()

marker = """  void loadPersistedMedications() {
    final saved = HiveService.loadMedications();
    if (saved.isNotEmpty) {
      _medications
        ..clear()
        ..addAll(saved);
    }
  }"""

addition = marker + """

  /// Carga los examenes de laboratorio guardados localmente (Hive) al iniciar la app.
  void loadPersistedLabExams() {
    final saved = HiveService.loadLabExams();
    if (saved.isNotEmpty) {
      _labExams
        ..clear()
        ..addAll(saved);
    }
  }"""

if marker in content and "loadPersistedLabExams" not in content:
    content = content.replace(marker, addition, 1)
    with open(path, "w") as f:
        f.write(content)
    print("OK: loadPersistedLabExams agregado")
else:
    print("AVISO: no aplicado")
