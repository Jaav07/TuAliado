import 'package:flutter/material.dart';
import '../../../../core/providers/app_state_provider.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../perfil/domain/models/patient_profile.dart';
import '../../data/nutrition_service.dart';
import '../../domain/models/nutrition_plan.dart';

class NutricionScreen extends StatefulWidget {
  const NutricionScreen({super.key});

  @override
  State<NutricionScreen> createState() => _NutricionScreenState();
}

class _NutricionScreenState extends State<NutricionScreen> {
  int _selectedDayIndex = 0;
  WeeklyNutritionPlan? _weeklyPlan;
  bool _isLoadingPlan = true;
  bool _wasAdjustedByLabs = false;

  final List<String> _daysOfWeek = [
    'Lunes',
    'Martes',
    'Miércoles',
    'Jueves',
    'Viernes',
    'Sábado',
    'Domingo'
  ];

  PatientProfile get _userProfile =>
      AppStateProvider.instance.profile ??
      const PatientProfile(
        name: 'Usuario',
        age: 35,
        gender: 'Masculino',
        email: 'usuario@tualiado.com',
      );

  @override
  void initState() {
    super.initState();
    _loadWeeklyPlan();
  }

  Future<void> _loadWeeklyPlan() async {
    setState(() => _isLoadingPlan = true);

    final labExams = AppStateProvider.instance.labExams;
    final plan = await NutritionService.instance.loadOrGenerateWeeklyPlan(
      _userProfile,
      labExams,
    );

    if (!mounted) return;
    setState(() {
      _weeklyPlan = plan;
      _wasAdjustedByLabs = plan.isAiGenerated;
      _isLoadingPlan = false;
      _selectedDayIndex = 0;
    });
  }

  /// A diferencia de [_loadWeeklyPlan] (que reutiliza el último plan
  /// guardado), esto SIEMPRE vuelve a generar uno nuevo — es lo que se usa
  /// cuando el paciente pide explícitamente "Regenerar" o "IA Suggest".
  Future<void> _regeneratePlan() async {
    setState(() => _isLoadingPlan = true);

    final labExams = AppStateProvider.instance.labExams;
    final plan = await NutritionService.instance.regenerateWeeklyPlan(
      _userProfile,
      labExams,
    );

    if (!mounted) return;
    setState(() {
      _weeklyPlan = plan;
      _wasAdjustedByLabs = plan.isAiGenerated;
      _isLoadingPlan = false;
      _selectedDayIndex = 0;
    });
  }

  void _showAiCustomizationSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.auto_awesome, color: AppColors.deepTeal),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Personalizar Menú con TuAliado IA',
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.deepTeal),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Text(
                'Selecciona tus preferencias nutricionales para que la IA adapte tus menús de Lunes a Domingo:',
                style: TextStyle(color: AppColors.textGray, fontSize: 14),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  FilterChip(
                      label: const Text('🥦 Bajo en Sodio'),
                      selected: true,
                      selectedColor: AppColors.tealSoft,
                      checkmarkColor: AppColors.deepTeal,
                      onSelected: (_) {}),
                  FilterChip(
                      label: const Text('🥛 Sin Lactosa'),
                      selected: false,
                      selectedColor: AppColors.tealSoft,
                      checkmarkColor: AppColors.deepTeal,
                      onSelected: (_) {}),
                  FilterChip(
                      label: const Text('🥑 Bajo en Carbohidratos'),
                      selected: false,
                      selectedColor: AppColors.tealSoft,
                      checkmarkColor: AppColors.deepTeal,
                      onSelected: (_) {}),
                  FilterChip(
                      label: const Text('🌱 Vegetariano'),
                      selected: false,
                      selectedColor: AppColors.tealSoft,
                      checkmarkColor: AppColors.deepTeal,
                      onSelected: (_) {}),
                  FilterChip(
                      label: const Text('💪 Alto en Proteínas'),
                      selected: true,
                      selectedColor: AppColors.tealSoft,
                      checkmarkColor: AppColors.deepTeal,
                      onSelected: (_) {}),
                ],
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.of(ctx).pop();
                    _regeneratePlan();
                  },
                  icon: const Icon(Icons.refresh),
                  label: const Text('Regenerar menú semanal'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.deepTeal,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingPlan || _weeklyPlan == null) {
      return Scaffold(
        backgroundColor: AppColors.warmCream,
        appBar: AppBar(
          title: const Text('Plan Nutricional IA'),
          backgroundColor: AppColors.deepTeal,
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        body: const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: AppColors.deepTeal),
              SizedBox(height: 16),
              Text(
                'Generando tu menú personalizado...',
                style: TextStyle(color: AppColors.textGray, fontSize: 13),
              ),
            ],
          ),
        ),
      );
    }

    if (_weeklyPlan!.days.isEmpty) {
      // Salvaguarda extra: no debería pasar nunca (WeeklyNutritionPlan.fromJson
      // ya lanza error si faltan días), pero si ocurriera, regenera en vez de
      // truenar la pantalla.
      WidgetsBinding.instance.addPostFrameCallback((_) => _regeneratePlan());
      return Scaffold(
        backgroundColor: AppColors.warmCream,
        appBar: AppBar(
          title: const Text('Plan Nutricional IA'),
          backgroundColor: AppColors.deepTeal,
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        body: const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: AppColors.deepTeal),
              SizedBox(height: 16),
              Text(
                'Generando tu menú personalizado...',
                style: TextStyle(color: AppColors.textGray, fontSize: 13),
              ),
            ],
          ),
        ),
      );
    }

    final safeIndex = _selectedDayIndex.clamp(0, _weeklyPlan!.days.length - 1);
    final currentMenu = _weeklyPlan!.days[safeIndex];

    return Scaffold(
      backgroundColor: AppColors.warmCream,
      appBar: AppBar(
        title: const Text('Plan Nutricional IA'),
        backgroundColor: AppColors.deepTeal,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.tune),
            tooltip: 'Personalizar con IA',
            onPressed: _showAiCustomizationSheet,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Sugerencia Diaria Inteligente de Agua Banner (Sin contador manual)
            _buildWaterSuggestionBanner(),
            const SizedBox(height: 14),

            // Aviso visible cuando el menú fue ajustado según laboratorios
            if (_wasAdjustedByLabs) _buildLabAdjustedBanner(),
            if (_wasAdjustedByLabs) const SizedBox(height: 14),

            // Selector de Días de Lunes a Domingo
            const Text(
              'Menú Semanal (Lunes a Domingo)',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.deepTeal),
            ),
            const SizedBox(height: 12),
            _buildDaySelectorChips(),
            const SizedBox(height: 20),

            // Menú del día seleccionado
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    'Sugerencia para el ${_daysOfWeek[_selectedDayIndex]}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
                TextButton.icon(
                  onPressed: _showAiCustomizationSheet,
                  icon: const Icon(Icons.auto_awesome, size: 16),
                  label: const Text('IA Suggest'),
                  style:
                      TextButton.styleFrom(foregroundColor: AppColors.deepTeal),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Tarjetas de Comidas
            _buildMealCard(
              icon: Icons.wb_twilight,
              iconColor: const Color(0xFFD97706),
              mealType: '🌅 Desayuno',
              meal: currentMenu.breakfast,
            ),
            const SizedBox(height: 14),
            _buildMealCard(
              icon: Icons.wb_sunny,
              iconColor: const Color(0xFFEA580C),
              mealType: '☀️ Almuerzo',
              meal: currentMenu.lunch,
            ),
            const SizedBox(height: 14),
            _buildMealCard(
              icon: Icons.nights_stay,
              iconColor: const Color(0xFF4F46E5),
              mealType: '🌙 Comida / Cena',
              meal: currentMenu.dinner,
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildLabAdjustedBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.tealSoft,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.deepTeal.withValues(alpha: 0.25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.auto_awesome, color: AppColors.deepTeal, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Ajustado según tus laboratorios',
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: AppColors.deepTeal),
                ),
                const SizedBox(height: 4),
                Text(
                  _weeklyPlan!.aiRecommendationNotes,
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.textGray, height: 1.3),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWaterSuggestionBanner() {
    final liters = _weeklyPlan!.dailyWaterSuggestionLiters;
    final glasses = (liters * 4).round();

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.deepTeal,
            AppColors.deepTeal.withValues(alpha: 0.85),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.deepTeal.withValues(alpha: 0.25),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.water_drop, color: Colors.white, size: 36),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Expanded(
                      child: Text(
                        '💧 Hidratación Diaria Recomendada',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 15),
                      ),
                    ),
                    SizedBox(width: 6),
                    Icon(Icons.verified, color: Colors.cyanAccent, size: 16),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Para tu perfil (${_userProfile.gender}, ${_userProfile.age} años), la IA sugiere $liters Litros ($glasses vasos/día) de agua constante.',
                  style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.9),
                      fontSize: 13,
                      height: 1.3),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDaySelectorChips() {
    return SizedBox(
      height: 44,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _daysOfWeek.length,
        itemBuilder: (context, index) {
          final isSelected = index == _selectedDayIndex;
          return Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: ChoiceChip(
              label: Text(_daysOfWeek[index]),
              selected: isSelected,
              selectedColor: AppColors.deepTeal,
              backgroundColor: Colors.white,
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : AppColors.deepTeal,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              ),
              side: const BorderSide(color: AppColors.deepTeal, width: 1),
              onSelected: (selected) {
                if (selected) {
                  setState(() {
                    _selectedDayIndex = index;
                  });
                }
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildMealCard({
    required IconData icon,
    required Color iconColor,
    required String mealType,
    required MealItem meal,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: iconColor, size: 22),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  mealType,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: AppColors.deepTeal),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.softBlue,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${meal.calories} kcal',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppColors.deepTeal,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            meal.title,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
          ),
          const SizedBox(height: 6),
          Text(
            meal.description,
            style: const TextStyle(
                color: AppColors.textGray, fontSize: 13, height: 1.4),
          ),
          if (meal.tags.isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: meal.tags.map((tag) {
                return Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Text(
                    '• $tag',
                    style: const TextStyle(
                        fontSize: 11, color: AppColors.textGray),
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }
}
