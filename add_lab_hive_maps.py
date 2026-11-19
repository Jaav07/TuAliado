path = "lib/features/laboratorios/domain/models/lab_exam.dart"
with open(path, "r") as f:
    content = f.read()

marker = """      resultSummary: resultSummary ?? this.resultSummary,
      examType: examType ?? this.examType,
    );
  }
}"""

addition = """      resultSummary: resultSummary ?? this.resultSummary,
      examType: examType ?? this.examType,
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
    );
  }
}"""

if marker in content:
    content = content.replace(marker, addition, 1)
    with open(path, "w") as f:
        f.write(content)
    print("OK: toMap/fromMap agregados a LabExam")
else:
    print("AVISO: no coincidio el marcador")
