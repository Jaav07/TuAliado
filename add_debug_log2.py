path = "lib/core/services/gemini_vision_service.dart"
with open(path, "r") as f:
    content = f.read()

old = """      if (response.statusCode != 200) {
        return DocumentAnalysisResult.fallback(
            'Hubo un problema conectando con la IA (${response.statusCode}).');
      }"""

new = """      // ignore: avoid_print
      print('GEMINI_VISION_STATUS: ${response.statusCode}');
      // ignore: avoid_print
      print('GEMINI_VISION_BODY: ${response.body.substring(0, response.body.length > 1500 ? 1500 : response.body.length)}');
      if (response.statusCode != 200) {
        return DocumentAnalysisResult.fallback(
            'Hubo un problema conectando con la IA (${response.statusCode}).');
      }"""

if old not in content:
    print("AVISO: no coincidio el bloque del statusCode")
else:
    content = content.replace(old, new, 1)

old2 = """    } catch (e) {
      return DocumentAnalysisResult.fallback(
          'No se pudo interpretar la respuesta de la IA. Intenta de nuevo.');
    }"""

new2 = """    } catch (e) {
      // ignore: avoid_print
      print('GEMINI_VISION_ERROR: $e');
      return DocumentAnalysisResult.fallback(
          'No se pudo interpretar la respuesta de la IA. Intenta de nuevo.');
    }"""

if old2 not in content:
    print("AVISO: no coincidio el bloque del catch")
else:
    content = content.replace(old2, new2, 1)

with open(path, "w") as f:
    f.write(content)
print("Guardado")
