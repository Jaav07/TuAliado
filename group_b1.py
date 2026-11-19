path = "lib/features/medicamentos/presentation/screens/medicamentos_screen.dart"
with open(path, "r") as f:
    content = f.read()

marker = "  Widget _buildMedicationCard(Medication med) {"
if "_buildGroupedMedicationSections" in content:
    print("Ya presente, no se duplica")
else:
    new_method = """  List<Widget> _buildGroupedMedicationSections() {
    final Map<String, List<Medication>> grouped = {};
    for (final med in _medications) {
      final key = (med.specialty != null && med.specialty!.trim().isNotEmpty)
          ? med.specialty!.trim()
          : 'Sin especialidad';
      grouped.putIfAbsent(key, () => []).add(med);
    }
    final widgets = <Widget>[];
    for (final entry in grouped.entries) {
      widgets.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 10, top: 6),
          child: Text(
            entry.key,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.primaryBlue,
            ),
          ),
        ),
      );
      widgets.addAll(entry.value.map(_buildMedicationCard));
      widgets.add(const SizedBox(height: 6));
    }
    return widgets;
  }

"""
    content = content.replace(marker, new_method + marker, 1)
    with open(path, "w") as f:
        f.write(content)
    print("OK: metodo _buildGroupedMedicationSections agregado")
