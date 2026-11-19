path = "lib/core/widgets/tualiado_modals.dart"
with open(path, "r") as f:
    content = f.read()

old = """    final isMed = result.category == 'medicamento' || result.medications.isNotEmpty;
    final isLab = result.category == 'laboratorio';"""

new = """    final isLab = result.category == 'laboratorio';
    final isMed = !isLab &&
        (result.category == 'medicamento' || result.medications.isNotEmpty);"""

if old in content:
    content = content.replace(old, new, 1)
    with open(path, "w") as f:
        f.write(content)
    print("OK: prioridad de categoria corregida")
else:
    print("AVISO: no coincidio el bloque")
