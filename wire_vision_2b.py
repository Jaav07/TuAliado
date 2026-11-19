path = "lib/core/widgets/tualiado_modals.dart"
with open(path, "r") as f:
    content = f.read()

marker = "Future<AnalyzedDocument?> showTuAliadoAnalysis("
start = content.find(marker)
if start == -1:
    print("AVISO: no se encontro showTuAliadoAnalysis")
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
    func_end = i

    new_func = '''Future<AnalyzedDocument?> showTuAliadoAnalysis(
  BuildContext context, {
  required String fileName,
  required List<int> bytes,
  required String mimeType,
}) {
  return showDialog<AnalyzedDocument>(
    context: context,
    barrierDismissible: false,
    builder: (_) => _AnalysisOverlay(
      fileName: fileName,
      bytes: bytes,
      mimeType: mimeType,
    ),
  );
}'''

    content = content[:start] + new_func + content[func_end:]
    with open(path, "w") as f:
        f.write(content)
    print("OK: showTuAliadoAnalysis reemplazado y guardado")
