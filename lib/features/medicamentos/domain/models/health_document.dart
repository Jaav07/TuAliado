/// Documento de salud agregado al baúl de documentos (Módulo 003/004/012).
class HealthDocument {
  final String name;
  final String date;
  final String type; // 'PDF' | 'Imagen'
  final String
      targetModule; // Módulo donde se clasificó (Medicamentos, Laboratorios, etc.)

  const HealthDocument({
    required this.name,
    required this.date,
    required this.type,
    required this.targetModule,
  });
}
