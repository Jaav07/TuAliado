path = "lib/features/medicamentos/presentation/screens/medicamentos_screen.dart"
with open(path, "r") as f:
    content = f.read()

old_button = """          SizedBox(
            width: double.infinity,
            height: 46,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(46),
                textStyle: const TextStyle(fontSize: 15, letterSpacing: 0.3),
              ),
              onPressed: _openAddMedicationModal,
              child: const Text('boton_texto'),
            ),
          ),
          const SizedBox(height: 18),"""

old_button = old_button.replace("boton_texto", chr(0x2795) + " Agregar Nuevo Medicamento")

if old_button in content:
    content = content.replace(old_button, "", 1)
    with open(path, "w") as f:
        f.write(content)
    print("OK: boton manual eliminado y guardado")
else:
    print("AVISO: no se encontro el boton manual")
