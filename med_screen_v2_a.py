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

    new_block = """if (module.contains('Medicamentos') && doc.medications.isNotEmpty) {
      setState(() {
        for (final extracted in doc.medications) {
          final existingIndex = _medications.indexWhere(
            (m) => m.name.toLowerCase().trim() ==
                extracted.name.toLowerCase().trim(),
          );
          if (existingIndex != -1) {
            final existing = _medications[existingIndex];
            _medications[existingIndex] = existing.copyWith(
              dosage: extracted.dosage ?? existing.dosage,
              purpose: extracted.purpose ?? existing.purpose,
              lastUpdated: DateTime.now(),
              status: 'active',
            );
          } else {
            _medications.insert(
              0,
              Medication(
                id: DateTime.now().millisecondsSinceEpoch +
                    _medications.length,
                name: extracted.name,
                dosage: extracted.dosage != null && extracted.dosage!.trim().isNotEmpty
                    ? extracted.dosage!.trim()
                    : (extracted.frequency ?? 'Dosis no detectada, verificar con tu medico'),
                stockDays: 30,
                deliveryDate: '30 dias',
                status: 'active',
                purpose: extracted.purpose,
                orderedBy: doc.orderedBy,
                lastUpdated: DateTime.now(),
              ),
            );
          }
        }
      });
    }"""

    content = content[:start] + new_block + content[end:]
    with open(path, "w") as f:
        f.write(content)
    print("OK: logica de multiples medicamentos actualizada y guardada")
