path = "lib/core/services/gemini_vision_service.dart"
with open(path, "r") as f:
    content = f.read()

old = '''  "ordered_by": "medico y/o especialidad que ordena el documento si aparece, o null",
  "summary": "resumen breve y humano de que encontraste (max 2 frases)"'''

new = '''  "ordered_by": "nombre del medico que ordena el documento si aparece, o null",
  "specialty": "especialidad medica del profesional que formula (ej. Cardiologia, Gastroenterologia, Fisiatria, Medicina General), o null si no es identificable",
  "summary": "resumen breve y humano de que encontraste (max 2 frases)"'''

if old in content:
    content = content.replace(old, new, 1)
    with open(path, "w") as f:
        f.write(content)
    print("OK: specialty agregado al prompt y guardado")
else:
    print("AVISO: no coincidio el bloque exacto")
