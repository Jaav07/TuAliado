import 'dart:convert';
import 'package:http/http.dart' as http;

/// Servicio para conversar con la IA de TuAliado usando Gemini (Google AI)
/// con fallback automático a modelos alternativos y Nvidia.
class GeminiService {
  static const String _defaultApiKey =
      '';
  static const String _defaultNvidiaKey =
      '';

  static String get _apiKey {
    const env = String.fromEnvironment('GEMINI_API_KEY');
    return env.isNotEmpty ? env : _defaultApiKey;
  }

  static String get _nvidiaApiKey {
    const env = String.fromEnvironment('NVIDIA_API_KEY');
    return env.isNotEmpty ? env : _defaultNvidiaKey;
  }

  static const String _primaryModel = 'gemini-2.5-flash';
  static const String _secondaryModel = 'gemini-3.6-flash';

  static const String _systemPrompt = '''
Eres "TuAliado IA", el asistente de salud dentro de la app TuAliado.
Hablas siempre en español, con calidez y empatía, como un aliado de confianza
para el paciente (no como un chatbot frío).
Puedes: responder dudas generales de salud en lenguaje sencillo, ayudar a
registrar medicamentos que el usuario menciona, y guiarlo dentro de la app.
Sé breve (máximo 3-4 frases por respuesta) salvo que el usuario pida más detalle.
Nunca reemplazas a un médico: si detectas algo que suene a urgencia o síntoma
grave, recomienda amablemente buscar atención médica presencial.
''';

  /// Envía el mensaje del usuario junto con el historial reciente y devuelve
  /// la respuesta de texto de la IA. Usa gemini-2.5-flash y conmuta automáticamente
  /// a modelos de respaldo si ocurre algún fallo.
  static Future<String?> sendMessage({
    required String userMessage,
    required List<Map<String, String>> history,
  }) async {
    final apiKey = _apiKey;
    if (apiKey.isEmpty) {
      return 'La IA no está configurada (falta GEMINI_API_KEY).';
    }

    // Normalizar historial para formato de turnos válidos de Gemini
    final contents = <Map<String, dynamic>>[];
    for (final m in history) {
      final role = (m['role'] == 'model') ? 'model' : 'user';
      final text = m['text']?.trim() ?? '';
      if (text.isNotEmpty) {
        contents.add({
          'role': role,
          'parts': [
            {'text': text}
          ],
        });
      }
    }

    // Gemini exige que el contenido comience con un turno del usuario
    while (contents.isNotEmpty && contents.first['role'] == 'model') {
      contents.removeAt(0);
    }

    contents.add({
      'role': 'user',
      'parts': [
        {'text': userMessage.trim()}
      ],
    });

    // 1. Intentar con modelo primario: gemini-2.5-flash
    final primaryReply = await _callGemini(
      model: _primaryModel,
      apiKey: apiKey,
      contents: contents,
    );
    if (primaryReply != null && primaryReply.isNotEmpty) {
      return primaryReply;
    }

    // 2. Intentar con modelo secundario: gemini-3.6-flash
    final secondaryReply = await _callGemini(
      model: _secondaryModel,
      apiKey: apiKey,
      contents: contents,
    );
    if (secondaryReply != null && secondaryReply.isNotEmpty) {
      return secondaryReply;
    }

    // 3. Respaldo adicional con Nvidia
    final nvidiaReply = await _callNvidia(
      userMessage: userMessage,
      history: history,
    );
    if (nvidiaReply != null && nvidiaReply.isNotEmpty) {
      return nvidiaReply;
    }

    return 'No hay conexión con la IA en este momento. Verifica tu internet e intenta de nuevo.';
  }

  static Future<String?> _callGemini({
    required String model,
    required String apiKey,
    required List<Map<String, dynamic>> contents,
  }) async {
    final url = Uri.parse(
      'https://generativelanguage.googleapis.com/v1beta/models/$model:generateContent?key=$apiKey',
    );

    final body = jsonEncode({
      'system_instruction': {
        'parts': [
          {'text': _systemPrompt}
        ]
      },
      'contents': contents,
      'generationConfig': {
        'temperature': 0.7,
        'maxOutputTokens': 400,
      },
    });

    try {
      final response = await http
          .post(url, headers: {'Content-Type': 'application/json'}, body: body)
          .timeout(const Duration(seconds: 20));

      if (response.statusCode != 200) {
        return null;
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final candidates = data['candidates'] as List?;
      if (candidates == null || candidates.isEmpty) return null;

      final parts = candidates[0]['content']?['parts'] as List?;
      if (parts == null || parts.isEmpty) return null;

      final text = parts[0]['text'] as String?;
      return text?.trim();
    } catch (_) {
      return null;
    }
  }

  static Future<String?> _callNvidia({
    required String userMessage,
    required List<Map<String, String>> history,
  }) async {
    final nvidiaKey = _nvidiaApiKey;
    if (nvidiaKey.isEmpty) return null;

    try {
      final url =
          Uri.parse('https://integrate.api.nvidia.com/v1/chat/completions');

      final messages = <Map<String, String>>[
        {'role': 'system', 'content': _systemPrompt},
      ];

      for (final m in history) {
        final text = m['text']?.trim() ?? '';
        if (text.isNotEmpty) {
          messages.add({
            'role': (m['role'] == 'model') ? 'assistant' : 'user',
            'content': text,
          });
        }
      }

      messages.add({'role': 'user', 'content': userMessage.trim()});

      final body = jsonEncode({
        'model': 'nvidia/nemotron-3-nano-omni-30b-a3b-reasoning',
        'messages': messages,
        'max_tokens': 400,
        'temperature': 0.7,
      });

      final response = await http
          .post(
            url,
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $nvidiaKey',
            },
            body: body,
          )
          .timeout(const Duration(seconds: 25));

      if (response.statusCode != 200) return null;

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final choices = data['choices'] as List?;
      if (choices == null || choices.isEmpty) return null;

      final text = choices[0]['message']?['content'] as String?;
      return text?.trim();
    } catch (_) {
      return null;
    }
  }
}
