import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

class Team {
  final String id;
  final String name;
  final String description;
  final Color color;
  final String ownerId;
  final DateTime createdAt;
  final DateTime updatedAt;

  Team({
    String? id,
    required this.name,
    required this.description,
    required this.color,
    required this.ownerId,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  Team copyWith({
    String? name,
    String? description,
    Color? color,
    String? ownerId,
    DateTime? updatedAt,
  }) {
    return Team(
      id: id,
      name: name ?? this.name,
      description: description ?? this.description,
      color: color ?? this.color,
      ownerId: ownerId ?? this.ownerId,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'color': color.value,
      'ownerId': ownerId,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory Team.fromJson(Map<String, dynamic> json) {
    return Team(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      color: _parseColor(json['color']),
      ownerId: json['ownerId'],
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }

  static Color _parseColor(dynamic colorValue) {
    if (colorValue is String) {
      // Hex color string (#3b82f6) 처리
      String hexColor = colorValue.replaceAll('#', '');
      if (hexColor.length == 6) {
        hexColor = 'FF$hexColor'; // Add alpha channel
      }
      return Color(int.parse(hexColor, radix: 16));
    } else if (colorValue is int) {
      // Integer color value 처리
      return Color(colorValue);
    } else {
      // 기본값 반환
      return Colors.blue;
    }
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Team && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
} 