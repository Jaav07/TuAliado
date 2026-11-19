path = "lib/core/widgets/tualiado_modals.dart"
with open(path, "r") as f:
    content = f.read()

marker = "Future<void> _handleSourceSelected("
start = content.find(marker)
if start == -1:
    print("AVISO: no se encontro _handleSourceSelected")
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
    func_end = i

    new_func = '''Future<void> _handleSourceSelected(
  BuildContext context,
  BuildContext sheetContext,
  DocumentSource source,
) async {
  Navigator.of(sheetContext).pop();
  String? fileName;
  List<int>? bytes;
  String mimeType = 'image/jpeg';
  try {
    switch (source) {
      case DocumentSource.foto:
        final photo = await ImagePicker().pickImage(
          source: ImageSource.camera,
          imageQuality: 85,
        );
        if (photo != null) {
          fileName = photo.name;
          bytes = await photo.readAsBytes();
          mimeType = 'image/jpeg';
        }
        break;
      case DocumentSource.imagen:
        final image = await ImagePicker().pickImage(
          source: ImageSource.gallery,
          imageQuality: 85,
        );
        if (image != null) {
          fileName = image.name;
          bytes = await image.readAsBytes();
          mimeType = image.name.toLowerCase().endsWith('.png')
              ? 'image/png'
              : 'image/jpeg';
        }
        break;
      case DocumentSource.pdf:
        final result = await FilePicker.platform.pickFiles(
          type: FileType.custom,
          allowedExtensions: ['pdf'],
          withData: true,
        );
        if (result != null && result.files.isNotEmpty) {
          fileName = result.files.single.name;
          bytes = result.files.single.bytes;
          mimeType = 'application/pdf';
        }
        break;
    }
  } catch (_) {
    fileName = null;
    bytes = null;
  }
  if (fileName == null || bytes == null || !context.mounted) return;
  showTuAliadoAnalysis(
    context,
    fileName: fileName,
    bytes: bytes,
    mimeType: mimeType,
  ).then((analyzedDoc) {
    if (analyzedDoc != null && context.mounted) {
      showAiResultBreakdownDialog(context, analyzedDoc: analyzedDoc);
    }
  });
}'''

    content = content[:start] + new_func + content[func_end:]
    with open(path, "w") as f:
        f.write(content)
    print("OK: _handleSourceSelected reemplazado y guardado")
