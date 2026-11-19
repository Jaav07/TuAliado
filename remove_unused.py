path = "lib/features/medicamentos/presentation/screens/medicamentos_screen.dart"
with open(path, "r") as f:
    content = f.read()

marker = "String _cleanFileName(String fileName) {"
start = content.find(marker)
if start == -1:
    print("AVISO: no se encontro _cleanFileName")
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
    end = i
    content = content[:start] + content[end:]
    with open(path, "w") as f:
        f.write(content)
    print("OK: _cleanFileName eliminado y guardado")
