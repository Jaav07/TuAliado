/// Modelo de un medicamento activo del paciente (Módulo 006).
class Medication {
  final int id;
  final String name;
  final String dosage;
  final int stockDays;
  final String deliveryDate;
  final String status;
  final String? purpose;
  final String? orderedBy;
  final String? specialty;
  final DateTime? lastUpdated;
  const Medication({
    required this.id,
    required this.name,
    required this.dosage,
    required this.stockDays,
    required this.deliveryDate,
    this.status = 'active',
    this.purpose,
    this.orderedBy,
    this.specialty,
    this.lastUpdated,
  });
  Medication copyWith({
    int? id,
    String? name,
    String? dosage,
    int? stockDays,
    String? deliveryDate,
    String? status,
    String? purpose,
    String? orderedBy,
    String? specialty,
    DateTime? lastUpdated,
  }) {
    return Medication(
      id: id ?? this.id,
      name: name ?? this.name,
      dosage: dosage ?? this.dosage,
      stockDays: stockDays ?? this.stockDays,
      deliveryDate: deliveryDate ?? this.deliveryDate,
      status: status ?? this.status,
      purpose: purpose ?? this.purpose,
      orderedBy: orderedBy ?? this.orderedBy,
      specialty: specialty ?? this.specialty,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'dosage': dosage,
      'stockDays': stockDays,
      'deliveryDate': deliveryDate,
      'status': status,
      'purpose': purpose,
      'orderedBy': orderedBy,
      'specialty': specialty,
      'lastUpdated': lastUpdated?.toIso8601String(),
    };
  }

  factory Medication.fromMap(Map<dynamic, dynamic> map) {
    return Medication(
      id: map['id'] as int,
      name: map['name'] as String,
      dosage: map['dosage'] as String,
      stockDays: map['stockDays'] as int,
      deliveryDate: map['deliveryDate'] as String,
      status: (map['status'] as String?) ?? 'active',
      purpose: map['purpose'] as String?,
      orderedBy: map['orderedBy'] as String?,
      specialty: map['specialty'] as String?,
      lastUpdated: map['lastUpdated'] != null
          ? DateTime.parse(map['lastUpdated'] as String)
          : null,
    );
  }
}
