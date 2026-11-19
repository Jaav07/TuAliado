path = "lib/core/services/gemini_vision_service.dart"
with open(path, "r") as f:
    content = f.read()

old = """      final cleaned =
          rawText.replaceAll('```json', '').replaceAll('```', '').trim();

      final jsonMap = jsonDecode(cleaned) as Map<String, dynamic>;
      return DocumentAnalysisResult.fromJson(jsonMap);"""

new = """      final cleaned =
          rawText.replaceAll('```json', '').replaceAll('```', '').trim();
      // ignore: avoid_print
      print('GEMINI_VISION_RAW_RESPONSE: ' + cleaned);

      final jsonMap = jsonDecode(cleaned) as Map<String, dynamic>;
      return DocumentAnalysisResult.fromJson(jsonMap);"""

if old not in content:
    print("AVISO: no coincidio el bloque")
else:
    content = content.replace(old, new, 1)
    with open(path, "w") as f:
        f.write(content)
    print("OK: log de diagnostico agregado")
