path = "lib/core/services/gemini_vision_service.dart"
with open(path, "r") as f:
    content = f.read()

old = """2. SI ES UN EXAMEN DE LABORATORIO O ESTUDIO RADIOLÓGICO (Sangre, Rayos X Rx, etc.):
   - La categoría DEBE ser "laboratorio".
   - Extrae el nombre del examen en "exam_name", el tipo en "exam_type", el médico que ordena en "ordered_by", y los resultados / conclusiones principales en "exam_result".
''';"""

new = """2. SI ES UN EXAMEN DE LABORATORIO O ESTUDIO RADIOLÓGICO (Sangre, Rayos X Rx, etc.):
   - La categoría DEBE ser "laboratorio", incluso si el documento contiene resultados con valores numéricos, unidades (mg/dL, mmol/L, g/dL) y rangos de referencia.
   - Extrae el nombre del examen en "exam_name", el tipo en "exam_type", el médico que ordena en "ordered_by", y los resultados / conclusiones principales en "exam_result".
   - IMPORTANTE: si el reporte de laboratorio menciona medicamentos que el paciente ya toma (por ejemplo en una sección de "medicación actual" o "antecedentes farmacológicos"), NO clasifiques el documento como "medicamento" por eso. La categoría sigue siendo "laboratorio" y el arreglo "medications" debe quedar vacío [].
3. Un documento es "medicamento" ÚNICAMENTE si su propósito principal es indicar qué medicamentos debe tomar el paciente (una fórmula o receta), no si simplemente los menciona de paso.
''';"""

if old in content:
    content = content.replace(old, new, 1)
    with open(path, "w") as f:
        f.write(content)
    print("OK: regla de laboratorio reforzada")
else:
    print("AVISO: no coincidio el bloque")
