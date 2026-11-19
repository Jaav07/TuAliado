path = "lib/core/services/gemini_vision_service.dart"
with open(path, "r") as f:
    content = f.read()

marker = "class DocumentAnalysisResult {"
start = content.find(marker)
if start == -1:
    print("AVISO: no se encontro DocumentAnalysisResult")
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

    new_block = '''class DocumentAnalysisResult {
  final String category;
  final List<MedicationExtract> medications;
  final String? examName;
  final String? examResult;
  final String? orderedBy;
  final String? specialty;
  final String summary;
  const DocumentAnalysisResult({
    required this.category,
    this.medications = const [],
    this.examName,
    this.examResult,
    this.orderedBy,
    this.specialty,
    required this.summary,
  });
  factory DocumentAnalysisResult.fromJson(Map<String, dynamic> json) {
    final medsJson = json['medications'] as List?;
    final meds = medsJson
            ?.whereType<Map<String, dynamic>>()
            .map(MedicationExtract.fromJson)
            .toList() ??
        const <MedicationExtract>[];
    return DocumentAnalysisResult(
      category: (json['category'] as String?)?.toLowerCase().trim() ?? 'otro',
      medications: meds,
      examName: json['exam_name'] as String?,
      examResult: json['exam_result'] as String?,
      orderedBy: json['ordered_by'] as String?,
      specialty: json['specialty'] as String?,
      summary: json['summary'] as String? ?? 'Documento procesado.',
    );
  }
  factory DocumentAnalysisResult.fallback(String reason) {
    return DocumentAnalysisResult(category: 'otro', summary: reason);
  }
}'''

    content = content[:start] + new_block + content[end:]
    with open(path, "w") as f:
        f.write(content)
    print("OK: campo specialty agregado al modelo y guardado")
