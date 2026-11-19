path = "lib/core/widgets/tualiado_modals.dart"

def load():
    with open(path, "r") as f:
        return f.read()

def save(content):
    with open(path, "w") as f:
        f.write(content)

def replace_brace_block(content, marker, new_block, label):
    start = content.find(marker)
    if start == -1:
        print("AVISO: no se encontro '" + label + "'")
        return content
    brace_open = content.find("{", start)
    depth = 1
    i = brace_open + 1
    while depth > 0:
        if content[i] == "{":
            depth += 1
        elif content[i] == "}":
            depth -= 1
        i += 1
    func_end = i
    content = content[:start] + new_block + content[func_end:]
    save(content)
    print("OK: '" + label + "' reemplazado y guardado")
    return content

content = load()

if "gemini_vision_service.dart" not in content:
    content = content.replace(
        "import '../services/gemini_service.dart';",
        "import '../services/gemini_service.dart';\nimport '../services/gemini_vision_service.dart';",
        1
    )
    save(content)
    print("OK: import agregado")
else:
    print("Import ya presente")

content = load()

new_analyzed_doc = "class AnalyzedDocument {\n  final String fileName;\n  final String targetModule;\n  final String extractedDetail;\n  final String status;\n  final String category;\n  final String? medicationName;\n  final String? dosage;\n  final String? examName;\n  final String? examResult;\n  final String? orderedBy;\n  const AnalyzedDocument({\n    required this.fileName,\n    required this.targetModule,\n    required this.extractedDetail,\n    required this.status,\n    this.category = 'otro',\n    this.medicationName,\n    this.dosage,\n    this.examName,\n    this.examResult,\n    this.orderedBy,\n  });\n}"

content = replace_brace_block(content, "class AnalyzedDocument {", new_analyzed_doc, "AnalyzedDocument")
