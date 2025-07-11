import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

enum EventType { meeting, deadline, reminder, celebration, other }

class Event {
  final String id;
  final String title;
  final String description;
  final DateTime startTime;
  final DateTime endTime;
  final String teamId;
  final String createdBy;
  final EventType type;
  final Color? color;
  final bool isAllDay;
  final List<String> attendees;
  final DateTime createdAt;
  final DateTime updatedAt;

  Event({
    String? id,
    required this.title,
    required this.description,
    required this.startTime,
    required this.endTime,
    required this.teamId,
    required this.createdBy,
    this.type = EventType.other,
    this.color,
    this.isAllDay = false,
    this.attendees = const [],
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  Event copyWith({
    String? title,
    String? description,
    DateTime? startTime,
    DateTime? endTime,
    String? teamId,
    String? createdBy,
    EventType? type,
    Color? color,
    bool? isAllDay,
    List<String>? attendees,
    DateTime? updatedAt,
  }) {
    return Event(
      id: id,
      title: title ?? this.title,
      description: description ?? this.description,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      teamId: teamId ?? this.teamId,
      createdBy: createdBy ?? this.createdBy,
      type: type ?? this.type,
      color: color ?? this.color,
      isAllDay: isAllDay ?? this.isAllDay,
      attendees: attendees ?? this.attendees,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime.toIso8601String(),
      'teamId': teamId,
      'createdBy': createdBy,
      'type': type.name,
      'color': color?.value,
      'isAllDay': isAllDay,
      'attendees': attendees,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory Event.fromJson(Map<String, dynamic> json) {
    return Event(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      startTime: DateTime.parse(json['startTime']),
      endTime: DateTime.parse(json['endTime']),
      teamId: json['teamId'],
      createdBy: json['createdBy'],
      type: EventType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => EventType.other,
      ),
      color: json['color'] != null ? Color(json['color']) : null,
      isAllDay: json['isAllDay'] ?? false,
      attendees: List<String>.from(json['attendees'] ?? []),
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Event && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
} 