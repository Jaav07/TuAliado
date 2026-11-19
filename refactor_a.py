path = "lib/features/medicamentos/presentation/screens/medicamentos_screen.dart"
with open(path, "r") as f:
    content = f.read()

old_import = "import '../../../../core/widgets/tualiado_modals.dart';"
new_import = """import '../../../../core/widgets/tualiado_modals.dart';
import '../../../../core/providers/app_state_provider.dart';"""

if new_import in content:
    print("Import ya presente")
elif old_import in content:
    content = content.replace(old_import, new_import, 1)
    with open(path, "w") as f:
        f.write(content)
    print("OK: import agregado")
else:
    print("AVISO: no se encontro el import original")
