import 'package:flutter/material.dart';
import '../../../../core/providers/app_state_provider.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/models/medical_appointment.dart';

class AgendaScreen extends StatefulWidget {
  const AgendaScreen({super.key});

  @override
  State<AgendaScreen> createState() => _AgendaScreenState();
}

class _AgendaScreenState extends State<AgendaScreen> {
  static const _months = [
    'Ene',
    'Feb',
    'Mar',
    'Abr',
    'May',
    'Jun',
    'Jul',
    'Ago',
    'Sep',
    'Oct',
    'Nov',
    'Dic'
  ];

  Future<void> _addAppointment() async {
    final doctorController = TextEditingController();
    final specialtyController = TextEditingController();
    final locationController = TextEditingController();

    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date == null || !mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 9, minute: 0),
    );
    if (time == null || !mounted) return;

    final fullDate =
        DateTime(date.year, date.month, date.day, time.hour, time.minute);

    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Nueva Cita Medica'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: doctorController,
              decoration: const InputDecoration(labelText: 'Nombre del medico'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: specialtyController,
              decoration: const InputDecoration(labelText: 'Especialidad'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: locationController,
              decoration: const InputDecoration(labelText: 'Lugar'),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () {
              if (doctorController.text.trim().isEmpty) return;
              AppStateProvider.instance.addAppointment(
                MedicalAppointment(
                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                  doctorName: doctorController.text.trim(),
                  specialty: specialtyController.text.trim().isEmpty
                      ? 'General'
                      : specialtyController.text.trim(),
                  date: fullDate,
                  location: locationController.text.trim().isEmpty
                      ? 'Por confirmar'
                      : locationController.text.trim(),
                ),
              );
              Navigator.of(ctx).pop();
            },
            child: const Text('Agendar'),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final hour =
        date.hour > 12 ? date.hour - 12 : (date.hour == 0 ? 12 : date.hour);
    final period = date.hour >= 12 ? 'PM' : 'AM';
    final minute = date.minute.toString().padLeft(2, '0');
    return '${date.day} ${_months[date.month - 1]} ${date.year} - $hour:$minute $period';
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: AppStateProvider.instance,
      builder: (context, _) {
        final sorted = List<MedicalAppointment>.from(
            AppStateProvider.instance.appointments)
          ..sort((a, b) => a.date.compareTo(b.date));

        return Scaffold(
          backgroundColor: AppColors.warmCream,
          appBar: AppBar(
            title: const Text('Agenda Medica'),
            backgroundColor: AppColors.deepTeal,
            foregroundColor: Colors.white,
            elevation: 0,
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: _addAppointment,
            backgroundColor: AppColors.deepTeal,
            child: const Icon(Icons.add),
          ),
          body: sorted.isEmpty
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: Text(
                      'No tienes citas próximas.\n\nUsa el botón "+" para agendar una manualmente, o toma foto de la confirmación de tu cita médica.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          color: AppColors.textGray, fontSize: 14, height: 1.5),
                    ),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(20),
                  itemCount: sorted.length,
                  itemBuilder: (context, index) {
                    final appt = sorted[index];
                    return Dismissible(
                      key: ValueKey(appt.id),
                      direction: DismissDirection.endToStart,
                      onDismissed: (_) =>
                          AppStateProvider.instance.deleteAppointment(appt.id),
                      background: Container(
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 24),
                        margin: const EdgeInsets.only(bottom: 12),
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
                            borderRadius: BorderRadius.circular(16)),
                        margin: const EdgeInsets.only(bottom: 12),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: AppColors.softBlue,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Column(
                                  children: [
                                    Text('${appt.date.day}',
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 18,
                                            color: AppColors.deepTeal)),
                                    Text(_months[appt.date.month - 1],
                                        style: const TextStyle(
                                            fontSize: 11,
                                            color: AppColors.deepTeal)),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(appt.doctorName,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 15)),
                                    const SizedBox(height: 2),
                                    Text(appt.specialty,
                                        style: const TextStyle(
                                            color: AppColors.textGray,
                                            fontSize: 13)),
                                    const SizedBox(height: 6),
                                    Text(_formatDate(appt.date),
                                        style: const TextStyle(
                                            fontSize: 12,
                                            color: AppColors.deepTeal,
                                            fontWeight: FontWeight.w600)),
                                    const SizedBox(height: 2),
                                    Text(appt.location,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                            fontSize: 12,
                                            color: AppColors.textGray)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
        );
      },
    );
  }
}
