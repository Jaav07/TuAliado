import 'package:flutter/material.dart';
import '../../../../core/providers/app_state_provider.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/tualiado_modals.dart';
import '../../../medicamentos/presentation/screens/medicamentos_screen.dart';
import '../../../nutricion/presentation/screens/nutricion_screen.dart';
import '../../../perfil/presentation/screens/perfil_screen.dart';
import '../../../laboratorios/presentation/screens/laboratorios_screen.dart';
import '../../../autorizaciones/presentation/screens/autorizaciones_screen.dart';
import '../../../agenda/presentation/screens/agenda_screen.dart';
import '../../../evolucion/presentation/screens/evolucion_screen.dart';

class HomeDashboardScreen extends StatefulWidget {
  final VoidCallback? onResetApp;

  const HomeDashboardScreen({
    super.key,
    this.onResetApp,
  });

  @override
  State<HomeDashboardScreen> createState() => _HomeDashboardScreenState();
}

class _HomeDashboardScreenState extends State<HomeDashboardScreen> {
  int _currentTab = 0;

  void _openMedications() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const MedicamentosScreen(),
      ),
    );
  }

  void _openNutrition() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const NutricionScreen(),
      ),
    );
  }

  void _openLaboratorios() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const LaboratoriosScreen(),
      ),
    );
  }

  void _openAutorizaciones() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const AutorizacionesScreen(),
      ),
    );
  }

  void _openAgenda() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const AgendaScreen(),
      ),
    );
  }

  void _openEvolucion() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const EvolucionScreen(),
      ),
    );
  }

  void _openProfile() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => PerfilScreen(onAppReset: widget.onResetApp),
      ),
    );
  }

  void _openAddInformation() {
    showAddInformationSheet(context);
  }

  void _onNavTap(int index) {
    if (index == 1) {
      _openAddInformation();
      return;
    }
    if (index == 2) {
      _openNutrition();
      return;
    }
    if (index == 3) {
      _openProfile();
      return;
    }
    setState(() {
      _currentTab = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: AppStateProvider.instance,
      builder: (context, _) {
        final medications = AppStateProvider.instance.medications;
        final labExams = AppStateProvider.instance.labExams;
        final appointments = AppStateProvider.instance.appointments;
        final authorizations = AppStateProvider.instance.authorizations;

        final labsBadge =
            '${labExams.length} ${labExams.length == 1 ? "examen" : "exámenes"}';
        final agendaBadge = appointments.isEmpty
            ? 'Sin citas'
            : '${appointments.length} ${appointments.length == 1 ? "próxima" : "próximas"}';
        final authBadge = authorizations.isEmpty
            ? 'Sin trámites'
            : '${authorizations.length} ${authorizations.length == 1 ? "trámite" : "trámites"}';

        return Scaffold(
          backgroundColor: AppColors.warmCream,
          appBar: AppBar(
            title: const Text('TuAliado'),
            backgroundColor: AppColors.deepTeal,
            foregroundColor: Colors.white,
            elevation: 0,
            actions: [
              IconButton(
                icon: const Icon(Icons.person),
                onPressed: _openProfile,
              ),
            ],
          ),
          body: SingleChildScrollView(
            padding:
                const EdgeInsets.symmetric(horizontal: 18.0, vertical: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  (DateTime.now().hour < 12)
                      ? 'Buenos días'
                      : ((DateTime.now().hour < 19)
                          ? 'Buenas tardes'
                          : 'Buenas noches'),
                  style: const TextStyle(
                      fontSize: 13, color: AppColors.warmTextMuted),
                ),
                const SizedBox(height: 2),
                Text(
                  AppStateProvider.instance.profile?.name ?? 'Bienvenido',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppColors.warmTextDark,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Tu Aliado te ayuda a entender la Evolución de tu salud!',
                  style: TextStyle(
                    fontSize: 12.5,
                    color: AppColors.warmTextMuted,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 16),
                // Cuadrícula de Módulos (Responsive Grid)
                Row(
                  children: [
                    Expanded(
                      child: _buildBigModuleCard(
                        icon: '💊',
                        title: 'Medicina',
                        badge: '${medications.length} activos',
                        onTap: _openMedications,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildBigModuleCard(
                        icon: '🧪',
                        title: 'Laboratorios',
                        badge: labsBadge,
                        onTap: _openLaboratorios,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                _buildListRow(
                  icon: '🗓️',
                  title: 'Agenda de citas',
                  badge: agendaBadge,
                  onTap: _openAgenda,
                ),
                const SizedBox(height: 8),
                _buildListRow(
                  icon: '📋',
                  title: 'Autorizaciones',
                  badge: authBadge,
                  onTap: _openAutorizaciones,
                ),
                const SizedBox(height: 8),
                _buildListRow(
                  icon: '🍎',
                  title: 'Nutrición',
                  badge: 'Plan activo',
                  onTap: _openNutrition,
                ),
                const SizedBox(height: 8),
                _buildListRow(
                  icon: '📈',
                  title: 'Evolución',
                  badge: 'Salud Biológica',
                  onTap: _openEvolucion,
                ),
              ],
            ),
          ),
          bottomNavigationBar: BottomNavigationBar(
            selectedItemColor: AppColors.primaryBlue,
            unselectedItemColor: AppColors.textGray,
            currentIndex: _currentTab,
            onTap: _onNavTap,
            type: BottomNavigationBarType.fixed,
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.home),
                label: 'Inicio',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.add_circle,
                    size: 36, color: AppColors.primaryBlue),
                label: 'TuAliado',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.restaurant_menu),
                label: 'Nutrición',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.person_outline),
                label: 'Perfil',
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBigModuleCard({
    required String icon,
    required String title,
    required String badge,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 0,
      color: AppColors.tealSoft,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(14.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(icon, style: const TextStyle(fontSize: 24)),
              const SizedBox(height: 8),
              // Sin maxLines/ellipsis: si el título no cabe en una línea,
              // pasa a una segunda en vez de cortarse ("Medicamen...").
              Text(
                title,
                style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: AppColors.tealText),
              ),
              const SizedBox(height: 2),
              Text(
                badge,
                style: const TextStyle(fontSize: 12, color: AppColors.deepTeal),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildListRow({
    required String icon,
    required String title,
    required String badge,
    required VoidCallback onTap,
  }) {
    return Material(
      color: AppColors.backgroundWhite,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.warmBorder),
          ),
          child: Row(
            children: [
              Text(icon, style: const TextStyle(fontSize: 20)),
              const SizedBox(width: 12),
              // Título y dato apilados verticalmente en vez de competir por
              // espacio en la misma fila: así ninguno se corta sin importar
              // qué tan largo sea (ej. "96% adherencia" completo).
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.warmTextDark),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      badge,
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.warmTextMuted),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right,
                  size: 18, color: AppColors.warmTextMuted),
            ],
          ),
        ),
      ),
    );
  }
}
