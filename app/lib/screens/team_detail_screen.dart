import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/models.dart';
import '../providers/calendar_providers.dart';
import 'team_form_screen.dart';

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

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
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
        .where((member) => member.teamId == widget.team.id && member.userId == currentUser?.id)
        .firstOrNull;
    
    final canManage = membership?.canManageTeam ?? false;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.team.name),
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
        .where((event) => event.teamId == widget.team.id)
        .toList();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Team info card
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: widget.team.color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: widget.team.color.withOpacity(0.3),
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
                      color: widget.team.color,
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
                          widget.team.name,
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.team.description,
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
    final members = ref.watch(membersForTeamProvider(widget.team.id));
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
              backgroundColor: widget.team.color,
              foregroundColor: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
        ],
        
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
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _getRoleColor(member.role),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _getRoleText(member.role),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ),
                if (canManage && member.role != TeamRole.owner)
                  PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'remove') {
                        _removeMember(member);
                      } else if (value == 'change_role') {
                        _showChangeRoleDialog(member);
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'change_role',
                        child: Text('역할 변경'),
                      ),
                      const PopupMenuItem(
                        value: 'remove',
                        child: Text('멤버 제거'),
                      ),
                    ],
                  ),
              ],
            ),
          );
        }).toList(),
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

  void _navigateToEditTeam() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => TeamFormScreen(existingTeam: widget.team),
      ),
    );
  }

  void _showAddMemberDialog() {
    final allUsers = ref.read(usersProvider);
    final currentMembers = ref.read(membersForTeamProvider(widget.team.id));
    final memberUserIds = currentMembers.map((m) => m.userId).toSet();
    final availableUsers = allUsers.where((user) => !memberUserIds.contains(user.id)).toList();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('멤버 초대'),
        content: SizedBox(
          width: double.maxFinite,
          child: availableUsers.isEmpty
              ? const Text('초대할 수 있는 사용자가 없습니다.')
              : ListView.builder(
                  shrinkWrap: true,
                  itemCount: availableUsers.length,
                  itemBuilder: (context, index) {
                    final user = availableUsers[index];
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: widget.team.color,
                        child: Text(
                          user.name.substring(0, 1),
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                      title: Text(user.name),
                      subtitle: Text(user.email),
                      onTap: () {
                        _addMember(user);
                        Navigator.of(context).pop();
                      },
                    );
                  },
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('취소'),
          ),
        ],
      ),
    );
  }

  void _addMember(User user) {
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
            onPressed: () {
              ref.read(teamMembersProvider.notifier).removeMember(member.id);
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('${user?.name ?? '사용자'}가 팀에서 제거되었습니다')),
              );
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
            onPressed: () {
              ref.read(teamMembersProvider.notifier).updateMemberRole(member.id, selectedRole);
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('${user?.name ?? '사용자'}의 역할이 변경되었습니다')),
              );
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
} 