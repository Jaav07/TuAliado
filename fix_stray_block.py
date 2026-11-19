path = "lib/core/widgets/tualiado_modals.dart"
with open(path, "r") as f:
    content = f.read()

stray = """  );
}) {
  return showDialog<AnalyzedDocument>(
    context: context,
    barrierDismissible: false,
    builder: (_) => _AnalysisOverlay(fileName: fileName),
  );
}
class _ModalOption"""

replacement = """  );
}
class _ModalOption"""

if stray in content:
    content = content.replace(stray, replacement, 1)
    with open(path, "w") as f:
        f.write(content)
    print("OK: bloque duplicado eliminado y guardado")
else:
    print("AVISO: no coincidio el texto exacto, revisar manualmente")
