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
      startTime: _parseDateTime(json['startTime']),
      endTime: _parseDateTime(json['endTime']),
      teamId: json['teamId'] ?? '', // null인 경우 빈 문자열로 처리
      createdBy: json['createdBy'] ?? '', // null인 경우 빈 문자열로 처리
      type: EventType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => EventType.other,
      ),
      color: json['color'] != null ? _parseColor(json['color']) : null,
      isAllDay: json['isAllDay'] ?? false,
      attendees: List<String>.from(json['attendees'] ?? []),
      createdAt: _parseDateTime(json['createdAt']),
      updatedAt: _parseDateTime(json['updatedAt']),
    );
  }

  // 서버에서 받은 시간을 로컬 시간으로 변환
  static DateTime _parseDateTime(String dateTimeString) {
    final parsedDateTime = DateTime.parse(dateTimeString);
    // 만약 UTC로 파싱되었다면 로컬 시간으로 변환
    return parsedDateTime.isUtc ? parsedDateTime.toLocal() : parsedDateTime;
  }

  // 서버에서 받은 색상 데이터를 Color 객체로 변환
  static Color? _parseColor(dynamic colorData) {
    if (colorData == null) return null;
    
    if (colorData is int) {
      return Color(colorData);
    }
    
    if (colorData is String) {
      try {
        // hex 문자열을 int로 변환
        final cleanHex = colorData.replaceAll('#', '');
        final hexValue = int.parse(cleanHex, radix: 16);
        
        // alpha 값이 없으면 추가
        if (cleanHex.length == 6) {
          return Color(0xFF000000 | hexValue);
        } else {
          return Color(hexValue);
        }
      } catch (e) {
        print('Color 파싱 실패: $colorData, 오류: $e');
        return null;
      }
    }
    
    return null;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Event && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
} 