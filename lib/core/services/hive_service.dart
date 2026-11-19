import 'package:hive_flutter/hive_flutter.dart';
import '../../features/medicamentos/domain/models/medication.dart';
import '../../features/laboratorios/domain/models/lab_exam.dart';
import '../../features/autorizaciones/domain/models/authorization_request.dart';
import '../../features/agenda/domain/models/medical_appointment.dart';
import '../../features/evolucion/domain/models/weight_entry.dart';

/// Servicio de persistencia local (offline) usando Hive.
/// Guarda y carga los datos del paciente en el disco del dispositivo,
/// para que no se pierdan al cerrar la app o sin conexion a internet.
class HiveService {
  HiveService._();
  static const String _medicationsBoxName = 'medications_box';
  static const String _labExamsBoxName = 'lab_exams_box';
  static const String _authorizationsBoxName = 'authorizations_box';
  static const String _appointmentsBoxName = 'appointments_box';
  static const String _profileBoxName = 'profile_box';
  static const String _nutritionPlanBoxName = 'nutrition_plan_box';
  static const String _weightEntriesBoxName = 'weight_entries_box';
  static const String _motivationBoxName = 'motivation_box';
  static const String _labDecoderBoxName = 'lab_decoder_box';

  static Box? _medicationsBox;
  static Box? _labExamsBox;
  static Box? _authorizationsBox;
  static Box? _appointmentsBox;
  static Box? _profileBox;
  static Box? _nutritionPlanBox;
  static Box? _weightEntriesBox;
  static Box? _motivationBox;
  static Box? _labDecoderBox;

  static Future<void> initialize() async {
    await Hive.initFlutter();
    _medicationsBox = await Hive.openBox(_medicationsBoxName);
    _labExamsBox = await Hive.openBox(_labExamsBoxName);
    _authorizationsBox = await Hive.openBox(_authorizationsBoxName);
    _appointmentsBox = await Hive.openBox(_appointmentsBoxName);
    _profileBox = await Hive.openBox(_profileBoxName);
    _nutritionPlanBox = await Hive.openBox(_nutritionPlanBoxName);
    _weightEntriesBox = await Hive.openBox(_weightEntriesBoxName);
    _motivationBox = await Hive.openBox(_motivationBoxName);
    _labDecoderBox = await Hive.openBox(_labDecoderBoxName);
  }

  static List<Medication> loadMedications() {
    final box = _medicationsBox;
    if (box == null) return [];
    return box.values
        .map(
            (raw) => Medication.fromMap(Map<dynamic, dynamic>.from(raw as Map)))
        .toList();
  }

  static Future<void> saveAllMedications(List<Medication> medications) async {
    final box = _medicationsBox;
    if (box == null) return;
    await box.clear();
    final Map<String, Map<String, dynamic>> entries = {
      for (final med in medications) med.id.toString(): med.toMap(),
    };
    await box.putAll(entries);
  }

  static List<LabExam> loadLabExams() {
    final box = _labExamsBox;
    if (box == null) return [];
    return box.values
        .map((raw) => LabExam.fromMap(Map<dynamic, dynamic>.from(raw as Map)))
        .toList();
  }

  static Future<void> saveAllLabExams(List<LabExam> exams) async {
    final box = _labExamsBox;
    if (box == null) return;
    await box.clear();
    final Map<String, Map<String, dynamic>> entries = {
      for (final exam in exams) exam.id: exam.toMap(),
    };
    await box.putAll(entries);
  }

  static List<AuthorizationRequest> loadAuthorizations() {
    final box = _authorizationsBox;
    if (box == null) return [];
    return box.values
        .map((raw) =>
            AuthorizationRequest.fromMap(Map<String, dynamic>.from(raw as Map)))
        .toList();
  }

  static Future<void> saveAllAuthorizations(
      List<AuthorizationRequest> authorizations) async {
    final box = _authorizationsBox;
    if (box == null) return;
    await box.clear();
    final Map<String, Map<String, dynamic>> entries = {
      for (final auth in authorizations) auth.id: auth.toMap(),
    };
    await box.putAll(entries);
  }

  static List<MedicalAppointment> loadAppointments() {
    final box = _appointmentsBox;
    if (box == null) return [];
    return box.values
        .map((raw) =>
            MedicalAppointment.fromMap(Map<String, dynamic>.from(raw as Map)))
        .toList();
  }

  static Future<void> saveAllAppointments(
      List<MedicalAppointment> appointments) async {
    final box = _appointmentsBox;
    if (box == null) return;
    await box.clear();
    final Map<String, Map<String, dynamic>> entries = {
      for (final appt in appointments) appt.id: appt.toMap(),
    };
    await box.putAll(entries);
  }

  static Future<void> saveProfile(Map<String, dynamic> json) async {
    final box = _profileBox;
    if (box == null) return;
    await box.put('profile', json);
  }

  static Map<String, dynamic>? loadProfile() {
    final box = _profileBox;
    if (box == null) return null;
    final raw = box.get('profile');
    if (raw == null) return null;
    return Map<String, dynamic>.from(raw as Map);
  }

  static Future<void> clearProfile() async {
    final box = _profileBox;
    if (box == null) return;
    await box.delete('profile');
  }

  static Future<void> saveNutritionPlan(Map<String, dynamic> json) async {
    final box = _nutritionPlanBox;
    if (box == null) return;
    await box.put('plan', json);
  }

  static Map<String, dynamic>? loadNutritionPlan() {
    final box = _nutritionPlanBox;
    if (box == null) return null;
    final raw = box.get('plan');
    if (raw == null) return null;
    return Map<String, dynamic>.from(raw as Map);
  }

  static Future<void> clearNutritionPlan() async {
    final box = _nutritionPlanBox;
    if (box == null) return;
    await box.delete('plan');
  }

  static List<WeightEntry> loadWeightEntries() {
    final box = _weightEntriesBox;
    if (box == null) return [];
    return box.values
        .map(
            (raw) => WeightEntry.fromMap(Map<String, dynamic>.from(raw as Map)))
        .toList();
  }

  static Future<void> saveAllWeightEntries(List<WeightEntry> entries) async {
    final box = _weightEntriesBox;
    if (box == null) return;
    await box.clear();
    final Map<String, Map<String, dynamic>> map = {
      for (final entry in entries) entry.id: entry.toMap(),
    };
    await box.putAll(map);
  }

  /// Mensaje motivacional del día (guardado junto a la fecha para saber si
  /// hay que regenerarlo o si el de hoy todavía sirve).
  static Future<void> saveDailyMotivation(Map<String, dynamic> json) async {
    final box = _motivationBox;
    if (box == null) return;
    await box.put('today', json);
  }

  static Map<String, dynamic>? loadDailyMotivation() {
    final box = _motivationBox;
    if (box == null) return null;
    final raw = box.get('today');
    if (raw == null) return null;
    return Map<String, dynamic>.from(raw as Map);
  }

  /// Caché del "Decodificador de Laboratorios" (Evolución): guarda las
  /// tarjetas generadas por IA junto con la firma de laboratorios que las
  /// generó, para no volver a llamar a la IA si los laboratorios no cambiaron.
  static Future<void> saveLabDecoderCache(Map<String, dynamic> json) async {
    final box = _labDecoderBox;
    if (box == null) return;
    await box.put('cache', json);
  }

  static Map<String, dynamic>? loadLabDecoderCache() {
    final box = _labDecoderBox;
    if (box == null) return null;
    final raw = box.get('cache');
    if (raw == null) return null;
    return Map<String, dynamic>.from(raw as Map);
  }
}
