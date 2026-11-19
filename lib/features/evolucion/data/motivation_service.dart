import 'dart:convert';
import 'package:http/http.dart' as http;

import '../../../core/services/hive_service.dart';
import '../../perfil/domain/models/patient_profile.dart';

/// Genera un mensaje motivacional corto y cálido para el paciente, una vez
/// al día (no en cada entrada a la pantalla, para no gastar llamadas de
/// más). Si la IA falla por cualquier razón, siempre hay un mensaje de
/// respaldo — nunca se queda sin nada que mostrar.
class MotivationService {
  static final MotivationService instance = MotivationService._internal();

  MotivationService._internal();

  static const String _defaultApiKey =
      '';

  static String get _apiKey {
    const env = String.fromEnvironment('GEMINI_API_KEY');
    return env.isNotEmpty ? env : _defaultApiKey;
  }

  static const String _primaryModel = 'gemini-2.5-flash';
  static const String _secondaryModel = 'gemini-3.6-flash';

  static const String _fallbackMessage =
      '💙 Cada paso que das organizando tu salud cuenta. ¡Vas muy bien!';

  Future<String> getTodaysMessage({
    required PatientProfile profile,
    required int activeMedications,
    required int upcomingAppointments,
    required int pendingAuthorizations,
  }) async {
    final todayKey = _todayKey();
    final saved = HiveService.loadDailyMotivation();
    if (saved != null && saved['date'] == todayKey) {
      return (saved['message'] as String?) ?? _fallbackMessage;
    }

    final message = await _generateMessage(
      profile: profile,
      activeMedications: activeMedications,
      upcomingAppointments: upcomingAppointments,
      pendingAuthorizations: pendingAuthorizations,
    );

    await HiveService.saveDailyMotivation(
        {'date': todayKey, 'message': message});
    return message;
  }

  String _todayKey() {
    final now = DateTime.now();
    return '${now.year}-${now.month}-${now.day}';
  }

  Future<String> _generateMessage({
    required PatientProfile profile,
    required int activeMedications,
    required int upcomingAppointments,
    required int pendingAuthorizations,
  }) async {
    final apiKey = _apiKey;
    if (apiKey.isEmpty) return _fallbackMessage;

    final prompt = '''
Eres TuAliado, un acompañante de salud cálido y empático. Escribe UN solo mensaje corto (máximo 2 frases, menos de 30 palabras) motivacional y saludable para ${profile.name}, en español, comenzando con un emoji relacionado con salud/bienestar.

Contexto del paciente (menciónalo solo si suma naturalmente, no lo fuerces ni lo hagas sonar a lista): $activeMedications medicamentos activos, $upcomingAppointments citas próximas, $pendingAuthorizations trámites pendientes.

Responde ÚNICAMENTE con el mensaje final, sin comillas, sin explicaciones, sin markdown.
''';

    final modelsToTry = [_primaryModel, _secondaryModel];

    for (final model in modelsToTry) {
      try {
        final url = Uri.parse(
          'https://generativelanguage.googleapis.com/v1beta/models/$model:generateContent?key=$apiKey',
        );
        final body = jsonEncode({
          'contents': [
            {
              'role': 'user',
              'parts': [
                {'text': prompt},
              ],
            }
          ],
          'generationConfig': {
            'temperature': 0.85,
            'maxOutputTokens': 200,
          },
        });

        final response = await http
            .post(url, headers: {'Content-Type': 'application/json'}, body: body)
            .timeout(const Duration(seconds: 15));

        if (response.statusCode != 200) continue;

        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final candidates = data['candidates'] as List?;
        if (candidates == null || candidates.isEmpty) continue;

        final parts = candidates[0]['content']?['parts'] as List?;
        final text = (parts != null && parts.isNotEmpty)
            ? parts[0]['text'] as String?
            : null;
        if (text == null || text.trim().isEmpty) continue;

        return text.trim();
      } catch (_) {
        continue;
      }
    }

    return _fallbackMessage;
  }
}
