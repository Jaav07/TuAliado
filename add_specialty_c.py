path = "lib/core/widgets/tualiado_modals.dart"
with open(path, "r") as f:
    content = f.read()

marker = "class AnalyzedDocument {"
start = content.find(marker)
if start == -1:
    print("AVISO: no se encontro AnalyzedDocument")
else:
    brace_open = content.find("{", start)
    depth = 1
    i = brace_open + 1
    while depth > 0:
        if content[i] == "{":
            depth += 1
        elif content[i] == "}":
            depth -= 1
        i += 1
    end = i

    new_class = '''class AnalyzedDocument {
  final String fileName;
  final String targetModule;
  final String extractedDetail;
  final String status;
  final String category;
  final List<MedicationExtract> medications;
  final String? examName;
  final String? examResult;
  final String? orderedBy;
  final String? specialty;
  const AnalyzedDocument({
    required this.fileName,
    required this.targetModule,
    required this.extractedDetail,
    required this.status,
    this.category = 'otro',
    this.medications = const [],
    this.examName,
    this.examResult,
    this.orderedBy,
    this.specialty,
  });
}'''

    content = content[:start] + new_class + content[end:]
    with open(path, "w") as f:
        f.write(content)
    print("OK: AnalyzedDocument con specialty actualizado y guardado")
