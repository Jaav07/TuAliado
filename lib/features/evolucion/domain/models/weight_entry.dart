/// Un registro de peso ingresado por el propio paciente (Módulo Evolución).
/// A diferencia de otros datos, este nunca viene de captura con IA — el
/// paciente lo ingresa directamente, porque no hay ningún documento del cual
/// extraerlo automáticamente.
class WeightEntry {
  final String id;
  final DateTime date;
  final double weightKg;

  const WeightEntry({
    required this.id,
    required this.date,
    required this.weightKg,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'date': date.toIso8601String(),
        'weight_kg': weightKg,
      };

  factory WeightEntry.fromMap(Map<String, dynamic> map) {
    DateTime parsedDate;
    try {
      parsedDate = DateTime.parse(map['date'] as String);
    } catch (_) {
      parsedDate = DateTime.now();
    }
    return WeightEntry(
      id: map['id']?.toString() ??
          DateTime.now().millisecondsSinceEpoch.toString(),
      date: parsedDate,
      weightKg: (map['weight_kg'] as num?)?.toDouble() ?? 0,
    );
  }
}
