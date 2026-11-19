path = "lib/features/medicamentos/domain/models/medication.dart"
with open(path, "r") as f:
    content = f.read()

marker = "class Medication {"
start = content.find(marker)
if start == -1:
    print("AVISO: no se encontro la clase Medication")
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

    new_class = '''class Medication {
  final int id;
  final String name;
  final String dosage;
  final int stockDays;
  final String deliveryDate;
  final String status;
  final String? purpose;
  final String? orderedBy;
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
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }
}'''

    content = content[:start] + new_class + content[end:]
    with open(path, "w") as f:
        f.write(content)
    print("OK: modelo Medication actualizado y guardado")
