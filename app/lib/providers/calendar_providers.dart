import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:table_calendar/table_calendar.dart';
import '../models/models.dart';
import '../services/event_service.dart';
export 'team_providers.dart';
export 'search_providers.dart';

// Calendar view enum
enum CalendarView { month, week, threeDay }

// 현재 로그인한 사용자
final currentUserProvider = StateProvider<User?>((ref) => null);

// 선택된 날짜
final selectedDateProvider = StateProvider<DateTime>((ref) => DateTime.now());

// 현재 캘린더 뷰
final currentViewProvider = StateProvider<CalendarView>((ref) => CalendarView.month);

// Events provider that can be modified
final eventsProvider = StateNotifierProvider<EventsNotifier, List<Event>>((ref) {
  // 빈 리스트로 시작 - 실제 일정은 서버에서 로드
  return EventsNotifier([]);
});

// Provider to get events for a specific day
final eventsForDayProvider = Provider.family<List<Event>, DateTime>((ref, day) {
  final events = ref.watch(eventsProvider);
  return events.where((event) {
    // 해당 날짜가 이벤트 기간 내에 있는지 확인
    final eventStartDay = DateTime(event.startTime.year, event.startTime.month, event.startTime.day);
    final eventEndDay = DateTime(event.endTime.year, event.endTime.month, event.endTime.day);
    final targetDay = DateTime(day.year, day.month, day.day);
    
    return targetDay.isAtSameMomentAs(eventStartDay) || 
           targetDay.isAtSameMomentAs(eventEndDay) ||
           (targetDay.isAfter(eventStartDay) && targetDay.isBefore(eventEndDay));
  }).toList();
});

// Provider to get events for selected day (used in UI)
final eventsForSelectedDayProvider = Provider.family<List<Event>, DateTime>((ref, selectedDay) {
  return ref.watch(eventsForDayProvider(selectedDay));
});

// Current selected team provider
final selectedTeamProvider = StateProvider<Team?>((ref) => null);

// Sample teams provider
final sampleTeamsProvider = Provider<List<Team>>((ref) {
  return [
    Team(
      id: 'team1',
      name: '개발팀',
      description: '소프트웨어 개발을 담당하는 팀입니다.',
      color: Colors.blue,
      ownerId: 'user1',
    ),
    Team(
      id: 'team2',
      name: '디자인팀',
      description: 'UI/UX 디자인을 담당하는 팀입니다.',
      color: Colors.purple,
      ownerId: 'user2',
    ),
    Team(
      id: 'team3',
      name: '기획팀',
      description: '제품 기획을 담당하는 팀입니다.',
      color: Colors.green,
      ownerId: 'user3',
    ),
    // 서버의 테스트 팀 추가
    Team(
      id: 'cmcyvq77b0000cnau5vvxfkgk',
      name: '테스트 팀',
      description: '팀 초대 기능을 테스트하기 위한 팀입니다',
      color: const Color(0xFF3b82f6),
      ownerId: 'cmcyvh4si0000cnsc4kuvyxsp',
    ),
    // 김민수가 생성한 팀들 추가
    Team(
      id: 'cmcywk66k000acnoqjio68mt2',
      name: '스터디',
      description: '스터디입니다',
      color: const Color(0xFF2196f3),
      ownerId: 'cmcyvhuky0001cnsc6e9xcrbv',
    ),
    Team(
      id: 'cmcywksbc0000cn9mhi8luugl',
      name: 'ㅁㄴㅇㄹ',
      description: 'ㅁㄴㅇㄹ',
      color: const Color(0xFF000000),
      ownerId: 'cmcyvhuky0001cnsc6e9xcrbv',
    ),
  ];
});

// Teams provider
final teamsProvider = StateNotifierProvider<TeamsNotifier, List<Team>>((ref) {
  final sampleTeams = ref.watch(sampleTeamsProvider);
  return TeamsNotifier(sampleTeams);
});

// EventsNotifier for managing events state
class EventsNotifier extends StateNotifier<List<Event>> {
  EventsNotifier(List<Event> initialEvents) : super(initialEvents);

  Future<Event> addEvent(Event event, String userId) async {
    try {
      // 서버에 일정 생성 요청
      final createdEvent = await EventService.createEvent(
        title: event.title,
        description: event.description,
        startTime: event.startTime,
        endTime: event.endTime,
        userId: userId,
        teamId: event.teamId.isEmpty ? null : event.teamId, // 빈 문자열인 경우 null로 변환
        eventType: event.type,
        color: event.color?.value.toRadixString(16),
        isAllDay: event.isAllDay,
      );

      // 서버 생성 성공 시 로컬 상태 업데이트
      state = [...state, createdEvent];
      return createdEvent;
    } catch (e) {
      throw Exception('일정 생성에 실패했습니다: $e');
    }
  }

  Future<Event> updateEvent(Event updatedEvent) async {
    try {
      // 서버에 일정 수정 요청
      final serverUpdatedEvent = await EventService.updateEvent(
        eventId: updatedEvent.id!,
        title: updatedEvent.title,
        description: updatedEvent.description,
        startTime: updatedEvent.startTime,
        endTime: updatedEvent.endTime,
        teamId: updatedEvent.teamId,
        eventType: updatedEvent.type,
        color: updatedEvent.color?.value.toRadixString(16),
        isAllDay: updatedEvent.isAllDay,
      );

      // 서버 수정 성공 시 로컬 상태 업데이트
      state = state.map((event) {
        return event.id == serverUpdatedEvent.id ? serverUpdatedEvent : event;
      }).toList();
      
      return serverUpdatedEvent;
    } catch (e) {
      throw Exception('일정 수정에 실패했습니다: $e');
    }
  }

  Future<void> removeEvent(String eventId) async {
    try {
      // 서버에 일정 삭제 요청
      await EventService.deleteEvent(eventId);

      // 서버 삭제 성공 시 로컬 상태 업데이트
      state = state.where((event) => event.id != eventId).toList();
    } catch (e) {
      throw Exception('일정 삭제에 실패했습니다: $e');
    }
  }

  List<Event> getEventsForDay(DateTime day) {
    return state.where((event) {
      // 해당 날짜가 이벤트 기간 내에 있는지 확인
      final eventStartDay = DateTime(event.startTime.year, event.startTime.month, event.startTime.day);
      final eventEndDay = DateTime(event.endTime.year, event.endTime.month, event.endTime.day);
      final targetDay = DateTime(day.year, day.month, day.day);
      
      return targetDay.isAtSameMomentAs(eventStartDay) || 
             targetDay.isAtSameMomentAs(eventEndDay) ||
             (targetDay.isAfter(eventStartDay) && targetDay.isBefore(eventEndDay));
    }).toList();
  }

  List<Event> getEventsForTeam(String teamId) {
    return state.where((event) => event.teamId == teamId).toList();
  }
}

// TeamsNotifier for managing teams state
class TeamsNotifier extends StateNotifier<List<Team>> {
  TeamsNotifier(List<Team> initialTeams) : super(initialTeams);

  void addTeam(Team team) {
    state = [...state, team];
  }

  void updateTeam(Team updatedTeam) {
    state = state.map((team) {
      return team.id == updatedTeam.id ? updatedTeam : team;
    }).toList();
  }

  void removeTeam(String teamId) {
    state = state.where((team) => team.id != teamId).toList();
  }

  Team? getTeamById(String teamId) {
    try {
      return state.firstWhere((team) => team.id == teamId);
    } catch (e) {
      return null;
    }
  }
}