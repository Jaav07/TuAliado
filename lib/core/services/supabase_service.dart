import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Servicio centralizado de Supabase para TuAliado.
/// Gestiona Autenticación (Email, Google, JWT), Base de Datos PostgreSQL (RLS)
/// y Almacenamiento seguro en Supabase Storage.
class SupabaseService {
  static final SupabaseService instance = SupabaseService._internal();

  SupabaseService._internal();

  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  /// Inicializa la conexión con Supabase.
  Future<void> initialize({String? url, String? anonKey}) async {
    final targetUrl = url ?? const String.fromEnvironment('SUPABASE_URL');
    final targetKey =
        anonKey ?? const String.fromEnvironment('SUPABASE_ANON_KEY');

    try {
      final uri = Uri.tryParse(targetUrl);
      if (uri != null &&
          uri.hasScheme &&
          uri.hasAuthority &&
          targetKey.length > 20) {
        await Supabase.initialize(
          url: targetUrl,
          publishableKey: targetKey,
          authOptions: const FlutterAuthClientOptions(
            authFlowType: AuthFlowType.pkce,
          ),
        );
        _isInitialized = true;
        debugPrint('✅ Supabase inicializado correctamente.');
        if (client?.auth.currentUser == null) {
          try {
            await client?.auth.signInAnonymously();
            debugPrint('✅ Sesion anonima de Supabase iniciada.');
          } catch (e) {
            debugPrint('⚠️ No se pudo iniciar sesion anonima: $e');
          }
        }
      } else {
        debugPrint(
            'ℹ️ Supabase no está configurado. La app operará en modo local.');
      }
    } catch (e) {
      debugPrint(
          '⚠️ Error al inicializar Supabase: $e. Operando en modo local fallback.');
    }
  }

  SupabaseClient? get client {
    if (_isInitialized) {
      return Supabase.instance.client;
    }
    return null;
  }

  User? get currentUser => client?.auth.currentUser;
  Session? get currentSession => client?.auth.currentSession;
  bool get isAuthenticated => currentUser != null;

  // --- AUTENTICACIÓN (Email, Google, JWT) ---

  /// Registro con Email y Contraseña
  Future<AuthResponse?> signUpWithEmail({
    required String email,
    required String password,
    Map<String, dynamic>? data,
  }) async {
    if (!_isInitialized) return null;
    return await client?.auth.signUp(
      email: email,
      password: password,
      data: data,
    );
  }

  /// Inicio de Sesión con Email y Contraseña
  Future<AuthResponse?> signInWithEmail({
    required String email,
    required String password,
  }) async {
    if (!_isInitialized) return null;
    return await client?.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  /// Inicio de Sesión con Google OAuth
  Future<bool> signInWithGoogle() async {
    if (!_isInitialized) return false;
    try {
      return await client?.auth.signInWithOAuth(
            OAuthProvider.google,
            redirectTo:
                kIsWeb ? null : 'io.supabase.tualiado://login-callback/',
          ) ??
          false;
    } catch (e) {
      debugPrint('Error en OAuth Google: $e');
      return false;
    }
  }

  /// Cerrar Sesión
  Future<void> signOut() async {
    if (!_isInitialized) return;
    await client?.auth.signOut();
  }

  // --- BASE DE DATOS (RLS - Row Level Security) ---

  /// Guarda o actualiza el perfil del usuario en la tabla 'profiles'
  Future<bool> saveProfile(Map<String, dynamic> profileMap) async {
    if (!_isInitialized || currentUser == null) return false;
    try {
      final data = {
        'id': currentUser!.id,
        ...profileMap,
        'updated_at': DateTime.now().toIso8601String(),
      };
      await client?.from('profiles').upsert(data);
      return true;
    } catch (e) {
      debugPrint('Error al guardar perfil en Supabase: $e');
      return false;
    }
  }

  /// Obtiene el perfil del usuario autenticado
  Future<Map<String, dynamic>?> fetchProfile() async {
    if (!_isInitialized || currentUser == null) return null;
    try {
      final res = await client
          ?.from('profiles')
          .select()
          .eq('id', currentUser!.id)
          .maybeSingle();
      return res;
    } catch (e) {
      debugPrint('Error al consultar perfil en Supabase: $e');
      return null;
    }
  }
  Future<bool> saveMedications(List<Map<String, dynamic>> meds) async {
    if (!_isInitialized || currentUser == null) return false;
    try {
      final userId = currentUser!.id;
      for (final med in meds) {
        await client?.from('medications').upsert({
          ...med,
          'user_id': userId,
        });
      }
      return true;
    } catch (e) {
      debugPrint('Error al guardar medicamentos en Supabase: $e');
      return false;
    }
  }

  Future<List<Map<String, dynamic>>?> fetchMedications() async {
    if (!_isInitialized || currentUser == null) return null;
    try {
      final res = await client
          ?.from('medications')
          .select()
          .eq('user_id', currentUser!.id);
      return res != null ? List<Map<String, dynamic>>.from(res) : null;
    } catch (e) {
      debugPrint('Error al consultar medicamentos en Supabase: $e');
      return null;
    }
  }

  Future<bool> saveLabExams(List<Map<String, dynamic>> exams) async {
    if (!_isInitialized || currentUser == null) return false;
    try {
      final userId = currentUser!.id;
      for (final exam in exams) {
        await client?.from('lab_exams').upsert({
          ...exam,
          'user_id': userId,
        });
      }
      return true;
    } catch (e) {
      debugPrint('Error al guardar laboratorios en Supabase: $e');
      return false;
    }
  }

  Future<List<Map<String, dynamic>>?> fetchLabExams() async {
    if (!_isInitialized || currentUser == null) return null;
    try {
      final res = await client
          ?.from('lab_exams')
          .select()
          .eq('user_id', currentUser!.id);
      return res != null ? List<Map<String, dynamic>>.from(res) : null;
    } catch (e) {
      debugPrint('Error al consultar laboratorios en Supabase: $e');
      return null;
    }
  }


  /// Elimina los datos del usuario en la base de datos (Reset App)
  Future<bool> resetUserData() async {
    if (!_isInitialized || currentUser == null) return true;
    try {
      final userId = currentUser!.id;
      await client?.from('nutrition_plans').delete().eq('user_id', userId);
      await client?.from('medications').delete().eq('user_id', userId);
      await client?.from('lab_exams').delete().eq('user_id', userId);
      await client?.from('health_documents').delete().eq('user_id', userId);
      await client?.from('profiles').delete().eq('id', userId);
      await signOut();
      return true;
    } catch (e) {
      debugPrint('Error al resetear datos en Supabase: $e');
      return false;
    }
  }

  // --- ALMACENAMIENTO (Supabase Storage) ---

  /// Sube un archivo médico al bucket seguro 'health-documents'
  Future<String?> uploadHealthDocument({
    required String filePath,
    required List<int> bytes,
    required String fileName,
  }) async {
    if (!_isInitialized || currentUser == null) return null;
    try {
      final userId = currentUser!.id;
      final path = '$userId/$fileName';
      final storageResponse =
          await client?.storage.from('health-documents').uploadBinary(
                path,
                Uint8List.fromList(bytes),
                fileOptions: const FileOptions(upsert: true),
              );
      return storageResponse;
    } catch (e) {
      debugPrint('Error al subir archivo a Supabase Storage: $e');
      return null;
    }
  }
}
