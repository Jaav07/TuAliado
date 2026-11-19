path = "lib/core/widgets/tualiado_modals.dart"
with open(path, "r") as f:
    content = f.read()

if "core/services/gemini_service.dart" not in content:
    content = content.replace(
        "import 'package:file_picker/file_picker.dart';",
        "import 'package:file_picker/file_picker.dart';\n"
        "import '../services/gemini_service.dart';",
        1
    )
    print("Import de GeminiService agregado")
else:
    print("Import ya presente")

marker = "void _handleSubmitted(String text) {"
start = content.find(marker)
if start == -1:
    print("ERROR: no se encontró _handleSubmitted (puede que ya haya sido reemplazada)")
else:
    brace_open = content.find("{", start)
    depth = 1
    i = brace_open + 1
    while depth > 0:
        if content[i] == "{":
            depth += 1
        elif content[i] == "}":
            depth -= 1
        i += 1
    func_end = i
    old_func = content[start:func_end]
    print("Función original encontrada, longitud:", len(old_func))

    new_func = '''Future<void> _handleSubmitted(String text) async {
    if (text.trim().isEmpty) return;
    _textController.clear();
    setState(() {
      _messages.add(_ChatMessage(text: text, isTuAliado: false));
      _isTyping = true;
    });

    final lower = text.toLowerCase();
    String? actionModule;
    if (lower.contains('agrega') ||
        lower.contains('tomo') ||
        lower.contains('pastilla') ||
        lower.contains('medicamento')) {
      final medName = text
          .replaceAll(
              RegExp(r'agrega|tomo|pastilla|medicamento', caseSensitive: false),
              '')
          .trim();
      final name = medName.isEmpty ? 'Nuevo Medicamento' : medName;
      AppStateProvider.instance.addMedication(
        Medication(
          id: DateTime.now().millisecondsSinceEpoch,
          name: name,
          dosage: 'Según indicación por chat IA',
          stockDays: 30,
          deliveryDate: '30 días',
          status: 'active',
        ),
      );
      actionModule = 'meds';
    }

    final history = _messages
        .take(_messages.length - 1)
        .map((m) => {
              'role': m.isTuAliado ? 'model' : 'user',
              'text': m.text,
            })
        .toList();

    final aiReply = await GeminiService.sendMessage(
      userMessage: text,
      history: history,
    );

    if (!mounted) return;
    setState(() {
      _isTyping = false;
      _messages.add(
        _ChatMessage(
          text: aiReply ?? 'No pude responder en este momento. Intenta de nuevo.',
          isTuAliado: true,
          actionModule: actionModule,
        ),
      );
    });
  }'''

    content = content[:start] + new_func + content[func_end:]
    print("_handleSubmitted reemplazada correctamente")

old_field = "  final List<_ChatMessage> _messages = [];"
new_field = "  final List<_ChatMessage> _messages = [];\n  bool _isTyping = false;"
if "_isTyping = false;" in content:
    print("Campo _isTyping ya presente, no se duplica")
elif old_field in content:
    content = content.replace(old_field, new_field, 1)
    print("Campo _isTyping agregado")
else:
    print("ERROR: no se encontró el campo _messages para agregar _isTyping")

old_list = """          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];"""
new_list = """          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length + (_isTyping ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == _messages.length) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 6),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: SizedBox(
                        width: 40,
                        height: 24,
                        child: Center(
                          child: SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        ),
                      ),
                    ),
                  );
                }
                final msg = _messages[index];"""

if new_list.split("\\n")[3] in content:
    print("Indicador de escritura ya presente, no se duplica")
elif old_list in content:
    content = content.replace(old_list, new_list, 1)
    print("Indicador de 'escribiendo...' agregado al ListView")
else:
    print("ERROR: no se encontró el ListView.builder para agregar el indicador")

with open(path, "w") as f:
    f.write(content)
