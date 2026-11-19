path = "lib/core/widgets/tualiado_modals.dart"
with open(path, "r") as f:
    content = f.read()

old = """Widget _buildRow(String label, String value, {Color? color}) {
  return Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Text(label, style: const TextStyle(fontSize: 13, color: AppColors.textGray, fontWeight: FontWeight.w500)),
      Flexible(
        child: Text(
          value,
          textAlign: TextAlign.end,
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: color ?? AppColors.primaryBlue),
        ),
      ),
    ],
  );
}"""

new = """Widget _buildRow(String label, String value, {Color? color}) {
  return Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Expanded(
        flex: 3,
        child: Text(label, style: const TextStyle(fontSize: 13, color: AppColors.textGray, fontWeight: FontWeight.w500)),
      ),
      const SizedBox(width: 8),
      Expanded(
        flex: 4,
        child: Text(
          value,
          textAlign: TextAlign.end,
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: color ?? AppColors.primaryBlue),
        ),
      ),
    ],
  );
}"""

if old in content:
    content = content.replace(old, new, 1)
    with open(path, "w") as f:
        f.write(content)
    print("OK: overflow de _buildRow corregido")
else:
    print("AVISO: no coincidio el bloque")
