import '../services/api_service.dart';
import '../models/models.dart';

class TeamService {
  // 팀 생성
  static Future<Team> createTeam({
    required String name,
    required String description,
    required String color,
    required String ownerId,
  }) async {
    final response = await ApiService.post('/teams', {
      'name': name,
      'description': description,
      'color': color,
      'ownerId': ownerId,
    }, requireAuth: true);

    final data = ApiService.handleResponse(response);
    return Team.fromJson(data);
  }

  // 모든 팀 조회
  static Future<List<Team>> getAllTeams() async {
    final response = await ApiService.get('/teams', requireAuth: true);
    final data = ApiService.handleResponse(response);
    
    return (data as List<dynamic>)
        .map((teamJson) => Team.fromJson(teamJson as Map<String, dynamic>))
        .toList();
  }

  // 사용자가 속한 팀들 조회
  static Future<List<Team>> getUserTeams(String userId) async {
    final response = await ApiService.get('/teams?userId=$userId', requireAuth: true);
    final data = ApiService.handleResponse(response);
    
    return (data as List<dynamic>)
        .map((teamJson) => Team.fromJson(teamJson as Map<String, dynamic>))
        .toList();
  }

  // 특정 팀 조회
  static Future<Team> getTeam(String teamId) async {
    final response = await ApiService.get('/teams/$teamId', requireAuth: true);
    final data = ApiService.handleResponse(response);
    
    return Team.fromJson(data);
  }

  // 팀 정보 수정
  static Future<Team> updateTeam({
    required String teamId,
    String? name,
    String? description,
    String? color,
  }) async {
    final updateData = <String, dynamic>{};
    if (name != null) updateData['name'] = name;
    if (description != null) updateData['description'] = description;
    if (color != null) updateData['color'] = color;

    final response = await ApiService.patch('/teams/$teamId', updateData, requireAuth: true);
    final data = ApiService.handleResponse(response);
    
    return Team.fromJson(data);
  }

  // 팀 삭제
  static Future<void> deleteTeam(String teamId) async {
    await ApiService.delete('/teams/$teamId', requireAuth: true);
  }

  // 팀 멤버 목록 조회
  static Future<List<TeamMember>> getTeamMembers(String teamId) async {
    final response = await ApiService.get('/teams/$teamId/members', requireAuth: true);
    final data = ApiService.handleResponse(response);
    
    return (data as List<dynamic>)
        .map((memberJson) => TeamMember.fromJson(memberJson as Map<String, dynamic>))
        .toList();
  }

  // 팀 멤버 추가
  static Future<TeamMember> addMember({
    required String teamId,
    required String userId,
    TeamRole role = TeamRole.member,
  }) async {
    final response = await ApiService.post('/teams/$teamId/members', {
      'userId': userId,
      'role': role.name.toUpperCase(),
    }, requireAuth: true);

    final data = ApiService.handleResponse(response);
    return TeamMember.fromJson(data);
  }

  // 팀 멤버 제거
  static Future<void> removeMember({
    required String teamId,
    required String userId,
  }) async {
    await ApiService.delete('/teams/$teamId/members/$userId', requireAuth: true);
  }

  // 팀 멤버 역할 변경
  static Future<TeamMember> updateMemberRole({
    required String teamId,
    required String userId,
    required TeamRole role,
  }) async {
    final response = await ApiService.patch('/teams/$teamId/members/$userId/role', {
      'role': role.name.toUpperCase(),
    }, requireAuth: true);

    final data = ApiService.handleResponse(response);
    return TeamMember.fromJson(data);
  }
} 