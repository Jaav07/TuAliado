path = "lib/core/services/gemini_vision_service.dart"
with open(path, "r") as f:
    content = f.read()

old = """    final rawCat = (json['category'] as String?)?.toLowerCase().trim() ?? 'medicamento';
    String category = rawCat;
    if (meds.isNotEmpty || rawCat.contains('med') || rawCat.contains('receta') || rawCat.contains('form')) {
      category = 'medicamento';
    } else if (rawCat.contains('lab') || rawCat.contains('sangre') || rawCat.contains('rx') || rawCat.contains('exam')) {
      category = 'laboratorio';
    }
    return DocumentAnalysisResult(
      category: category,
      medications: meds,"""

new = """    final rawCat = (json['category'] as String?)?.toLowerCase().trim() ?? 'medicamento';
    String category = rawCat;
    if (rawCat.contains('lab') || rawCat.contains('sangre') || rawCat.contains('rx') || rawCat.contains('exam')) {
      category = 'laboratorio';
    } else if (meds.isNotEmpty || rawCat.contains('med') || rawCat.contains('receta') || rawCat.contains('form')) {
      category = 'medicamento';
    }
    final safeMeds = category == 'laboratorio' ? const <MedicationExtract>[] : meds;
    return DocumentAnalysisResult(
      category: category,
      medications: safeMeds,"""

if old in content:
    content = content.replace(old, new, 1)
    with open(path, "w") as f:
        f.write(content)
    print("OK: causa raiz corregida")
else:
    print("AVISO: no coincidio el bloque")
