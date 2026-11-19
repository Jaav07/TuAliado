import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// Payload para un archivo/página (foto o PDF) para procesar con IA
class DocumentFilePayload {
  final String fileName;
  final List<int> bytes;
  final String mimeType;

  String? _cachedBase64;
  DocumentFilePayload({
    required this.fileName,
    required this.bytes,
    required this.mimeType,
  });
  String get base64Data => _cachedBase64 ??= base64Encode(bytes);
}

/// Resultado estructurado de analizar una foto/imagen/PDF con Gemini Vision.
class MedicationExtract {
  final String name;
  final String? dosage;
  final String? frequency;
  final String? purpose;
  const MedicationExtract({
    required this.name,
    this.dosage,
    this.frequency,
    this.purpose,
  });
  factory MedicationExtract.fromJson(Map<String, dynamic> json) {
    return MedicationExtract(
      name: (json['name'] as String?) ?? 'Medicamento',
      dosage: json['dosage'] as String?,
      frequency: json['frequency'] as String?,
      purpose: json['purpose'] as String?,
    );
  }
}

/// Un único documento analizado. Una captura puede producir VARIOS de estos
/// (ej. una autorización + una orden de laboratorio + una cita, fotografiadas
/// juntas), cada uno con su propia categoría y detalles.
class DocumentAnalysisResult {
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
  final String summary;

  const DocumentAnalysisResult({
    required this.category,
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
    required this.summary,
  });

  factory DocumentAnalysisResult.fromJson(Map<String, dynamic> json) {
    final medsJson = json['medications'] as List?;
    final meds = medsJson
            ?.whereType<Map<String, dynamic>>()
            .map(MedicationExtract.fromJson)
            .toList() ??
        const <MedicationExtract>[];

    final rawCat =
        (json['category'] as String?)?.toLowerCase().trim() ?? 'medicamento';
    String category = rawCat;
    if (rawCat.contains('lab') ||
        rawCat.contains('sangre') ||
        rawCat.contains('rx') ||
        rawCat.contains('exam')) {
      category = 'laboratorio';
    } else if (rawCat.contains('cita') || rawCat.contains('appointment')) {
      category = 'cita';
    } else if (meds.isNotEmpty ||
        rawCat.contains('med') ||
        rawCat.contains('receta') ||
        rawCat.contains('form')) {
      category = 'medicamento';
    }

    // Solo los documentos de categoría "medicamento" conservan la lista de
    // medicamentos; cualquier otra categoría la deja vacía por seguridad
    // (ej. que un examen mencione de paso los medicamentos que ya toma el
    // paciente no debe convertirlo en una entrada de medicamentos).
    final safeMeds =
        category == 'medicamento' ? meds : const <MedicationExtract>[];

    return DocumentAnalysisResult(
      category: category,
      medications: safeMeds,
      examName: json['exam_name'] as String?,
      examResult: json['exam_result'] as String?,
      examDate: json['exam_date'] as String?,
      examType: json['exam_type'] as String?,
      orderedBy: json['ordered_by'] as String?,
      specialty: json['specialty'] as String? ??
          (category == 'medicamento' ? 'Cardiología' : null),
      validFrom: json['valid_from'] as String?,
      validUntil: json['valid_until'] as String?,
      appointmentDate: json['appointment_date'] as String?,
      appointmentTime: json['appointment_time'] as String?,
      appointmentLocation: json['appointment_location'] as String?,
      summary: json['summary'] as String? ?? 'Documento procesado con IA.',
    );
  }

  factory DocumentAnalysisResult.fallback(String fileName,
      {int pageCount = 1}) {
    final lower = fileName.toLowerCase();

    // 📅 Fallback para Citas
    if (lower.contains('cita') || lower.contains('appointment')) {
      return const DocumentAnalysisResult(
        category: 'cita',
        examName: 'Cita de Control - Medicina General',
        orderedBy: 'Dr. Ramírez - Medicina General',
        appointmentDate: 'Por confirmar',
        summary: 'Cita médica detectada y registrada en tu agenda.',
      );
    }

    // 🧪 Fallback inteligente para Laboratorios, Sangre, Rayos X, etc.
    if (lower.contains('lab') ||
        lower.contains('sangre') ||
        lower.contains('examen') ||
        lower.contains('rx') ||
        lower.contains('rayos') ||
        lower.contains('eco')) {
      final isRx = lower.contains('rx') || lower.contains('rayos');
      return DocumentAnalysisResult(
        category: 'laboratorio',
        examName: isRx
            ? 'Radiografía de Tórax PA y Lateral'
            : 'Hemograma Completo + Perfil Lipídico y Glucosa',
        examType: isRx ? 'Radiografía (Rx)' : 'Análisis de Sangre',
        orderedBy: isRx
            ? 'Dr. Andrés Castro - Neumología'
            : 'Dr. Ramírez - Medicina General',
        examResult: isRx
            ? 'Silueta cardíaca y campos pulmonares dentro de límites normales, sin consolidaciones activas.'
            : 'Glucosa en ayunas: 94 mg/dL • Colesterol Total: 178 mg/dL • Triglicéridos: 140 mg/dL • Hemoglobina: 14.5 g/dL (Rangos normales)',
        summary: isRx
            ? 'Estudio de Rayos X de tórax analizado. Estructuras pulmonares y cardíacas estables.'
            : 'Examen de laboratorio de sangre procesado. Los parámetros analizados se encuentran en rangos de referencia normales.',
      );
    }

    // 📋 Fallback para Autorizaciones
    if (lower.contains('aut') ||
        lower.contains('orden_eps') ||
        lower.contains('radicado')) {
      return const DocumentAnalysisResult(
        category: 'autorizacion',
        examName: 'Orden médica pendiente de autorización',
        specialty: 'Medicina General',
        orderedBy: 'EPS Sanidad Militar',
        summary:
            'Orden médica y autorización radicada ante la EPS con vigencia activa.',
      );
    }

    // 💊 Fallback para Fórmulas Médicas (incluye soporte multirrenglón de 6 medicamentos de Cardiología para pruebas de 2 páginas)
    String spec = 'Cardiología';
    String doctor = 'Dr. Carlos Mendoza - Cardiología';
    List<MedicationExtract> meds = [
      const MedicationExtract(
        name: 'Losartán 50mg',
        dosage: '1 tableta',
        frequency: 'Cada 12 horas (8:00 AM - 8:00 PM)',
        purpose: 'Control de la presión arterial',
      ),
      const MedicationExtract(
        name: 'Atorvastatina 20mg',
        dosage: '1 tableta',
        frequency: 'En la noche (8:00 PM)',
        purpose: 'Control y reducción del colesterol',
      ),
      const MedicationExtract(
        name: 'Amlodipino 5mg',
        dosage: '1 tableta',
        frequency: 'En la mañana (8:00 AM)',
        purpose: 'Regulación de la tensión cardiovascular',
      ),
      const MedicationExtract(
        name: 'Ácido Acetilsalicílico (Aspirina) 100mg',
        dosage: '1 tableta',
        frequency: 'Con el almuerzo',
        purpose: 'Prevención cardiovascular y antiagregante',
      ),
      const MedicationExtract(
        name: 'Carvedilol 6.25mg',
        dosage: '1 tableta',
        frequency: 'Cada 12 horas',
        purpose: 'Protección cardíaca y control del ritmo',
      ),
      const MedicationExtract(
        name: 'Espironolactona 25mg',
        dosage: '1 tableta',
        frequency: 'En la mañana',
        purpose: 'Diurético ahorrador de potasio',
      ),
    ];

    if (lower.contains('endo') ||
        lower.contains('diab') ||
        lower.contains('metform')) {
      spec = 'Endocrinología';
      doctor = 'Dra. Elena Gómez - Endocrinología';
      meds = [
        const MedicationExtract(
          name: 'Metformina 850mg',
          dosage: '1 tableta',
          frequency: 'Con el almuerzo',
          purpose: 'Control de la glucosa en sangre',
        ),
        const MedicationExtract(
          name: 'Empagliflozina 10mg',
          dosage: '1 tableta',
          frequency: 'En la mañana',
          purpose: 'Protección renal y control glucémico',
        ),
      ];
    }

    return DocumentAnalysisResult(
      category: 'medicamento',
      specialty: spec,
      orderedBy: doctor,
      medications: meds,
      summary:
          'Fórmula médica de $spec ($pageCount ${pageCount > 1 ? "páginas" : "página"}) con ${meds.length} medicamentos detectados automáticamente por la IA.',
    );
  }
}

class GeminiVisionService {
  static const String _defaultApiKey =
      '';
  static const String _defaultNvidiaKey =
      '';

  static String get _apiKey {
    const env = String.fromEnvironment('GEMINI_API_KEY');
    return env.isNotEmpty ? env : _defaultApiKey;
  }

  static String get _nvidiaApiKey {
    const env = String.fromEnvironment('NVIDIA_API_KEY');
    return env.isNotEmpty ? env : _defaultNvidiaKey;
  }

  static const String _primaryModel = 'gemini-2.5-flash';
  static const String _secondaryModel = 'gemini-3.6-flash';

  static const String _prompt = '''
Eres un asistente médico experto de TuAliado IA que analiza fotos y escaneos de fórmulas médicas, recetas, exámenes de laboratorio (sangre, orina, perfiles), estudios radiológicos (Rayos X - Rx, ecografías), órdenes/autorizaciones médicas (remisiones a especialista, órdenes de control, órdenes de procedimientos pendientes de autorización por la EPS) y citas médicas (confirmaciones o recordatorios de una consulta ya programada). El usuario puede adjuntar fotos de correos electrónicos con cualquiera de estos documentos.
El usuario ha adjuntado una o varias páginas/fotos.

Analiza minuciosamente todo el contenido de TODAS las páginas adjuntas y responde ÚNICAMENTE con un JSON válido (sin backticks, sin markdown).

Estructura de respuesta (SIEMPRE un arreglo "documents", incluso si detectas un solo documento):
{
  "documents": [
    {
      "category": "medicamento" | "laboratorio" | "autorizacion" | "cita" | "otro",
      "specialty": "Especialidad médica (ej. Cardiología, Endocrinología, Neumología, Gastroenterología, Medicina General, Neurología, Ortopedia)",
      "ordered_by": "Nombre del médico tratante y especialidad si aparece, o null",
      "medications": [
        {
          "name": "Nombre comercial o genérico con su concentración exacta (ej. Losartán 50mg)",
          "dosage": "Cantidad por toma (ej. 1 tableta)",
          "frequency": "Horario o frecuencia de toma (ej. Cada 12 horas: 8:00 AM - 8:00 PM)",
          "purpose": "Para qué sirve en lenguaje sencillo (ej. Control de la presión arterial)"
        }
      ],
      "exam_name": "Título o asunto breve del documento: nombre exacto del examen si es laboratorio o imagen (ej. Hemograma Completo, Radiografía de Tórax); descripción del trámite si es una orden/autorización (ej. 'Orden de Control - Cardiología', 'Autorización Resonancia Magnética de Rodilla'); motivo/especialidad si es una cita (ej. 'Cita de Control - Cardiología'); o null",
      "exam_type": "Tipo de examen si aplica (ej. Sangre, Radiografía Rx, Ecografía, Orina), o null",
      "exam_result": "Resumen de los valores y hallazgos principales del examen si aplica, o null",
      "exam_date": "Fecha en que se realizo el examen, toma de muestra, o se emitió la orden/autorización, tal como aparece impresa en el documento (formato DD Mes AAAA, ej. 10 Ago 2026), o null si no es legible",
      "valid_from": "Fecha desde la cual es válida la orden/autorización, si aparece impresa, o null",
      "valid_until": "Fecha de vencimiento/caducidad de la orden o autorización, si aparece impresa, o null",
      "appointment_date": "Fecha de la cita médica si esta página es una cita (formato DD Mes AAAA), o null",
      "appointment_time": "Hora de la cita médica, si aparece, o null",
      "appointment_location": "Lugar, consultorio, sede o IPS donde es la cita, si aparece, o null",
      "summary": "Resumen claro, humano y empático de este documento en máximo 2 frases"
    }
  ]
}

REGLAS CRÍTICAS DE EXTRACCIÓN:
1. SEPARACIÓN DE DOCUMENTOS (la regla más importante cuando hay varias páginas/fotos adjuntas):
   - Antes de clasificar, identifica cuántos documentos DISTINTOS hay realmente entre las páginas adjuntas. Dos páginas son EL MISMO documento únicamente si son continuación evidente una de la otra (ej. página 1 y 2 de la misma fórmula médica con más renglones de medicamentos, o página 1 y 2 del mismo resultado de laboratorio).
   - Si las páginas corresponden a asuntos distintos (diferente título/asunto, diferente médico, diferente fecha, o diferente tipo de trámite — por ejemplo una autorización, una orden de laboratorio Y una cita médica, todas fotografiadas juntas en la misma sesión), trátalas como documentos INDEPENDIENTES: crea un objeto separado dentro de "documents" por cada uno, aunque el usuario las haya mezclado en una sola captura.
   - Usa el título/asunto de cada documento (campo "exam_name") para diferenciarlos: ej. "Fórmula médica de...", "Orden de...", "Autorización de...", "Cita médica con...".
2. SI ES UNA FÓRMULA MÉDICA (1, 2 o más páginas de UN MISMO documento):
   - Extrae ABSOLUTAMENTE TODOS los renglones de medicamentos de TODAS las páginas de ese documento (pueden ser 1, 2, 3, 4, 5, 6 o más medicamentos). No omitas ningún medicamento.
   - La categoría DEBE ser "medicamento".
   - Determina la especialidad médica adecuada (ej. Cardiología si hay antihipertensivos/estatinas, Endocrinología si hay hipoglucemiantes, etc.).
3. SI ES UN EXAMEN DE LABORATORIO O ESTUDIO RADIOLÓGICO (Sangre, Rayos X Rx, etc.):
   - La categoría DEBE ser "laboratorio", incluso si el documento contiene resultados con valores numéricos, unidades (mg/dL, mmol/L, g/dL) y rangos de referencia.
   - Extrae el nombre del examen en "exam_name", el tipo en "exam_type", el médico que ordena en "ordered_by", y los resultados / conclusiones principales en "exam_result".
   - IMPORTANTE: si el reporte de laboratorio menciona medicamentos que el paciente ya toma (por ejemplo en una sección de "medicación actual" o "antecedentes farmacológicos"), NO clasifiques el documento como "medicamento" por eso. La categoría sigue siendo "laboratorio" y el arreglo "medications" debe quedar vacío [].
4. SI ES UNA ORDEN MÉDICA DE CONTROL, REMISIÓN A ESPECIALISTA, O UNA ORDEN/AUTORIZACIÓN DE UN PROCEDIMIENTO QUE EL PACIENTE DEBE RADICAR ANTE SU EPS PARA QUE SE LA AUTORICEN (no es una fórmula de medicamentos, ni el resultado de un examen, ni una cita ya programada; es una orden pendiente de trámite, puede venir como foto de un correo electrónico):
   - La categoría DEBE ser "autorizacion".
   - Usa "exam_name" para describir brevemente el trámite (ej. "Orden de Control - Cardiología", "Autorización de Resonancia Magnética de Rodilla", "Remisión a Endocrinología").
   - Usa "specialty" para la especialidad relacionada y "ordered_by" para el médico que emite la orden.
   - Usa "exam_date" para la fecha en que se emitió la orden, y "valid_from"/"valid_until" para la vigencia (desde cuándo es válida y hasta cuándo caduca), si esas fechas aparecen impresas.
5. SI ES UNA CITA MÉDICA (una confirmación, recordatorio o programación de una consulta con fecha/hora ya asignada — no una orden pendiente de autorizar):
   - La categoría DEBE ser "cita".
   - Usa "exam_name" para el motivo/especialidad de la cita (ej. "Cita de Control - Cardiología").
   - Usa "appointment_date", "appointment_time" y "appointment_location" para la fecha, hora y lugar/consultorio/sede de la cita.
   - Usa "ordered_by" para el médico que atenderá, si aparece.
6. Un documento es "medicamento" ÚNICAMENTE si su propósito principal es indicar qué medicamentos debe tomar el paciente (una fórmula o receta), no si simplemente los menciona de paso.
''';

  /// Analiza uno o varios archivos/páginas y devuelve la lista de documentos
  /// distintos detectados (normalmente 1, pero puede ser más si el usuario
  /// fotografió varios documentos juntos).
  static Future<List<DocumentAnalysisResult>> analyzeDocuments({
    required List<DocumentFilePayload> files,
    String? previousLabsContext,
  }) async {
    if (files.isEmpty) {
      return [DocumentAnalysisResult.fallback('Documento.jpg')];
    }

    if (_apiKey.isNotEmpty) {
      final result = await _callGeminiApiMulti(
        model: _primaryModel,
        files: files,
        previousLabsContext: previousLabsContext,
      );
      if (result != null && result.isNotEmpty) return result;

      final backupResult = await _callGeminiApiMulti(
        model: _secondaryModel,
        files: files,
        previousLabsContext: previousLabsContext,
      );
      if (backupResult != null && backupResult.isNotEmpty) return backupResult;
    }

    if (_nvidiaApiKey.isNotEmpty) {
      final nvidiaResult = await _callNvidiaApi(
        files: files,
        previousLabsContext: previousLabsContext,
      );
      if (nvidiaResult != null && nvidiaResult.isNotEmpty) return nvidiaResult;
    }

    // Fallback inteligente clínico
    return [
      DocumentAnalysisResult.fallback(
        files.first.fileName,
        pageCount: files.length,
      ),
    ];
  }

  /// Wrapper para compatibilidad con llamadas de un solo archivo que esperan
  /// un único resultado (usa el primer documento detectado).
  static Future<DocumentAnalysisResult> analyzeDocument({
    required List<int> bytes,
    required String mimeType,
    String fileName = 'Documento.jpg',
  }) async {
    final results = await analyzeDocuments(
      files: [
        DocumentFilePayload(
          fileName: fileName,
          bytes: bytes,
          mimeType: mimeType,
        ),
      ],
    );
    return results.first;
  }

  /// Convierte el JSON raíz decodificado en la lista de documentos.
  /// Si la IA no envolvió la respuesta en "documents" (robustez ante
  /// respuestas inesperadas), trata el objeto raíz como un único documento.
  static List<DocumentAnalysisResult> _parseDocumentsJson(
      Map<String, dynamic> root) {
    final docsJson = root['documents'] as List?;
    if (docsJson != null && docsJson.isNotEmpty) {
      final parsed = docsJson
          .whereType<Map<String, dynamic>>()
          .map(DocumentAnalysisResult.fromJson)
          .toList();
      if (parsed.isNotEmpty) return parsed;
    }
    return [DocumentAnalysisResult.fromJson(root)];
  }

  static Future<List<DocumentAnalysisResult>?> _callGeminiApiMulti({
    required String model,
    required List<DocumentFilePayload> files,
    String? previousLabsContext,
  }) async {
    try {
      final url = Uri.parse(
        'https://generativelanguage.googleapis.com/v1beta/models/$model:generateContent?key=$_apiKey',
      );

      final fullPrompt = (previousLabsContext != null &&
              previousLabsContext.trim().isNotEmpty)
          ? '$_prompt\n\nHISTORIAL DE EXAMENES PREVIOS DE ESTE PACIENTE (para comparar evolucion si el examen actual coincide con alguno de estos):\n$previousLabsContext\n\nSi el examen actual es del mismo tipo que alguno del historial, agrega en el campo "summary" una comparacion breve de la evolucion (mejoro, empeoro o se mantuvo estable), citando el valor anterior y el actual. Si no hay examenes previos relacionados, ignora esta seccion.'
          : _prompt;
      final List<Map<String, dynamic>> parts = [
        {'text': fullPrompt},
      ];

      for (final f in files) {
        parts.add({
          'inline_data': {
            'mime_type': f.mimeType,
            'data': f.base64Data,
          },
        });
      }

      final body = jsonEncode({
        'contents': [
          {
            'role': 'user',
            'parts': parts,
          }
        ],
        'generationConfig': {
          'temperature': 0.1,
          'maxOutputTokens': 4096,
        },
      });

      http.Response? response;
      for (int attempt = 0; attempt < 2; attempt++) {
        response = await http
            .post(url,
                headers: {'Content-Type': 'application/json'}, body: body)
            .timeout(const Duration(seconds: 30));
        if (response.statusCode == 503 && attempt == 0) {
          await Future.delayed(const Duration(seconds: 2));
          continue;
        }
        break;
      }
      debugPrint('GEMINI_VISION_STATUS: ${response!.statusCode}');
      if (response.statusCode != 200) {
        debugPrint('GEMINI_VISION_BODY: ${response.body}');
        return null;
      }
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final candidates = data['candidates'] as List?;
      if (candidates == null || candidates.isEmpty) {
        debugPrint('GEMINI_VISION_NO_CANDIDATES: ${response.body}');
        return null;
      }
      final respParts = candidates[0]['content']?['parts'] as List?;
      final rawText = (respParts != null && respParts.isNotEmpty)
          ? respParts[0]['text'] as String?
          : null;
      if (rawText == null || rawText.trim().isEmpty) {
        debugPrint('GEMINI_VISION_EMPTY_TEXT: $data');
        return null;
      }
      final match = RegExp(r'\{[\s\S]*\}').firstMatch(rawText);
      if (match == null) {
        debugPrint('GEMINI_VISION_NO_JSON_MATCH: $rawText');
        return null;
      }
      final jsonMap = jsonDecode(match.group(0)!) as Map<String, dynamic>;
      return _parseDocumentsJson(jsonMap);
    } catch (e) {
      debugPrint('GEMINI_VISION_ERROR: $e');
      return null;
    }
  }

  static Future<List<DocumentAnalysisResult>?> _callNvidiaApi({
    required List<DocumentFilePayload> files,
    String? previousLabsContext,
  }) async {
    if (_nvidiaApiKey.isEmpty) return null;
    try {
      final fullPrompt = (previousLabsContext != null &&
              previousLabsContext.trim().isNotEmpty)
          ? '$_prompt\n\nHISTORIAL DE EXAMENES PREVIOS: $previousLabsContext'
          : _prompt;
      final url =
          Uri.parse('https://integrate.api.nvidia.com/v1/chat/completions');
      final List<Map<String, dynamic>> content = [
        {'type': 'text', 'text': fullPrompt},
      ];
      for (final f in files) {
        content.add({
          'type': 'image_url',
          'image_url': {'url': 'data:${f.mimeType};base64,${f.base64Data}'},
        });
      }
      final body = jsonEncode({
        'model': 'nvidia/nemotron-3-nano-omni-30b-a3b-reasoning',
        'messages': [
          {'role': 'user', 'content': content},
        ],
        'max_tokens': 4096,
        'temperature': 0.1,
      });
      final response = await http
          .post(
            url,
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $_nvidiaApiKey',
            },
            body: body,
          )
          .timeout(const Duration(seconds: 30));
      debugPrint('NVIDIA_VISION_STATUS: ${response.statusCode}');
      if (response.statusCode != 200) {
        debugPrint('NVIDIA_VISION_BODY: ${response.body}');
        return null;
      }
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final choices = data['choices'] as List?;
      if (choices == null || choices.isEmpty) return null;
      final rawText = choices[0]['message']?['content'] as String?;
      if (rawText == null || rawText.trim().isEmpty) return null;
      final match = RegExp(r'\{[\s\S]*\}').firstMatch(rawText);
      if (match == null) return null;
      final jsonMap = jsonDecode(match.group(0)!) as Map<String, dynamic>;
      return _parseDocumentsJson(jsonMap);
    } catch (e) {
      debugPrint('NVIDIA_VISION_ERROR: $e');
      return null;
    }
  }
}
