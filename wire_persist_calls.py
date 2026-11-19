path = "lib/core/providers/app_state_provider.dart"
with open(path, "r") as f:
    content = f.read()

replacements = [
    (
        "  void addMedication(Medication med) {\n    _medications.insert(0, med);\n    notifyListeners();\n  }",
        "  void addMedication(Medication med) {\n    _medications.insert(0, med);\n    _persistMedications();\n    notifyListeners();\n  }",
    ),
    (
        "        lastUpdated: DateTime.now(),\n      ),\n    );\n    notifyListeners();\n  }\n  /// Fusiona",
        "        lastUpdated: DateTime.now(),\n      ),\n    );\n    _persistMedications();\n    notifyListeners();\n  }\n  /// Fusiona",
    ),
]

count = 0
for old, new in replacements:
    if old in content:
        content = content.replace(old, new, 1)
        count += 1
    else:
        print("AVISO: no encontrado ->", old[:50])

with open(path, "w") as f:
    f.write(content)
print(f"OK: {count}/2 reemplazos aplicados")
