path = "lib/core/widgets/tualiado_modals.dart"
with open(path, "r") as f:
    content = f.read()

old = """                      onPressed: () {
                        Navigator.of(dialogCtx).pop();
                        // Guardar en el estado global
                        if (analyzedDoc.targetModule.contains('Medicamentos')) {
                          AppStateProvider.instance.addMedication(
                            Medication(
                              id: DateTime.now().millisecondsSinceEpoch,
                              name:
                                  'Nuevo: ${analyzedDoc.fileName.replaceAll(RegExp(r'\\.[^/.]+$'), '')}',
                              dosage: analyzedDoc.extractedDetail,
                              stockDays: 30,
                              deliveryDate: '30 días',
                              status: 'active',
                            ),
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
                      },"""

new = """                      onPressed: () {
                        Navigator.of(dialogCtx).pop();
                        // Guardar en el estado global
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
                      },"""

if old not in content:
    print("AVISO: no coincidio el bloque exacto del onPressed")
else:
    content = content.replace(old, new, 1)
    with open(path, "w") as f:
        f.write(content)
    print("OK: onPressed de Confirmar y Organizar actualizado y guardado")
