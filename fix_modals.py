import re

path = "lib/core/widgets/tualiado_modals.dart"
with open(path, "r") as f:
    content = f.read()

if "package:image_picker/image_picker.dart" not in content:
    content = content.replace(
        "import 'package:flutter/material.dart';",
        "import 'package:flutter/material.dart';\n"
        "import 'package:image_picker/image_picker.dart';\n"
        "import 'package:file_picker/file_picker.dart';",
        1
    )
    print("Imports agregados")
else:
    print("Imports ya estaban presentes")

marker = "void _handleSourceSelected("
start = content.find(marker)
if start == -1:
    marker2 = "Future<void> _handleSourceSelected("
    start2 = content.find(marker2)
    if start2 != -1:
        print("La función ya fue reemplazada anteriormente. No se hace nada.")
    else:
        print("ERROR: no se encontró la función _handleSourceSelected en absoluto")
else:
    func_start = start
    brace_open = content.find("{", start)
    depth = 1
    i = brace_open + 1
    while depth > 0:
        if content[i] == "{":
            depth += 1
        elif content[i] == "}":
            depth -= 1
        i += 1
    func_end = i
    old_func = content[func_start:func_end]
    print("Función original encontrada, longitud:", len(old_func))

    new_func = '''Future<void> _handleSourceSelected(
  BuildContext context,
  BuildContext sheetContext,
  DocumentSource source,
) async {
  Navigator.of(sheetContext).pop();
  String? fileName;
  try {
    switch (source) {
      case DocumentSource.foto:
        final photo = await ImagePicker().pickImage(
          source: ImageSource.camera,
          imageQuality: 85,
        );
        fileName = photo?.name;
        break;
      case DocumentSource.imagen:
        final image = await ImagePicker().pickImage(
          source: ImageSource.gallery,
          imageQuality: 85,
        );
        fileName = image?.name;
        break;
      case DocumentSource.pdf:
        final result = await FilePicker.platform.pickFiles(
          type: FileType.custom,
          allowedExtensions: ['pdf'],
        );
        fileName = result?.files.single.name;
        break;
    }
  } catch (_) {
    fileName = null;
  }
  if (fileName == null || !context.mounted) return;
  showTuAliadoAnalysis(context, fileName: fileName).then((analyzedDoc) {
    if (analyzedDoc != null && context.mounted) {
      showAiResultBreakdownDialog(context, analyzedDoc: analyzedDoc);
    }
  });
}'''

    content = content[:func_start] + new_func + content[func_end:]
    with open(path, "w") as f:
        f.write(content)
    print("Función reemplazada correctamente")
