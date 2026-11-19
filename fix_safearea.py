path = "lib/core/widgets/tualiado_modals.dart"
with open(path, "r") as f:
    content = f.read()

old_open = """          Container(
            padding: const EdgeInsets.all(12),
            color: Colors.white,
            child: Row("""

new_open = """          SafeArea(
            top: false,
            child: Container(
            padding: const EdgeInsets.all(12),
            color: Colors.white,
            child: Row("""

if old_open not in content:
    print("ERROR: no se encontró el inicio de la barra de input (old_open)")
else:
    content = content.replace(old_open, new_open, 1)
    print("Inicio de la barra envuelto en SafeArea")

old_close = """                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.send, color: AppColors.primaryBlue),
                  onPressed: () => _handleSubmitted(_textController.text),
                ),
              ],
            ),
          ),
        ],"""

new_close = """                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.send, color: AppColors.primaryBlue),
                  onPressed: () => _handleSubmitted(_textController.text),
                ),
              ],
            ),
          ),
          ),
        ],"""

if old_close not in content:
    print("ERROR: no se encontró el cierre de la barra de input (old_close)")
else:
    content = content.replace(old_close, new_close, 1)
    print("Cierre del SafeArea agregado correctamente")

with open(path, "w") as f:
    f.write(content)
