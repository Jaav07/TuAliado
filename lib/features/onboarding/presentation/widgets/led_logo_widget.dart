import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

class LedLogoWidget extends StatefulWidget {
  final bool isInteracting;

  const LedLogoWidget({
    super.key,
    this.isInteracting = false,
  });

  @override
  State<LedLogoWidget> createState() => _LedLogoWidgetState();
}

class _LedLogoWidgetState extends State<LedLogoWidget>
    with TickerProviderStateMixin {
  late AnimationController _breatheController;
  late Animation<double> _breatheAnimation;
  late AnimationController _spinController;
  late Animation<double> _spinAnimation;

  @override
  void initState() {
    super.initState();
    // Animación de respiración continua (4s)
    _breatheController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);

    _breatheAnimation = Tween<double>(begin: 0.95, end: 1.08).animate(
      CurvedAnimation(
        parent: _breatheController,
        curve: Curves.easeInOut,
      ),
    );

    // Animación de giro de 360° (1s) al interactuar
    _spinController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _spinAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _spinController,
        curve: Curves.easeInOutBack,
      ),
    );
  }

  @override
  void didUpdateWidget(covariant LedLogoWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isInteracting && !oldWidget.isInteracting) {
      _spinController.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _breatheController.dispose();
    _spinController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_breatheAnimation, _spinAnimation]),
      builder: (context, child) {
        final scale = _breatheAnimation.value;
        final rotation = _spinAnimation.value * 2 * 3.141592653589793;
        final glowIntensity = widget.isInteracting ? 45.0 : 25.0;

        return Transform.scale(
          scale: scale,
          child: Transform.rotate(
            angle: rotation,
            child: Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xFFEAF4FE),
                    Color(0xFFFFFFFF),
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primaryBlue.withValues(
                      alpha: widget.isInteracting ? 0.45 : 0.22,
                    ),
                    blurRadius: glowIntensity,
                    spreadRadius: widget.isInteracting ? 10.0 : 4.0,
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  '+',
                  style: TextStyle(
                    fontSize: 76,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryBlue,
                    shadows: [
                      Shadow(
                        color: AppColors.lightBlue.withValues(alpha: 0.6),
                        blurRadius: 15,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
