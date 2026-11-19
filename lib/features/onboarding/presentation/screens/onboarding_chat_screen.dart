import 'package:flutter/material.dart';
import '../../../../core/providers/app_state_provider.dart';
import '../../../../core/theme/app_theme.dart';

class OnboardingChatScreen extends StatefulWidget {
  final VoidCallback onOnboardingComplete;

  const OnboardingChatScreen({
    super.key,
    required this.onOnboardingComplete,
  });

  @override
  State<OnboardingChatScreen> createState() => _OnboardingChatScreenState();
}

class _OnboardingChatScreenState extends State<OnboardingChatScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController =
      TextEditingController(text: 'Jorge Aguirre');
  final TextEditingController _ageController =
      TextEditingController(text: '55');
  final TextEditingController _emailController =
      TextEditingController(text: 'jaav07@gmail.com');
  final TextEditingController _epsController =
      TextEditingController(text: 'Sanidad Militar');
  final TextEditingController _docController =
      TextEditingController(text: '1.234.567.890');
  String _selectedGender = 'Masculino';
  String _selectedRh = 'O+';

  static const List<String> _rhOptions = [
    'O+',
    'O-',
    'A+',
    'A-',
    'B+',
    'B-',
    'AB+',
    'AB-',
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _emailController.dispose();
    _epsController.dispose();
    _docController.dispose();
    super.dispose();
  }

  void _submitUserForm() {
    if (_formKey.currentState?.validate() ?? false) {
      final name = _nameController.text.trim();
      final age = int.tryParse(_ageController.text.trim()) ?? 55;
      final email = _emailController.text.trim();
      final eps = _epsController.text.trim();
      final doc = _docController.text.trim();
      final gender = _selectedGender;

      // Inicializar el estado único del usuario en AppStateProvider
      AppStateProvider.instance.initializeUser(
        name: name,
        age: age,
        gender: gender,
        email: email,
        rh: _selectedRh,
        eps: eps.isEmpty ? 'Sanidad Militar' : eps,
        document: doc.isEmpty ? '1.234.567.890' : doc,
      );

      // Redirección directa al Centro de Gestiones (Requerimiento 6)
      widget.onOnboardingComplete();
    }
  }

  InputDecoration _fieldDecoration({
    required String label,
    required IconData icon,
  }) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(fontSize: 14),
      prefixIcon: Icon(icon, size: 22),
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.warmCream,
      appBar: AppBar(
        backgroundColor: AppColors.deepTeal,
        elevation: 0,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: const Text('➕', style: TextStyle(fontSize: 16)),
            ),
            const SizedBox(width: 12),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'TuAliado',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white),
                ),
                Text(
                  'En línea • Te acompaña',
                  style: TextStyle(fontSize: 12, color: AppColors.softBlue),
                ),
              ],
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Burbuja de bienvenida de TuAliado
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.softBlue,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                '¡Hola! Qué alegría conocerte. Me llamo TuAliado y estaré aquí para ayudarte a organizar tu salud de forma clara y sin estrés. 💙\n\nPor favor, completa este pequeño formato para personalizar tu experiencia:',
                style: TextStyle(
                  fontSize: 15,
                  height: 1.5,
                  color: AppColors.deepTeal,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Formulario de Registro Inicial de Perfil
            Card(
              elevation: 4,
              shadowColor: AppColors.shadowBlue,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.assignment_ind,
                              color: AppColors.deepTeal, size: 26),
                          SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Registro Inicial de Perfil',
                              style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.deepTeal),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Nombre Completo
                      TextFormField(
                        controller: _nameController,
                        textCapitalization: TextCapitalization.words,
                        decoration: _fieldDecoration(
                            label: 'Nombre Completo *', icon: Icons.person),
                        validator: (val) => (val == null || val.trim().isEmpty)
                            ? 'Ingresa tu nombre completo'
                            : null,
                      ),
                      const SizedBox(height: 14),

                      // Edad (ahora en su propia línea, ancho completo)
                      TextFormField(
                        controller: _ageController,
                        keyboardType: TextInputType.number,
                        decoration:
                            _fieldDecoration(label: 'Edad *', icon: Icons.cake),
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) {
                            return 'Requerido';
                          }
                          final num = int.tryParse(val.trim());
                          if (num == null || num <= 0 || num > 120) {
                            return 'Inválido';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 14),

                      // Sexo (ahora en su propia línea, ancho completo)
                      DropdownButtonFormField<String>(
                        initialValue: _selectedGender,
                        isExpanded: true,
                        decoration:
                            _fieldDecoration(label: 'Sexo *', icon: Icons.wc),
                        items: const [
                          DropdownMenuItem(
                              value: 'Masculino', child: Text('Masculino')),
                          DropdownMenuItem(
                              value: 'Femenino', child: Text('Femenino')),
                          DropdownMenuItem(value: 'Otro', child: Text('Otro')),
                        ],
                        onChanged: (val) {
                          if (val != null) {
                            setState(() => _selectedGender = val);
                          }
                        },
                      ),
                      const SizedBox(height: 14),

                      // Factor Rh (nueva línea, ancho completo)
                      DropdownButtonFormField<String>(
                        initialValue: _selectedRh,
                        isExpanded: true,
                        decoration: _fieldDecoration(
                            label: 'Factor Rh *', icon: Icons.bloodtype),
                        items: _rhOptions
                            .map((rh) =>
                                DropdownMenuItem(value: rh, child: Text(rh)))
                            .toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setState(() => _selectedRh = val);
                          }
                        },
                      ),
                      const SizedBox(height: 14),

                      // E-mail
                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: _fieldDecoration(
                            label: 'E-mail *', icon: Icons.email),
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) {
                            return 'Ingresa tu e-mail';
                          }
                          if (!val.contains('@') || !val.contains('.')) {
                            return 'E-mail inválido';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 14),

                      // EPS (ahora en su propia línea, ancho completo)
                      TextFormField(
                        controller: _epsController,
                        decoration: _fieldDecoration(
                            label: 'EPS', icon: Icons.local_hospital),
                      ),
                      const SizedBox(height: 14),

                      // Documento (ahora en su propia línea, ancho completo)
                      TextFormField(
                        controller: _docController,
                        decoration: _fieldDecoration(
                            label: 'Documento', icon: Icons.badge),
                      ),
                      const SizedBox(height: 20),

                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton.icon(
                          onPressed: _submitUserForm,
                          icon: const Icon(Icons.check_circle_outline),
                          label: const Text('Completar registro',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 14)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.deepTeal,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
