/// Perfil del paciente (Módulo 012 - Perfil e Historial Documental).
///
/// Formato del paciente con los campos solicitados: Nombre y Apellido, Edad,
/// Sexo, E-mail, Rh, EPS (Sanidad Militar), además de documento y contacto
/// de emergencia.
class PatientProfile {
  final String name;
  final int age;
  final String gender; // Sexo: Masculino, Femenino, Otro, Prefiero no decir
  final String email;
  final String rh; // Factor Rh, ej. "O+"
  final String eps; // EPS / régimen, ej. "Sanidad Militar"
  final String document;
  final String emergencyContact;
  final String primaryGoal;

  const PatientProfile({
    required this.name,
    required this.age,
    required this.gender,
    required this.email,
    this.rh = 'O+',
    this.eps = 'Sanidad Militar',
    this.document = '1.234.567.890',
    this.emergencyContact = 'Contacto de Emergencia',
    this.primaryGoal =
        'Controlar mi salud integral y mantener hábitos saludables.',
  });

  PatientProfile copyWith({
    String? name,
    int? age,
    String? gender,
    String? email,
    String? rh,
    String? eps,
    String? document,
    String? emergencyContact,
    String? primaryGoal,
  }) {
    return PatientProfile(
      name: name ?? this.name,
      age: age ?? this.age,
      gender: gender ?? this.gender,
      email: email ?? this.email,
      rh: rh ?? this.rh,
      eps: eps ?? this.eps,
      document: document ?? this.document,
      emergencyContact: emergencyContact ?? this.emergencyContact,
      primaryGoal: primaryGoal ?? this.primaryGoal,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'full_name': name,
      'age': age,
      'gender': gender,
      'email': email,
      'rh': rh,
      'eps': eps,
      'document': document,
      'emergency_contact': emergencyContact,
      'primary_goal': primaryGoal,
    };
  }

  factory PatientProfile.fromJson(Map<String, dynamic> json) {
    return PatientProfile(
      name: json['full_name'] ?? json['name'] ?? '',
      age: json['age'] is int
          ? json['age']
          : int.tryParse(json['age'].toString()) ?? 30,
      gender: json['gender'] ?? 'Prefiero no decir',
      email: json['email'] ?? '',
      rh: json['rh'] ?? 'O+',
      eps: json['eps'] ?? 'Sanidad Militar',
      document: json['document'] ?? '1.234.567.890',
      emergencyContact:
          json['emergency_contact'] ?? json['emergencyContact'] ?? '',
      primaryGoal: json['primary_goal'] ??
          json['primaryGoal'] ??
          'Mantener hábitos saludables',
    );
  }
}
