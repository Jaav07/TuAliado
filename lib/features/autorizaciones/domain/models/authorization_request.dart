/// Estado de trámite de una orden/autorización médica.
/// Simplificado a 2 etapas internamente (pendiente/autorizada), pero la
/// ETIQUETA que se muestra depende del subtipo del documento (ver [subtype]):
/// una Orden aún debe tramitarse ante la EPS ("Pendiente de Autorización"),
/// mientras que una Autorización ya emitida solo falta agendarla como cita
/// ("Pendiente de Cita").
enum AuthorizationStatus { pendiente, autorizada }

/// Un único documento analizado. "orden" = trámite que el paciente aún debe
/// radicar para que se lo autoricen. "autorizacion" = ya viene autorizado
/// por la EPS, solo falta agendar la cita.
enum AuthorizationSubtype { orden, autorizacion }

extension AuthorizationSubtypeX on AuthorizationSubtype {
  /// Detecta el subtipo a partir del título del documento.
  static AuthorizationSubtype fromTitle(String title) {
    final lower = title.toLowerCase();
    if (lower.contains('autoriza')) return AuthorizationSubtype.autorizacion;
    return AuthorizationSubtype.orden;
  }
}

/// Una orden médica u trámite de autorización (Módulo Órdenes y Autorizaciones).
///
/// Ej: remisión a especialista, orden de control, orden de un procedimiento
/// que el paciente debe radicar ante su EPS para que se lo autoricen antes
/// de poder agendar la cita. Incluye vigencia (desde/hasta) cuando la orden
/// u autorización trae fecha de caducidad impresa.
class AuthorizationRequest {
  final String id;
  final String title; // ej. "Autorización Resonancia Magnética - Rodilla"
  final String specialty;
  final String orderedBy;
  final String requestDate;
  final String validFrom; // fecha desde la cual es válida la orden/autorización
  final String validUntil; // fecha de vencimiento/caducidad
  final String summary;
  final AuthorizationStatus status;
  final AuthorizationSubtype subtype;

  const AuthorizationRequest({
    required this.id,
    required this.title,
    this.specialty = 'Medicina General',
    this.orderedBy = 'Médico Tratante',
    this.requestDate = 'Hoy',
    this.validFrom = '',
    this.validUntil = '',
    this.summary = '',
    this.status = AuthorizationStatus.pendiente,
    this.subtype = AuthorizationSubtype.orden,
  });

  /// Etiqueta correcta a mostrar según el estado Y el subtipo del documento.
  String get statusLabel {
    final isAutorizacion = subtype == AuthorizationSubtype.autorizacion;
    if (status == AuthorizationStatus.autorizada) {
      return isAutorizacion ? 'Cita Agendada' : 'Autorizada';
    }
    return isAutorizacion ? 'Pendiente de Cita' : 'Pendiente de Autorización';
  }

  AuthorizationRequest copyWith({
    String? id,
    String? title,
    String? specialty,
    String? orderedBy,
    String? requestDate,
    String? validFrom,
    String? validUntil,
    String? summary,
    AuthorizationStatus? status,
    AuthorizationSubtype? subtype,
  }) {
    return AuthorizationRequest(
      id: id ?? this.id,
      title: title ?? this.title,
      specialty: specialty ?? this.specialty,
      orderedBy: orderedBy ?? this.orderedBy,
      requestDate: requestDate ?? this.requestDate,
      validFrom: validFrom ?? this.validFrom,
      validUntil: validUntil ?? this.validUntil,
      summary: summary ?? this.summary,
      status: status ?? this.status,
      subtype: subtype ?? this.subtype,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'specialty': specialty,
      'ordered_by': orderedBy,
      'request_date': requestDate,
      'valid_from': validFrom,
      'valid_until': validUntil,
      'summary': summary,
      'status': status.name,
      'subtype': subtype.name,
    };
  }

  factory AuthorizationRequest.fromMap(Map<String, dynamic> map) {
    final title = map['title'] ?? 'Trámite médico';
    return AuthorizationRequest(
      id: map['id']?.toString() ??
          DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      specialty: map['specialty'] ?? 'Medicina General',
      orderedBy: map['ordered_by'] ?? map['orderedBy'] ?? 'Médico Tratante',
      requestDate: map['request_date'] ?? map['requestDate'] ?? 'Hoy',
      validFrom: map['valid_from'] ?? map['validFrom'] ?? '',
      validUntil: map['valid_until'] ?? map['validUntil'] ?? '',
      summary: map['summary'] ?? '',
      status: AuthorizationStatus.values.firstWhere(
        (s) => s.name == map['status'],
        orElse: () => AuthorizationStatus.pendiente,
      ),
      // Si el registro es de antes de que existiera este campo (Hive viejo),
      // lo infiere del título en vez de asumir "orden" a ciegas.
      subtype: map['subtype'] != null
          ? AuthorizationSubtype.values.firstWhere(
              (s) => s.name == map['subtype'],
              orElse: () => AuthorizationSubtypeX.fromTitle(title),
            )
          : AuthorizationSubtypeX.fromTitle(title),
    );
  }
}
