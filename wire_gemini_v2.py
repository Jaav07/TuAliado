path = "lib/core/widgets/tualiado_modals.dart"

def load():
    with open(path, "r") as f:
        return f.read()

def save(content):
    with open(path, "w") as f:
        f.write(content)

content = load()

# 1. Import
if "core/services/gemini_service.dart" not in content:
    content = content.replace(
        "import 'package:file_picker/file_picker.dart';",
        "import 'package:file_picker/file_picker.dart';\n"
        "import '../services/gemini_service.dart';",
        1
    )
    save(content)
    print("Import de GeminiService agregado y GUARDADO")
else:
    print("Import ya presente")

content = load()

# 2. Replace _handleSubmitted
marker = "void _handleSubmitted(String text) {"
start = content.find(marker)
if start == -1:
    print("La función ya no tiene la firma vieja (puede que ya esté reemplazada)")
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
    save(content)
    print("_handleSubmitted reemplazada y GUARDADA")
