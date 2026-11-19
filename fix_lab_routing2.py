path = "lib/core/widgets/tualiado_modals.dart"
with open(path, "r") as f:
    content = f.read()

old = "  final isMed = analyzedDoc.category == 'medicamento' || analyzedDoc.medications.isNotEmpty;\n  final isLab = analyzedDoc.category == 'laboratorio';"
new = "  final isLab = analyzedDoc.category == 'laboratorio';\n  final isMed = !isLab &&\n      (analyzedDoc.category == 'medicamento' || analyzedDoc.medications.isNotEmpty);"

if old in content:
    content = content.replace(old, new, 1)
    with open(path, "w") as f:
        f.write(content)
    print("OK: segunda ocurrencia corregida")
else:
    print("AVISO: no coincidio el bloque")
