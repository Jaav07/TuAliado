path = "lib/core/widgets/tualiado_modals.dart"
with open(path, "r") as f:
    content = f.read()

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

if "itemCount: _messages.length + (_isTyping ? 1 : 0)" in content:
    print("Indicador ya estaba presente, no se duplica")
elif old_list in content:
    content = content.replace(old_list, new_list, 1)
    with open(path, "w") as f:
        f.write(content)
    print("Indicador de 'escribiendo...' agregado correctamente")
else:
    print("ERROR: no se encontró el bloque del ListView.builder")
