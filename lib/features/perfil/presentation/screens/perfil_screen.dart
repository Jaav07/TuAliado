import 'package:flutter/material.dart';
import '../../../../core/providers/app_state_provider.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../main.dart';
import '../../../medicamentos/domain/models/health_document.dart';
import '../../data/pdf_export_service.dart';
import '../../domain/models/patient_profile.dart';

class PerfilScreen extends StatefulWidget {
  final VoidCallback? onAppReset;

  const PerfilScreen({
    super.key,
    this.onAppReset,
  });

  @override
  State<PerfilScreen> createState() => _PerfilScreenState();
}

class _PerfilScreenState extends State<PerfilScreen> {
  bool _exporting = false;

  PatientProfile get _profile =>
      AppStateProvider.instance.profile ??
      const PatientProfile(
        name: 'Jorge Aguirre',
        age: 55,
        gender: 'Masculino',
        email: 'jaav07@gmail.com',
        rh: 'O Rh+',
        eps: 'Sanidad Militar',
        document: '1.234.567.890',
        primaryGoal:
            'Controlar mi salud integral y mantener hábitos saludables.',
      );

  List<HealthDocument> get _documents => AppStateProvider.instance.documents;

  Future<void> _exportHealthReport() async {
    setState(() => _exporting = true);

    try {
      final service = PdfExportService();
      final path = await service.exportarHistoriaClinica(
        profile: _profile,
        medications: AppStateProvider.instance.medications,
        documents: _documents,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Reporte exportado con éxito en: $path'),
            backgroundColor: const Color(0xFF15803D),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Nota sobre reporte: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _exporting = false);
      }
    }
  }

  void _confirmAndResetApp() {
    showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.red, size: 28),
            SizedBox(width: 10),
            Text('Restablecer Registro',
                style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        content: const Text(
          '¿Estás seguro de que deseas restablecer tu perfil e iniciar el registro nuevamente?\n\n'
          'Esta acción borrará tus datos guardados en el dispositivo.',
          style: TextStyle(height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancelar',
                style: TextStyle(color: AppColors.textGray)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Sí, Restablecer'),
          ),
        ],
      ),
    ).then((confirmed) async {
      if (confirmed == true && mounted) {
        await AppStateProvider.instance.resetApp();
        if (mounted) {
          Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
            MaterialPageRoute<void>(
                builder: (_) => const MainNavigationWrapper()),
            (route) => false,
          );
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final initials = _profile.name.isNotEmpty
        ? _profile.name
            .trim()
            .split(' ')
            .map((e) => e[0])
            .take(2)
            .join('')
            .toUpperCase()
        : 'JA';

    return Scaffold(
      backgroundColor: AppColors.warmCream,
      appBar: AppBar(
        title: const Text('Mi Perfil de Salud'),
        backgroundColor: AppColors.deepTeal,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Cabecera con avatar e información personal del registro
              Card(
                elevation: 3,
                shadowColor: AppColors.shadowBlue,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20)),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 36,
                        backgroundColor: AppColors.softBlue,
                        child: Text(
                          initials,
                          style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: AppColors.deepTeal),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _profile.name,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            fontSize: 22, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '📧 ${_profile.email}',
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            color: AppColors.deepTeal,
                            fontWeight: FontWeight.w600,
                            fontSize: 14),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'EPS: ${_profile.eps}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            color: AppColors.textGray, fontSize: 14),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Tarjeta de detalles del registro inicial
              Card(
                elevation: 3,
                shadowColor: AppColors.shadowBlue,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20)),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildInfoLine('Edad', '${_profile.age} años'),
                      const Divider(height: 24),
                      _buildInfoLine('Sexo', _profile.gender),
                      const Divider(height: 24),
                      _buildInfoLine('Factor Rh', _profile.rh),
                      const Divider(height: 24),
                      _buildInfoLine('Documento', _profile.document),
                      const Divider(height: 24),
                      _buildInfoLine('E-mail', _profile.email),
                      const SizedBox(height: 16),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.softBlue,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '🎯 Objetivo: ${_profile.primaryGoal}',
                          style: const TextStyle(
                              fontSize: 13,
                              color: AppColors.deepTeal,
                              fontStyle: FontStyle.italic),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Botones de exportación y reseteo
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: _exporting ? null : _exportHealthReport,
                  icon: const Icon(Icons.picture_as_pdf),
                  label: Text(_exporting
                      ? 'Generando PDF...'
                      : '📄 Exportar Historia Clínica (PDF)'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.deepTeal,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
              const SizedBox(height: 10),

              SizedBox(
                width: double.infinity,
                height: 48,
                child: OutlinedButton.icon(
                  onPressed: _confirmAndResetApp,
                  icon: const Icon(Icons.restart_alt, color: Color(0xFF64748B)),
                  label: const Text('🔄 Restablecer Registro Inicial',
                      style: TextStyle(
                          color: Color(0xFF64748B),
                          fontWeight: FontWeight.bold)),
                  style: OutlinedButton.styleFrom(
                    side:
                        const BorderSide(color: Color(0xFFCBD5E1), width: 1.5),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),

              const SizedBox(height: 24),
              Text(
                '📁 Baúl de Documentos (${_documents.length})',
                style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.deepTeal),
              ),
              const SizedBox(height: 10),
              ..._documents.map(_buildDocumentTile),
            ],
          ),
        ),
      ),
    );
  }

  // Fila label (izquierda) + valor (derecha, puede envolver a varias líneas
  // y nunca se corta sin importar qué tan largo sea el valor).
  Widget _buildInfoLine(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 100,
          child: Text(label,
              style: const TextStyle(fontSize: 13, color: AppColors.textGray)),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1A1C1E)),
          ),
        ),
      ],
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
              style: const TextStyle(fontSize: 24)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  doc.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                Text(
                  '${doc.date} • ${doc.targetModule}',
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
