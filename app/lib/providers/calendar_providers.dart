import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:table_calendar/table_calendar.dart';
import '../models/models.dart';
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

// Sample events for testing
final sampleEventsProvider = Provider<List<Event>>((ref) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  
  return [
    Event(
      title: '팀 미팅',
      description: '주간 업무 회의입니다.',
      startTime: today.add(const Duration(hours: 10)),
      endTime: today.add(const Duration(hours: 11)),
      teamId: 'team1',
      createdBy: 'user1',
      type: EventType.meeting,
      color: Colors.blue,
    ),
    Event(
      title: '프로젝트 마감',
      description: '최종 발표 준비 완료해야 합니다.',
      startTime: today.add(const Duration(days: 2, hours: 18)),
      endTime: today.add(const Duration(days: 2, hours: 19)),
      teamId: 'team1',
      createdBy: 'user2',
      type: EventType.deadline,
      color: Colors.red,
    ),
    Event(
      title: '생일 파티',
      description: '김철수 생일 축하 파티',
      startTime: today.add(const Duration(days: 5)),
      endTime: today.add(const Duration(days: 5, hours: 3)),
      teamId: 'team1',
      createdBy: 'user3',
      type: EventType.celebration,
      color: Colors.pink,
      isAllDay: true,
    ),
    Event(
      title: '코드 리뷰',
      description: '새로운 기능에 대한 코드 리뷰를 진행합니다.',
      startTime: today.add(const Duration(days: 1, hours: 14)),
      endTime: today.add(const Duration(days: 1, hours: 15, minutes: 30)),
      teamId: 'team1',
      createdBy: 'user1',
      type: EventType.meeting,
      color: Colors.green,
    ),
    Event(
      title: '문서 작성 완료',
      description: 'API 문서 작성을 완료해야 합니다.',
      startTime: today.add(const Duration(days: 3, hours: 16)),
      endTime: today.add(const Duration(days: 3, hours: 17)),
      teamId: 'team1',
      createdBy: 'user2',
      type: EventType.reminder,
      color: Colors.orange,
    ),
  ];
});

// Events provider that can be modified
final eventsProvider = StateNotifierProvider<EventsNotifier, List<Event>>((ref) {
  final sampleEvents = ref.watch(sampleEventsProvider);
  return EventsNotifier(sampleEvents);
});

// Provider to get events for a specific day
final eventsForDayProvider = Provider.family<List<Event>, DateTime>((ref, day) {
  final events = ref.watch(eventsProvider);
  return events.where((event) => isSameDay(event.startTime, day)).toList();
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

  void addEvent(Event event) {
    state = [...state, event];
  }

  void updateEvent(Event updatedEvent) {
    state = state.map((event) {
      return event.id == updatedEvent.id ? updatedEvent : event;
    }).toList();
  }

  void removeEvent(String eventId) {
    state = state.where((event) => event.id != eventId).toList();
  }

  List<Event> getEventsForDay(DateTime day) {
    return state.where((event) => isSameDay(event.startTime, day)).toList();
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