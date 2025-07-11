import '../services/api_service.dart';
import '../models/models.dart';

class EventService {
  // 일정 생성
  static Future<Event> createEvent({
    required String title,
    required String description,
    required DateTime startTime,
    required DateTime endTime,
    required String userId,
    String? teamId,
    String? color,
    EventType eventType = EventType.other,
    bool isAllDay = false,
  }) async {
    final response = await ApiService.post('/events', {
      'title': title,
      'description': description,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime.toIso8601String(),
      'userId': userId,
      if (teamId != null) 'teamId': teamId,
      if (color != null) 'color': color,
      'eventType': eventType.name.toUpperCase(),
      'isAllDay': isAllDay,
    }, requireAuth: true);

    final data = ApiService.handleResponse(response);
    return Event.fromJson(data);
  }

  // 모든 일정 조회 (필터링 옵션 포함)
  static Future<List<Event>> getEvents({
    List<String>? teamIds,
    List<EventType>? eventTypes,
    DateTime? startDate,
    DateTime? endDate,
    String? userId,
    String? search,
  }) async {
    final queryParams = <String, String>{};
    
    if (teamIds != null && teamIds.isNotEmpty) {
      queryParams['teamIds'] = teamIds.join(',');
    }
    if (eventTypes != null && eventTypes.isNotEmpty) {
      queryParams['eventTypes'] = eventTypes.map((type) => type.name.toUpperCase()).join(',');
    }
    if (startDate != null) {
      queryParams['startDate'] = startDate.toIso8601String();
    }
    if (endDate != null) {
      queryParams['endDate'] = endDate.toIso8601String();
    }
    if (userId != null) {
      queryParams['userId'] = userId;
    }
    if (search != null && search.isNotEmpty) {
      queryParams['search'] = search;
    }

    final queryString = queryParams.entries
        .map((entry) => '${entry.key}=${Uri.encodeComponent(entry.value)}')
        .join('&');
    
    final endpoint = queryString.isEmpty ? '/events' : '/events?$queryString';
    final response = await ApiService.get(endpoint, requireAuth: true);
    final data = ApiService.handleResponse(response);
    
    return (data as List<dynamic>)
        .map((eventJson) => Event.fromJson(eventJson as Map<String, dynamic>))
        .toList();
  }

  // 날짜 범위로 일정 조회
  static Future<List<Event>> getEventsByDateRange({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final queryString = 'startDate=${startDate.toIso8601String()}&endDate=${endDate.toIso8601String()}';
    final response = await ApiService.get('/events/date-range?$queryString', requireAuth: true);
    final data = ApiService.handleResponse(response);
    
    return (data as List<dynamic>)
        .map((eventJson) => Event.fromJson(eventJson as Map<String, dynamic>))
        .toList();
  }

  // 특정 날짜의 일정 조회
  static Future<List<Event>> getEventsByDay(DateTime date) async {
    final dateString = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    final response = await ApiService.get('/events/day/$dateString', requireAuth: true);
    final data = ApiService.handleResponse(response);
    
    return (data as List<dynamic>)
        .map((eventJson) => Event.fromJson(eventJson as Map<String, dynamic>))
        .toList();
  }

  // 팀별 일정 조회
  static Future<List<Event>> getTeamEvents({
    required String teamId,
    DateTime? startDate,
    DateTime? endDate,
    List<EventType>? eventTypes,
    String? search,
  }) async {
    final queryParams = <String, String>{};
    
    if (startDate != null) {
      queryParams['startDate'] = startDate.toIso8601String();
    }
    if (endDate != null) {
      queryParams['endDate'] = endDate.toIso8601String();
    }
    if (eventTypes != null && eventTypes.isNotEmpty) {
      queryParams['eventTypes'] = eventTypes.map((type) => type.name.toUpperCase()).join(',');
    }
    if (search != null && search.isNotEmpty) {
      queryParams['search'] = search;
    }

    final queryString = queryParams.entries
        .map((entry) => '${entry.key}=${Uri.encodeComponent(entry.value)}')
        .join('&');
    
    final endpoint = queryString.isEmpty 
        ? '/events/team/$teamId' 
        : '/events/team/$teamId?$queryString';
    
    final response = await ApiService.get(endpoint, requireAuth: true);
    final data = ApiService.handleResponse(response);
    
    return (data as List<dynamic>)
        .map((eventJson) => Event.fromJson(eventJson as Map<String, dynamic>))
        .toList();
  }

  // 사용자별 일정 조회
  static Future<List<Event>> getUserEvents({
    required String userId,
    DateTime? startDate,
    DateTime? endDate,
    List<EventType>? eventTypes,
    String? search,
  }) async {
    final queryParams = <String, String>{};
    
    if (startDate != null) {
      queryParams['startDate'] = startDate.toIso8601String();
    }
    if (endDate != null) {
      queryParams['endDate'] = endDate.toIso8601String();
    }
    if (eventTypes != null && eventTypes.isNotEmpty) {
      queryParams['eventTypes'] = eventTypes.map((type) => type.name.toUpperCase()).join(',');
    }
    if (search != null && search.isNotEmpty) {
      queryParams['search'] = search;
    }

    final queryString = queryParams.entries
        .map((entry) => '${entry.key}=${Uri.encodeComponent(entry.value)}')
        .join('&');
    
    final endpoint = queryString.isEmpty 
        ? '/events/user/$userId' 
        : '/events/user/$userId?$queryString';
    
    final response = await ApiService.get(endpoint, requireAuth: true);
    final data = ApiService.handleResponse(response);
    
    return (data as List<dynamic>)
        .map((eventJson) => Event.fromJson(eventJson as Map<String, dynamic>))
        .toList();
  }

  // 특정 일정 조회
  static Future<Event> getEvent(String eventId) async {
    final response = await ApiService.get('/events/$eventId', requireAuth: true);
    final data = ApiService.handleResponse(response);
    
    return Event.fromJson(data);
  }

  // 일정 수정
  static Future<Event> updateEvent({
    required String eventId,
    String? title,
    String? description,
    DateTime? startTime,
    DateTime? endTime,
    String? teamId,
    String? color,
    EventType? eventType,
    bool? isAllDay,
  }) async {
    final updateData = <String, dynamic>{};
    
    if (title != null) updateData['title'] = title;
    if (description != null) updateData['description'] = description;
    if (startTime != null) updateData['startTime'] = startTime.toIso8601String();
    if (endTime != null) updateData['endTime'] = endTime.toIso8601String();
    if (teamId != null) updateData['teamId'] = teamId;
    if (color != null) updateData['color'] = color;
    if (eventType != null) updateData['eventType'] = eventType.name.toUpperCase();
    if (isAllDay != null) updateData['isAllDay'] = isAllDay;

    final response = await ApiService.patch('/events/$eventId', updateData, requireAuth: true);
    final data = ApiService.handleResponse(response);
    
    return Event.fromJson(data);
  }

  // 일정 삭제
  static Future<void> deleteEvent(String eventId) async {
    await ApiService.delete('/events/$eventId', requireAuth: true);
  }

  // 일정 통계 조회
  static Future<Map<EventType, int>> getEventStats({
    String? userId,
    String? teamId,
  }) async {
    final queryParams = <String, String>{};
    if (userId != null) queryParams['userId'] = userId;
    if (teamId != null) queryParams['teamId'] = teamId;

    final queryString = queryParams.entries
        .map((entry) => '${entry.key}=${Uri.encodeComponent(entry.value)}')
        .join('&');
    
    final endpoint = queryString.isEmpty ? '/events/stats' : '/events/stats?$queryString';
    final response = await ApiService.get(endpoint, requireAuth: true);
    final data = ApiService.handleResponse(response) as List<dynamic>;
    
    final stats = <EventType, int>{};
    for (final stat in data) {
      final eventTypeString = stat['eventType'] as String;
      final count = stat['count'] as int;
      
      final eventType = EventType.values.firstWhere(
        (type) => type.name.toUpperCase() == eventTypeString,
        orElse: () => EventType.other,
      );
      
      stats[eventType] = count;
    }
    
    return stats;
  }
} 