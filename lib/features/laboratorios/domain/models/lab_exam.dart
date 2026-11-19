enum LabExamStatus { pendiente, programado, completado }

extension LabExamStatusX on LabExamStatus {
  String get label {
    switch (this) {
      case LabExamStatus.pendiente:
        return 'Pendiente';
      case LabExamStatus.programado:
        return 'Programado';
      case LabExamStatus.completado:
        return 'Completado';
    }
  }
}

class LabExam {
  final String id;
  final String name;
  final String orderedBy;
  final String requestedDate;
  final LabExamStatus status;
  final String? resultSummary;
  final String? examType;
  final String? interpretation;

  const LabExam({
    required this.id,
    required this.name,
    required this.orderedBy,
    required this.requestedDate,
    required this.status,
    this.resultSummary,
    this.examType,
    this.interpretation,
  });

  LabExam copyWith({
    LabExamStatus? status,
    String? resultSummary,
    String? examType,
    String? interpretation,
  }) {
    return LabExam(
      id: id,
      name: name,
      orderedBy: orderedBy,
      requestedDate: requestedDate,
      status: status ?? this.status,
      resultSummary: resultSummary ?? this.resultSummary,
      examType: examType ?? this.examType,
      interpretation: interpretation ?? this.interpretation,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'orderedBy': orderedBy,
      'requestedDate': requestedDate,
      'status': status.name,
      'resultSummary': resultSummary,
      'examType': examType,
      'interpretation': interpretation,
    };
  }

  factory LabExam.fromMap(Map<dynamic, dynamic> map) {
    return LabExam(
      id: map['id'] as String,
      name: map['name'] as String,
      orderedBy: map['orderedBy'] as String,
      requestedDate: map['requestedDate'] as String,
      status: LabExamStatus.values.firstWhere(
        (s) => s.name == map['status'],
        orElse: () => LabExamStatus.pendiente,
      ),
      resultSummary: map['resultSummary'] as String?,
      examType: map['examType'] as String?,
      interpretation: map['interpretation'] as String?,
    );
  }
}
