/// Convierte de forma segura cualquier mapa "crudo" (venga de jsonDecode o
/// de vuelta de Hive, que puede devolver Map<dynamic, dynamic> en vez de
/// Map<String, dynamic> para estructuras anidadas) a un Map<String, dynamic>
/// utilizable. Nunca lanza error: si no es un mapa válido, devuelve uno vacío.
Map<String, dynamic> _asStringMap(dynamic raw) {
  if (raw is Map<String, dynamic>) return raw;
  if (raw is Map) return Map<String, dynamic>.from(raw);
  return <String, dynamic>{};
}

/// Modelo de Item de Comida (Desayuno, Almuerzo o Comida/Cena)
class MealItem {
  final String title;
  final String description;
  final int calories;
  final List<String> tags;

  const MealItem({
    required this.title,
    required this.description,
    required this.calories,
    this.tags = const [],
  });

  Map<String, dynamic> toJson() => {
        'title': title,
        'description': description,
        'calories': calories,
        'tags': tags,
      };

  factory MealItem.fromJson(Map<String, dynamic> json) => MealItem(
        title: json['title'] ?? '',
        description: json['description'] ?? '',
        calories: json['calories'] ?? 350,
        tags: json['tags'] != null
            ? List<String>.from(json['tags'] as List)
            : const [],
      );
}

/// Menú diario para un día específico de la semana (Lunes a Domingo)
class DailyMenu {
  final String dayOfWeek; // 'Lunes', 'Martes', ..., 'Domingo'
  final MealItem breakfast;
  final MealItem lunch;
  final MealItem dinner;

  const DailyMenu({
    required this.dayOfWeek,
    required this.breakfast,
    required this.lunch,
    required this.dinner,
  });

  Map<String, dynamic> toJson() => {
        'day_of_week': dayOfWeek,
        'breakfast': breakfast.toJson(),
        'lunch': lunch.toJson(),
        'dinner': dinner.toJson(),
      };

  factory DailyMenu.fromJson(Map<String, dynamic> json) => DailyMenu(
        dayOfWeek: json['day_of_week'] ?? 'Lunes',
        breakfast: MealItem.fromJson(_asStringMap(json['breakfast'])),
        lunch: MealItem.fromJson(_asStringMap(json['lunch'])),
        dinner: MealItem.fromJson(_asStringMap(json['dinner'])),
      );
}

/// Plan de Nutrición Semanal Completo sugerido por la IA (o el plan fijo
/// saludable por defecto). [isAiGenerated] distingue cuál de los dos es,
/// para que la interfaz solo muestre el aviso "Ajustado según tus
/// laboratorios" cuando el plan REALMENTE vino de la IA (no solo porque el
/// paciente tenga laboratorios registrados).
class WeeklyNutritionPlan {
  final List<DailyMenu> days;
  final double dailyWaterSuggestionLiters;
  final String aiRecommendationNotes;
  final bool isAiGenerated;

  const WeeklyNutritionPlan({
    required this.days,
    required this.dailyWaterSuggestionLiters,
    required this.aiRecommendationNotes,
    this.isAiGenerated = false,
  });

  Map<String, dynamic> toJson() => {
        'days': days.map((d) => d.toJson()).toList(),
        'daily_water_suggestion_liters': dailyWaterSuggestionLiters,
        'ai_recommendation_notes': aiRecommendationNotes,
        'is_ai_generated': isAiGenerated,
      };

  /// Lanza [FormatException] si el JSON no trae los 7 días completos —
  /// así el llamador (normalmente un plan guardado en Hive) puede detectarlo
  /// y regenerar el plan en vez de quedarse con una lista de días vacía o
  /// incompleta en silencio.
  factory WeeklyNutritionPlan.fromJson(Map<String, dynamic> json) {
    final daysJson = json['days'] as List?;
    final days = (daysJson ?? const [])
        .map((e) => DailyMenu.fromJson(_asStringMap(e)))
        .toList();

    if (days.length != 7) {
      throw FormatException(
          'Plan de nutrición incompleto: ${days.length} días en vez de 7');
    }

    return WeeklyNutritionPlan(
      days: days,
      dailyWaterSuggestionLiters:
          (json['daily_water_suggestion_liters'] as num?)?.toDouble() ?? 2.5,
      aiRecommendationNotes: json['ai_recommendation_notes'] ?? '',
      isAiGenerated: json['is_ai_generated'] == true,
    );
  }
}
