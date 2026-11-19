path = "lib/core/widgets/tualiado_modals.dart"
with open(path, "r") as f:
    content = f.read()

old = "        orderedBy: result.orderedBy,\n      ),\n    );\n  }"
new = "        orderedBy: result.orderedBy,\n        specialty: result.specialty,\n      ),\n    );\n  }"

if old in content:
    content = content.replace(old, new, 1)
    with open(path, "w") as f:
        f.write(content)
    print("OK: specialty conectado en el constructor y guardado")
else:
    print("AVISO: no coincidio el bloque exacto")
