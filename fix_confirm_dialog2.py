path = "lib/core/widgets/tualiado_modals.dart"
with open(path, "r") as f:
    content = f.read()

marker = "onPressed: () {\n                        Navigator.of(dialogCtx).pop();"
start = content.find(marker)
if start == -1:
    print("AVISO: no se encontro el marcador del onPressed")
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

    new_block = """onPressed: () {
                        Navigator.of(dialogCtx).pop();
                        if (analyzedDoc.category == 'medicamento' &&
                            analyzedDoc.medications.isNotEmpty) {
                          AppStateProvider.instance.mergeMedicationsFromCapture(
                            analyzedDoc.medications,
                            orderedBy: analyzedDoc.orderedBy,
                          );
                          Navigator.of(context).push(MaterialPageRoute<void>(
                              builder: (_) => const MedicamentosScreen()));
                        } else {
                          AppStateProvider.instance.addHealthDocument(
                            HealthDocument(
                              name: analyzedDoc.fileName,
                              date: 'Hoy',
                              type: analyzedDoc.fileName.endsWith('.pdf')
                                  ? 'PDF'
                                  : 'Imagen',
                              targetModule: analyzedDoc.targetModule,
                            ),
                          );
                          Navigator.of(context).push(MaterialPageRoute<void>(
                              builder: (_) => const PerfilScreen()));
                        }
                      }"""

    content = content[:start] + new_block + content[end:]
    with open(path, "w") as f:
        f.write(content)
    print("OK: onPressed reemplazado por conteo de llaves y guardado")
