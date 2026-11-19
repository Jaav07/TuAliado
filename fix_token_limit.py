path = "lib/core/services/gemini_vision_service.dart"
with open(path, "r") as f:
    content = f.read()

old = "'maxOutputTokens': 700,"
new = "'maxOutputTokens': 2048,"

if old not in content:
    print("AVISO: no se encontro el limite de tokens")
else:
    content = content.replace(old, new, 1)
    with open(path, "w") as f:
        f.write(content)
    print("OK: limite de tokens aumentado a 2048 y guardado")
