import 'dart:async';
import 'package:flutter/material.dart';
import '../../features/laboratorios/domain/models/lab_exam.dart';
import '../../features/medicamentos/domain/models/health_document.dart';
import '../../features/medicamentos/domain/models/medication.dart';
import '../../features/autorizaciones/domain/models/authorization_request.dart';
import '../../features/agenda/domain/models/medical_appointment.dart';
import '../../features/evolucion/domain/models/weight_entry.dart';
import '../../features/perfil/domain/models/patient_profile.dart';
import '../services/supabase_service.dart';
import '../services/gemini_vision_service.dart';
import '../services/hive_service.dart';

/// Estado global de la aplicación TuAliado.
/// Mantiene la sesión única del usuario, su perfil y las listas reactivas de medicamentos, laboratorios y documentos.
class AppStateProvider extends ChangeNotifier {
  static final AppStateProvider instance = AppStateProvider._internal();

  AppStateProvider._internal();

  PatientProfile? _profile;
  bool _isOnboarded = false;

  final List<Medication> _medications = [];

  final List<HealthDocument> _documents = [];

  final List<LabExam> _labExams = [];

  final List<AuthorizationRequest> _authorizations = [];

  final List<MedicalAppointment> _appointments = [];

  final List<WeightEntry> _weightEntries = [];

  PatientProfile? get profile => _profile;
  bool get isOnboarded => _isOnboarded;
  List<Medication> get medications => List.unmodifiable(_medications);

  /// Carga los medicamentos guardados localmente (Hive) al iniciar la app,
  /// si existen datos persistidos previamente en este dispositivo.
  void loadPersistedMedications() {
    final saved = HiveService.loadMedications();
    if (saved.isNotEmpty) {
      _medications
        ..clear()
        ..addAll(saved);
    }
  }

  /// Carga los examenes de laboratorio guardados localmente (Hive) al iniciar la app.
  void loadPersistedLabExams() {
    final saved = HiveService.loadLabExams();
    if (saved.isNotEmpty) {
      _labExams
        ..clear()
        ..addAll(saved);
    }
  }

  /// Carga las órdenes/autorizaciones guardadas localmente (Hive) al iniciar la app.
  void loadPersistedAuthorizations() {
    final saved = HiveService.loadAuthorizations();
    if (saved.isNotEmpty) {
      _authorizations
        ..clear()
        ..addAll(saved);
    }
  }

  /// Carga las citas guardadas localmente (Hive) al iniciar la app.
  void loadPersistedAppointments() {
    final saved = HiveService.loadAppointments();
    if (saved.isNotEmpty) {
      _appointments
        ..clear()
        ..addAll(saved);
    }
  }

  /// Carga los registros de peso guardados localmente (Hive) al iniciar la app.
  void loadPersistedWeightEntries() {
    final saved = HiveService.loadWeightEntries();
    if (saved.isNotEmpty) {
      _weightEntries
        ..clear()
        ..addAll(saved);
    }
  }

  Future<void> trySupabaseRestoreIfEmpty() async {
    var restoredSomething = false;
    if (_medications.isEmpty) {
      final remote = await SupabaseService.instance.fetchMedications();
      if (remote != null && remote.isNotEmpty) {
        _medications.addAll(remote.map((m) => Medication.fromMap(m)));
        HiveService.saveAllMedications(_medications);
        restoredSomething = true;
      }
    }
    if (_labExams.isEmpty) {
      final remote = await SupabaseService.instance.fetchLabExams();
      if (remote != null && remote.isNotEmpty) {
        _labExams.addAll(remote.map((e) => LabExam.fromMap(e)));
        HiveService.saveAllLabExams(_labExams);
        restoredSomething = true;
      }
    }
    if (restoredSomething) notifyListeners();
  }

  void loadPersistedProfile() {
    final saved = HiveService.loadProfile();
    if (saved != null) {
      _profile = PatientProfile.fromJson(saved);
      _isOnboarded = true;
    }
  }

  /// Guarda el estado actual de medicamentos en Hive (disco local).
  void _persistMedications() {
    HiveService.saveAllMedications(_medications);
    unawaited(SupabaseService.instance
        .saveMedications(_medications.map((m) => m.toMap()).toList()));
  }

  void _persistLabExams() {
    HiveService.saveAllLabExams(_labExams);
    unawaited(SupabaseService.instance
        .saveLabExams(_labExams.map((e) => e.toMap()).toList()));
  }

  /// Guarda las órdenes/autorizaciones en Hive (disco local).
  /// Por ahora solo local (Opción A): no se sincroniza con Supabase todavía.
  void _persistAuthorizations() {
    HiveService.saveAllAuthorizations(_authorizations);
  }

  /// Guarda las citas en Hive (disco local). Igual que autorizaciones,
  /// por ahora solo local, sin sincronización con Supabase.
  void _persistAppointments() {
    HiveService.saveAllAppointments(_appointments);
  }

  List<HealthDocument> get documents => List.unmodifiable(_documents);
  List<LabExam> get labExams => List.unmodifiable(_labExams);
  List<AuthorizationRequest> get authorizations =>
      List.unmodifiable(_authorizations);
  List<MedicalAppointment> get appointments => List.unmodifiable(_appointments);
  List<WeightEntry> get weightEntries => List.unmodifiable(_weightEntries);

  /// Inicializa el perfil del usuario tras el registro inicial.
  void initializeUser({
    required String name,
    required int age,
    required String gender,
    required String email,
    String rh = 'O+',
    String eps = 'Sanidad Militar',
    String document = '1.234.567.890',
  }) {
    _profile = PatientProfile(
      name: name,
      age: age,
      gender: gender,
      email: email,
      rh: rh,
      eps: eps,
      document: document,
    );
    _isOnboarded = true;

    SupabaseService.instance.saveProfile(_profile!.toJson());
    HiveService.saveProfile(_profile!.toJson());
    notifyListeners();
  }

  void addMedication(Medication med) {
    _medications.insert(0, med);
    _persistMedications();
    notifyListeners();
  }

  void addManualMedication({
    required String name,
    required String dosage,
    required String specialty,
    String? purpose,
    int stockDays = 30,
  }) {
    _medications.insert(
      0,
      Medication(
        id: DateTime.now().millisecondsSinceEpoch,
        name: name,
        dosage: dosage.trim().isNotEmpty
            ? dosage.trim()
            : 'Según indicación médica',
        stockDays: stockDays,
        deliveryDate: '$stockDays días',
        status: 'active',
        purpose: purpose?.trim().isNotEmpty == true
            ? purpose!.trim()
            : 'Agregado por el paciente',
        specialty:
            specialty.trim().isNotEmpty ? specialty.trim() : 'Medicina General',
        lastUpdated: DateTime.now(),
      ),
    );
    _persistMedications();
    notifyListeners();
  }

  /// Fusiona una lista de medicamentos detectados por la IA con los ya existentes.
  void mergeMedicationsFromCapture(
    List<MedicationExtract> extracted, {
    String? documentName,
    String? orderedBy,
    String? specialty,
  }) {
    final spec = (specialty != null && specialty.trim().isNotEmpty)
        ? specialty.trim()
        : 'Cardiología';

    for (final item in extracted) {
      final existingIndex = _medications.indexWhere(
        (m) => m.name.toLowerCase().trim() == item.name.toLowerCase().trim(),
      );
      if (existingIndex != -1) {
        final existing = _medications[existingIndex];
        _medications[existingIndex] = existing.copyWith(
          dosage: item.dosage ?? existing.dosage,
          purpose: item.purpose ?? existing.purpose,
          orderedBy: orderedBy ?? existing.orderedBy,
          specialty: spec,
          lastUpdated: DateTime.now(),
          status: 'active',
        );
      } else {
        _medications.insert(
          0,
          Medication(
            id: DateTime.now().millisecondsSinceEpoch + _medications.length,
            name: item.name,
            dosage: item.dosage != null && item.dosage!.trim().isNotEmpty
                ? item.dosage!.trim()
                : (item.frequency ?? 'Dosis según fórmula médica'),
            stockDays: 30,
            deliveryDate: '30 días',
            status: 'active',
            purpose: item.purpose,
            orderedBy: orderedBy,
            specialty: spec,
            lastUpdated: DateTime.now(),
          ),
        );
      }
    }

    if (documentName != null && documentName.trim().isNotEmpty) {
      final exists = _documents.any((d) => d.name == documentName);
      if (!exists) {
        _documents.insert(
          0,
          HealthDocument(
            name: documentName,
            date: 'Hoy',
            type: documentName.toLowerCase().endsWith('.pdf')
                ? 'PDF'
                : 'Foto / Scan',
            targetModule: '💊 Medicamentos',
          ),
        );
      }
    }

    _persistMedications();
    notifyListeners();
  }

  /// Registra o actualiza un examen de laboratorio o estudio radiológico analizado por la IA.
  void mergeLabExamFromCapture({
    String? requestedDate,
    required String examName,
    String? orderedBy,
    String? resultSummary,
    String? examType,
    String? documentName,
    String? interpretation,
  }) {
    final newExam = LabExam(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: examName,
      orderedBy: orderedBy ?? 'Médico Tratante',
      requestedDate: (requestedDate != null && requestedDate.trim().isNotEmpty)
          ? requestedDate.trim()
          : 'Hoy',
      status: (resultSummary != null && resultSummary.trim().isNotEmpty)
          ? LabExamStatus.completado
          : LabExamStatus.pendiente,
      resultSummary: resultSummary,
      examType: examType ?? 'Laboratorio Clínico',
      interpretation: interpretation,
    );

    _labExams.insert(0, newExam);
    _persistLabExams();

    if (documentName != null && documentName.trim().isNotEmpty) {
      final exists = _documents.any((d) => d.name == documentName);
      if (!exists) {
        _documents.insert(
          0,
          HealthDocument(
            name: documentName,
            date: 'Hoy',
            type: documentName.toLowerCase().endsWith('.pdf')
                ? 'PDF'
                : 'Foto / Scan',
            targetModule: '🧪 Laboratorios',
          ),
        );
      }
    }

    notifyListeners();
  }

  /// Registra una orden médica / trámite de autorización analizado por la IA.
  void mergeAuthorizationFromCapture({
    required String title,
    String? orderedBy,
    String? specialty,
    String? summary,
    String? documentName,
    String? requestedDate,
    String? validFrom,
    String? validUntil,
  }) {
    final resolvedTitle =
        title.trim().isNotEmpty ? title.trim() : 'Trámite médico';
    _authorizations.insert(
      0,
      AuthorizationRequest(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: resolvedTitle,
        orderedBy: (orderedBy != null && orderedBy.trim().isNotEmpty)
            ? orderedBy.trim()
            : 'Médico Tratante',
        specialty: (specialty != null && specialty.trim().isNotEmpty)
            ? specialty.trim()
            : 'Medicina General',
        requestDate: (requestedDate != null && requestedDate.trim().isNotEmpty)
            ? requestedDate.trim()
            : 'Hoy',
        validFrom: (validFrom != null && validFrom.trim().isNotEmpty)
            ? validFrom.trim()
            : '',
        validUntil: (validUntil != null && validUntil.trim().isNotEmpty)
            ? validUntil.trim()
            : '',
        summary: summary ?? '',
        status: AuthorizationStatus.pendiente,
        subtype: AuthorizationSubtypeX.fromTitle(resolvedTitle),
      ),
    );
    _persistAuthorizations();

    if (documentName != null && documentName.trim().isNotEmpty) {
      final exists = _documents.any((d) => d.name == documentName);
      if (!exists) {
        _documents.insert(
          0,
          HealthDocument(
            name: documentName,
            date: 'Hoy',
            type: documentName.toLowerCase().endsWith('.pdf')
                ? 'PDF'
                : 'Foto / Scan',
            targetModule: '📋 Autorizaciones',
          ),
        );
      }
    }

    notifyListeners();
  }

  /// Convierte la fecha/hora en texto que extrae la IA (ej. "24 Jul 2026",
  /// "10:00 AM") a un DateTime real para MedicalAppointment. Si no logra
  /// interpretar el texto, usa una fecha por defecto razonable en vez de
  /// fallar, para nunca perder la cita detectada.
  DateTime _parseAppointmentDateTime(String? dateStr, String? timeStr) {
    const months = {
      'ene': 1,
      'feb': 2,
      'mar': 3,
      'abr': 4,
      'may': 5,
      'jun': 6,
      'jul': 7,
      'ago': 8,
      'sep': 9,
      'oct': 10,
      'nov': 11,
      'dic': 12,
    };

    DateTime base = DateTime.now().add(const Duration(days: 7));
    if (dateStr != null && dateStr.trim().isNotEmpty) {
      final match = RegExp(r'(\d{1,2})\s+([A-Za-zñÑ]{3,})\.?\s+(\d{4})')
          .firstMatch(dateStr);
      if (match != null) {
        final day = int.tryParse(match.group(1)!) ?? base.day;
        final monthKey = match.group(2)!.toLowerCase().substring(0, 3);
        final month = months[monthKey] ?? base.month;
        final year = int.tryParse(match.group(3)!) ?? base.year;
        base = DateTime(year, month, day);
      }
    }

    int hour = 9;
    int minute = 0;
    if (timeStr != null && timeStr.trim().isNotEmpty) {
      final tMatch = RegExp(r'(\d{1,2}):(\d{2})\s*([AaPp]\.?\s?[Mm]\.?)?')
          .firstMatch(timeStr);
      if (tMatch != null) {
        hour = int.tryParse(tMatch.group(1)!) ?? hour;
        minute = int.tryParse(tMatch.group(2)!) ?? minute;
        final period = tMatch.group(3)?.toLowerCase() ?? '';
        if (period.startsWith('p') && hour < 12) hour += 12;
        if (period.startsWith('a') && hour == 12) hour = 0;
      }
    }

    return DateTime(base.year, base.month, base.day, hour, minute);
  }

  /// Registra una cita médica analizada por la IA.
  void mergeAppointmentFromCapture({
    required String title,
    String? orderedBy,
    String? date,
    String? time,
    String? location,
    String? summary,
    String? documentName,
  }) {
    _appointments.insert(
      0,
      MedicalAppointment(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        doctorName: (orderedBy != null && orderedBy.trim().isNotEmpty)
            ? orderedBy.trim()
            : 'Médico Tratante',
        specialty: title.trim().isNotEmpty ? title.trim() : 'Cita médica',
        date: _parseAppointmentDateTime(date, time),
        location: (location != null && location.trim().isNotEmpty)
            ? location.trim()
            : 'Por confirmar',
        notes: summary ?? '',
      ),
    );
    _persistAppointments();

    if (documentName != null && documentName.trim().isNotEmpty) {
      final exists = _documents.any((d) => d.name == documentName);
      if (!exists) {
        _documents.insert(
          0,
          HealthDocument(
            name: documentName,
            date: 'Hoy',
            type: documentName.toLowerCase().endsWith('.pdf')
                ? 'PDF'
                : 'Foto / Scan',
            targetModule: '📅 Agenda',
          ),
        );
      }
    }

    notifyListeners();
  }

  /// Agrega una cita creada manualmente por el paciente (no por captura IA).
  void addAppointment(MedicalAppointment appointment) {
    _appointments.insert(0, appointment);
    _persistAppointments();
    notifyListeners();
  }

  void deleteAppointment(String id) {
    _appointments.removeWhere((a) => a.id == id);
    _persistAppointments();
    notifyListeners();
  }

  void _persistWeightEntries() {
    HiveService.saveAllWeightEntries(_weightEntries);
  }

  /// Registra un peso ingresado directamente por el paciente (Módulo Evolución).
  void addWeightEntry(double weightKg, {DateTime? date}) {
    _weightEntries.insert(
      0,
      WeightEntry(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        date: date ?? DateTime.now(),
        weightKg: weightKg,
      ),
    );
    _persistWeightEntries();
    notifyListeners();
  }

  void deleteWeightEntry(String id) {
    _weightEntries.removeWhere((w) => w.id == id);
    _persistWeightEntries();
    notifyListeners();
  }

  /// Alterna el estado de un trámite entre Pendiente y Autorizada.
  void toggleAuthorizationStatus(int index) {
    if (index >= 0 && index < _authorizations.length) {
      final current = _authorizations[index];
      final next = current.status == AuthorizationStatus.pendiente
          ? AuthorizationStatus.autorizada
          : AuthorizationStatus.pendiente;
      _authorizations[index] = current.copyWith(status: next);
      _persistAuthorizations();
      notifyListeners();
    }
  }

  void deleteAuthorization(String id) {
    _authorizations.removeWhere((a) => a.id == id);
    _persistAuthorizations();
    notifyListeners();
  }

  void addLabExam(LabExam exam) {
    _labExams.insert(0, exam);
    _persistLabExams();
    notifyListeners();
  }

  void toggleLabExamStatus(int index) {
    if (index >= 0 && index < _labExams.length) {
      final current = _labExams[index];
      final next = switch (current.status) {
        LabExamStatus.pendiente => LabExamStatus.programado,
        LabExamStatus.programado => LabExamStatus.completado,
        LabExamStatus.completado => LabExamStatus.pendiente,
      };
      _labExams[index] = current.copyWith(status: next);
      _persistLabExams();
      notifyListeners();
    }
  }

  void addHealthDocument(HealthDocument doc) {
    _documents.insert(0, doc);
    notifyListeners();
  }

  void updateProfile(PatientProfile updatedProfile) {
    _profile = updatedProfile;
    SupabaseService.instance.saveProfile(_profile!.toJson());
    HiveService.saveProfile(_profile!.toJson());
    notifyListeners();
  }

  /// Resetea completamente (clean) la app y todas sus listas para iniciar desde cero.
  void deleteMedication(int id) {
    _medications.removeWhere((m) => m.id == id);
    _persistMedications();
    notifyListeners();
  }

  void deleteLabExam(String id) {
    _labExams.removeWhere((e) => e.id == id);
    _persistLabExams();
    notifyListeners();
  }

  Future<void> resetApp() async {
    _profile = null;
    _isOnboarded = false;
    _medications.clear();
    _documents.clear();
    _labExams.clear();
    _authorizations.clear();
    _appointments.clear();
    _weightEntries.clear();
    await HiveService.clearProfile();
    await HiveService.saveAllMedications(_medications);
    await HiveService.saveAllLabExams(_labExams);
    await HiveService.saveAllAuthorizations(_authorizations);
    await HiveService.saveAllAppointments(_appointments);
    await HiveService.saveAllWeightEntries(_weightEntries);
    await HiveService.clearNutritionPlan();
    await SupabaseService.instance.resetUserData();
    notifyListeners();
  }
}
