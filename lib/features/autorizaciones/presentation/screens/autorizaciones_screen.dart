import 'package:flutter/material.dart';
import '../../../../core/providers/app_state_provider.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/models/authorization_request.dart';

class AutorizacionesScreen extends StatelessWidget {
  const AutorizacionesScreen({super.key});

  Color _statusColor(AuthorizationStatus status) {
    return status == AuthorizationStatus.autorizada
        ? const Color(0xFF15803D)
        : const Color(0xFFD97706);
  }

  Map<String, List<AuthorizationRequest>> _groupBySpecialty(
      List<AuthorizationRequest> items) {
    final map = <String, List<AuthorizationRequest>>{};
    for (final item in items) {
      final key = item.specialty.trim().isEmpty
          ? 'Sin especialidad'
          : item.specialty.trim();
      map.putIfAbsent(key, () => []).add(item);
    }
    return map;
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: AppStateProvider.instance,
      builder: (context, _) {
        final requests = AppStateProvider.instance.authorizations;
        final grouped = _groupBySpecialty(requests);

        return Scaffold(
          backgroundColor: AppColors.warmCream,
          appBar: AppBar(
            title: const Text('Órdenes y Autorizaciones'),
            backgroundColor: AppColors.deepTeal,
            foregroundColor: Colors.white,
            elevation: 0,
          ),
          body: requests.isEmpty
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: Text(
                      'Aún no tienes órdenes ni trámites registrados.\n\nUsa el botón "+" para tomar foto de una orden médica, remisión a especialista, o captura de pantalla del correo de tu EPS.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          color: AppColors.textGray, fontSize: 14, height: 1.5),
                    ),
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.all(20),
                  children: grouped.entries.expand((entry) {
                    final items = <Widget>[
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10, top: 6),
                        child: Text(
                          entry.key,
                          style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: AppColors.deepTeal),
                        ),
                      ),
                    ];
                    for (final req in entry.value) {
                      final index = requests.indexOf(req);
                      items.add(
                        _AuthorizationCard(
                          request: req,
                          statusColor: _statusColor(req.status),
                          onToggleStatus: () => AppStateProvider.instance
                              .toggleAuthorizationStatus(index),
                        ),
                      );
                    }
                    items.add(const SizedBox(height: 10));
                    return items;
                  }).toList(),
                ),
        );
      },
    );
  }
}

class _AuthorizationCard extends StatelessWidget {
  final AuthorizationRequest request;
  final Color statusColor;
  final VoidCallback onToggleStatus;

  const _AuthorizationCard({
    required this.request,
    required this.statusColor,
    required this.onToggleStatus,
  });

  @override
  Widget build(BuildContext context) {
    final hasVigencia = request.validFrom.trim().isNotEmpty ||
        request.validUntil.trim().isNotEmpty;

    return Dismissible(
      key: ValueKey(request.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) =>
          AppStateProvider.instance.deleteAuthorization(request.id),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color: const Color(0xFFDC2626),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      child: Card(
        elevation: 2,
        shadowColor: AppColors.shadowBlue,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        margin: const EdgeInsets.only(bottom: 14),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text('📋', style: TextStyle(fontSize: 22)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      request.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Especialidad como chip destacado
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.softBlue,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      request.specialty,
                      style: const TextStyle(
                          color: AppColors.deepTeal,
                          fontWeight: FontWeight.bold,
                          fontSize: 11),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              Text('Médico: ${request.orderedBy}',
                  style:
                      const TextStyle(color: AppColors.textGray, fontSize: 13)),
              const SizedBox(height: 2),
              Text('Fecha de emisión: ${request.requestDate}',
                  style:
                      const TextStyle(color: AppColors.textGray, fontSize: 12)),

              if (hasVigencia) ...[
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF7ED),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFFED7AA)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.event_available,
                          size: 16, color: Color(0xFFB45309)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Vigencia: ${request.validFrom.trim().isNotEmpty ? request.validFrom : "—"} → ${request.validUntil.trim().isNotEmpty ? request.validUntil : "sin fecha de caducidad"}',
                          style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFFB45309)),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              if (request.summary.trim().isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  request.summary,
                  style: const TextStyle(
                      color: Color(0xFF334155), fontSize: 12, height: 1.3),
                ),
              ],
              const SizedBox(height: 14),
              Align(
                alignment: Alignment.centerRight,
                child: InkWell(
                  onTap: onToggleStatus,
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          request.status == AuthorizationStatus.autorizada
                              ? Icons.check_circle
                              : Icons.hourglass_bottom,
                          size: 14,
                          color: statusColor,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          request.statusLabel,
                          style: TextStyle(
                              color: statusColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
