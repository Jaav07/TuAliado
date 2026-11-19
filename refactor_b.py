path = "lib/features/medicamentos/presentation/screens/medicamentos_screen.dart"
with open(path, "r") as f:
    content = f.read()

marker = "final List<Medication> _medications = ["
start = content.find(marker)
if start == -1:
    print("AVISO: no se encontro el campo _medications (puede que ya se haya reemplazado)")
else:
    bracket_open = content.find("[", start)
    depth = 1
    i = bracket_open + 1
    while depth > 0:
        if content[i] == "[":
            depth += 1
        elif content[i] == "]":
            depth -= 1
        i += 1
    end = i + 1  # incluir el ';' que sigue

    new_getter = "List<Medication> get _medications => AppStateProvider.instance.medications;"
    content = content[:start] + new_getter + content[end:]
    with open(path, "w") as f:
        f.write(content)
    print("OK: campo reemplazado por getter y guardado")
