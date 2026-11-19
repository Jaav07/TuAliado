path = "lib/core/services/gemini_vision_service.dart"
with open(path, "r") as f:
    content = f.read()

marker = "class MedicationExtract {"
start = content.find(marker)
if start == -1:
    print("AVISO: no se encontro MedicationExtract")
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

    new_block = '''class MedicationExtract {
  final String name;
  final String? dosage;
  final String? frequency;
  final String? purpose;
  const MedicationExtract({
    required this.name,
    this.dosage,
    this.frequency,
    this.purpose,
  });
  factory MedicationExtract.fromJson(Map<String, dynamic> json) {
    return MedicationExtract(
      name: (json['name'] as String?) ?? 'Medicamento',
      dosage: json['dosage'] as String?,
      frequency: json['frequency'] as String?,
      purpose: json['purpose'] as String?,
    );
  }
}'''

    content = content[:start] + new_block + content[end:]
    with open(path, "w") as f:
        f.write(content)
    print("OK: MedicationExtract con 'purpose' actualizado y guardado")
