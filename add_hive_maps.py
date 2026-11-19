path = "lib/features/medicamentos/domain/models/medication.dart"
with open(path, "r") as f:
    content = f.read()

marker = "      lastUpdated: lastUpdated ?? this.lastUpdated,\n    );\n  }\n}"
addition = """      lastUpdated: lastUpdated ?? this.lastUpdated,
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
}"""

if marker in content:
    content = content.replace(marker, addition, 1)
    with open(path, "w") as f:
        f.write(content)
    print("OK: toMap/fromMap agregados a Medication")
else:
    print("AVISO: no coincidio el marcador")
