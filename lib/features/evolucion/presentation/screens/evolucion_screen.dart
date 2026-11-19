import 'package:flutter/material.dart';
import '../../../../core/providers/app_state_provider.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../autorizaciones/domain/models/authorization_request.dart';
import '../../../laboratorios/domain/models/lab_exam.dart';
import '../../../perfil/domain/models/patient_profile.dart';
import '../../data/lab_decoder_service.dart';
import '../../data/motivation_service.dart';
import '../../domain/models/lab_decoder_card.dart';
import '../../domain/models/weight_entry.dart';

class EvolucionScreen extends StatefulWidget {
  const EvolucionScreen({super.key});

  @override
  State<EvolucionScreen> createState() => _EvolucionScreenState();
}

class _EvolucionScreenState extends State<EvolucionScreen> {
  String? _motivationMessage;
  int _selectedRuleIndex = 0;
  final Set<int> _expandedLabCards = {
    0
  }; // Primera tarjeta expandida por defecto

  List<LabDecoderCard>? _decoderCards;
  String? _decoderLoadedSignature;
  bool _decoderLoading = false;

  @override
  void initState() {
    super.initState();
    _loadMotivationMessage();
  }

  void _maybeLoadDecoderCards(List<LabExam> labExams) {
    if (labExams.isEmpty) {
      if (_decoderCards != null || _decoderLoadedSignature != null) {
        // Se borraron todos los laboratorios: limpia el estado sin llamar IA.
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          setState(() {
            _decoderCards = [];
            _decoderLoadedSignature = '';
          });
        });
      }
      return;
    }

    final signature = LabDecoderService.instance.buildSignature(labExams);
    if (_decoderLoadedSignature == signature || _decoderLoading) return;

    _decoderLoading = true;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final cards =
          await LabDecoderService.instance.getDecoderCards(labExams, signature);
      if (!mounted) return;
      setState(() {
        _decoderCards = cards;
        _decoderLoadedSignature = signature;
        _decoderLoading = false;
        _expandedLabCards
          ..clear()
          ..add(0);
      });
    });
  }

  Future<void> _loadMotivationMessage() async {
    final profile = AppStateProvider.instance.profile ??
        const PatientProfile(
          name: 'Usuario',
          age: 35,
          gender: 'Masculino',
          email: 'usuario@tualiado.com',
        );
    final message = await MotivationService.instance.getTodaysMessage(
      profile: profile,
      activeMedications: AppStateProvider.instance.medications.length,
      upcomingAppointments: AppStateProvider.instance.appointments
          .where((a) => a.date.isAfter(DateTime.now()))
          .length,
      pendingAuthorizations: AppStateProvider.instance.authorizations
          .where((a) => a.status == AuthorizationStatus.pendiente)
          .length,
    );
    if (!mounted) return;
    setState(() => _motivationMessage = message);
  }

  void _showAddWeightDialog() {
    final controller = TextEditingController();
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.monitor_weight_outlined, color: AppColors.deepTeal),
            SizedBox(width: 8),
            Text('Registrar Peso'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Tu peso fluctúa diariamente por hidratación y ritmo circadiano. Registra tu peso en ayunas para ver la tendencia real.',
              style: TextStyle(
                  fontSize: 12, color: AppColors.textGray, height: 1.3),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              autofocus: true,
              decoration: InputDecoration(
                labelText: 'Peso (kg)',
                hintText: 'ej. 78.5',
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancelar',
                style: TextStyle(color: AppColors.textGray)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.deepTeal,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () {
              final value =
                  double.tryParse(controller.text.trim().replaceAll(',', '.'));
              if (value == null || value <= 0) return;
              AppStateProvider.instance.addWeightEntry(value);
              Navigator.of(ctx).pop();
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: AppStateProvider.instance,
      builder: (context, _) {
        final weightEntries = AppStateProvider.instance.weightEntries;
        final labExams = AppStateProvider.instance.labExams;
        _maybeLoadDecoderCards(labExams);

        return Scaffold(
          backgroundColor: AppColors.warmCream,
          appBar: AppBar(
            title: const Text('Evolución'),
            backgroundColor: AppColors.deepTeal,
            foregroundColor: Colors.white,
            elevation: 0,
          ),
          body: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
            children: [
              // 1. HERO BANNER
              _buildHeroBanner(),
              const SizedBox(height: 24),

              // 2. LAS 4 REGLAS DE ORO — la sección más importante de la pantalla
              _buildSectionHeader(
                icon: Icons.shield_outlined,
                title: 'Las 4 Reglas de Oro',
                subtitle: 'Los hábitos que más impactan tu salud día a día',
                emphasized: true,
              ),
              const SizedBox(height: 12),
              _buildGoldenRulesInteractive(),
              const SizedBox(height: 28),

              // 3. LABORATORIOS: ¿QUÉ TE DICEN TUS EXÁMENES?
              _buildSectionHeader(
                icon: Icons.biotech_outlined,
                title: 'Laboratorios: ¿Qué te dicen tus exámenes?',
                subtitle: 'Por qué se alteran tus marcadores y cómo mejorarlos',
              ),
              const SizedBox(height: 12),
              _buildEvolutionaryLabsDecoder(labExams),
              const SizedBox(height: 28),

              // 4. CÓMO PENSAR TUS MEDICAMENTOS
              _buildSectionHeader(
                icon: Icons.medication_liquid_outlined,
                title: 'Cómo Pensar tus Medicamentos',
                subtitle: 'Tres ideas clave para acompañar tu tratamiento',
              ),
              const SizedBox(height: 12),
              _buildMedicationEvolutionaryFramework(),
              const SizedBox(height: 28),

              // 5. REGISTRO BIOMÉTRICO (PESO Y TENDENCIA)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _buildSectionHeader(
                      icon: Icons.show_chart,
                      title: 'Composición & Peso',
                      subtitle: 'Tu tendencia a largo plazo',
                    ),
                  ),
                  const SizedBox(width: 8),
                  TextButton.icon(
                    onPressed: _showAddWeightDialog,
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text('Registrar'),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.deepTeal,
                      backgroundColor: Colors.white,
                      elevation: 1,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20)),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _buildWeightSection(weightEntries),
              const SizedBox(height: 28),

              // 6. HISTORIAL DE LABORATORIOS CAPTURADOS (si existen)
              if (labExams.isNotEmpty) ...[
                _buildSectionHeader(
                  icon: Icons.history_edu,
                  title: 'Tus Exámenes Registrados',
                  subtitle: 'Historial clínico digitalizado',
                ),
                const SizedBox(height: 12),
                _buildLabHistory(labExams),
                const SizedBox(height: 20),
              ],
            ],
          ),
        );
      },
    );
  }

  // --- HERO BANNER ---
  Widget _buildHeroBanner() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF133E4D), Color(0xFF1D5A6E), Color(0xFF2E7B8F)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF133E4D).withValues(alpha: 0.25),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Text(
                'Evoluciona tu Salud',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.3,
                ),
              ),
              Transform.rotate(
                angle: -0.5,
                child:
                    const Icon(Icons.bolt, color: Colors.amberAccent, size: 26),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Text(
            'Tu cuerpo puede mejorar con pequeños ajustes día a día. Siguiendo las 4 Reglas de Oro, puedes ayudarlo a funcionar mejor.',
            style: TextStyle(
              color: Color(0xFFE2E8F0),
              fontSize: 13,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 14),
          // Micro-tarjeta con mensaje motivador de la IA
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
            ),
            child: Row(
              children: [
                const Text('💡', style: TextStyle(fontSize: 16)),
                const SizedBox(width: 10),
                Expanded(
                  child: _motivationMessage == null
                      ? const Text(
                          'Preparando tu mensaje del día...',
                          style: TextStyle(color: Colors.white70, fontSize: 12),
                        )
                      : Text(
                          _motivationMessage!,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            height: 1.3,
                          ),
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- CABECERA DE SECCIÓN ---
  Widget _buildSectionHeader({
    required IconData icon,
    required String title,
    required String subtitle,
    bool emphasized = false,
  }) {
    if (emphasized) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.tealSoft,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 24, color: AppColors.deepTeal),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.bold,
                      color: AppColors.deepTeal,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: const TextStyle(fontSize: 13, color: AppColors.deepTeal),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 20, color: AppColors.deepTeal),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.deepTeal,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 3),
        Text(
          subtitle,
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.textGray,
          ),
        ),
      ],
    );
  }

  // --- LAS 4 REGLAS DE ORO INTERACTIVAS ---
  static const List<Map<String, dynamic>> _goldenRules = [
    {
      'icon': '🥑',
      'name': 'Nutrición',
      'tag': 'Densidad & Ayuno',
      'color': Color(0xFF15803D),
      'mismatch':
          'Alimentos hiperpalatables, ultraprocesados e ingesta ininterrumpida 24/7.',
      'intervention':
          'Comida real (un solo ingrediente), alta densidad nutricional y ventanas de descanso digestivo (12-14h de ayuno nocturno).',
      'action':
          'Prioriza proteínas de calidad, huevos, vegetales y elimina aceites industriales de semillas.',
    },
    {
      'icon': '🏃',
      'name': 'Movimiento',
      'tag': 'Fuerza & Pasos',
      'color': Color(0xFFD97706),
      'mismatch':
          'Sedentarismo prolongado (+8 horas sentados) intercalado con ejercicio intenso voluntario pero aislado.',
      'intervention':
          'Movimiento constante de baja intensidad (caminar varios km), fuerza muscular regular y sprints breves ocasionales.',
      'action':
          'Camina 10 a 15 minutos después de tus comidas principales para ayudar a tus músculos a procesar mejor la glucosa.',
    },
    {
      'icon': '☀️',
      'name': 'Sueño y Luz',
      'tag': 'Ritmo Circadiano',
      'color': Color(0xFF0284C7),
      'mismatch':
          'Luz artificial nocturna (pantallas LED, focos) y desconexión solar matutina viviendo en interiores.',
      'intervention':
          'Oscuridad total de noche y exposición directa a la luz solar matutina para sincronizar tu reloj biológico.',
      'action':
          'Recibe 10-15 min de sol en los ojos (sin gafas) al despertar y bloquea la luz azul 2 horas antes de dormir.',
    },
    {
      'icon': '🧘',
      'name': 'Estrés y Descanso',
      'tag': 'Adaptación',
      'color': Color(0xFF7C3AED),
      'mismatch':
          'Estrés psicológico crónico y sostenido en posición sentada, sin resolución física del peligro.',
      'intervention':
          'Estrés breve y beneficioso (frío, calor/sauna, esfuerzo breve) seguido de recuperación profunda y descanso.',
      'action':
          'Prueba duchas frías de 30-60 seg o baños de calor, y practica respiración profunda para calmar el sistema nervioso.',
    },
  ];

  Widget _buildGoldenRulesInteractive() {
    final current = _goldenRules[_selectedRuleIndex];
    final color = current['color'] as Color;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          // Selector de áreas en forma de píldoras, con pista visual de que
          // hay más opciones deslizando a la derecha (degradado + flecha).
          Stack(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 12, 28, 12),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: List.generate(_goldenRules.length, (i) {
                      final isSelected = i == _selectedRuleIndex;
                      final item = _goldenRules[i];
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: InkWell(
                          onTap: () => setState(() => _selectedRuleIndex = i),
                          borderRadius: BorderRadius.circular(16),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? (item['color'] as Color)
                                      .withValues(alpha: 0.15)
                                  : const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isSelected
                                    ? (item['color'] as Color)
                                    : Colors.transparent,
                                width: 1.5,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(item['icon'] as String,
                                    style: const TextStyle(fontSize: 16)),
                                const SizedBox(width: 6),
                                Text(
                                  item['name'] as String,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: isSelected
                                        ? FontWeight.bold
                                        : FontWeight.w600,
                                    color: isSelected
                                        ? (item['color'] as Color)
                                        : AppColors.textGray,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                ),
              ),
              Positioned(
                right: 0,
                top: 0,
                bottom: 0,
                child: IgnorePointer(
                  child: Container(
                    width: 32,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                        colors: [
                          Colors.white.withValues(alpha: 0.0),
                          Colors.white,
                        ],
                      ),
                    ),
                    alignment: Alignment.center,
                    child: const Icon(Icons.chevron_right,
                        color: AppColors.deepTeal, size: 18),
                  ),
                ),
              ),
            ],
          ),

          const Divider(height: 1, color: Color(0xFFF1F5F9)),

          // Contenido interactivo: cómo vivimos hoy vs. lo que el cuerpo necesita
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Tag de área
                Row(
                  children: [
                    Text(current['icon'] as String,
                        style: const TextStyle(fontSize: 22)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        current['name'] as String,
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: color),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3.5),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        current['tag'] as String,
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: color),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Tarjeta: cómo vivimos hoy
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF2F2),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                        color: const Color(0xFFFCA5A5).withValues(alpha: 0.5)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('⚠️', style: TextStyle(fontSize: 16)),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Cómo vivimos hoy',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF991B1B),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              current['mismatch'] as String,
                              style: const TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF7F1D1D),
                                  height: 1.35),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),

                // Tarjeta: lo que tu cuerpo necesita
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0FDF4),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                        color: const Color(0xFF86EFAC).withValues(alpha: 0.6)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('🌿', style: TextStyle(fontSize: 16)),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Lo que tu cuerpo necesita',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF166534),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              current['intervention'] as String,
                              style: const TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF14532D),
                                  height: 1.35),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Acción práctica inmediata
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.bolt, color: AppColors.amber, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          current['action'] as String,
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.warmTextDark,
                            fontWeight: FontWeight.w600,
                            height: 1.3,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- DECODIFICADOR DE LABORATORIOS (generado por IA a partir de los
  // laboratorios REALES del paciente; ver _maybeLoadDecoderCards) ---
  Widget _buildEvolutionaryLabsDecoder(List<dynamic> labExams) {
    if (labExams.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: const Column(
          children: [
            Icon(Icons.biotech_outlined, size: 32, color: AppColors.deepTeal),
            SizedBox(height: 8),
            Text(
              'Aún no tienes laboratorios capturados',
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: AppColors.deepTeal),
            ),
            SizedBox(height: 4),
            Text(
              'En cuanto captures tu primer examen, la IA analizará tus resultados reales y te explicará qué significan.',
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: AppColors.textGray, fontSize: 12, height: 1.35),
            ),
          ],
        ),
      );
    }

    if (_decoderLoading || _decoderCards == null) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: const Column(
          children: [
            SizedBox(
              height: 22,
              width: 22,
              child: CircularProgressIndicator(
                  strokeWidth: 2.5, color: AppColors.deepTeal),
            ),
            SizedBox(height: 10),
            Text(
              'Analizando tus laboratorios...',
              style: TextStyle(color: AppColors.textGray, fontSize: 12),
            ),
          ],
        ),
      );
    }

    return Column(
      children: _decoderCards!.asMap().entries.map((entry) {
        final index = entry.key;
        final card = entry.value;
        final isExpanded = _expandedLabCards.contains(index);
        final color = card.color;

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isExpanded
                  ? color.withValues(alpha: 0.5)
                  : const Color(0xFFE2E8F0),
              width: isExpanded ? 1.5 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: isExpanded
                    ? color.withValues(alpha: 0.08)
                    : Colors.black.withValues(alpha: 0.02),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Theme(
            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
            child: ExpansionTile(
              initiallyExpanded: isExpanded,
              onExpansionChanged: (expanded) {
                setState(() {
                  if (expanded) {
                    _expandedLabCards.add(index);
                  } else {
                    _expandedLabCards.remove(index);
                  }
                });
              },
              tilePadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              leading: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: Text(card.emoji, style: const TextStyle(fontSize: 22)),
              ),
              title: Text(
                card.name,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: isExpanded ? color : AppColors.deepTeal,
                ),
              ),
              subtitle: Text(
                card.subtitle,
                style: const TextStyle(fontSize: 11, color: AppColors.textGray),
              ),
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Divider(height: 1, color: Color(0xFFF1F5F9)),
                      const SizedBox(height: 12),

                      // ¿Por qué pasa esto?
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.psychology_alt_outlined,
                              size: 18, color: AppColors.deepTeal),
                          const SizedBox(width: 8),
                          Expanded(
                            child: RichText(
                              text: TextSpan(
                                style: const TextStyle(
                                    fontSize: 12,
                                    color: AppColors.warmTextDark,
                                    height: 1.4),
                                children: [
                                  const TextSpan(
                                    text: '¿Por qué pasa esto? ',
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.deepTeal),
                                  ),
                                  TextSpan(text: card.explanation),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Qué puedes hacer
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF0FDF4),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: const Color(0xFF86EFAC)
                                  .withValues(alpha: 0.6)),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('🌱', style: TextStyle(fontSize: 16)),
                            const SizedBox(width: 8),
                            Expanded(
                              child: RichText(
                                text: TextSpan(
                                  style: const TextStyle(
                                      fontSize: 12,
                                      color: Color(0xFF14532D),
                                      height: 1.35),
                                  children: [
                                    const TextSpan(
                                      text: 'Qué puedes hacer: ',
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF166534)),
                                    ),
                                    TextSpan(text: card.advice),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),

                      // Puntos de acción rápida
                      ...(card.actionPoints.map((point) => Padding(
                            padding: const EdgeInsets.only(top: 4, left: 4),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('• ',
                                    style: TextStyle(
                                        color: AppColors.deepTeal,
                                        fontWeight: FontWeight.bold)),
                                Expanded(
                                  child: Text(
                                    point,
                                    style: const TextStyle(
                                        fontSize: 11.5,
                                        color: AppColors.textGray),
                                  ),
                                ),
                              ],
                            ),
                          ))),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  // --- CÓMO PENSAR TUS MEDICAMENTOS ---
  Widget _buildMedicationEvolutionaryFramework() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.deepTeal.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.healing_outlined,
                    color: AppColors.deepTeal, size: 22),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Si ya tomas medicamentos',
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppColors.deepTeal),
                    ),
                    Text(
                      'Aborda tu tratamiento con estas tres ideas',
                      style: TextStyle(fontSize: 11, color: AppColors.textGray),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Principio 1
          _buildMedicationPrincipleItem(
            number: '1',
            title: 'Apaga el síntoma, no cambia la causa de fondo',
            description:
                'Las estatinas, antihipertensivos o metformina salvan vidas al controlar el daño agudo, pero no corrigen por sí solos el estilo de vida que provocó la alteración.',
            color: const Color(0xFF0284C7),
          ),
          const SizedBox(height: 12),

          // Principio 2
          _buildMedicationPrincipleItem(
            number: '2',
            title: 'Respeta las señales de tu cuerpo',
            description:
                'La fiebre o la inflamación leve son respuestas naturales de defensa. Apagar toda señal del cuerpo mediante automedicación indiscriminada puede retrasar tu propia recuperación.',
            color: const Color(0xFFD97706),
          ),
          const SizedBox(height: 12),

          // Principio 3
          _buildMedicationPrincipleItem(
            number: '3',
            title: 'La meta: menos dependencia, con el tiempo',
            description:
                'El objetivo es cambiar hábitos (dieta, movimiento, descanso, luz) para que tu cuerpo recupere su equilibrio, reduciendo la dependencia del fármaco cuando sea médicamente seguro y siempre bajo supervisión médica.',
            color: const Color(0xFF16A34A),
          ),
        ],
      ),
    );
  }

  Widget _buildMedicationPrincipleItem({
    required String number,
    required String title,
    required String description,
    required Color color,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            shape: BoxShape.circle,
            border: Border.all(color: color, width: 1.5),
          ),
          alignment: Alignment.center,
          child: Text(
            number,
            style: TextStyle(
                fontSize: 12, fontWeight: FontWeight.bold, color: color),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: AppColors.warmTextDark,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                description,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textGray,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // --- SECCIÓN DE PESO Y TENDENCIA ---
  Widget _buildWeightSection(List<WeightEntry> entries) {
    if (entries.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Column(
          children: [
            const Icon(Icons.scale_outlined,
                size: 36, color: AppColors.deepTeal),
            const SizedBox(height: 8),
            const Text(
              'Aún no has registrado tu peso',
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: AppColors.deepTeal),
            ),
            const SizedBox(height: 4),
            const Text(
              'Registra tu peso periódicamente. Evaluamos la tendencia a largo plazo, sin juzgar las variaciones normales de corto plazo.',
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: AppColors.textGray, fontSize: 12, height: 1.35),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: _showAddWeightDialog,
              icon: const Icon(Icons.add, size: 16),
              label: const Text('Registrar Primer Peso'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.deepTeal,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      );
    }

    final sorted = List<WeightEntry>.from(entries)
      ..sort((a, b) => a.date.compareTo(b.date));
    final recent =
        sorted.length > 6 ? sorted.sublist(sorted.length - 6) : sorted;
    final values = recent.map((e) => e.weightKg).toList();
    final maxWeight = values.reduce((a, b) => a > b ? a : b);
    final minWeight = values.reduce((a, b) => a < b ? a : b);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Último registro: ${recent.last.weightKg} kg',
                style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: AppColors.deepTeal),
              ),
              Text(
                '${recent.length} registros analizados',
                style: const TextStyle(fontSize: 11, color: AppColors.textGray),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: List.generate(recent.length, (i) {
              final entry = recent[i];
              final range = (maxWeight - minWeight).clamp(0.1, double.infinity);
              final heightFraction =
                  ((entry.weightKg - minWeight) / range) * 0.7 + 0.3;
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text('${entry.weightKg}',
                          style: const TextStyle(
                              fontSize: 11, color: AppColors.textGray)),
                      const SizedBox(height: 4),
                      Container(
                        height: 90 * heightFraction,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [AppColors.deepTeal, Color(0xFF2E7B8F)],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text('${entry.date.day}/${entry.date.month}',
                          style: const TextStyle(
                              fontSize: 11, color: AppColors.textGray)),
                    ],
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 12),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),
          const SizedBox(height: 8),
          const Row(
            children: [
              Icon(Icons.info_outline, size: 14, color: AppColors.textGray),
              SizedBox(width: 6),
              Expanded(
                child: Text(
                  'El peso oscila por agua y glucógeno muscular. Concéntrate en tu energía y vitalidad.',
                  style: TextStyle(fontSize: 10.5, color: AppColors.textGray),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // --- HISTORIAL DE LABORATORIOS CAPTURADOS ---
  Widget _buildLabHistory(List<dynamic> labExams) {
    return Column(
      children: labExams.take(5).map<Widget>((exam) {
        final summary = (exam.resultSummary != null &&
                (exam.resultSummary as String).trim().isNotEmpty)
            ? exam.resultSummary as String
            : (exam.interpretation as String? ??
                'Sin resultados registrados aún.');
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 10,
                height: 10,
                margin: const EdgeInsets.only(top: 5),
                decoration: const BoxDecoration(
                  color: AppColors.deepTeal,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            exam.name as String,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          exam.requestedDate as String,
                          style: const TextStyle(
                              fontSize: 11, color: AppColors.textGray),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      summary,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.textGray, height: 1.3),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
