path = "lib/features/medicamentos/presentation/screens/medicamentos_screen.dart"
with open(path, "r") as f:
    content = f.read()

marker = "  Widget _buildMedicationCard(Medication med) {"
helper = """  static const List<String> _mesesAbrev = [
    'Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun',
    'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic',
  ];

  String _dateRangeLabel(Medication med) {
    final start = med.lastUpdated ?? DateTime.now();
    final end = start.add(Duration(days: med.stockDays));
    final startLabel = '${start.day} ${_mesesAbrev[start.month - 1]}';
    final endLabel = '${end.day} ${_mesesAbrev[end.month - 1]}';
    return '$startLabel - $endLabel';
  }

"""

if marker in content and "_mesesAbrev" not in content:
    content = content.replace(marker, helper + marker, 1)
    with open(path, "w") as f:
        f.write(content)
    print("OK: helper agregado")
else:
    print("AVISO: no aplicado (marcador no encontrado o ya existia)")
