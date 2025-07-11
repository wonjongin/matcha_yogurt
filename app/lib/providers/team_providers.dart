import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/models.dart';
import 'calendar_providers.dart';

// Team members provider
final teamMembersProvider = StateNotifierProvider<TeamMembersNotifier, List<TeamMember>>((ref) {
  return TeamMembersNotifier();
});

// Provider to get members for a specific team
final membersForTeamProvider = Provider.family<List<TeamMember>, String>((ref, teamId) {
  final allMembers = ref.watch(teamMembersProvider);
  return allMembers.where((member) => member.teamId == teamId).toList();
});

// Provider to get user's teams
final userTeamsProvider = Provider.family<List<Team>, String>((ref, userId) {
  final teams = ref.watch(teamsProvider);
  final memberships = ref.watch(teamMembersProvider);
  
  final userTeamIds = memberships
      .where((member) => member.userId == userId)
      .map((member) => member.teamId)
      .toList();
  
  return teams.where((team) => userTeamIds.contains(team.id)).toList();
});

// Provider to check if user can manage a team
final canManageTeamProvider = Provider.family<bool, ({String teamId, String userId})>((ref, params) {
  final membership = ref.watch(teamMembersProvider)
      .where((member) => member.teamId == params.teamId && member.userId == params.userId)
      .firstOrNull;
  
  return membership?.canManageTeam ?? false;
});

// Sample users for team management
final sampleUsersProvider = Provider<List<User>>((ref) {
  return [
    User(
      id: 'user1',
      name: '홍길동',
      email: 'hong@example.com',
    ),
    User(
      id: 'user2',
      name: '김철수',
      email: 'kim@example.com',
    ),
    User(
      id: 'user3',
      name: '이영희',
      email: 'lee@example.com',
    ),
    User(
      id: 'user4',
      name: '박민수',
      email: 'park@example.com',
    ),
    User(
      id: 'user5',
      name: '최정은',
      email: 'choi@example.com',
    ),
  ];
});

// All users provider
final usersProvider = StateNotifierProvider<UsersNotifier, List<User>>((ref) {
  final sampleUsers = ref.watch(sampleUsersProvider);
  return UsersNotifier(sampleUsers);
});

// Team members notifier
class TeamMembersNotifier extends StateNotifier<List<TeamMember>> {
  TeamMembersNotifier() : super(_generateSampleMembers());

  static List<TeamMember> _generateSampleMembers() {
    return [
      // 개발팀 멤버
      TeamMember(
        teamId: 'team1', // 개발팀 ID (sampleTeamsProvider에서 생성될 예정)
        userId: 'user1',
        role: TeamRole.owner,
      ),
      TeamMember(
        teamId: 'team1',
        userId: 'user2',
        role: TeamRole.admin,
      ),
      TeamMember(
        teamId: 'team1',
        userId: 'user4',
        role: TeamRole.member,
      ),
      // 디자인팀 멤버
      TeamMember(
        teamId: 'team2',
        userId: 'user2',
        role: TeamRole.owner,
      ),
      TeamMember(
        teamId: 'team2',
        userId: 'user3',
        role: TeamRole.member,
      ),
      // 기획팀 멤버
      TeamMember(
        teamId: 'team3',
        userId: 'user3',
        role: TeamRole.owner,
      ),
      TeamMember(
        teamId: 'team3',
        userId: 'user5',
        role: TeamRole.member,
      ),
    ];
  }

  void addMember(TeamMember member) {
    state = [...state, member];
  }

  void updateMemberRole(String memberId, TeamRole newRole) {
    state = state.map((member) {
      return member.id == memberId ? member.copyWith(role: newRole) : member;
    }).toList();
  }

  void removeMember(String memberId) {
    state = state.where((member) => member.id != memberId).toList();
  }

  void removeAllMembersFromTeam(String teamId) {
    state = state.where((member) => member.teamId != teamId).toList();
  }

  List<TeamMember> getMembersForTeam(String teamId) {
    return state.where((member) => member.teamId == teamId).toList();
  }

  TeamMember? getMembershipForUser(String teamId, String userId) {
    try {
      return state.firstWhere(
        (member) => member.teamId == teamId && member.userId == userId,
      );
    } catch (e) {
      return null;
    }
  }
}

// Users notifier
class UsersNotifier extends StateNotifier<List<User>> {
  UsersNotifier(List<User> initialUsers) : super(initialUsers);

  void addUser(User user) {
    state = [...state, user];
  }

  void updateUser(User updatedUser) {
    state = state.map((user) {
      return user.id == updatedUser.id ? updatedUser : user;
    }).toList();
  }

  void removeUser(String userId) {
    state = state.where((user) => user.id != userId).toList();
  }

  User? getUserById(String userId) {
    try {
      return state.firstWhere((user) => user.id == userId);
    } catch (e) {
      return null;
    }
  }
} 