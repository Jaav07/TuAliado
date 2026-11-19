path = "lib/features/medicamentos/presentation/screens/medicamentos_screen.dart"
with open(path, "r") as f:
    content = f.read()

old_block = """            Text(
              med.dosage,
              style: const TextStyle(color: AppColors.textGray, fontSize: 14),
            ),
            const SizedBox(height: 10),
            Text(
              'Dosis para ${med.stockDays} dias restantes',"""

new_block = """            Text(
              med.dosage,
              style: const TextStyle(color: AppColors.textGray, fontSize: 14),
            ),
            if (med.purpose != null && med.purpose!.trim().isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                'Para: ${med.purpose}',
                style: const TextStyle(
                  color: AppColors.textGray,
                  fontSize: 13,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
            const SizedBox(height: 10),
            Text(
              'Dosis para ${med.stockDays} dias restantes',"""

old_block_accented = old_block.replace("dias restantes", "d\u00edas restantes")

if old_block_accented in content:
    content = content.replace(old_block_accented, new_block.replace("dias restantes", "d\u00edas restantes"), 1)
    with open(path, "w") as f:
        f.write(content)
    print("OK: campo 'para que es' agregado a la tarjeta y guardado")
else:
    print("AVISO: no coincidio el bloque exacto")
