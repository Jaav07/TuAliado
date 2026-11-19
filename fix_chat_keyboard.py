path = "lib/core/widgets/tualiado_modals.dart"
with open(path, "r") as f:
    content = f.read()

old_start = """    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      child: Column("""

new_start = """    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      child: Column("""

if old_start not in content:
    print("ERROR: no se encontró el inicio del Container del chat (old_start)")
else:
    content = content.replace(old_start, new_start, 1)
    print("Inicio del Container envuelto en Padding")

old_end = """              ],
            ),
          ),
        ],
      ),
    );
  }
}"""

new_end = """              ],
            ),
          ),
        ],
      ),
      ),
    );
  }
}"""

if old_end not in content:
    print("ERROR: no se encontró el final del archivo (old_end)")
else:
    content = content.replace(old_end, new_end, 1)
    print("Cierre del Container/Padding agregado correctamente")

with open(path, "w") as f:
    f.write(content)
