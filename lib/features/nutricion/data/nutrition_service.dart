import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../../../core/services/hive_service.dart';
import '../../laboratorios/domain/models/lab_exam.dart';
import '../../perfil/domain/models/patient_profile.dart';
import '../domain/models/nutrition_plan.dart';

/// Servicio de Inteligencia Artificial Nutricional de TuAliado.
/// Genera sugerencias de menús diarios de Lunes a Domingo (Desayuno, Almuerzo, Comida)
/// y calcula la sugerencia inteligente de hidratación diaria sin contadores manuales.
class NutritionService {
  static final NutritionService instance = NutritionService._internal();

  NutritionService._internal();

  static const String _defaultApiKey =
      '';

  static String get _apiKey {
    const env = String.fromEnvironment('GEMINI_API_KEY');
    return env.isNotEmpty ? env : _defaultApiKey;
  }

  static const String _primaryModel = 'gemini-2.5-flash';
  static const String _secondaryModel = 'gemini-3.6-flash';

  /// Plan fijo y saludable por defecto (sin IA). Se usa mientras el paciente
  /// no tenga laboratorios registrados, o como respaldo si la IA falla.
  WeeklyNutritionPlan getWeeklyPlan(PatientProfile profile) {
    final waterLit = _calculateRecommendedWater(profile);

    return WeeklyNutritionPlan(
      dailyWaterSuggestionLiters: waterLit,
      aiRecommendationNotes:
          'Plan nutricional saludable general para ${profile.name} (${profile.age} años, ${profile.gender}). Enfocado en control de sodio, balance de energía y salud digestiva.',
      days: [
        const DailyMenu(
          dayOfWeek: 'Lunes',
          breakfast: MealItem(
            title: '🥞 Omelette de Claras con Espinaca y Vaso de Avena',
            description:
                '2 claras de huevo, espinacas frescas, 1 rebanada de pan integral tostado y té verde sin azúcar.',
            calories: 320,
            tags: ['Bajo en Sodio', 'Alto en Proteína'],
          ),
          lunch: MealItem(
            title: '🥗 Pechuga a la Plancha con Quinua y Vegetales al Vapor',
            description:
                '150g de pechuga de pollo, 1/2 taza de quinua cocida, brócoli, zanahoria y ensalada fresca con aceite de oliva.',
            calories: 520,
            tags: ['Saludable', 'Energía Ligera'],
          ),
          dinner: MealItem(
            title: '🍲 Crema de Zapallo y Pescado Blanco',
            description:
                'Crema natural de ahuyama/zapallo con trozos de filete de corvina o merluza a la plancha.',
            calories: 380,
            tags: ['Fácil Digestión', 'Cena Ligera'],
          ),
        ),
        const DailyMenu(
          dayOfWeek: 'Martes',
          breakfast: MealItem(
            title:
                '🥣 Bowl de Yogur Griego con Semillas de Chía y Frutos Rojos',
            description:
                'Yogur sin azúcar, 1 cucharada de semillas de chía, fresas y arándanos frescos.',
            calories: 290,
            tags: ['Antioxidante', 'Probiótico'],
          ),
          lunch: MealItem(
            title: '🐟 Filete de Salmón o Trucha con Puré de Camote',
            description:
                'Salmón a la plancha con hierbas finas, puré de camote amarillo y espárragos salteados.',
            calories: 560,
            tags: ['Omega 3', 'Corazón Sano'],
          ),
          dinner: MealItem(
            title: '🥗 Ensalada de Pollo Desmenuzado y Aguacate',
            description:
                'Mezcla de lechugas, aguacate en cubos, pechuga desmenuzada y vinagreta de limón.',
            calories: 340,
            tags: ['Keto Friendly', 'Sin Gluten'],
          ),
        ),
        const DailyMenu(
          dayOfWeek: 'Miércoles',
          breakfast: MealItem(
            title: '🍞 Arepa de Maíz Blanco con Queso Campesino Bajo en Sal',
            description:
                '1 arepa asada, 40g de queso bajo en grasa/sodio y jugo natural de papaya sin azúcar.',
            calories: 340,
            tags: ['Balance Tradicional'],
          ),
          lunch: MealItem(
            title: '🥩 Carne Magra en Salsa de Tomate Natural y Arroz Integral',
            description:
                '140g de lomo fino de res en concassé de tomate casero, arroz integral y ensalada de pepino.',
            calories: 540,
            tags: ['Hierro', 'Proteína Completa'],
          ),
          dinner: MealItem(
            title: '🍲 Sopa de Verduras y Tofu o Pollo',
            description:
                'Caldo claro de verduras de estación con cubos de pollo o tofu y pizca de cilantro.',
            calories: 310,
            tags: ['Desintoxicante', 'Ligero'],
          ),
        ),
        const DailyMenu(
          dayOfWeek: 'Jueves',
          breakfast: MealItem(
            title: '🍳 Huevos Revueltos con Tomate y Pan de Centeno',
            description:
                '2 huevos enteros salteados con chonto picado, 1 tostada de centeno y café descafeinado.',
            calories: 330,
            tags: ['Saciante'],
          ),
          lunch: MealItem(
            title: '🍗 Muslo de Pavo Horneado con Papas Criollas al Horno',
            description:
                'Pavo a las finas hierbas con 3 papas criollas asadas con piel y ensalada verde mixta.',
            calories: 510,
            tags: ['Bajo en Grasa'],
          ),
          dinner: MealItem(
            title: '🥪 Wrap Integral de Hummus y Vegetales Grillados',
            description:
                'Tortilla integral de grano entero, hummus de garbanzo, pimentón asado y calabacín.',
            calories: 360,
            tags: ['Fibra', 'Vegetariano'],
          ),
        ),
        const DailyMenu(
          dayOfWeek: 'Viernes',
          breakfast: MealItem(
            title: '🍌 Smoothie Verde de Espinaca, Piña y Proteína',
            description:
                'Batido natural de manzana verde, espinaca, piña y leche de almendras sin azúcar.',
            calories: 280,
            tags: ['Energía Rápida', 'Detox'],
          ),
          lunch: MealItem(
            title: '🍲 Cazuela de Lentejas con Camote y Arroz Silvestre',
            description:
                'Guiso de lentejas con verduras picadas, plátano verde cocido y porción de arroz silvestre.',
            calories: 530,
            tags: ['Proteína Vegetal', 'Fibra Alta'],
          ),
          dinner: MealItem(
            title: '🐟 Filete de Tilapia al Limón con Ensalada César Ligera',
            description:
                'Tilapia horneada con jugo de limón y pimienta negra, lechuga romana y aderezo de yogur.',
            calories: 330,
            tags: ['Bajo Calórico', 'Proteína Limpia'],
          ),
        ),
        const DailyMenu(
          dayOfWeek: 'Sábado',
          breakfast: MealItem(
            title: '🥞 Pancakes Integrales de Avena y Banano',
            description:
                'Pancakes de 1 huevo, 1/2 banano y avena molida con un hilo de miel pura.',
            calories: 360,
            tags: ['Fin de Semana Sano'],
          ),
          lunch: MealItem(
            title: '🥘 Bowl Mediterráneo de Garbanzos, Pepino y Feta',
            description:
                'Garbanzos cocidos, pepino fresco, aceitunas negras, queso feta bajo en sal y aderezo de orégano.',
            calories: 490,
            tags: ['Dieta Mediterránea'],
          ),
          dinner: MealItem(
            title: '🍳 Tortilla de Calabacín y Pimentón',
            description:
                'Omelette esponjoso con calabacín rallado y pimentones salteados.',
            calories: 320,
            tags: ['Cena Reparadora'],
          ),
        ),
        const DailyMenu(
          dayOfWeek: 'Domingo',
          breakfast: MealItem(
            title: '🥑 Tostada de Aguacate con Huevo Escalfado',
            description:
                '1 rebanada grande de pan de masa madre, 1/2 aguacate machacado y 1 huevo poché encima.',
            calories: 370,
            tags: ['Grasas Saludables'],
          ),
          lunch: MealItem(
            title: '🍖 Pechuga Rellena de Ricotta y Espinacas',
            description:
                'Pechuga de pollo horneada rellena, acompañada de yuca al vapor y ensalada colorida.',
            calories: 550,
            tags: ['Especial Domingo'],
          ),
          dinner: MealItem(
            title: '🍲 Crema de Champiñones Naturales',
            description:
                'Sopa cremosa a base de champiñones salteados con cebollín y leche descremada.',
            calories: 310,
            tags: ['Confortable', 'Ligero'],
          ),
        ),
      ],
    );
  }

  /// Carga el plan ya guardado en Hive si existe (sin llamar a la IA de
  /// nuevo). Si nunca se ha generado uno para este paciente, lo genera por
  /// primera vez (según [getPersonalizedWeeklyPlan]) y lo guarda. Esto es lo
  /// que se usa al abrir la pantalla o reiniciar la app — el menú se queda
  /// quieto hasta que el paciente pida explícitamente regenerarlo.
  Future<WeeklyNutritionPlan> loadOrGenerateWeeklyPlan(
    PatientProfile profile,
    List<LabExam> labExams,
  ) async {
    final saved = HiveService.loadNutritionPlan();
    if (saved != null) {
      try {
        return WeeklyNutritionPlan.fromJson(saved);
      } catch (_) {
        // Dato corrupto o de una versión vieja: sigue de largo y genera uno nuevo.
      }
    }
    return regenerateWeeklyPlan(profile, labExams);
  }

  /// Genera un plan nuevo desde cero (fijo si no hay laboratorios, con IA si
  /// sí los hay) y lo guarda en Hive para que quede fijo hasta la próxima
  /// vez que se llame este método explícitamente (botón "Regenerar"/"IA
  /// Suggest").
  Future<WeeklyNutritionPlan> regenerateWeeklyPlan(
    PatientProfile profile,
    List<LabExam> labExams,
  ) async {
    final plan = await getPersonalizedWeeklyPlan(profile, labExams);
    HiveService.saveNutritionPlan(plan.toJson());
    return plan;
  }

  /// Devuelve el plan personalizado: si el paciente NO tiene laboratorios
  /// registrados (o no hay API key configurada), usa el plan fijo saludable
  /// de [getWeeklyPlan]. Si SÍ tiene laboratorios, le pide a la IA que ajuste
  /// el menú según esos resultados. Sin importar qué pase (sin internet,
  /// timeout, respuesta inválida, más de 35s de espera), SIEMPRE cae de
  /// vuelta al plan fijo — la pantalla nunca se queda cargando para siempre.
  Future<WeeklyNutritionPlan> getPersonalizedWeeklyPlan(
    PatientProfile profile,
    List<LabExam> labExams,
  ) async {
    final fallback = getWeeklyPlan(profile);

    if (labExams.isEmpty) {
      debugPrint(
          'NUTRITION_AI_SKIPPED: sin laboratorios registrados, usando plan fijo');
      return fallback;
    }
    if (_apiKey.isEmpty) {
      debugPrint(
          'NUTRITION_AI_SKIPPED: GEMINI_API_KEY vacío (revisa el launch config), usando plan fijo');
      return fallback;
    }

    try {
      return await _generateFromLabs(profile, labExams, fallback).timeout(
        const Duration(seconds: 35),
        onTimeout: () {
          debugPrint('NUTRITION_AI_TIMEOUT: no respondió en 35s, usando plan fijo');
          return fallback;
        },
      );
    } catch (e) {
      debugPrint('NUTRITION_AI_ERROR: $e');
      return fallback;
    }
  }

  Future<WeeklyNutritionPlan> _generateFromLabs(
    PatientProfile profile,
    List<LabExam> labExams,
    WeeklyNutritionPlan fallback,
  ) async {
    final labsSummary = labExams.take(8).map((e) {
      final result =
          (e.resultSummary != null && e.resultSummary!.trim().isNotEmpty)
              ? e.resultSummary
              : (e.interpretation ?? 'sin resultados registrados');
      return '- ${e.name} (${e.examType ?? "Laboratorio"}, ${e.requestedDate}): $result';
    }).join('\n');

    final prompt = '''
Eres un nutricionista experto de TuAliado IA. Genera un plan de menú semanal (Lunes a Domingo) para este paciente, ajustado a sus resultados de laboratorio.

Paciente: ${profile.name}, ${profile.age} años, sexo ${profile.gender}.

Resultados de laboratorio recientes:
$labsSummary

Ajusta las comidas según lo que encuentres relevante (ej. bajo en sodio si hay hipertensión o problemas renales, bajo en azúcares/carbohidratos simples si hay glucosa elevada o diabetes, cardio-saludable si hay colesterol/triglicéridos altos, etc.). Si algún examen no tiene hallazgos relevantes para nutrición, no lo menciones ni lo fuerces.

Responde ÚNICAMENTE con un JSON válido (sin backticks, sin markdown) con esta estructura exacta:
{
  "notes": "Nota breve y empática de máximo 2 frases explicando cómo se ajustó el menú según los laboratorios",
  "days": [
    {
      "day_of_week": "Lunes",
      "breakfast": {"title": "...", "description": "...", "calories": 350, "tags": ["..."]},
      "lunch": {"title": "...", "description": "...", "calories": 550, "tags": ["..."]},
      "dinner": {"title": "...", "description": "...", "calories": 350, "tags": ["..."]}
    }
  ]
}

El arreglo "days" debe tener EXACTAMENTE 7 elementos, en este orden: Lunes, Martes, Miércoles, Jueves, Viernes, Sábado, Domingo. Usa comidas variadas, sabrosas, con ingredientes comunes en Colombia, igual que un menú casero saludable. Cada lista "tags" debe reflejar por qué esa comida es adecuada para este paciente (ej. "Bajo en Sodio", "Control Glucémico").
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
            'temperature': 0.4,
            'maxOutputTokens': 4096,
          },
        });

        debugPrint(
            'NUTRITION_AI_REQUEST: generando menú con $model (${labExams.length} laboratorios)');

        final response = await http
            .post(url, headers: {'Content-Type': 'application/json'}, body: body)
            .timeout(const Duration(seconds: 30));

        debugPrint('NUTRITION_AI_STATUS: ${response.statusCode}');
        if (response.statusCode != 200) {
          debugPrint('NUTRITION_AI_BODY: ${response.body}');
          continue;
        }

        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final candidates = data['candidates'] as List?;
        if (candidates == null || candidates.isEmpty) {
          debugPrint('NUTRITION_AI_NO_CANDIDATES: $data');
          continue;
        }

        final parts = candidates[0]['content']?['parts'] as List?;
        final rawText = (parts != null && parts.isNotEmpty)
            ? parts[0]['text'] as String?
            : null;
        if (rawText == null || rawText.trim().isEmpty) {
          debugPrint('NUTRITION_AI_EMPTY_TEXT');
          continue;
        }

        final match = RegExp(r'\{[\s\S]*\}').firstMatch(rawText);
        if (match == null) {
          debugPrint('NUTRITION_AI_NO_JSON_MATCH: $rawText');
          continue;
        }

        final jsonMap = jsonDecode(match.group(0)!) as Map<String, dynamic>;
        final daysJson = jsonMap['days'] as List?;
        if (daysJson == null || daysJson.length < 7) {
          debugPrint('NUTRITION_AI_INCOMPLETE_DAYS: ${daysJson?.length}');
          continue;
        }

        final days = daysJson
            .whereType<Map<String, dynamic>>()
            .map(DailyMenu.fromJson)
            .toList();

        debugPrint('NUTRITION_AI_SUCCESS: menú generado y ajustado según laboratorios ($model)');
        return WeeklyNutritionPlan(
          dailyWaterSuggestionLiters: fallback.dailyWaterSuggestionLiters,
          aiRecommendationNotes:
              jsonMap['notes'] as String? ?? fallback.aiRecommendationNotes,
          days: days,
          isAiGenerated: true,
        );
      } catch (e) {
        debugPrint('NUTRITION_AI_ERROR ($model): $e');
      }
    }

    return fallback;
  }

  /// Sugerencia inteligente de hidratación basada en edad y sexo del usuario
  double _calculateRecommendedWater(PatientProfile profile) {
    double base = profile.gender == 'Femenino' ? 2.2 : 2.7;
    if (profile.age > 60) {
      base = 2.3;
    } else if (profile.age < 25) {
      base += 0.3;
    }
    return base;
  }
}
