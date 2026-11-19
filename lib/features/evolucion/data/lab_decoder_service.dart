import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../../../core/services/hive_service.dart';
import '../../laboratorios/domain/models/lab_exam.dart';
import '../domain/models/lab_decoder_card.dart';

/// Genera el "Decodificador de Laboratorios" de la pantalla Evolución:
/// tarjetas que explican, en lenguaje sencillo, POR QUÉ pasa algo con los
/// laboratorios REALES del paciente y QUÉ hacer al respecto — nunca
/// contenido genérico fijo. Se guarda en caché por "firma" de laboratorios
/// (qué exámenes tiene el paciente) para no volver a llamar la IA si nada
/// cambió. IMPORTANTE: solo se cachean resultados REALES de la IA — un
/// resultado de respaldo (fallback) nunca se guarda, para que la próxima
/// vez que se abra la pantalla se vuelva a intentar.
class LabDecoderService {
  static final LabDecoderService instance = LabDecoderService._internal();

  LabDecoderService._internal();

  static const String _defaultApiKey =
      '';

  static String get _apiKey {
    const env = String.fromEnvironment('GEMINI_API_KEY');
    return env.isNotEmpty ? env : _defaultApiKey;
  }

  static const String _primaryModel = 'gemini-2.5-flash';
  static const String _secondaryModel = 'gemini-3.6-flash';

  static const String _fallbackCardName = 'Sigue registrando tus laboratorios';

  static final List<LabDecoderCard> _fallbackCards = [
    const LabDecoderCard(
      emoji: '🩺',
      name: _fallbackCardName,
      subtitle: 'Aún no pudimos generar un análisis personalizado',
      category: 'General',
      colorKey: 'blue',
      explanation:
          'No logramos conectarnos con la IA en este momento, pero tus laboratorios ya están guardados y organizados en tu perfil.',
      advice:
          'Intenta de nuevo más tarde, o revisa la sección "Tus Exámenes Registrados" más abajo para ver el detalle de cada uno.',
      actionPoints: [
        'Verifica tu conexión a internet.',
        'Vuelve a abrir esta pantalla en unos minutos.',
      ],
    ),
  ];

  bool _looksLikeFallback(List<LabDecoderCard> cards) {
    return cards.length == 1 && cards.first.name == _fallbackCardName;
  }

  /// Firma única basada en los laboratorios actuales del paciente — cambia
  /// si se agrega, quita o modifica cualquier examen.
  String buildSignature(List<LabExam> labExams) {
    return labExams
        .map((e) =>
            '${e.id}:${e.name}:${e.resultSummary ?? ""}:${e.interpretation ?? ""}')
        .join('|');
  }

  Future<List<LabDecoderCard>> getDecoderCards(
    List<LabExam> labExams,
    String signature,
  ) async {
    if (labExams.isEmpty) return const [];

    final cached = HiveService.loadLabDecoderCache();
    if (cached != null && cached['signature'] == signature) {
      final cardsJson = cached['cards'] as List?;
      if (cardsJson != null && cardsJson.isNotEmpty) {
        final cachedCards = cardsJson
            .whereType<Map>()
            .map((m) => LabDecoderCard.fromMap(Map<String, dynamic>.from(m)))
            .toList();
        // Si lo guardado es en realidad un resultado de respaldo de un
        // intento fallido anterior, lo ignoramos y volvemos a intentar.
        if (!_looksLikeFallback(cachedCards)) {
          debugPrint(
              'LAB_DECODER_CACHE_HIT: usando ${cachedCards.length} tarjetas guardadas');
          return cachedCards;
        }
        debugPrint('LAB_DECODER_CACHE_WAS_FALLBACK: reintentando con la IA');
      }
    }

    if (_apiKey.isEmpty) {
      debugPrint(
          'LAB_DECODER_SKIPPED: GEMINI_API_KEY vacío (revisa el launch config), usando respaldo');
      return _fallbackCards;
    }

    try {
      final cards = await _generateCards(labExams).timeout(
        const Duration(seconds: 35),
        onTimeout: () {
          debugPrint('LAB_DECODER_TIMEOUT: no respondió en 35s');
          return null;
        },
      );

      if (cards != null && cards.isNotEmpty) {
        await HiveService.saveLabDecoderCache({
          'signature': signature,
          'cards': cards.map((c) => c.toMap()).toList(),
        });
        return cards;
      }
      // No se guarda nada en caché: la próxima vez se reintenta solo.
      return _fallbackCards;
    } catch (e) {
      debugPrint('LAB_DECODER_ERROR: $e');
      return _fallbackCards;
    }
  }

  /// Devuelve null (nunca las tarjetas de respaldo) si algo falla, para que
  /// [getDecoderCards] decida qué hacer sin arriesgarse a cachear un
  /// resultado inválido.
  Future<List<LabDecoderCard>?> _generateCards(List<LabExam> labExams) async {
    final labsSummary = labExams.take(10).map((e) {
      final result =
          (e.resultSummary != null && e.resultSummary!.trim().isNotEmpty)
              ? e.resultSummary
              : (e.interpretation ?? 'sin resultados registrados');
      return '- ${e.name} (${e.examType ?? "Laboratorio"}, ${e.requestedDate}): $result';
    }).join('\n');

    final prompt = '''
Eres un médico educador de TuAliado IA especializado en explicar laboratorios de forma sencilla y con un enfoque de salud evolutiva (por qué el cuerpo humano reacciona así, y qué hacer al respecto en la vida moderna).

Estos son los laboratorios REALES de este paciente:
$labsSummary

Genera entre 1 y 4 tarjetas explicativas, SOLO sobre hallazgos que realmente aparecen en estos laboratorios (no inventes exámenes que no están ahí). Si todos los valores están normales o no hay hallazgos relevantes, genera 1 sola tarjeta positiva reconociendo eso, con un consejo de mantenimiento.

Responde ÚNICAMENTE con un JSON válido (sin backticks, sin markdown) con esta estructura exacta:
{
  "cards": [
    {
      "emoji": "🩸",
      "name": "Nombre corto del hallazgo (ej. Glucosa Elevada)",
      "subtitle": "Detalle breve (ej. Hemoglobina Glicosilada alta)",
      "category": "Categoría breve (ej. Metabolismo & Energía)",
      "color_key": "amber" | "red" | "green" | "blue" | "purple",
      "explanation": "Por qué pasa esto, en lenguaje sencillo, en 2-3 frases",
      "advice": "Qué puede hacer el paciente, en 1-2 frases",
      "action_points": ["Acción concreta 1", "Acción concreta 2"]
    }
  ]
}

Usa "color_key": "red" para hallazgos que requieren atención pronta, "amber" para hallazgos a vigilar, "green" para hallazgos positivos/normales, "blue" o "purple" para temas informativos neutros.
''';

    final modelsToTry = [_primaryModel, _secondaryModel];

    for (final model in modelsToTry) {
      try {
        final url = Uri.parse(
          'https://generativelanguage.googleapis.com/v1beta/models/$model:generateContent?key=$_apiKey',
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
            'temperature': 0.3,
            'maxOutputTokens': 4096,
          },
        });

        debugPrint(
            'LAB_DECODER_REQUEST: generando decodificador con $model (${labExams.length} laboratorios)');

        final response = await http
            .post(url, headers: {'Content-Type': 'application/json'}, body: body)
            .timeout(const Duration(seconds: 30));

        debugPrint('LAB_DECODER_STATUS: ${response.statusCode}');
        if (response.statusCode != 200) {
          debugPrint('LAB_DECODER_BODY: ${response.body}');
          continue;
        }

        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final candidates = data['candidates'] as List?;
        if (candidates == null || candidates.isEmpty) {
          debugPrint('LAB_DECODER_NO_CANDIDATES: $data');
          continue;
        }

        final parts = candidates[0]['content']?['parts'] as List?;
        final rawText = (parts != null && parts.isNotEmpty)
            ? parts[0]['text'] as String?
            : null;
        if (rawText == null || rawText.trim().isEmpty) {
          debugPrint('LAB_DECODER_EMPTY_TEXT');
          continue;
        }

        final match = RegExp(r'\{[\s\S]*\}').firstMatch(rawText);
        if (match == null) {
          debugPrint('LAB_DECODER_NO_JSON_MATCH: $rawText');
          continue;
        }

        final jsonMap = jsonDecode(match.group(0)!) as Map<String, dynamic>;
        final cardsJson = jsonMap['cards'] as List?;
        if (cardsJson == null || cardsJson.isEmpty) {
          debugPrint('LAB_DECODER_NO_CARDS: $jsonMap');
          continue;
        }

        debugPrint('LAB_DECODER_SUCCESS: ${cardsJson.length} tarjetas generadas con $model');
        return cardsJson
            .whereType<Map>()
            .map((m) => LabDecoderCard.fromMap(Map<String, dynamic>.from(m)))
            .toList();
      } catch (e) {
        debugPrint('LAB_DECODER_ERROR ($model): $e');
      }
    }
    return null;
  }
}
