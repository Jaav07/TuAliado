import 'package:flutter/material.dart';
import '../../../../core/providers/app_state_provider.dart';
import '../../../../core/theme/app_theme.dart';

class _WelcomeScreenState extends State<WelcomeScreen>
    with TickerProviderStateMixin {
  late AnimationController _breathCtrl;
  late Animation<double> _breathAnim;
  late AnimationController _rotateCtrl;

  bool _isInteracting = false;

  @override
  void initState() {
    super.initState();

    _breathCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);
    _breathAnim = Tween<double>(begin: 0.96, end: 1.04).animate(
      CurvedAnimation(parent: _breathCtrl, curve: Curves.easeInOut),
    );

    _rotateCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
  }

  @override
  void dispose() {
    _breathCtrl.dispose();
    _rotateCtrl.dispose();
    super.dispose();
  }

  void _handlePress({bool skipRegistration = false}) {
    if (_isInteracting) return;
    setState(() {
      _isInteracting = true;
    });

    _rotateCtrl.forward();

    Future.delayed(const Duration(milliseconds: 900), () {
      if (!mounted) return;
      setState(() {
        _isInteracting = false;
      });
      _rotateCtrl.reset();
      if (skipRegistration) {
        widget.onSkipPressed?.call();
      } else {
        widget.onStartPressed();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isOnboarded = AppStateProvider.instance.isOnboarded;
    final user = AppStateProvider.instance.profile;
    final userName = user?.name ?? 'Jorge Aguirre';

    return Scaffold(
      backgroundColor: AppColors.warmCream,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28.0, vertical: 24.0),
          child: Column(
            children: [
              const SizedBox(height: 20),
              // Esfera 3D con animación de respiración y giro interactivo
              AnimatedBuilder(
                animation: _breathAnim,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _breathAnim.value,
                    child: child,
                  );
                },
                child: AnimatedBuilder(
                  animation: _rotateCtrl,
                  builder: (context, child) {
                    return Transform.rotate(
                      angle: _rotateCtrl.value * 6.28318,
                      child: child,
                    );
                  },
                  child: Container(
                    width: 170,
                    height: 170,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.deepTeal.withValues(alpha: 0.35),
                          blurRadius: 30,
                          offset: const Offset(0, 12),
                        ),
                      ],
                    ),
                    child: ClipOval(
                      child: Image.asset(
                        'assets/Esfera3D_TuAliado.jpeg',
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Image.asset(
                          'assets/Esfera3D_Tu.png',
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            color: AppColors.deepTeal,
                            child: const Center(
                              child: Text('+',
                                  style: TextStyle(
                                      fontSize: 64, color: Colors.white)),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              if (isOnboarded) ...[
                // Saludo Destacado para usuario registrado
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20.0, vertical: 16.0),
                  decoration: BoxDecoration(
                    color: AppColors.deepTeal.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: AppColors.deepTeal.withValues(alpha: 0.25),
                      width: 1.5,
                    ),
                  ),
                  child: Column(
                    children: [
                      Text(
                        '¡Hola, $userName! 💙',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: AppColors.deepTeal,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Tu Aliado te ayuda a entender la Evolución de tu salud!',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          color: Color(0xFF1A1C1E),
                          fontWeight: FontWeight.w500,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
              ] else ...[
                const Text(
                  'TuAliado',
                  style: TextStyle(
                    fontSize: 34,
                    fontWeight: FontWeight.w800,
                    color: AppColors.deepTeal,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Tu Aliado te ayuda a entender la Evolución de tu salud con claridad y tranquilidad.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    height: 1.5,
                    color: AppColors.textGray,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],

              const Spacer(),

              // Botón COMENZAR / CENTRO DE GESTIONES
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.deepTeal,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 4,
                  ),
                  onPressed: _isInteracting ? null : () => _handlePress(),
                  child: Text(
                    isOnboarded ? 'Ir a mi panel' : 'Comenzar',
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),

              if (!isOnboarded) ...[
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.deepTeal,
                      side: const BorderSide(
                          color: AppColors.deepTeal, width: 1.5),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    onPressed: _isInteracting
                        ? null
                        : () => _handlePress(skipRegistration: true),
                    child: const Text(
                      'Continuar sin registrarme',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }
}

class WelcomeScreen extends StatefulWidget {
  final VoidCallback onStartPressed;
  final VoidCallback? onSkipPressed;

  const WelcomeScreen({
    super.key,
    required this.onStartPressed,
    this.onSkipPressed,
  });

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}
