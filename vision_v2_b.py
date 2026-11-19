path = "lib/core/services/gemini_vision_service.dart"
with open(path, "r") as f:
    content = f.read()

marker = "static const String _prompt = '''"
start = content.find(marker)
if start == -1:
    print("AVISO: no se encontro _prompt")
else:
    end_marker = "''';"
    end = content.find(end_marker, start) + len(end_marker)

    new_prompt = """static const String _prompt = '''
Eres un asistente medico que analiza documentos de salud (formulas medicas,
resultados de laboratorio, ordenes de autorizacion). Analiza el documento
adjunto y responde UNICAMENTE con un JSON valido (sin texto adicional, sin
markdown, sin backticks), con esta forma exacta:

{
  "category": "medicamento" | "laboratorio" | "autorizacion" | "otro",
  "medications": [
    {"name": "nombre y dosis del medicamento", "dosage": "cantidad/via", "frequency": "frecuencia en lenguaje natural"}
  ],
  "exam_name": "nombre del examen de laboratorio si aplica, o null",
  "exam_result": "resultado o valores relevantes si aplica, o null",
  "ordered_by": "medico o entidad que ordena el documento si aparece, o null",
  "summary": "resumen breve y humano de que encontraste (max 2 frases)"
}

IMPORTANTE: si el documento es una formula medica, incluye en el arreglo
"medications" TODOS los medicamentos que aparezcan en la formula, uno por
cada objeto en el arreglo (no solo el primero). Si el documento no contiene
medicamentos, deja "medications" como un arreglo vacio [].
Si no puedes leer el documento con confianza, usa category "otro" y explica
por que en "summary".
''';"""

    content = content[:start] + new_prompt + content[end:]
    with open(path, "w") as f:
        f.write(content)
    print("OK: prompt actualizado y guardado")
