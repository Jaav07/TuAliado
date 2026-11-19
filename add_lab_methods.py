path = "lib/core/services/hive_service.dart"
with open(path, "r") as f:
    content = f.read()

last_brace = content.rfind("}")
addition = """
  static List<LabExam> loadLabExams() {
    final box = _labExamsBox;
    if (box == null) return [];
    return box.values
        .map((raw) => LabExam.fromMap(Map<dynamic, dynamic>.from(raw as Map)))
        .toList();
  }

  static Future<void> saveAllLabExams(List<LabExam> exams) async {
    final box = _labExamsBox;
    if (box == null) return;
    await box.clear();
    final Map<String, Map<String, dynamic>> entries = {
      for (final exam in exams) exam.id: exam.toMap(),
    };
    await box.putAll(entries);
  }
"""

if "loadLabExams" not in content:
    content = content[:last_brace] + addition + content[last_brace:]
    with open(path, "w") as f:
        f.write(content)
    print("OK: metodos loadLabExams/saveAllLabExams agregados")
else:
    print("AVISO: ya existian")
