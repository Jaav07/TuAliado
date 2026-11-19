path = "lib/features/medicamentos/presentation/screens/medicamentos_screen.dart"
with open(path, "r") as f:
    content = f.read()

marker = "class _MedicamentosScreenState extends State<MedicamentosScreen> {"
if "_onAppStateChanged" in content:
    print("Listener ya presente, no se duplica")
else:
    insertion_point = content.find(marker) + len(marker) + 1  # +1 para saltar el salto de linea

    listener_code = """  @override
  void initState() {
    super.initState();
    AppStateProvider.instance.addListener(_onAppStateChanged);
  }

  @override
  void dispose() {
    AppStateProvider.instance.removeListener(_onAppStateChanged);
    super.dispose();
  }

  void _onAppStateChanged() {
    if (mounted) setState(() {});
  }

"""
    content = content[:insertion_point] + listener_code + content[insertion_point:]
    with open(path, "w") as f:
        f.write(content)
    print("OK: listener agregado y guardado")
