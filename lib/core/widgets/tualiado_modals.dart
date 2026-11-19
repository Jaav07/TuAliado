import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import '../services/gemini_service.dart';
import '../services/gemini_vision_service.dart';
import '../../features/medicamentos/domain/models/health_document.dart';
import '../../features/medicamentos/presentation/screens/medicamentos_screen.dart';
import '../../features/laboratorios/presentation/screens/laboratorios_screen.dart';
import '../../features/autorizaciones/presentation/screens/autorizaciones_screen.dart';
import '../../features/agenda/presentation/screens/agenda_screen.dart';
import '../../features/perfil/presentation/screens/perfil_screen.dart';
import '../providers/app_state_provider.dart';
import '../theme/app_theme.dart';

enum DocumentSource { foto, pdf, imagen }

class AnalyzedDocument {
  final String fileName;
  final String targetModule;
  final String extractedDetail;
  final String status;
  final String category;
  final List<MedicationExtract> medications;
  final String? examName;
  final String? examResult;
  final String? examDate;
  final String? examType;
  final String? orderedBy;
  final String? specialty;
  final String? validFrom;
  final String? validUntil;
  final String? appointmentDate;
  final String? appointmentTime;
  final String? appointmentLocation;
  final int pageCount;

  const AnalyzedDocument({
    required this.fileName,
    required this.targetModule,
    required this.extractedDetail,
    required this.status,
    this.category = 'otro',
    this.medications = const [],
    this.examName,
    this.examResult,
    this.examDate,
    this.examType,
    this.orderedBy,
    this.specialty,
    this.validFrom,
    this.validUntil,
    this.appointmentDate,
    this.appointmentTime,
    this.appointmentLocation,
    this.pageCount = 1,
  });
}

/// A qué categorías pertenece un documento analizado, resuelto una sola vez
/// y reutilizado tanto para mostrarlo como para organizarlo.
class _DocFlags {
  final bool isMed;
  final bool isLab;
  final bool isAuth;
  final bool isCita;

  const _DocFlags({
    required this.isMed,
    required this.isLab,
    required this.isAuth,
    required this.isCita,
  });
}

_DocFlags _classify(AnalyzedDocument doc) {
  final isLab = doc.category == 'laboratorio';
  final isAuth = doc.category == 'autorizacion';
  final isCita = doc.category == 'cita';
  final isMed = !isLab &&
      !isAuth &&
      !isCita &&
      (doc.category == 'medicamento' || doc.medications.isNotEmpty);
  return _DocFlags(isMed: isMed, isLab: isLab, isAuth: isAuth, isCita: isCita);
}

String _resolveSpecialty(AnalyzedDocument doc, {required bool isMed}) {
  return (doc.specialty != null && doc.specialty!.trim().isNotEmpty)
      ? doc.specialty!.trim()
      : (isMed ? 'Cardiología' : 'Medicina General');
}

String _categoryEmoji(String category) {
  switch (category) {
    case 'medicamento':
      return '💊';
    case 'laboratorio':
      return '🧪';
    case 'autorizacion':
      return '📋';
    case 'cita':
      return '📅';
    default:
      return '📁';
  }
}

String _categoryLabel(String category) {
  switch (category) {
    case 'medicamento':
      return 'Medicamento';
    case 'laboratorio':
      return 'Laboratorio';
    case 'autorizacion':
      return 'Autorización';
    case 'cita':
      return 'Cita Médica';
    default:
      return 'Documento';
  }
}

/// Organiza un documento analizado en el módulo correspondiente y devuelve
/// una etiqueta legible de a dónde fue a parar (para mostrar un resumen).
String _mergeAnalyzedDocument(AnalyzedDocument doc) {
  final flags = _classify(doc);
  final specialty = _resolveSpecialty(doc, isMed: flags.isMed);
  final title = (doc.examName != null && doc.examName!.trim().isNotEmpty)
      ? doc.examName!.trim()
      : doc.extractedDetail;

  if (flags.isMed) {
    AppStateProvider.instance.mergeMedicationsFromCapture(
      doc.medications,
      documentName: doc.fileName,
      orderedBy: doc.orderedBy,
      specialty: specialty,
    );
    return '💊 Medicamentos';
  } else if (flags.isLab) {
    AppStateProvider.instance.mergeLabExamFromCapture(
      examName: doc.examName ?? 'Examen de Laboratorio',
      orderedBy: doc.orderedBy,
      resultSummary: doc.examResult ?? doc.extractedDetail,
      examType: doc.examType,
      documentName: doc.fileName,
      interpretation: doc.extractedDetail,
      requestedDate: doc.examDate,
    );
    return '🧪 Laboratorios';
  } else if (flags.isAuth) {
    AppStateProvider.instance.mergeAuthorizationFromCapture(
      title: title,
      orderedBy: doc.orderedBy,
      specialty: specialty,
      summary: doc.extractedDetail,
      documentName: doc.fileName,
      requestedDate: doc.examDate,
      validFrom: doc.validFrom,
      validUntil: doc.validUntil,
    );
    return '📋 Autorizaciones';
  } else if (flags.isCita) {
    AppStateProvider.instance.mergeAppointmentFromCapture(
      title: title,
      orderedBy: doc.orderedBy,
      date: doc.appointmentDate ?? doc.examDate,
      time: doc.appointmentTime,
      location: doc.appointmentLocation,
      summary: doc.extractedDetail,
      documentName: doc.fileName,
    );
    return '📅 Citas';
  } else {
    AppStateProvider.instance.addHealthDocument(
      HealthDocument(
        name: doc.fileName,
        date: 'Hoy',
        type: doc.fileName.endsWith('.pdf') ? 'PDF' : 'Imagen',
        targetModule: doc.targetModule,
      ),
    );
    return '📁 Baúl de Perfil';
  }
}

/// Módulo 003: Hoja "Agregar Información con IA"
Future<void> showAddInformationSheet(
  BuildContext context, {
  void Function(AnalyzedDocument doc)? onDocumentAnalyzed,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) {
      return Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
          boxShadow: [
            BoxShadow(
              color: Color(0x26000000),
              blurRadius: 30,
              offset: Offset(0, -6),
            ),
          ],
        ),
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 48,
                height: 48,
                decoration: const BoxDecoration(
                  color: AppColors.primaryBlue,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.add, color: Colors.white, size: 28),
              ),
            ),
            const SizedBox(height: 14),
            const Text(
              'Agregar Información con IA',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.primaryBlue,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Toma foto (1 o más páginas), selecciona de galería o sube PDF para clasificar con IA.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: AppColors.textGray),
            ),
            const SizedBox(height: 24),
            _ModalOption(
              icon: Icons.camera_alt_outlined,
              label: 'Tomar foto (1 o varias páginas)',
              onTap: () => _handleSourceSelected(
                context,
                sheetContext,
                DocumentSource.foto,
              ),
            ),
            _ModalOption(
              icon: Icons.image_outlined,
              label: 'Seleccionar imagen(es) de galería',
              onTap: () => _handleSourceSelected(
                context,
                sheetContext,
                DocumentSource.imagen,
              ),
            ),
            _ModalOption(
              icon: Icons.picture_as_pdf_outlined,
              label: 'Adjuntar PDF',
              onTap: () => _handleSourceSelected(
                context,
                sheetContext,
                DocumentSource.pdf,
              ),
            ),
            _ModalOption(
              icon: Icons.chat_bubble_outline,
              label: 'Preguntar a TuAliado (IA)',
              onTap: () {
                Navigator.of(sheetContext).pop();
                showTuAliadoChat(context);
              },
            ),
            const SizedBox(height: 8),
            Center(
              child: TextButton(
                onPressed: () => Navigator.of(sheetContext).pop(),
                child: const Text('Cancelar'),
              ),
            ),
          ],
        ),
      );
    },
  );
}

Future<void> _handleSourceSelected(
  BuildContext context,
  BuildContext sheetContext,
  DocumentSource source,
) async {
  Navigator.of(sheetContext).pop();
  final List<DocumentFilePayload> payloads = [];

  try {
    switch (source) {
      case DocumentSource.foto:
        final photo = await ImagePicker().pickImage(
          source: ImageSource.camera,
          imageQuality: 85,
          maxWidth: 1600,
          maxHeight: 1600,
        );
        if (photo != null) {
          final bytes = await photo.readAsBytes();
          payloads.add(
            DocumentFilePayload(
              fileName: photo.name,
              bytes: bytes,
              mimeType: 'image/jpeg',
            ),
          );

          // Preguntar si hay una página/documento adicional
          bool addingMore = true;
          int pageNum = 2;
          while (addingMore && payloads.length < 5) {
            if (!context.mounted) break;
            final addAnother = await showDialog<bool>(
              context: context,
              builder: (c) => AlertDialog(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20)),
                title: Row(
                  children: [
                    const Icon(Icons.photo_library,
                        color: AppColors.primaryBlue),
                    const SizedBox(width: 8),
                    Text('Página ${payloads.length} lista'),
                  ],
                ),
                content: Text(
                    '¿Deseas tomar la foto a la página $pageNum? (Si es un documento distinto, tranquilo: la IA lo va a separar y clasificar por su cuenta).'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(c).pop(false),
                    child: Text(
                        'No, Analizar (${payloads.length} ${payloads.length > 1 ? "páginas" : "página"})'),
                  ),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryBlue,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () => Navigator.of(c).pop(true),
                    icon: const Icon(Icons.camera_alt, size: 16),
                    label: Text('Tomar Página $pageNum'),
                  ),
                ],
              ),
            );

            if (addAnother == true) {
              final nextPhoto = await ImagePicker().pickImage(
                source: ImageSource.camera,
                imageQuality: 85,
                maxWidth: 1600,
                maxHeight: 1600,
              );
              if (nextPhoto != null) {
                final nextBytes = await nextPhoto.readAsBytes();
                payloads.add(
                  DocumentFilePayload(
                    fileName: nextPhoto.name,
                    bytes: nextBytes,
                    mimeType: 'image/jpeg',
                  ),
                );
                pageNum++;
              } else {
                addingMore = false;
              }
            } else {
              addingMore = false;
            }
          }
        }
        break;

      case DocumentSource.imagen:
        final images = await ImagePicker().pickMultiImage(
          imageQuality: 85,
          maxWidth: 1600,
          maxHeight: 1600,
        );
        if (images.isNotEmpty) {
          for (final img in images) {
            final bytes = await img.readAsBytes();
            payloads.add(
              DocumentFilePayload(
                fileName: img.name,
                bytes: bytes,
                mimeType: img.name.toLowerCase().endsWith('.png')
                    ? 'image/png'
                    : 'image/jpeg',
              ),
            );
          }
        } else {
          final singleImg = await ImagePicker().pickImage(
            source: ImageSource.gallery,
            imageQuality: 85,
            maxWidth: 1600,
            maxHeight: 1600,
          );
          if (singleImg != null) {
            final bytes = await singleImg.readAsBytes();
            payloads.add(
              DocumentFilePayload(
                fileName: singleImg.name,
                bytes: bytes,
                mimeType: singleImg.name.toLowerCase().endsWith('.png')
                    ? 'image/png'
                    : 'image/jpeg',
              ),
            );
          }
        }
        break;

      case DocumentSource.pdf:
        final result = await FilePicker.platform.pickFiles(
          type: FileType.custom,
          allowedExtensions: ['pdf'],
          withData: true,
          allowMultiple: true,
        );
        if (result != null && result.files.isNotEmpty) {
          for (final file in result.files) {
            if (file.bytes != null) {
              payloads.add(
                DocumentFilePayload(
                  fileName: file.name,
                  bytes: file.bytes!,
                  mimeType: 'application/pdf',
                ),
              );
            }
          }
        }
        break;
    }
  } catch (_) {
    payloads.clear();
  }

  if (payloads.isEmpty || !context.mounted) return;

  showTuAliadoAnalysis(
    context,
    payloads: payloads,
  ).then((analyzedDocs) {
    if (analyzedDocs != null && analyzedDocs.isNotEmpty && context.mounted) {
      if (analyzedDocs.length == 1) {
        showAiResultBreakdownDialog(context, analyzedDoc: analyzedDocs.first);
      } else {
        showAiMultiResultBreakdownDialog(context, analyzedDocs: analyzedDocs);
      }
    }
  });
}

/// Diálogo interactivo con desglose de IA para confirmar y organizar datos automáticamente
/// (caso de UN solo documento detectado).
void showAiResultBreakdownDialog(
  BuildContext context, {
  required AnalyzedDocument analyzedDoc,
}) {
  final flags = _classify(analyzedDoc);
  final isLab = flags.isLab;
  final isAuth = flags.isAuth;
  final isCita = flags.isCita;
  final isMed = flags.isMed;
  final detectedSpecialty = _resolveSpecialty(analyzedDoc, isMed: isMed);

  showDialog<void>(
    context: context,
    builder: (dialogCtx) {
      return Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(dialogCtx).size.height * 0.85,
          ),
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(22.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [AppColors.primaryBlue, AppColors.cyanMedic],
                        ),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Text(
                        '✨ TuAliado IA • ${analyzedDoc.pageCount > 1 ? "${analyzedDoc.pageCount} Páginas Analizadas" : "Documento Analizado"}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    analyzedDoc.fileName,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryBlue,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.softBlue,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Column(
                      children: [
                        _buildRow('Módulo destino:', analyzedDoc.targetModule),
                        if (isMed) ...[
                          const Divider(height: 14),
                          _buildRow(
                              'Especialidad detectada:', detectedSpecialty,
                              color: AppColors.primaryBlue),
                        ],
                        if (isLab && analyzedDoc.examName != null) ...[
                          const Divider(height: 14),
                          _buildRow('Examen:', analyzedDoc.examName!),
                          if (analyzedDoc.examType != null) ...[
                            const Divider(height: 14),
                            _buildRow(
                                'Tipo de Estudio:', analyzedDoc.examType!),
                          ],
                        ],
                        if (isAuth) ...[
                          if (analyzedDoc.examName != null) ...[
                            const Divider(height: 14),
                            _buildRow('Trámite:', analyzedDoc.examName!),
                          ],
                          const Divider(height: 14),
                          _buildRow('Especialidad:', detectedSpecialty,
                              color: AppColors.primaryBlue),
                          if ((analyzedDoc.validFrom != null &&
                                  analyzedDoc.validFrom!.trim().isNotEmpty) ||
                              (analyzedDoc.validUntil != null &&
                                  analyzedDoc.validUntil!
                                      .trim()
                                      .isNotEmpty)) ...[
                            const Divider(height: 14),
                            _buildRow(
                              'Vigencia:',
                              '${(analyzedDoc.validFrom?.trim().isNotEmpty ?? false) ? analyzedDoc.validFrom : "—"} → ${(analyzedDoc.validUntil?.trim().isNotEmpty ?? false) ? analyzedDoc.validUntil : "sin caducidad"}',
                              color: const Color(0xFFB45309),
                            ),
                          ],
                        ],
                        if (isCita) ...[
                          if (analyzedDoc.examName != null) ...[
                            const Divider(height: 14),
                            _buildRow('Motivo:', analyzedDoc.examName!),
                          ],
                          if (analyzedDoc.appointmentDate != null &&
                              analyzedDoc.appointmentDate!
                                  .trim()
                                  .isNotEmpty) ...[
                            const Divider(height: 14),
                            _buildRow('Fecha:', analyzedDoc.appointmentDate!),
                          ],
                          if (analyzedDoc.appointmentTime != null &&
                              analyzedDoc.appointmentTime!
                                  .trim()
                                  .isNotEmpty) ...[
                            const Divider(height: 14),
                            _buildRow('Hora:', analyzedDoc.appointmentTime!),
                          ],
                          if (analyzedDoc.appointmentLocation != null &&
                              analyzedDoc.appointmentLocation!
                                  .trim()
                                  .isNotEmpty) ...[
                            const Divider(height: 14),
                            _buildRow(
                                'Lugar:', analyzedDoc.appointmentLocation!),
                          ],
                        ],
                        const Divider(height: 14),
                        _buildRow(
                            'Detalle extraído:', analyzedDoc.extractedDetail),
                        if (analyzedDoc.orderedBy != null &&
                            analyzedDoc.orderedBy!.trim().isNotEmpty) ...[
                          const Divider(height: 14),
                          _buildRow('Médico tratante:', analyzedDoc.orderedBy!),
                        ],
                        const Divider(height: 14),
                        _buildRow('Estado:', analyzedDoc.status,
                            color: const Color(0xFF16A34A)),
                      ],
                    ),
                  ),

                  // Lista de todos los medicamentos extraídos por la IA de Google (soporte de 6 o más)
                  if (isMed && analyzedDoc.medications.isNotEmpty) ...[
                    const SizedBox(height: 14),
                    Text(
                      '💊 Medicamentos extraídos por la IA (${analyzedDoc.medications.length}):',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primaryBlue,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...analyzedDoc.medications.map((m) => Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Padding(
                                padding: EdgeInsets.only(top: 2),
                                child: Icon(Icons.check_circle,
                                    size: 16, color: Color(0xFF16A34A)),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '${m.name} - ${m.dosage ?? m.frequency ?? "Según fórmula"}',
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF1E293B),
                                      ),
                                    ),
                                    if (m.purpose != null &&
                                        m.purpose!.trim().isNotEmpty)
                                      Text(
                                        '💡 ${m.purpose}',
                                        style: const TextStyle(
                                            fontSize: 11,
                                            color: AppColors.textGray),
                                      ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        )),
                  ],

                  if (isLab &&
                      analyzedDoc.examResult != null &&
                      analyzedDoc.examResult!.trim().isNotEmpty) ...[
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '🧪 Resultados y Hallazgos (IA):',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primaryBlue,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            analyzedDoc.examResult!,
                            style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFF334155),
                                height: 1.3),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryBlue,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () {
                        Navigator.of(dialogCtx).pop();
                        _mergeAnalyzedDocument(analyzedDoc);

                        Widget screen;
                        if (isMed) {
                          screen = const MedicamentosScreen();
                        } else if (isLab) {
                          screen = const LaboratoriosScreen();
                        } else if (isAuth) {
                          screen = const AutorizacionesScreen();
                        } else if (isCita) {
                          screen = const AgendaScreen();
                        } else {
                          screen = const PerfilScreen();
                        }

                        Navigator.of(context).push(
                          MaterialPageRoute<void>(builder: (_) => screen),
                        );
                      },
                      child: Text(
                          '✅ Confirmar y Organizar en ${analyzedDoc.targetModule}'),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () => Navigator.of(dialogCtx).pop(),
                    child: const Text('Cancelar',
                        style: TextStyle(color: AppColors.textGray)),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    },
  );
}

/// Diálogo cuando la IA detecta VARIOS documentos distintos en la misma
/// captura (ej. el usuario tomó fotos de una cita, una autorización y varias
/// órdenes seguidas). Muestra cada uno clasificado y los organiza todos de
/// una sola vez.
void showAiMultiResultBreakdownDialog(
  BuildContext context, {
  required List<AnalyzedDocument> analyzedDocs,
}) {
  showDialog<void>(
    context: context,
    builder: (dialogCtx) {
      return Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(dialogCtx).size.height * 0.85,
          ),
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(22.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [AppColors.primaryBlue, AppColors.cyanMedic],
                        ),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Text(
                        '✨ TuAliado IA • ${analyzedDocs.length} Documentos Detectados',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Detectamos varios documentos distintos en tus fotos y ya los separamos. Revisa que cada uno quedó bien clasificado antes de organizarlos.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontSize: 12, color: AppColors.textGray, height: 1.3),
                  ),
                  const SizedBox(height: 16),
                  ...analyzedDocs.map((doc) {
                    final flags = _classify(doc);
                    final specialty =
                        _resolveSpecialty(doc, isMed: flags.isMed);
                    final title = (doc.examName != null &&
                            doc.examName!.trim().isNotEmpty)
                        ? doc.examName!.trim()
                        : doc.extractedDetail;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.softBlue,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(_categoryEmoji(doc.category),
                              style: const TextStyle(fontSize: 22)),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _categoryLabel(doc.category),
                                  style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.primaryBlue),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  title,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF1E293B)),
                                ),
                                if (doc.orderedBy != null &&
                                    doc.orderedBy!.trim().isNotEmpty)
                                  Text(doc.orderedBy!,
                                      style: const TextStyle(
                                          fontSize: 11,
                                          color: AppColors.textGray)),
                                if (flags.isMed || flags.isAuth)
                                  Text(specialty,
                                      style: const TextStyle(
                                          fontSize: 11,
                                          color: AppColors.textGray)),
                                if (flags.isCita &&
                                    doc.appointmentDate != null &&
                                    doc.appointmentDate!.trim().isNotEmpty)
                                  Text(
                                    '${doc.appointmentDate}${(doc.appointmentTime?.trim().isNotEmpty ?? false) ? " • ${doc.appointmentTime}" : ""}',
                                    style: const TextStyle(
                                        fontSize: 11,
                                        color: AppColors.textGray),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryBlue,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () {
                        Navigator.of(dialogCtx).pop();
                        final counts = <String, int>{};
                        for (final doc in analyzedDocs) {
                          final dest = _mergeAnalyzedDocument(doc);
                          counts[dest] = (counts[dest] ?? 0) + 1;
                        }
                        final summary = counts.entries
                            .map((e) => '${e.value} en ${e.key}')
                            .join(', ');
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                              content: Text(
                                  '✅ Se organizaron ${analyzedDocs.length} documentos: $summary')),
                        );
                      },
                      child: Text(
                          '✅ Confirmar y Organizar los ${analyzedDocs.length} Documentos'),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () => Navigator.of(dialogCtx).pop(),
                    child: const Text('Cancelar',
                        style: TextStyle(color: AppColors.textGray)),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    },
  );
}

Widget _buildRow(String label, String value, {Color? color}) {
  return Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Expanded(
        flex: 3,
        child: Text(label,
            style: const TextStyle(
                fontSize: 13,
                color: AppColors.textGray,
                fontWeight: FontWeight.w500)),
      ),
      const SizedBox(width: 8),
      Expanded(
        flex: 4,
        child: Text(
          value,
          textAlign: TextAlign.end,
          style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: color ?? AppColors.primaryBlue),
        ),
      ),
    ],
  );
}

/// Módulo 004: Overlay de análisis con la IA.
/// Devuelve la lista de documentos distintos que la IA detectó en la captura
/// (normalmente 1, pero puede ser más si el usuario fotografió varios juntos).
Future<List<AnalyzedDocument>?> showTuAliadoAnalysis(
  BuildContext context, {
  required List<DocumentFilePayload> payloads,
}) {
  return showDialog<List<AnalyzedDocument>>(
    context: context,
    barrierDismissible: false,
    builder: (_) => _AnalysisOverlay(payloads: payloads),
  );
}

class _ModalOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ModalOption(
      {required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.softBlue,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: AppColors.primaryBlue, size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    label,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                ),
                const Icon(Icons.arrow_forward_ios,
                    size: 14, color: AppColors.textGray),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AnalysisOverlay extends StatefulWidget {
  final List<DocumentFilePayload> payloads;

  const _AnalysisOverlay({required this.payloads});

  @override
  State<_AnalysisOverlay> createState() => _AnalysisOverlayState();
}

class _AnalysisOverlayState extends State<_AnalysisOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _spinController;

  @override
  void initState() {
    super.initState();
    _spinController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
    _runAnalysis();
  }

  Future<void> _runAnalysis() async {
    final existingExams = AppStateProvider.instance.labExams;
    String? labsContext;
    if (existingExams.isNotEmpty) {
      final lines = existingExams.take(8).map((e) {
        final result =
            (e.resultSummary != null && e.resultSummary!.trim().isNotEmpty)
                ? e.resultSummary
                : 'sin resultados registrados';
        return '- ${e.name} (${e.requestedDate}): $result';
      }).join('\n');
      labsContext = lines;
    }
    final results = await GeminiVisionService.analyzeDocuments(
      files: widget.payloads,
      previousLabsContext: labsContext,
    );
    if (!mounted) return;

    final displayNameBase = widget.payloads.length > 1
        ? '${widget.payloads.first.fileName} (+${widget.payloads.length - 1} páginas)'
        : widget.payloads.first.fileName;
    final isBatch = results.length > 1;

    final analyzedDocs = results.map((result) {
      final isLab = result.category == 'laboratorio';
      final isAuth = result.category == 'autorizacion';
      final isCita = result.category == 'cita';
      final isMed = !isLab &&
          !isAuth &&
          !isCita &&
          (result.category == 'medicamento' || result.medications.isNotEmpty);

      String module;
      String status;
      if (isMed) {
        module = '💊 Medicamentos';
        status = 'Listo para registrar';
      } else if (isLab) {
        module = '🧪 Laboratorios';
        status = 'Listo para registrar';
      } else if (isAuth) {
        module = '📋 Autorizaciones';
        status = 'Procesado';
      } else if (isCita) {
        module = '📅 Citas';
        status = 'Detectada';
      } else {
        module = '📁 Baúl de Perfil';
        status = 'Guardado';
      }

      final category = isMed
          ? 'medicamento'
          : (isLab
              ? 'laboratorio'
              : (isAuth
                  ? 'autorizacion'
                  : (isCita ? 'cita' : result.category)));

      // Cuando se detectan varios documentos, usa el título de cada uno como
      // nombre para diferenciarlos; con un solo documento, mantiene el
      // nombre real del archivo/foto como antes.
      final displayName = isBatch
          ? ((result.examName != null && result.examName!.trim().isNotEmpty)
              ? result.examName!.trim()
              : displayNameBase)
          : displayNameBase;

      return AnalyzedDocument(
        fileName: displayName,
        targetModule: module,
        extractedDetail: result.summary,
        status: status,
        category: category,
        medications: result.medications,
        examName: result.examName,
        examResult: result.examResult,
        examDate: result.examDate,
        examType: result.examType,
        orderedBy: result.orderedBy,
        specialty: result.specialty,
        validFrom: result.validFrom,
        validUntil: result.validUntil,
        appointmentDate: result.appointmentDate,
        appointmentTime: result.appointmentTime,
        appointmentLocation: result.appointmentLocation,
        pageCount: widget.payloads.length,
      );
    }).toList();

    Navigator.of(context).pop(analyzedDocs);
  }

  @override
  void dispose() {
    _spinController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pagesText = widget.payloads.length > 1
        ? ' (${widget.payloads.length} páginas)'
        : '';

    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: AppColors.primaryBlue,
          borderRadius: BorderRadius.circular(28),
          boxShadow: const [
            BoxShadow(
              color: Color(0x33000000),
              blurRadius: 30,
              offset: Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RotationTransition(
              turns: _spinController,
              child: Container(
                width: 72,
                height: 72,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Text('✨', style: TextStyle(fontSize: 32)),
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Analizando con TuAliado IA...',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Extrayendo datos de "${widget.payloads.first.fileName}"$pagesText y separando/clasificando automáticamente en tu perfil de salud...',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.softBlue,
                fontSize: 13,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Módulo 002: Modal de Chat con TuAliado IA
Future<void> showTuAliadoChat(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => const _TuAliadoChatModal(),
  );
}

class _TuAliadoChatModal extends StatefulWidget {
  const _TuAliadoChatModal();

  @override
  State<_TuAliadoChatModal> createState() => _TuAliadoChatModalState();
}

class _TuAliadoChatModalState extends State<_TuAliadoChatModal> {
  final TextEditingController _controller = TextEditingController();
  final List<_ChatMessage> _messages = [];
  bool _isTyping = false;

  @override
  void initState() {
    super.initState();
    _messages.add(
      const _ChatMessage(
        text:
            '¡Hola! Soy TuAliado IA. ¿En qué puedo acompañarte hoy con tu salud?',
        isTuAliado: true,
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _sendMessage(String text) async {
    if (text.trim().isEmpty) return;
    _controller.clear();

    setState(() {
      _messages.add(_ChatMessage(text: text, isTuAliado: false));
      _isTyping = true;
    });

    final lower = text.toLowerCase();
    String? actionModule;
    if (lower.contains('medicamento') ||
        lower.contains('remedio') ||
        lower.contains('pastilla') ||
        lower.contains('dosis')) {
      actionModule = 'meds';
    } else if (lower.contains('autorizaci') ||
        lower.contains('eps') ||
        lower.contains('orden')) {
      actionModule = 'auth';
    } else if (lower.contains('cita') || lower.contains('agenda')) {
      actionModule = 'cita';
    } else if (lower.contains('examen') ||
        lower.contains('laboratorio') ||
        lower.contains('sangre') ||
        lower.contains('rx')) {
      actionModule = 'lab';
    }

    final history = _messages
        .take(_messages.length - 1)
        .map((m) => {
              'role': m.isTuAliado ? 'model' : 'user',
              'text': m.text,
            })
        .toList();

    final aiReply = await GeminiService.sendMessage(
      userMessage: text,
      history: history,
    );

    if (!mounted) return;
    setState(() {
      _isTyping = false;
      _messages.add(
        _ChatMessage(
          text:
              aiReply ?? 'No pude responder en este momento. Intenta de nuevo.',
          isTuAliado: true,
          actionModule: actionModule,
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final bottomInset = mediaQuery.viewInsets.bottom;
    final systemBottomPadding = mediaQuery.viewPadding.bottom > 0
        ? mediaQuery.viewPadding.bottom
        : mediaQuery.padding.bottom;

    // Si el teclado está abierto, el Padding exterior de la vista ya lo eleva.
    // Si el teclado está cerrado, agregamos un margen generoso que despeje
    // completamente los 3 botones de navegación del sistema Android.
    final double bottomMargin = bottomInset > 0
        ? 12.0
        : math.max(systemBottomPadding + 20.0, 44.0);

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Container(
        height: mediaQuery.size.height * 0.85,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: const BoxDecoration(
                color: AppColors.primaryBlue,
                borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
              ),
              child: Row(
                children: [
                  const Text('💬', style: TextStyle(fontSize: 22)),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Asistente TuAliado IA',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          'En línea • Te acompaña',
                          style: TextStyle(
                              color: AppColors.softBlue, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _messages.length + (_isTyping ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index == _messages.length) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 6),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: SizedBox(
                          width: 40,
                          height: 24,
                          child: Center(
                            child: SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.primaryBlue,
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  }
                  return _messages[index];
                },
              ),
            ),
            if (_messages.length <= 1)
              Container(
                height: 38,
                margin: const EdgeInsets.only(bottom: 10),
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    _buildSuggestionChip('¿Presión normal es cuánto?'),
                    const SizedBox(width: 8),
                    _buildSuggestionChip('¿Para qué sirve el Losartán?'),
                    const SizedBox(width: 8),
                    _buildSuggestionChip('Revisar mis autorizaciones'),
                    const SizedBox(width: 8),
                    _buildSuggestionChip('Consejo de alimentación hoy'),
                  ],
                ),
              ),
            Container(
              padding: EdgeInsets.fromLTRB(16, 12, 16, bottomMargin),
              decoration: const BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Color(0x0F000000),
                    blurRadius: 10,
                    offset: Offset(0, -3),
                  ),
                ],
                border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      decoration: InputDecoration(
                        hintText: 'Escribe tu consulta de salud...',
                        hintStyle: const TextStyle(
                            color: AppColors.textGray, fontSize: 14),
                        prefixIcon: const Icon(
                          Icons.chat_bubble_outline_rounded,
                          color: AppColors.primaryBlue,
                          size: 20,
                        ),
                        filled: true,
                        fillColor: const Color(0xFFF1F5F9),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(26),
                          borderSide:
                              const BorderSide(color: Color(0xFFCBD5E1), width: 1.2),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(26),
                          borderSide:
                              const BorderSide(color: Color(0xFFCBD5E1), width: 1.2),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(26),
                          borderSide:
                              const BorderSide(color: AppColors.primaryBlue, width: 1.8),
                        ),
                      ),
                      onSubmitted: _sendMessage,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    width: 46,
                    height: 46,
                    decoration: const BoxDecoration(
                      color: AppColors.primaryBlue,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Color(0x330066FF),
                          blurRadius: 8,
                          offset: Offset(0, 3),
                        ),
                      ],
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.send_rounded,
                          color: Colors.white, size: 20),
                      onPressed: () => _sendMessage(_controller.text),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuggestionChip(String text) {
    return ActionChip(
      label: Text(
        text,
        style: const TextStyle(
          color: AppColors.primaryBlue,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
      backgroundColor: const Color(0xFFEFF6FF),
      side: const BorderSide(color: Color(0xFFBFDBFE)),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      onPressed: () {
        _controller.text = text;
        _sendMessage(text);
      },
    );
  }
}

class _ChatMessage extends StatelessWidget {
  final String text;
  final bool isTuAliado;
  final String? actionModule;

  const _ChatMessage({
    required this.text,
    required this.isTuAliado,
    this.actionModule,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment:
            isTuAliado ? CrossAxisAlignment.start : CrossAxisAlignment.end,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color:
                  isTuAliado ? const Color(0xFFF1F5F9) : AppColors.primaryBlue,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Text(
              text,
              style: TextStyle(
                color: isTuAliado ? const Color(0xFF1E293B) : Colors.white,
                fontSize: 14,
                height: 1.4,
              ),
            ),
          ),
          if (actionModule != null) ...[
            const SizedBox(height: 6),
            InkWell(
              onTap: () {
                Navigator.of(context).pop();
                if (actionModule == 'meds') {
                  Navigator.of(context).push(MaterialPageRoute<void>(
                      builder: (_) => const MedicamentosScreen()));
                } else if (actionModule == 'lab') {
                  Navigator.of(context).push(MaterialPageRoute<void>(
                      builder: (_) => const LaboratoriosScreen()));
                } else if (actionModule == 'auth') {
                  Navigator.of(context).push(MaterialPageRoute<void>(
                      builder: (_) => const AutorizacionesScreen()));
                } else if (actionModule == 'cita') {
                  Navigator.of(context).push(MaterialPageRoute<void>(
                      builder: (_) => const AgendaScreen()));
                }
              },
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.softBlue,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  actionModule == 'meds'
                      ? '👉 Ir a 💊 Medicamentos'
                      : (actionModule == 'lab'
                          ? '👉 Ir a 🧪 Laboratorios'
                          : (actionModule == 'auth'
                              ? '👉 Ir a 📋 Autorizaciones'
                              : (actionModule == 'cita'
                                  ? '👉 Ir a 📅 Citas'
                                  : '👉 Ir al Baúl'))),
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryBlue,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
