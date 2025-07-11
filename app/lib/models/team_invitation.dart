import 'package:flutter/material.dart';
import 'team.dart';
import 'user.dart';
import 'team_member.dart';

enum InvitationStatus {
  pending,
  accepted,
  declined,
  expired,
}

class TeamInvitation {
  final String id;
  final String email;
  final String teamId;
  final String invitedBy;
  final TeamRole role;
  final InvitationStatus status;
  final String token;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime expiresAt;
  
  // Optional related objects
  final Team? team;
  final User? inviter;

  const TeamInvitation({
    required this.id,
    required this.email,
    required this.teamId,
    required this.invitedBy,
    required this.role,
    required this.status,
    required this.token,
    required this.createdAt,
    required this.updatedAt,
    required this.expiresAt,
    this.team,
    this.inviter,
  });

  factory TeamInvitation.fromJson(Map<String, dynamic> json) {
    return TeamInvitation(
      id: json['id'] as String,
      email: json['email'] as String,
      teamId: json['teamId'] as String,
      invitedBy: json['invitedBy'] as String,
      role: _parseTeamRole(json['role'] as String),
      status: _parseInvitationStatus(json['status'] as String),
      token: json['token'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      expiresAt: DateTime.parse(json['expiresAt'] as String),
      team: json['team'] != null ? Team.fromJson(json['team'] as Map<String, dynamic>) : null,
      inviter: json['inviter'] != null ? User.fromJson(json['inviter'] as Map<String, dynamic>) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'teamId': teamId,
      'invitedBy': invitedBy,
      'role': role.name.toUpperCase(),
      'status': status.name.toUpperCase(),
      'token': token,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'expiresAt': expiresAt.toIso8601String(),
      if (team != null) 'team': team!.toJson(),
      if (inviter != null) 'inviter': inviter!.toJson(),
    };
  }

  TeamInvitation copyWith({
    String? id,
    String? email,
    String? teamId,
    String? invitedBy,
    TeamRole? role,
    InvitationStatus? status,
    String? token,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? expiresAt,
    Team? team,
    User? inviter,
  }) {
    return TeamInvitation(
      id: id ?? this.id,
      email: email ?? this.email,
      teamId: teamId ?? this.teamId,
      invitedBy: invitedBy ?? this.invitedBy,
      role: role ?? this.role,
      status: status ?? this.status,
      token: token ?? this.token,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      expiresAt: expiresAt ?? this.expiresAt,
      team: team ?? this.team,
      inviter: inviter ?? this.inviter,
    );
  }

  static TeamRole _parseTeamRole(String roleString) {
    switch (roleString.toUpperCase()) {
      case 'OWNER':
        return TeamRole.owner;
      case 'ADMIN':
        return TeamRole.admin;
      case 'MEMBER':
        return TeamRole.member;
      case 'VIEWER':
        return TeamRole.viewer;
      default:
        return TeamRole.member;
    }
  }

  static InvitationStatus _parseInvitationStatus(String statusString) {
    switch (statusString.toUpperCase()) {
      case 'PENDING':
        return InvitationStatus.pending;
      case 'ACCEPTED':
        return InvitationStatus.accepted;
      case 'DECLINED':
        return InvitationStatus.declined;
      case 'EXPIRED':
        return InvitationStatus.expired;
      default:
        return InvitationStatus.pending;
    }
  }

  // 유틸리티 메서드들
  bool get isPending => status == InvitationStatus.pending;
  bool get isExpired => DateTime.now().isAfter(expiresAt);
  bool get canAccept => isPending && !isExpired;

  String get statusText {
    switch (status) {
      case InvitationStatus.pending:
        return '대기 중';
      case InvitationStatus.accepted:
        return '수락됨';
      case InvitationStatus.declined:
        return '거절됨';
      case InvitationStatus.expired:
        return '만료됨';
    }
  }

  Color get statusColor {
    switch (status) {
      case InvitationStatus.pending:
        return Colors.orange;
      case InvitationStatus.accepted:
        return Colors.green;
      case InvitationStatus.declined:
        return Colors.red;
      case InvitationStatus.expired:
        return Colors.grey;
    }
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TeamInvitation &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'TeamInvitation{id: $id, email: $email, teamId: $teamId, status: $status}';
  }
} 