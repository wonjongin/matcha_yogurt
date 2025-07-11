import 'package:uuid/uuid.dart';

enum TeamRole { owner, admin, member, viewer }

class TeamMember {
  final String id;
  final String teamId;
  final String userId;
  final TeamRole role;
  final DateTime joinedAt;
  final DateTime updatedAt;

  TeamMember({
    String? id,
    required this.teamId,
    required this.userId,
    this.role = TeamRole.member,
    DateTime? joinedAt,
    DateTime? updatedAt,
  })  : id = id ?? const Uuid().v4(),
        joinedAt = joinedAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  TeamMember copyWith({
    String? teamId,
    String? userId,
    TeamRole? role,
    DateTime? updatedAt,
  }) {
    return TeamMember(
      id: id,
      teamId: teamId ?? this.teamId,
      userId: userId ?? this.userId,
      role: role ?? this.role,
      joinedAt: joinedAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'teamId': teamId,
      'userId': userId,
      'role': role.name,
      'joinedAt': joinedAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory TeamMember.fromJson(Map<String, dynamic> json) {
    return TeamMember(
      id: json['id'],
      teamId: json['teamId'],
      userId: json['userId'],
      role: TeamRole.values.firstWhere(
        (r) => r.name == json['role'],
        orElse: () => TeamRole.member,
      ),
      joinedAt: DateTime.parse(json['joinedAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }

  bool get canManageTeam => role == TeamRole.owner || role == TeamRole.admin;
  bool get canEditEvents => role != TeamRole.viewer;
  bool get isOwner => role == TeamRole.owner;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TeamMember && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
} 