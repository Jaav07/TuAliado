import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'core/providers/app_state_provider.dart';
import 'core/services/hive_service.dart';
import 'core/services/supabase_service.dart';
import 'core/theme/app_theme.dart';
import 'features/home/presentation/screens/home_dashboard_screen.dart';
import 'features/onboarding/presentation/screens/onboarding_chat_screen.dart';
import 'features/onboarding/presentation/screens/welcome_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  try {
    await HiveService.initialize();
    AppStateProvider.instance.loadPersistedMedications();
    AppStateProvider.instance.loadPersistedLabExams();
    AppStateProvider.instance.loadPersistedAuthorizations();
    AppStateProvider.instance.loadPersistedAppointments();
    AppStateProvider.instance.loadPersistedProfile();
    AppStateProvider.instance.loadPersistedWeightEntries();
  } catch (e) {
    debugPrint('⚠️ Error al inicializar Hive o cargar persistencia local: $e');
  }

  runApp(const TuAliadoApp());

  // La interfaz debe mostrarse de inmediato. La conexión remota se configura
  // en segundo plano y nunca debe bloquear el primer fotograma.
  unawaited(SupabaseService.instance.initialize().then(
        (_) => AppStateProvider.instance.trySupabaseRestoreIfEmpty(),
      ));
}

class TuAliadoApp extends StatelessWidget {
  const TuAliadoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TuAliado',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const MainNavigationWrapper(),
    );
  }
}

class MainNavigationWrapper extends StatefulWidget {
  const MainNavigationWrapper({super.key});

  @override
  State<MainNavigationWrapper> createState() => _MainNavigationWrapperState();
}

class _MainNavigationWrapperState extends State<MainNavigationWrapper> {
  late int _currentStep;

  @override
  void initState() {
    super.initState();
    _currentStep = AppStateProvider.instance.isOnboarded ? 3 : 1;
    AppStateProvider.instance.addListener(_handleAppStateChange);
  }

  @override
  void dispose() {
    AppStateProvider.instance.removeListener(_handleAppStateChange);
    super.dispose();
  }

  void _handleAppStateChange() {
    if (!AppStateProvider.instance.isOnboarded && _currentStep != 1) {
      setState(() {
        _currentStep = 1;
      });
    }
  }

  void _resetAppToStep1() {
    setState(() {
      _currentStep = 1;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isOnboarded = AppStateProvider.instance.isOnboarded;

    if (_currentStep == 1 && !isOnboarded) {
      return WelcomeScreen(
        onStartPressed: () {
          setState(() {
            _currentStep = 2;
          });
        },
        onSkipPressed: () {
          setState(() {
            _currentStep = 3;
          });
        },
      );
    } else if (_currentStep == 1 && isOnboarded) {
      return WelcomeScreen(
        onStartPressed: () {
          setState(() {
            _currentStep = 3;
          });
        },
      );
    } else if (_currentStep == 2) {
      return OnboardingChatScreen(
        onOnboardingComplete: () {
          setState(() {
            _currentStep = 3;
          });
        },
      );
    }

    return HomeDashboardScreen(onResetApp: _resetAppToStep1);
  }
}
