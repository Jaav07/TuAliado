path = "lib/features/medicamentos/presentation/screens/medicamentos_screen.dart"
with open(path, "r") as f:
    content = f.read()

marker = "if (module.contains('Medicamentos')) {"
start = content.find(marker)
if start == -1:
    print("AVISO: no se encontro el bloque de _onDocumentAnalyzed")
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
    end = i

    new_block = """if (module.contains('Medicamentos')) {
      setState(() {
        _medications.insert(
          0,
          Medication(
            id: DateTime.now().millisecondsSinceEpoch,
            name: doc.medicationName != null && doc.medicationName!.trim().isNotEmpty
                ? doc.medicationName!.trim()
                : 'Medicamento (revisar foto)',
            dosage: doc.dosage != null && doc.dosage!.trim().isNotEmpty
                ? doc.dosage!.trim()
                : 'Dosis no detectada, verificar con tu medico',
            stockDays: 30,
            deliveryDate: '30 dias',
            status: 'active',
          ),
        );
      });
    }"""

    content = content[:start] + new_block + content[end:]
    with open(path, "w") as f:
        f.write(content)
    print("OK: logica actualizada con datos reales y guardado")
