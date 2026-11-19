path = "lib/core/services/gemini_vision_service.dart"
with open(path, "r") as f:
    content = f.read()

old1 = """      // ignore: avoid_print
      print('GEMINI_VISION_STATUS: ${response.statusCode}');
      // ignore: avoid_print
      print('GEMINI_VISION_BODY: ${response.body.substring(0, response.body.length > 1500 ? 1500 : response.body.length)}');
      if (response.statusCode != 200) {"""

new1 = """      if (response.statusCode != 200) {"""

if old1 in content:
    content = content.replace(old1, new1, 1)
    print("OK: prints de status/body eliminados")
else:
    print("AVISO: no se encontro el bloque de status/body")

old2 = """      final cleaned =
          rawText.replaceAll('```json', '').replaceAll('```', '').trim();
      // ignore: avoid_print
      print('GEMINI_VISION_RAW_RESPONSE: ' + cleaned);

      final jsonMap"""

new2 = """      final cleaned =
          rawText.replaceAll('```json', '').replaceAll('```', '').trim();

      final jsonMap"""

if old2 in content:
    content = content.replace(old2, new2, 1)
    print("OK: print de raw response eliminado")
else:
    print("AVISO: no se encontro el bloque de raw response")

old3 = """    } catch (e) {
      // ignore: avoid_print
      print('GEMINI_VISION_ERROR: $e');
      return DocumentAnalysisResult.fallback(
          'No se pudo interpretar la respuesta de la IA. Intenta de nuevo.');
    }"""

new3 = """    } catch (e) {
      return DocumentAnalysisResult.fallback(
          'No se pudo interpretar la respuesta de la IA. Intenta de nuevo.');
    }"""

if old3 in content:
    content = content.replace(old3, new3, 1)
    print("OK: print de error eliminado")
else:
    print("AVISO: no se encontro el bloque del catch")

with open(path, "w") as f:
    f.write(content)
print("Guardado")
