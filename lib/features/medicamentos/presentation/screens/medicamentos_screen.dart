import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/tualiado_modals.dart';
import '../../../../core/providers/app_state_provider.dart';
import '../../domain/models/medication.dart';
import '../../domain/models/health_document.dart';

class MedicamentosScreen extends StatefulWidget {
  const MedicamentosScreen({super.key});

  @override
  State<MedicamentosScreen> createState() => _MedicamentosScreenState();
}

class _MedicamentosScreenState extends State<MedicamentosScreen> {
  @override
  void initState() {
    super.initState();
    AppStateProvider.instance.addListener(_onAppStateChanged);
  }

  @override
  void dispose() {
    AppStateProvider.instance.removeListener(_onAppStateChanged);
    super.dispose();
  }

  void _onAppStateChanged() {
    if (mounted) setState(() {});
  }

  List<Medication> get _medications => AppStateProvider.instance.medications;
  List<HealthDocument> get _documents => AppStateProvider.instance.documents;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('💊 Medicamentos'),
        backgroundColor: AppColors.primaryBlue,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showAddInformationSheet(context);
        },
        backgroundColor: AppColors.primaryBlue,
        foregroundColor: Colors.white,
        tooltip: 'Agregar información con IA',
        child: const Icon(Icons.add, size: 30),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Tarjetas de medicamentos organizadas automáticamente por especialidad
          ..._buildGroupedMedicationSections(),
          const SizedBox(height: 6),

          // Baúl de documentos y fotos escaneadas
          Text(
            '📁 Documentos Agregados (${_documents.length})',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.primaryBlue,
            ),
          ),
          const SizedBox(height: 10),
          ..._documents.map(_buildDocumentTile),
        ],
      ),
    );
  }

  List<Widget> _buildGroupedMedicationSections() {
    final Map<String, List<Medication>> grouped = {};
    for (final med in _medications) {
      final key = (med.specialty != null && med.specialty!.trim().isNotEmpty)
          ? med.specialty!.trim()
          : 'Medicina General';
      grouped.putIfAbsent(key, () => []).add(med);
    }

    if (grouped.isEmpty) {
      return [
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 20),
          child: Center(
            child: Text(
              'No hay medicamentos registrados aún.',
              style: TextStyle(color: AppColors.textGray, fontSize: 14),
            ),
          ),
        ),
      ];
    }

    final widgets = <Widget>[];
    for (final entry in grouped.entries) {
      widgets.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 10, top: 6),
          child: Text(
            entry.key,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.primaryBlue,
            ),
          ),
        ),
      );
      widgets.addAll(entry.value.map(_buildMedicationCard));
      widgets.add(const SizedBox(height: 6));
    }
    return widgets;
  }

  static const List<String> _mesesAbrev = [
    'Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun',
    'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic',
  ];

  String _dateRangeLabel(Medication med) {
    final start = med.lastUpdated ?? DateTime.now();
    final end = start.add(Duration(days: med.stockDays));
    final crossesYear = start.year != end.year;
    final startLabel = crossesYear
        ? '${start.day} ${_mesesAbrev[start.month - 1]} ${start.year}'
        : '${start.day} ${_mesesAbrev[start.month - 1]}';
    final endLabel = crossesYear
        ? '${end.day} ${_mesesAbrev[end.month - 1]} ${end.year}'
        : '${end.day} ${_mesesAbrev[end.month - 1]}';
    return '$startLabel - $endLabel';
  }

  Widget _buildMedicationCard(Medication med) {
    final isPending = med.status == 'pending';

    return Dismissible(
      key: ValueKey(med.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => AppStateProvider.instance.deleteMedication(med.id),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: const Color(0xFFDC2626),
          borderRadius: BorderRadius.circular(18),
        ),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      child: Card(
      elevation: 3,
      shadowColor: AppColors.shadowBlue,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    med.name,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A1C1E),
                    ),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: isPending
                        ? const Color(0xFFFEF3C7)
                        : const Color(0xFFE0F2FE),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _dateRangeLabel(med),
                    style: TextStyle(
                      color: isPending
                          ? const Color(0xFFB45309)
                          : const Color(0xFF0369A1),
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              med.dosage,
              style: const TextStyle(color: AppColors.textGray, fontSize: 14),
            ),
            if (med.purpose != null && med.purpose!.trim().isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                'Para: ${med.purpose}',
                style: const TextStyle(
                  color: AppColors.textGray,
                  fontSize: 13,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
            const SizedBox(height: 10),
            Text(
              'Dosis para ${med.stockDays} días restantes',
              style: const TextStyle(
                color: AppColors.primaryBlue,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    ),
    );
  }

  Widget _buildDocumentTile(HealthDocument doc) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Text(doc.type == 'PDF' ? '📄' : '🖼️',
              style: const TextStyle(fontSize: 26)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  doc.name,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1A1C1E),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${doc.date} • ${doc.type} • ${doc.targetModule}',
                  style:
                      const TextStyle(fontSize: 12, color: AppColors.textGray),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
