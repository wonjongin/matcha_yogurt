import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/models.dart';
import '../providers/calendar_providers.dart';
import 'team_form_screen.dart';
import '../services/team_service.dart'; // Added import for TeamService
import '../services/api_service.dart'; // Added import for ApiService

class TeamDetailScreen extends ConsumerStatefulWidget {
  final Team team;

  const TeamDetailScreen({
    super.key,
    required this.team,
  });

  @override
  ConsumerState<TeamDetailScreen> createState() => _TeamDetailScreenState();
}

class _TeamDetailScreenState extends ConsumerState<TeamDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoadingMembers = false;
  late Team _currentTeam;

  @override
  void initState() {
    super.initState();
    _currentTeam = widget.team;
    _tabController = TabController(length: 2, vsync: this);
    _loadTeamMembers();
  }

  Future<void> _loadTeamMembers() async {
    setState(() {
      _isLoadingMembers = true;
    });

    try {
      // 서버에서 팀원 목록 가져오기 (사용자 정보 포함)
      final response = await ApiService.get('/teams/${_currentTeam.id}/members', requireAuth: true);
      final data = ApiService.handleResponse(response);
      
      // 서버 응답에서 TeamMember와 User 정보 분리
      final serverMembers = <TeamMember>[];
      final serverUsers = <User>[];
      
      for (final memberData in data as List<dynamic>) {
        final memberJson = memberData as Map<String, dynamic>;
        
        // TeamMember 생성
        final member = TeamMember.fromJson({
          'id': memberJson['id'],
          'teamId': memberJson['teamId'], 
          'userId': memberJson['userId'],
          'role': memberJson['role'],
          'joinedAt': memberJson['joinedAt'],
          'updatedAt': memberJson['updatedAt'],
        });
        serverMembers.add(member);
        
        // User 정보 추출 (서버에서 include된 user 데이터)
        if (memberJson['user'] != null) {
          final userJson = memberJson['user'] as Map<String, dynamic>;
          final user = User.fromJson(userJson);
          serverUsers.add(user);
        }
      }
      
      // 로컬 상태 업데이트: 기존 팀원들 제거 후 서버 데이터로 교체
      ref.read(teamMembersProvider.notifier).removeAllMembersFromTeam(_currentTeam.id);
      for (final member in serverMembers) {
        ref.read(teamMembersProvider.notifier).addMember(member);
      }
      
      // 사용자 정보도 로컬 상태에 추가/업데이트
      for (final user in serverUsers) {
        final currentUsers = ref.read(usersProvider);
        final userExists = currentUsers.any((u) => u.id == user.id);
        if (!userExists) {
          ref.read(usersProvider.notifier).addUser(user);
        } else {
          ref.read(usersProvider.notifier).updateUser(user);
        }
      }
      
      print('팀 ${_currentTeam.name} 멤버 목록 동기화 완료: ${serverMembers.length}명, 사용자 정보: ${serverUsers.length}명');
    } catch (e) {
      print('팀원 목록 로드 실패: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('팀원 목록을 불러오는데 실패했습니다: $e'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingMembers = false;
        });
      }
    }
  }

  Future<void> _refreshTeamInfo() async {
    try {
      final updatedTeam = await TeamService.getTeam(_currentTeam.id);
      setState(() {
        _currentTeam = updatedTeam;
      });
      print('팀 정보 새로고침 완료: ${updatedTeam.name}');
    } catch (e) {
      print('팀 정보 새로고침 실패: $e');
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(currentUserProvider);
    final membership = ref.watch(teamMembersProvider)
        .where((member) => member.teamId == _currentTeam.id && member.userId == currentUser?.id)
        .firstOrNull;
    
    final canManage = membership?.canManageTeam ?? false;

    return Scaffold(
      appBar: AppBar(
        title: Text(_currentTeam.name),
        actions: [
          if (canManage)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => _navigateToEditTeam(),
            ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.info), text: '정보'),
            Tab(icon: Icon(Icons.people), text: '멤버'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildInfoTab(),
          _buildMembersTab(canManage),
        ],
      ),
    );
  }

  Widget _buildInfoTab() {
    final events = ref.watch(eventsProvider)
        .where((event) => event.teamId == _currentTeam.id)
        .toList();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Team info card
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: _currentTeam.color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _currentTeam.color.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: _currentTeam.color,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.group,
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _currentTeam.name,
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _currentTeam.description,
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                              ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Statistics
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                icon: Icons.people,
                title: '멤버',
                value: '${ref.watch(membersForTeamProvider(widget.team.id)).length}명',
                color: Colors.blue,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                icon: Icons.event,
                title: '일정',
                value: '${events.length}개',
                color: Colors.green,
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),

        // Recent events
        Text(
          '최근 일정',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 12),
        if (events.isEmpty)
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Column(
                children: [
                  Icon(
                    Icons.event_available,
                    size: 48,
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '아직 일정이 없습니다',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                        ),
                  ),
                ],
              ),
            ),
          )
        else
          ...events.take(5).map((event) => Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: event.color ?? widget.team.color,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        event.title,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                    Text(
                      '${event.startTime.month}/${event.startTime.day}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                          ),
                    ),
                  ],
                ),
              )).toList(),
      ],
    );
  }

  Widget _buildMembersTab(bool canManage) {
    final members = ref.watch(membersForTeamProvider(_currentTeam.id));
    final users = ref.watch(usersProvider);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (canManage) ...[
          ElevatedButton.icon(
            icon: const Icon(Icons.person_add),
            label: const Text('멤버 초대'),
            onPressed: () => _showAddMemberDialog(),
            style: ElevatedButton.styleFrom(
              backgroundColor: _currentTeam.color,
              foregroundColor: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
        ],
        
        // 멤버 목록 섹션
        Row(
          children: [
            Text(
              '팀 멤버 (${members.length})',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            if (_isLoadingMembers) ...[
              const SizedBox(width: 8),
              const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ],
          ],
        ),
        const SizedBox(height: 12),
        
        // Members list
        ...members.map((member) {
          final user = users.where((u) => u.id == member.userId).firstOrNull;
          
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: widget.team.color,
                  child: Text(
                    user?.name.substring(0, 1) ?? '?',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user?.name ?? '알 수 없는 사용자',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                      Text(
                        user?.email ?? '',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                            ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getRoleColor(member.role),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _getRoleText(member.role),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                if (canManage && member.role != TeamRole.owner) ...[
                  const SizedBox(width: 8),
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert),
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'changeRole',
                        child: Row(
                          children: [
                            Icon(Icons.edit),
                            SizedBox(width: 8),
                            Text('역할 변경'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'remove',
                        child: Row(
                          children: [
                            Icon(Icons.remove_circle, color: Colors.red),
                            SizedBox(width: 8),
                            Text('팀에서 제거', style: TextStyle(color: Colors.red)),
                          ],
                        ),
                      ),
                    ],
                    onSelected: (value) {
                      if (value == 'changeRole') {
                        _showChangeRoleDialog(member);
                      } else if (value == 'remove') {
                        _removeMember(member);
                      }
                    },
                  ),
                ],
              ],
            ),
          );
        }).toList(),
        
        // 보낸 초대 목록 섹션 (관리자만)
        if (canManage) ...[
          const SizedBox(height: 24),
          Text(
            '보낸 초대',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 12),
          FutureBuilder<List<TeamInvitation>>(
            future: canManage ? TeamService.getTeamInvitations(_currentTeam.id) : Future.value(<TeamInvitation>[]),
            builder: (context, snapshot) {
              if (!canManage) {
                return Container(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    '팀 관리 권한이 필요합니다',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                );
              }
              
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: CircularProgressIndicator(),
                  ),
                );
              }
              
              if (snapshot.hasError) {
                String errorMessage = '초대 목록을 불러오는 중 오류가 발생했습니다';
                
                // 에러 타입에 따른 친숙한 메시지 제공
                if (snapshot.error.toString().contains('403')) {
                  errorMessage = '팀 초대를 조회할 권한이 없습니다';
                } else if (snapshot.error.toString().contains('404')) {
                  errorMessage = '팀을 찾을 수 없습니다';
                }
                
                return Container(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Text(
                        errorMessage,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: () {
                          setState(() {}); // 다시 시도
                        },
                        child: const Text('다시 시도'),
                      ),
                    ],
                  ),
                );
              }
              
              final invitations = snapshot.data ?? [];
              
              if (invitations.isEmpty) {
                return Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Theme.of(context).dividerColor,
                      style: BorderStyle.solid,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.mail_outline,
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        '보낸 초대가 없습니다',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                            ),
                      ),
                    ],
                  ),
                );
              }
              
              return Column(
                children: invitations.map((invitation) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: invitation.statusColor.withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: invitation.statusColor.withOpacity(0.2),
                          child: Icon(
                            Icons.email,
                            color: invitation.statusColor,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                invitation.email,
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                              ),
                              const SizedBox(height: 2),
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: _getRoleColor(invitation.role),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      _getRoleText(invitation.role),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    '• ${_formatInvitationDate(invitation.createdAt)}',
                                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                                        ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: invitation.statusColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: invitation.statusColor.withOpacity(0.3),
                            ),
                          ),
                          child: Text(
                            invitation.statusText,
                            style: TextStyle(
                              color: invitation.statusColor,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        if (invitation.isPending) ...[
                          const SizedBox(width: 8),
                          IconButton(
                            icon: const Icon(Icons.cancel, color: Colors.red),
                            onPressed: () => _cancelInvitation(invitation),
                            tooltip: '초대 취소',
                            visualDensity: VisualDensity.compact,
                          ),
                        ],
                      ],
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ],
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 8),
          Text(
            value,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
          ),
          Text(
            title,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                ),
          ),
        ],
      ),
    );
  }

  void _navigateToEditTeam() async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => TeamFormScreen(existingTeam: _currentTeam),
      ),
    );
    
    // 팀 편집 후 돌아오면 팀 정보 새로고침
    if (result == true) {
      // 팀이 삭제되었는지 확인
      try {
        await _refreshTeamInfo();
      } catch (e) {
        // 팀을 찾을 수 없으면 (삭제되었으면) 이전 화면으로 돌아가기
        if (e.toString().contains('404') || e.toString().contains('팀을 찾을 수 없습니다')) {
          if (mounted) {
            Navigator.of(context).pop();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('팀이 삭제되어 이전 화면으로 돌아갑니다'),
                backgroundColor: Colors.orange,
              ),
            );
          }
        }
      }
    }
  }

  void _showAddMemberDialog() {
    final TextEditingController emailController = TextEditingController();
    TeamRole selectedRole = TeamRole.member;
    bool isLoading = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('멤버 초대'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: emailController,
                decoration: const InputDecoration(
                  labelText: '이메일 주소',
                  hintText: 'example@email.com',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.email),
                ),
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<TeamRole>(
                value: selectedRole,
                decoration: const InputDecoration(
                  labelText: '역할',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person),
                ),
                items: TeamRole.values
                    .where((role) => role != TeamRole.owner) // 소유자 역할은 제외
                    .map((role) => DropdownMenuItem(
                          value: role,
                          child: Text(_getRoleText(role)),
                        ))
                    .toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      selectedRole = value;
                    });
                  }
                },
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info, color: Colors.blue, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '초대 이메일이 발송되며, 상대방이 수락하면 팀에 참여됩니다.',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.blue.shade700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: isLoading ? null : () => Navigator.of(context).pop(),
              child: const Text('취소'),
            ),
            ElevatedButton(
              onPressed: isLoading ? null : () async {
                final email = emailController.text.trim();
                if (email.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('이메일을 입력해주세요')),
                  );
                  return;
                }

                // 간단한 이메일 형식 검증
                if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email)) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('올바른 이메일 형식을 입력해주세요')),
                  );
                  return;
                }

                setState(() {
                  isLoading = true;
                });

                try {
                  await _sendInvitation(email, selectedRole);
                  Navigator.of(context).pop();
                } catch (e) {
                  setState(() {
                    isLoading = false;
                  });
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: _currentTeam.color,
                foregroundColor: Colors.white,
              ),
              child: isLoading 
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text('초대 발송'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _sendInvitation(String email, TeamRole role) async {
    try {
      await TeamService.inviteToTeam(
        teamId: _currentTeam.id,
        email: email,
        role: role,
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$email로 초대가 발송되었습니다'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('초대 발송 실패: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
      rethrow;
    }
  }

  void _addMember(User user) {
    // 이 메서드는 더 이상 사용되지 않지만, 
    // 기존 코드와의 호환성을 위해 남겨둡니다.
    final member = TeamMember(
      teamId: widget.team.id,
      userId: user.id,
      role: TeamRole.member,
    );
    
    ref.read(teamMembersProvider.notifier).addMember(member);
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${user.name}님이 팀에 추가되었습니다')),
    );
  }

  void _removeMember(TeamMember member) {
    final user = ref.read(usersProvider).where((u) => u.id == member.userId).firstOrNull;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('멤버 제거'),
        content: Text('${user?.name ?? '이 사용자'}를 팀에서 제거하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () async {
              try {
                Navigator.of(context).pop(); // 다이얼로그 먼저 닫기
                
                // 로딩 표시
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Row(
                      children: [
                        SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        ),
                        SizedBox(width: 12),
                        Text('멤버 제거 중...'),
                      ],
                    ),
                    duration: Duration(seconds: 2),
                  ),
                );
                
                // 서버 API 호출
                await TeamService.removeMember(
                  teamId: _currentTeam.id,
                  userId: member.userId,
                );
                
                // 로컬 상태도 업데이트
                ref.read(teamMembersProvider.notifier).removeMember(member.id);
                
                if (mounted) {
                  ScaffoldMessenger.of(context).hideCurrentSnackBar();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('${user?.name ?? '사용자'}가 팀에서 제거되었습니다')),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).hideCurrentSnackBar();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('멤버 제거 실패: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('제거'),
          ),
        ],
      ),
    );
  }

  void _showChangeRoleDialog(TeamMember member) {
    final user = ref.read(usersProvider).where((u) => u.id == member.userId).firstOrNull;
    TeamRole selectedRole = member.role;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${user?.name ?? '사용자'}의 역할 변경'),
        content: StatefulBuilder(
          builder: (context, setState) => Column(
            mainAxisSize: MainAxisSize.min,
            children: TeamRole.values
                .where((role) => role != TeamRole.owner) // Can't change to owner
                .map((role) => RadioListTile<TeamRole>(
                      title: Text(_getRoleText(role)),
                      value: role,
                      groupValue: selectedRole,
                      onChanged: (value) {
                        setState(() {
                          selectedRole = value!;
                        });
                      },
                    ))
                .toList(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () async {
              try {
                Navigator.of(context).pop(); // 다이얼로그 먼저 닫기
                
                // 로딩 표시
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Row(
                      children: [
                        SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        ),
                        SizedBox(width: 12),
                        Text('역할 변경 중...'),
                      ],
                    ),
                    duration: Duration(seconds: 2),
                  ),
                );
                
                // 서버 API 호출
                await TeamService.updateMemberRole(
                  teamId: _currentTeam.id,
                  userId: member.userId,
                  role: selectedRole,
                );
                
                // 로컬 상태도 업데이트
                ref.read(teamMembersProvider.notifier).updateMemberRole(member.id, selectedRole);
                
                if (mounted) {
                  ScaffoldMessenger.of(context).hideCurrentSnackBar();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('${user?.name ?? '사용자'}의 역할이 변경되었습니다')),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).hideCurrentSnackBar();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('역할 변경 실패: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text('변경'),
          ),
        ],
      ),
    );
  }

  Color _getRoleColor(TeamRole role) {
    switch (role) {
      case TeamRole.owner:
        return Colors.purple;
      case TeamRole.admin:
        return Colors.orange;
      case TeamRole.member:
        return Colors.blue;
      case TeamRole.viewer:
        return Colors.grey;
    }
  }

  String _getRoleText(TeamRole role) {
    switch (role) {
      case TeamRole.owner:
        return '소유자';
      case TeamRole.admin:
        return '관리자';
      case TeamRole.member:
        return '멤버';
      case TeamRole.viewer:
        return '뷰어';
    }
  }

  String _formatInvitationDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays > 0) {
      return '${difference.inDays}일 전';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}시간 전';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}분 전';
    } else {
      return '방금 전';
    }
  }

  Future<void> _cancelInvitation(TeamInvitation invitation) async {
    final shouldCancel = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('초대 취소'),
        content: Text('${invitation.email}에게 보낸 초대를 취소하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('아니요'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('취소'),
          ),
        ],
      ),
    );

    if (shouldCancel == true) {
      try {
        await TeamService.cancelInvitation(invitation.id);
        if (mounted) {
          setState(() {}); // UI 새로고침
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${invitation.email}에게 보낸 초대가 취소되었습니다'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('초대 취소 실패: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }
} 
 