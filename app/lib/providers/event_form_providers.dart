import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/models.dart';

// Event form state
class EventFormState {
  final String title;
  final String description;
  final DateTime startTime;
  final DateTime endTime;
  final String? teamId;
  final EventType type;
  final Color? color;
  final bool isAllDay;

  EventFormState({
    this.title = '',
    this.description = '',
    DateTime? startTime,
    DateTime? endTime,
    this.teamId,
    this.type = EventType.other,
    this.color,
    this.isAllDay = false,
  })  : startTime = startTime ?? DateTime.now().add(const Duration(hours: 1)),
        endTime = endTime ?? DateTime.now().add(const Duration(hours: 2));

  EventFormState copyWith({
    String? title,
    String? description,
    DateTime? startTime,
    DateTime? endTime,
    String? teamId,
    bool clearTeamId = false,
    EventType? type,
    Color? color,
    bool? isAllDay,
  }) {
    return EventFormState(
      title: title ?? this.title,
      description: description ?? this.description,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      teamId: clearTeamId ? null : (teamId ?? this.teamId),
      type: type ?? this.type,
      color: color ?? this.color,
      isAllDay: isAllDay ?? this.isAllDay,
    );
  }
}

// Event form notifier
class EventFormNotifier extends StateNotifier<EventFormState> {
  EventFormNotifier() : super(EventFormState());

  void loadEvent(Event event) {
    state = EventFormState(
      title: event.title,
      description: event.description,
      startTime: event.startTime,
      endTime: event.endTime,
      teamId: event.teamId,
      type: event.type,
      color: event.color,
      isAllDay: event.isAllDay,
    );
  }

  void setInitialDate(DateTime date) {
    // 전달받은 date가 시간 정보를 포함하고 있으면 그대로 사용, 아니면 기본 시간(10:00) 설정
    DateTime startTime;
    
    if (date.hour == 0 && date.minute == 0) {
      // 시간 정보가 없는 경우 (00:00) - 기본 시간 설정
      startTime = DateTime(date.year, date.month, date.day, 10, 0);
    } else {
      // 시간 정보가 포함된 경우 - 그대로 사용
      startTime = date;
    }
    
    final endTime = startTime.add(const Duration(hours: 1));
    
    state = state.copyWith(
      startTime: startTime,
      endTime: endTime,
    );
  }

  void updateTitle(String title) {
    state = state.copyWith(title: title);
  }

  void updateDescription(String description) {
    state = state.copyWith(description: description);
  }

  void updateStartTime(DateTime startTime) {
    // Automatically adjust end time if it's before start time
    DateTime endTime = state.endTime;
    if (endTime.isBefore(startTime)) {
      if (state.isAllDay) {
        endTime = startTime.add(const Duration(days: 1));
      } else {
        endTime = startTime.add(const Duration(hours: 1));
      }
    }

    state = state.copyWith(
      startTime: startTime,
      endTime: endTime,
    );
  }

  void updateEndTime(DateTime endTime) {
    state = state.copyWith(endTime: endTime);
  }

  void updateTeamId(String teamId) {
    state = state.copyWith(teamId: teamId);
  }

  void clearTeamId() {
    state = state.copyWith(clearTeamId: true);
  }

  void updateType(EventType type) {
    state = state.copyWith(type: type);
  }

  void updateColor(Color? color) {
    state = state.copyWith(color: color);
  }

  void updateIsAllDay(bool isAllDay) {
    DateTime startTime = state.startTime;
    DateTime endTime = state.endTime;

    if (isAllDay) {
      // Set to start of day and next day
      startTime = DateTime(startTime.year, startTime.month, startTime.day);
      endTime = startTime.add(const Duration(days: 1));
    } else {
      // Set default working hours if switching from all day
      if (state.isAllDay) {
        startTime = DateTime(startTime.year, startTime.month, startTime.day, 10, 0);
        endTime = startTime.add(const Duration(hours: 1));
      }
    }

    state = state.copyWith(
      isAllDay: isAllDay,
      startTime: startTime,
      endTime: endTime,
    );
  }

  void reset() {
    state = EventFormState();
  }
}

// Event form provider
final eventFormProvider = StateNotifierProvider<EventFormNotifier, EventFormState>((ref) {
  return EventFormNotifier();
}); 