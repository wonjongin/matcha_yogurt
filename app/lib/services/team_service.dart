import '../services/api_service.dart';
import '../models/models.dart';

class TeamService {
  // 팀 생성
  static Future<Team> createTeam({
    required String name,
    required String description,
    required String color,
    required String ownerId, // 서버에서 JWT로 자동 설정되므로 실제로는 사용되지 않음
  }) async {
    final response = await ApiService.post('/teams', {
      'name': name,
      'description': description,
      'color': color,
      // ownerId는 서버에서 JWT 토큰을 통해 자동으로 설정됨
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

  // === 초대 관련 메서드들 ===

  // 팀에 이메일로 초대 발송
  static Future<TeamInvitation> inviteToTeam({
    required String teamId,
    required String email,
    TeamRole role = TeamRole.member,
  }) async {
    final response = await ApiService.post('/invitations/teams/$teamId/invite', {
      'email': email,
      'role': role.name.toUpperCase(),
    }, requireAuth: true);

    final data = ApiService.handleResponse(response);
    return TeamInvitation.fromJson(data);
  }

  // 내가 받은 초대 목록 조회
  static Future<List<TeamInvitation>> getMyInvitations() async {
    try {
      final response = await ApiService.get('/invitations/my-invitations', requireAuth: true);
      final data = ApiService.handleResponse(response);
      
      // 안전한 타입 체크
      if (data is List) {
        final invitationsList = data;
        return invitationsList
            .map((invitationJson) {
              try {
                return TeamInvitation.fromJson(invitationJson as Map<String, dynamic>);
              } catch (e) {
                print('Error parsing invitation: $e');
                print('Invitation data: $invitationJson');
                return null;
              }
            })
            .where((invitation) => invitation != null)
            .cast<TeamInvitation>()
            .toList();
      } else {
        print('Unexpected data type for invitations: ${data.runtimeType}');
        print('Data: $data');
        return [];
      }
    } catch (e) {
      print('Error getting my invitations: $e');
      rethrow;
    }
  }

  // 팀의 초대 목록 조회 (팀 관리자용)
  static Future<List<TeamInvitation>> getTeamInvitations(String teamId) async {
    try {
      final response = await ApiService.get('/invitations/teams/$teamId', requireAuth: true);
      final data = ApiService.handleResponse(response);
      
      // 안전한 타입 체크
      if (data is List) {
        final invitationsList = data;
        return invitationsList
            .map((invitationJson) {
              try {
                return TeamInvitation.fromJson(invitationJson as Map<String, dynamic>);
              } catch (e) {
                print('Error parsing team invitation: $e');
                print('Invitation data: $invitationJson');
                return null;
              }
            })
            .where((invitation) => invitation != null)
            .cast<TeamInvitation>()
            .toList();
      } else {
        print('Unexpected data type for team invitations: ${data.runtimeType}');
        print('Data: $data');
        return [];
      }
    } catch (e) {
      print('Error getting team invitations: $e');
      rethrow;
    }
  }

  // 초대 수락
  static Future<void> acceptInvitation(String token) async {
    await ApiService.patch('/invitations/$token/accept', {}, requireAuth: true);
  }

  // 초대 거절
  static Future<void> declineInvitation(String token) async {
    await ApiService.patch('/invitations/$token/decline', {}, requireAuth: true);
  }

  // 초대 취소 (팀 관리자용)
  static Future<void> cancelInvitation(String invitationId) async {
    await ApiService.delete('/invitations/$invitationId', requireAuth: true);
  }

  // 사용자의 팀 데이터를 서버에서 가져오기 (파싱된 데이터 반환)
  static Future<({List<Team> teams, List<TeamMember> members, List<User> users})> getUserTeamData(String userId) async {
    final response = await ApiService.get('/teams?userId=$userId', requireAuth: true);
    final data = ApiService.handleResponse(response);
    
    final serverTeams = <Team>[];
    final serverMembers = <TeamMember>[];
    final serverUsers = <User>[];
    
    for (final teamData in data as List<dynamic>) {
      final teamJson = teamData as Map<String, dynamic>;
      
      // 팀 정보 추출
      final team = Team.fromJson(teamJson);
      serverTeams.add(team);
      
      // 멤버 정보 추출 (서버에서 include된 members 데이터)
      if (teamJson['members'] != null) {
        final members = teamJson['members'] as List<dynamic>;
        for (final memberData in members) {
          final memberJson = memberData as Map<String, dynamic>;
          
          final member = TeamMember.fromJson({
            'id': memberJson['id'],
            'teamId': memberJson['teamId'],
            'userId': memberJson['userId'],
            'role': memberJson['role'],
            'joinedAt': memberJson['joinedAt'],
            'updatedAt': memberJson['updatedAt'],
          });
          serverMembers.add(member);
          
          // 사용자 정보도 추출
          if (memberJson['user'] != null) {
            final userJson = memberJson['user'] as Map<String, dynamic>;
            final user = User.fromJson(userJson);
            serverUsers.add(user);
          }
        }
      }
    }
    
    return (teams: serverTeams, members: serverMembers, users: serverUsers);
  }
} 