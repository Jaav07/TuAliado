path = "lib/core/services/gemini_vision_service.dart"
with open(path, "r") as f:
    content = f.read()

old = """      final response = await http
          .post(url, headers: {'Content-Type': 'application/json'}, body: body)
          .timeout(const Duration(seconds: 35));
      if (response.statusCode != 200) return null;
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final candidates = data['candidates'] as List?;
      if (candidates == null || candidates.isEmpty) return null;
      final respParts = candidates[0]['content']?['parts'] as List?;
      final rawText = (respParts != null && respParts.isNotEmpty)
          ? respParts[0]['text'] as String?
          : null;
      if (rawText == null || rawText.trim().isEmpty) return null;
      final match = RegExp(r'\\{[\\s\\S]*\\}').firstMatch(rawText);
      if (match == null) return null;
      final jsonMap = jsonDecode(match.group(0)!) as Map<String, dynamic>;
      return DocumentAnalysisResult.fromJson(jsonMap);
    } catch (_) {
      return null;
    }"""

new = """      final response = await http
          .post(url, headers: {'Content-Type': 'application/json'}, body: body)
          .timeout(const Duration(seconds: 35));
      print('GEMINI_VISION_STATUS: ${response.statusCode}');
      if (response.statusCode != 200) {
        print('GEMINI_VISION_BODY: ${response.body}');
        return null;
      }
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final candidates = data['candidates'] as List?;
      if (candidates == null || candidates.isEmpty) {
        print('GEMINI_VISION_NO_CANDIDATES: ${response.body}');
        return null;
      }
      final respParts = candidates[0]['content']?['parts'] as List?;
      final rawText = (respParts != null && respParts.isNotEmpty)
          ? respParts[0]['text'] as String?
          : null;
      if (rawText == null || rawText.trim().isEmpty) {
        print('GEMINI_VISION_EMPTY_TEXT: $data');
        return null;
      }
      print('GEMINI_VISION_RAW_TEXT: $rawText');
      final match = RegExp(r'\\{[\\s\\S]*\\}').firstMatch(rawText);
      if (match == null) {
        print('GEMINI_VISION_NO_JSON_MATCH');
        return null;
      }
      final jsonMap = jsonDecode(match.group(0)!) as Map<String, dynamic>;
      return DocumentAnalysisResult.fromJson(jsonMap);
    } catch (e) {
      print('GEMINI_VISION_ERROR: $e');
      return null;
    }"""

if old in content:
    content = content.replace(old, new, 1)
    with open(path, "w") as f:
        f.write(content)
    print("OK: prints de depuracion agregados")
else:
    print("AVISO: no coincidio el bloque")
