import 'dart:io';
import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';

import '../../medicamentos/domain/models/health_document.dart';
import '../../medicamentos/domain/models/medication.dart';
import '../domain/models/patient_profile.dart';

/// Servicio de exportación de la Historia Clínica consolidada a un PDF real
/// (Módulo 012). Genera un archivo PDF con formato profesional (encabezado
/// TuAliado, datos del paciente, medicamentos activos y baúl documental) y
/// lo guarda en el directorio de documentos del dispositivo.
class PdfExportService {
  static const PdfColor _primary = PdfColor.fromInt(0xFF1976D2);
  static const PdfColor _softBlue = PdfColor.fromInt(0xFFE3F2FD);
  static const PdfColor _textDark = PdfColor.fromInt(0xFF1A1C1E);
  static const PdfColor _textGray = PdfColor.fromInt(0xFF5F6368);

  /// Genera el PDF real de la historia clínica consolidada.
  ///
  /// Devuelve la ruta absoluta del archivo generado. Lanza [PdfExportException]
  /// si no se puede escribir el archivo.
  Future<String> exportarHistoriaClinica({
    required PatientProfile profile,
    required List<Medication> medications,
    required List<HealthDocument> documents,
  }) async {
    final pdfBytes = await _buildPdf(
      profile: profile,
      medications: medications,
      documents: documents,
    );

    final docsDir = await getApplicationDocumentsDirectory();
    final stamp = _stampForFileName(DateTime.now());
    final fileName = 'Historia_Clinica_TuAliado_$stamp.pdf';
    final file = File('${docsDir.path}/$fileName');

    try {
      await file.writeAsBytes(pdfBytes, flush: true);
    } catch (e) {
      throw PdfExportException('No se pudo escribir el archivo PDF: $e');
    }

    return file.path;
  }

  Future<Uint8List> _buildPdf({
    required PatientProfile profile,
    required List<Medication> medications,
    required List<HealthDocument> documents,
  }) async {
    final doc = pw.Document(
      title: 'Historia Clínica - ${profile.name}',
      author: 'TuAliado',
      subject: 'Expediente clínico consolidado del paciente',
    );

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(36),
        header: _buildHeader,
        footer: (context) => pw.Align(
          alignment: pw.Alignment.center,
          child: pw.Text(
            'TuAliado • Expediente generado el ${_formatDate(DateTime.now())}',
            style: const pw.TextStyle(
              color: _textGray,
              fontSize: 8,
            ),
          ),
        ),
        build: (context) => [
          _buildProfileSection(profile),
          pw.SizedBox(height: 18),
          _sectionTitle('Medicamentos Activos (${medications.length})'),
          pw.SizedBox(height: 8),
          if (medications.isEmpty)
            _emptyRow('No hay medicamentos registrados.')
          else
            ...medications.map(_buildMedicationRow),
          pw.SizedBox(height: 18),
          _sectionTitle('Baúl de Documentos (${documents.length})'),
          pw.SizedBox(height: 8),
          if (documents.isEmpty)
            _emptyRow('No hay documentos en el baúl.')
          else
            ...documents.map(_buildDocumentRow),
        ],
      ),
    );

    return doc.save();
  }

  pw.Widget _buildHeader(pw.Context context) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 16),
      padding: const pw.EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: pw.BoxDecoration(
        color: _primary,
        borderRadius: pw.BorderRadius.circular(10),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            'TuAliado',
            style: const pw.TextStyle(
              color: PdfColors.white,
              fontSize: 18,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.Text(
            'Historia Clínica Consolidada',
            style: const pw.TextStyle(
              color: PdfColors.white,
              fontSize: 11,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _sectionTitle(String title) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: pw.BoxDecoration(
        color: _softBlue,
        borderRadius: pw.BorderRadius.circular(6),
      ),
      child: pw.Text(
        title,
        style: const pw.TextStyle(
          color: _primary,
          fontSize: 12,
          fontWeight: pw.FontWeight.bold,
        ),
      ),
    );
  }

  pw.Widget _buildProfileSection(PatientProfile profile) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: _primary, width: 1.2),
        borderRadius: pw.BorderRadius.circular(10),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            children: [
              pw.Container(
                width: 46,
                height: 46,
                decoration: const pw.BoxDecoration(
                  color: _softBlue,
                  shape: pw.BoxShape.circle,
                ),
                child: pw.Center(
                  child: pw.Text(
                    profile.name.isEmpty
                        ? '?'
                        : profile.name.substring(0, 1).toUpperCase(),
                    style: const pw.TextStyle(
                      color: _primary,
                      fontSize: 20,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ),
              ),
              pw.SizedBox(width: 12),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    profile.name,
                    style: const pw.TextStyle(
                      color: _textDark,
                      fontSize: 18,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.Text(
                    'Documento: ${profile.document}',
                    style: const pw.TextStyle(color: _textGray, fontSize: 10),
                  ),
                ],
              ),
            ],
          ),
          pw.SizedBox(height: 12),
          pw.Row(
            children: [
              _infoChip('Edad', '${profile.age} años'),
              pw.SizedBox(width: 8),
              _infoChip('Rh', profile.rh),
            ],
          ),
          pw.SizedBox(height: 8),
          pw.Row(
            children: [
              _infoChip('EPS', profile.eps),
              pw.SizedBox(width: 8),
              _infoChip('Mail', profile.email),
            ],
          ),
          pw.SizedBox(height: 8),
          pw.Text(
            'Contacto de emergencia: ${profile.emergencyContact}',
            style: const pw.TextStyle(color: _textGray, fontSize: 10),
          ),
          pw.SizedBox(height: 6),
          pw.Text(
            'Objetivo de salud: ${profile.primaryGoal}',
            style: const pw.TextStyle(color: _textGray, fontSize: 10),
          ),
        ],
      ),
    );
  }

  pw.Widget _infoChip(String label, String value) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: pw.BoxDecoration(
        color: _softBlue,
        borderRadius: pw.BorderRadius.circular(6),
      ),
      child: pw.RichText(
        text: pw.TextSpan(
          style: const pw.TextStyle(fontSize: 9),
          children: [
            pw.TextSpan(
              text: '$label: ',
              style: const pw.TextStyle(
                color: _textGray,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.TextSpan(
              text: value,
              style: const pw.TextStyle(color: _textDark),
            ),
          ],
        ),
      ),
    );
  }

  pw.Widget _buildMedicationRow(Medication med) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 6),
      padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: pw.BoxDecoration(
        color: const PdfColor.fromInt(0xFFF8FAFC),
        border: pw.Border.all(color: const PdfColor.fromInt(0xFFE2E8F0)),
        borderRadius: pw.BorderRadius.circular(6),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  _stripEmoji(med.name),
                  style: const pw.TextStyle(
                    color: _textDark,
                    fontSize: 11,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.Text(
                  med.dosage,
                  style: const pw.TextStyle(color: _textGray, fontSize: 9),
                ),
              ],
            ),
          ),
          pw.Text(
            'Stock: ${med.stockDays} días',
            style: pw.TextStyle(
              color: med.status == 'pending'
                  ? const PdfColor.fromInt(0xFFB45309)
                  : _primary,
              fontSize: 9,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildDocumentRow(HealthDocument doc) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 6),
      padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: pw.BoxDecoration(
        color: const PdfColor.fromInt(0xFFF8FAFC),
        border: pw.Border.all(color: const PdfColor.fromInt(0xFFE2E8F0)),
        borderRadius: pw.BorderRadius.circular(6),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  _stripEmoji(doc.name),
                  style: const pw.TextStyle(
                    color: _textDark,
                    fontSize: 10,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.Text(
                  '${doc.date} • ${doc.type} • ${_stripEmoji(doc.targetModule)}',
                  style: const pw.TextStyle(color: _textGray, fontSize: 8),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _emptyRow(String text) {
    return pw.Text(
      text,
      style: const pw.TextStyle(color: _textGray, fontSize: 10),
    );
  }

  /// Elimina caracteres que la fuente estándar (WinAnsi/Latin-1) del PDF
  /// no puede representar, como los emojis de los nombres de módulo
  /// (ej. '📋 Autorizaciones' -> 'Autorizaciones').
  String _stripEmoji(String input) {
    return input.runes
        .where((rune) => rune <= 0xFF)
        .map(String.fromCharCode)
        .join()
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  String _formatDate(DateTime dt) {
    const months = [
      'enero',
      'febrero',
      'marzo',
      'abril',
      'mayo',
      'junio',
      'julio',
      'agosto',
      'septiembre',
      'octubre',
      'noviembre',
      'diciembre',
    ];
    return '${dt.day} de ${months[dt.month - 1]} de ${dt.year}';
  }

  String _stampForFileName(DateTime dt) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${dt.year}${two(dt.month)}${two(dt.day)}_${two(dt.hour)}${two(dt.minute)}';
  }
}

/// Error lanzado cuando no se puede generar o guardar el PDF.
class PdfExportException implements Exception {
  final String message;

  PdfExportException(this.message);

  @override
  String toString() => message;
}
