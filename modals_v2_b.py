path = "lib/core/widgets/tualiado_modals.dart"
with open(path, "r") as f:
    content = f.read()

old_block = """    Navigator.of(context).pop(
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
    );"""

new_block = """    Navigator.of(context).pop(
      AnalyzedDocument(
        fileName: widget.fileName,
        targetModule: module,
        extractedDetail: result.summary,
        status: status,
        category: result.category,
        medications: result.medications,
        examName: result.examName,
        examResult: result.examResult,
        orderedBy: result.orderedBy,
      ),
    );"""

if old_block not in content:
    print("AVISO: no coincidio el bloque exacto")
else:
    content = content.replace(old_block, new_block, 1)
    with open(path, "w") as f:
        f.write(content)
    print("OK: bloque de AnalyzedDocument actualizado y guardado")
