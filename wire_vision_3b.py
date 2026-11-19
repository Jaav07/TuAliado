path = "lib/core/widgets/tualiado_modals.dart"
with open(path, "r") as f:
    content = f.read()

class_marker = "class _AnalysisOverlayState"
class_start = content.find(class_marker)
if class_start == -1:
    print("AVISO: no se encontro la clase _AnalysisOverlayState")
else:
    init_marker = "void initState() {"
    init_start = content.find(init_marker, class_start)
    if init_start == -1:
        print("AVISO: no se encontro initState dentro de la clase")
    else:
        brace_open = content.find("{", init_start)
        depth = 1
        i = brace_open + 1
        while depth > 0:
            if content[i] == "{":
                depth += 1
            elif content[i] == "}":
                depth -= 1
            i += 1
        init_end = i

        new_block = """void initState() {
    super.initState();
    _spinController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1500))
      ..repeat();
    _runAnalysis();
  }

  Future<void> _runAnalysis() async {
    final result = await GeminiVisionService.analyzeDocument(
      bytes: widget.bytes,
      mimeType: widget.mimeType,
    );
    if (!mounted) return;
    String module;
    String status;
    switch (result.category) {
      case 'medicamento':
        module = '💊 Medicamentos';
        status = 'Listo para registrar';
        break;
      case 'laboratorio':
        module = '🧪 Laboratorios';
        status = 'Procesado';
        break;
      case 'autorizacion':
        module = '📋 Autorizaciones';
        status = 'Procesado';
        break;
      default:
        module = '📁 Baúl de Perfil';
        status = 'Guardado';
    }
    Navigator.of(context).pop(
      AnalyzedDocument(
        fileName: widget.fileName,
        targetModule: module,
        extractedDetail: result.summary,
        status: status,
        category: result.category,
        medicationName: result.medicationName,
        dosage: result.dosage,
        examName: result.examName,
        examResult: result.examResult,
        orderedBy: result.orderedBy,
      ),
    );
  }"""

        content = content[:init_start] + new_block + content[init_end:]
        with open(path, "w") as f:
            f.write(content)
        print("OK: initState reemplazado por conteo de llaves y guardado")
