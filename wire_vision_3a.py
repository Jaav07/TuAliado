path = "lib/core/widgets/tualiado_modals.dart"
with open(path, "r") as f:
    content = f.read()

marker = "class _AnalysisOverlay extends StatefulWidget {"
start = content.find(marker)
if start == -1:
    print("AVISO: no se encontro _AnalysisOverlay widget")
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

    new_block = '''class _AnalysisOverlay extends StatefulWidget {
  final String fileName;
  final List<int> bytes;
  final String mimeType;
  const _AnalysisOverlay({
    required this.fileName,
    required this.bytes,
    required this.mimeType,
  });
  @override
  State<_AnalysisOverlay> createState() => _AnalysisOverlayState();
}'''

    content = content[:start] + new_block + content[func_end:]
    with open(path, "w") as f:
        f.write(content)
    print("OK: _AnalysisOverlay (widget) reemplazado y guardado")
