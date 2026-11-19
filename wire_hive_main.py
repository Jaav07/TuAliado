path = "lib/main.dart"
with open(path, "r") as f:
    content = f.read()

old_import = "import 'core/providers/app_state_provider.dart';"
new_import = "import 'core/providers/app_state_provider.dart';\nimport 'core/services/hive_service.dart';"
if new_import not in content:
    content = content.replace(old_import, new_import, 1)

old_main = """void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const TuAliadoApp());"""
new_main = """void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await HiveService.initialize();
  AppStateProvider.instance.loadPersistedMedications();
  runApp(const TuAliadoApp());"""

if old_main in content:
    content = content.replace(old_main, new_main, 1)
    with open(path, "w") as f:
        f.write(content)
    print("OK: main.dart conectado con HiveService")
else:
    print("AVISO: no coincidio el bloque de main()")
