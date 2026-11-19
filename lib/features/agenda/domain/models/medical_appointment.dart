/// Una cita médica programada (Módulo Agenda).
///
/// A diferencia de una orden/autorización (que es un trámite pendiente de
/// aprobación), una cita ya tiene fecha y hora reales asignadas.
class MedicalAppointment {
  final String id;
  final String doctorName;
  final String specialty;
  final DateTime date;
  final String location;
  final String notes;

  const MedicalAppointment({
    required this.id,
    required this.doctorName,
    required this.specialty,
    required this.date,
    this.location = 'Por confirmar',
    this.notes = '',
  });

  MedicalAppointment copyWith({
    String? id,
    String? doctorName,
    String? specialty,
    DateTime? date,
    String? location,
    String? notes,
  }) {
    return MedicalAppointment(
      id: id ?? this.id,
      doctorName: doctorName ?? this.doctorName,
      specialty: specialty ?? this.specialty,
      date: date ?? this.date,
      location: location ?? this.location,
      notes: notes ?? this.notes,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'doctor_name': doctorName,
      'specialty': specialty,
      'date': date.toIso8601String(),
      'location': location,
      'notes': notes,
    };
  }

  factory MedicalAppointment.fromMap(Map<String, dynamic> map) {
    DateTime parsedDate;
    try {
      parsedDate = DateTime.parse(map['date'] as String);
    } catch (_) {
      parsedDate = DateTime.now().add(const Duration(days: 7));
    }
    return MedicalAppointment(
      id: map['id']?.toString() ??
          DateTime.now().millisecondsSinceEpoch.toString(),
      doctorName: map['doctor_name'] ?? map['doctorName'] ?? 'Médico Tratante',
      specialty: map['specialty'] ?? 'Medicina General',
      date: parsedDate,
      location: map['location'] ?? 'Por confirmar',
      notes: map['notes'] ?? '',
    );
  }
}
