path = "lib/features/medicamentos/presentation/screens/medicamentos_screen.dart"
with open(path, "r") as f:
    content = f.read()

old = """  String _dateRangeLabel(Medication med) {
    final start = med.lastUpdated ?? DateTime.now();
    final end = start.add(Duration(days: med.stockDays));
    final startLabel = '${start.day} ${_mesesAbrev[start.month - 1]}';
    final endLabel = '${end.day} ${_mesesAbrev[end.month - 1]}';
    return '$startLabel - $endLabel';
  }"""

new = """  String _dateRangeLabel(Medication med) {
    final start = med.lastUpdated ?? DateTime.now();
    final end = start.add(Duration(days: med.stockDays));
    final crossesYear = start.year != end.year;
    final startLabel = crossesYear
        ? '${start.day} ${_mesesAbrev[start.month - 1]} ${start.year}'
        : '${start.day} ${_mesesAbrev[start.month - 1]}';
    final endLabel = crossesYear
        ? '${end.day} ${_mesesAbrev[end.month - 1]} ${end.year}'
        : '${end.day} ${_mesesAbrev[end.month - 1]}';
    return '$startLabel - $endLabel';
  }"""

if old in content:
    content = content.replace(old, new, 1)
    with open(path, "w") as f:
        f.write(content)
    print("OK: logica de año agregada")
else:
    print("AVISO: no coincidio el bloque")
