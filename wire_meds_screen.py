path = "lib/features/medicamentos/presentation/screens/medicamentos_screen.dart"
with open(path, "r") as f:
    content = f.read()

def remove_brace_block(content, marker, label):
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
    end = i
    content = content[:start] + content[end:]
    print("OK: '" + label + "' eliminado")
    return content

# 1. Eliminar las 3 funciones del formulario manual
content = remove_brace_block(content, "Future<void> _openAddMedicationModal() async {", "_openAddMedicationModal")
content = remove_brace_block(content, "InputDecoration _inputDecoration(String label, String hint) {", "_inputDecoration")
content = remove_brace_block(content, "void _saveNewMedication(", "_saveNewMedication")

with open(path, "w") as f:
    f.write(content)

print("Guardado tras eliminar las 3 funciones")
