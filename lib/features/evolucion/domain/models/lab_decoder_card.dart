import 'package:flutter/material.dart';

/// Una tarjeta del "Decodificador de Laboratorios" en Evolución, generada
/// por IA a partir de los resultados REALES del paciente (no genérica).
class LabDecoderCard {
  final String emoji;
  final String name;
  final String subtitle;
  final String category;
  final String colorKey; // clave del color: amber, red, green, blue, purple
  final String explanation;
  final String advice;
  final List<String> actionPoints;

  const LabDecoderCard({
    required this.emoji,
    required this.name,
    required this.subtitle,
    required this.category,
    required this.colorKey,
    required this.explanation,
    required this.advice,
    required this.actionPoints,
  });

  Color get color {
    switch (colorKey) {
      case 'red':
        return const Color(0xFFDC2626);
      case 'green':
        return const Color(0xFF15803D);
      case 'blue':
        return const Color(0xFF0284C7);
      case 'purple':
        return const Color(0xFF7C3AED);
      case 'amber':
      default:
        return const Color(0xFFD97706);
    }
  }

  Map<String, dynamic> toMap() => {
        'emoji': emoji,
        'name': name,
        'subtitle': subtitle,
        'category': category,
        'color_key': colorKey,
        'explanation': explanation,
        'advice': advice,
        'action_points': actionPoints,
      };

  factory LabDecoderCard.fromMap(Map<String, dynamic> map) {
    return LabDecoderCard(
      emoji: map['emoji'] ?? '🩺',
      name: map['name'] ?? 'Hallazgo',
      subtitle: map['subtitle'] ?? '',
      category: map['category'] ?? 'General',
      colorKey: map['color_key'] ?? 'amber',
      explanation: map['explanation'] ?? '',
      advice: map['advice'] ?? '',
      actionPoints: map['action_points'] != null
          ? List<String>.from(map['action_points'] as List)
          : const [],
    );
  }
}
