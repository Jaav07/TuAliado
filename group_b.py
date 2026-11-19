path = "lib/features/medicamentos/presentation/screens/medicamentos_screen.dart"
with open(path, "r") as f:
    content = f.read()

marker = "@override\n  Widget build(BuildContext context) {"
start = content.find(marker)
if start == -1:
    print("AVISO: no se encontro build()")
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

    new_build = '''@override
  Widget build(BuildContext context) {
    final Map<String, List<Medication>> grouped = {};
    for (final med in _medications) {
      final key = (med.specialty != null && med.specialty!.trim().isNotEmpty)
          ? med.specialty!.trim()
          : 'Sin especialidad';
      grouped.putIfAbsent(key, () => []).add(med);
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('\u{1F48A} Medicamentos'),
        backgroundColor: AppColors.primaryBlue,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showAddInformationSheet(context);
        },
        backgroundColor: AppColors.primaryBlue,
        foregroundColor: Colors.white,
        tooltip: 'Agregar informacion',
        child: const Icon(Icons.add, size: 30),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          if (grouped.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 40),
              child: Center(
                child: Text(
                  'Aun no tienes medicamentos registrados.\\nUsa el boton + para capturar una formula.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.textGray, fontSize: 14),
                ),
              ),
            ),
          for (final entry in grouped.entries) ...[
            Padding(
              padding: const EdgeInsets.only(bottom: 10, top: 6),
              child: Text(
                '\u{1FA7A} ' + entry.key,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primaryBlue,
                ),
              ),
            ),
            ...entry.value.map(_buildMedicationCard),
            const SizedBox(height: 6),
          ],
          Text(
            '\u{1F4C1} Documentos Agregados (\${_vaultDocuments.length})',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.primaryBlue,
            ),
          ),
          const SizedBox(height: 10),
          ..._vaultDocuments.map(_buildDocumentTile),
        ],
      ),
    );
  }'''

    content = content[:start] + new_build + content[end:]
    with open(path, "w") as f:
        f.write(content)
    print("OK: build() con agrupacion por especialidad guardado")
