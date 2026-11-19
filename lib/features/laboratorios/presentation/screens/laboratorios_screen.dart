import 'package:flutter/material.dart';
import '../../../../core/providers/app_state_provider.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/tualiado_modals.dart';
import '../../domain/models/lab_exam.dart';

class LaboratoriosScreen extends StatelessWidget {
  const LaboratoriosScreen({super.key});

  Color _statusColor(LabExamStatus status) {
    switch (status) {
      case LabExamStatus.pendiente:
        return const Color(0xFFD97706);
      case LabExamStatus.programado:
        return AppColors.primaryBlue;
      case LabExamStatus.completado:
        return const Color(0xFF15803D);
    }
  }

  String _getExamIcon(String name, String? type) {
    final lower = '$name ${type ?? ""}'.toLowerCase();
    if (lower.contains('rx') || lower.contains('rayos') || lower.contains('radiog')) {
      return '🩻';
    }
    if (lower.contains('sangre') || lower.contains('hemo') || lower.contains('lipid') || lower.contains('gluc')) {
      return '🩸';
    }
    if (lower.contains('eco') || lower.contains('tomog') || lower.contains('tac')) {
      return '📡';
    }
    if (lower.contains('orina') || lower.contains('uro')) {
      return '🧪';
    }
    return '🧪';
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: AppStateProvider.instance,
      builder: (context, _) {
        final exams = AppStateProvider.instance.labExams;
        final labDocs = AppStateProvider.instance.documents
            .where((d) => d.targetModule == '🧪 Laboratorios')
            .toList();

        return Scaffold(
          backgroundColor: const Color(0xFFF8FAFC),
          appBar: AppBar(
            title: const Text('🧪 Laboratorios e Imágenes'),
            backgroundColor: AppColors.primaryBlue,
            foregroundColor: Colors.white,
            elevation: 0,
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: () => showAddInformationSheet(context),
            backgroundColor: AppColors.primaryBlue,
            child: const Icon(Icons.add, color: Colors.white, size: 28),
          ),
          body: exams.isEmpty && labDocs.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('🧪', style: TextStyle(fontSize: 48)),
                        const SizedBox(height: 16),
                        const Text(
                          'No tienes exámenes registrados',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primaryBlue,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Toma una foto de tus resultados de sangre, Rayos X (Rx) o ecografías con el botón (+) para que la IA los analice.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: AppColors.textGray, fontSize: 14),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          onPressed: () => showAddInformationSheet(context),
                          icon: const Icon(Icons.camera_alt),
                          label: const Text('📸 Tomar Foto o Escanear'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryBlue,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    Text(
                      'Exámenes y Estudios Registrados (${exams.length})',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryBlue,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ...exams.asMap().entries.map((entry) {
                      final index = entry.key;
                      final exam = entry.value;
                      final icon = _getExamIcon(exam.name, exam.examType);

                      return Dismissible(
                        key: ValueKey(exam.id),
                        direction: DismissDirection.endToStart,
                        onDismissed: (_) => AppStateProvider.instance.deleteLabExam(exam.id),
                        background: Container(
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 24),
                          margin: const EdgeInsets.only(bottom: 14),
                          decoration: BoxDecoration(
                            color: const Color(0xFFDC2626),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Icon(Icons.delete, color: Colors.white),
                        ),
                        child: Card(
                        elevation: 2,
                        shadowColor: AppColors.shadowBlue,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        margin: const EdgeInsets.only(bottom: 14),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(icon, style: const TextStyle(fontSize: 26)),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          exam.name,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 15,
                                            color: Color(0xFF1E293B),
                                          ),
                                        ),
                                        if (exam.examType != null)
                                          Text(
                                            exam.examType!,
                                            style: const TextStyle(
                                              fontSize: 12,
                                              color: AppColors.primaryBlue,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: _statusColor(exam.status).withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Text(
                                      exam.status.label,
                                      style: TextStyle(
                                        color: _statusColor(exam.status),
                                        fontWeight: FontWeight.bold,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              if (exam.orderedBy.isNotEmpty)
                                Row(
                                  children: [
                                    const Icon(Icons.person_outline, size: 14, color: AppColors.textGray),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Text(
                                        exam.orderedBy,
                                        style: const TextStyle(color: AppColors.textGray, fontSize: 13),
                                      ),
                                    ),
                                  ],
                                ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  const Icon(Icons.calendar_today, size: 14, color: AppColors.textGray),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Fecha: ${exam.requestedDate}',
                                    style: const TextStyle(color: AppColors.textGray, fontSize: 12),
                                  ),
                                ],
                              ),
                              if (exam.resultSummary != null && exam.resultSummary!.trim().isNotEmpty) ...[
                                const SizedBox(height: 10),
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF8FAFC),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(color: const Color(0xFFE2E8F0)),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        '💡 Resultados y Hallazgos (IA):',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.primaryBlue,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        exam.resultSummary!,
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: Color(0xFF334155),
                                          height: 1.3,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                              if (exam.interpretation != null && exam.interpretation!.trim().isNotEmpty) ...[
                                const SizedBox(height: 10),
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF0FDF4),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(color: const Color(0xFFBBF7D0)),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Interpretacion:',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF15803D),
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        exam.interpretation!,
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: Color(0xFF166534),
                                          height: 1.3,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                              const SizedBox(height: 6),
                              Align(
                                alignment: Alignment.centerRight,
                                child: TextButton.icon(
                                  onPressed: () => AppStateProvider.instance.toggleLabExamStatus(index),
                                  icon: const Icon(Icons.swap_horiz, size: 16),
                                  label: Text(
                                    exam.status == LabExamStatus.pendiente
                                        ? 'Marcar como Programado'
                                        : (exam.status == LabExamStatus.programado
                                            ? 'Marcar como Completado'
                                            : 'Cambiar Estado'),
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      );
                    }),
                    if (labDocs.isNotEmpty) ...[
                      const SizedBox(height: 20),
                      Text(
                        '📁 Documentos y Exámenes Escaneados (${labDocs.length})',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryBlue,
                        ),
                      ),
                      const SizedBox(height: 10),
                      ...labDocs.map((doc) => Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: const Color(0xFFE2E8F0)),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    color: AppColors.softBlue,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Center(
                                    child: Text(
                                      doc.type == 'PDF' ? '📄' : '📸',
                                      style: const TextStyle(fontSize: 20),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        doc.name,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        '${doc.date} • ${doc.type}',
                                        style: const TextStyle(
                                          color: AppColors.textGray,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          )),
                    ],
                  ],
                ),
        );
      },
    );
  }
}
