import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../models/models.dart';
import '../services/team_service.dart';
import '../providers/calendar_providers.dart';
import '../providers/invitation_providers.dart';

class InvitationsScreen extends ConsumerWidget {
  const InvitationsScreen({super.key});

  // 플랫폼 구분: 768px 기준으로 모바일 vs 데스크톱+태블릿
  bool isMobile(BuildContext context) => MediaQuery.of(context).size.width < 768;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final invitationsAsync = ref.watch(myInvitationsProvider);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('받은 초대'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.refresh(myInvitationsProvider),
            tooltip: '새로고침',
          ),
        ],
      ),
      body: invitationsAsync.when(
        data: (invitations) => _buildBody(context, ref, invitations),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => _buildErrorState(context, ref, error),
      ),
    );
  }

  Widget _buildBody(BuildContext context, WidgetRef ref, List<TeamInvitation> invitations) {
    if (invitations.isEmpty) {
      return _buildEmptyState(context, ref);
    }

    return RefreshIndicator(
      onRefresh: () async {
        ref.refresh(myInvitationsProvider);
      },
      child: ListView.builder(
        padding: EdgeInsets.all(isMobile(context) ? 16 : 24),
        itemCount: invitations.length,
        itemBuilder: (context, index) {
          final invitation = invitations[index];
          return _buildInvitationCard(context, ref, invitation);
        },
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, WidgetRef ref) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.mail_outline,
            size: 80,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
          ),
          const SizedBox(height: 24),
          Text(
            '받은 초대가 없습니다',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                ),
          ),
          const SizedBox(height: 12),
          Text(
            '팀에 초대받으면 여기에 표시됩니다',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          TextButton.icon(
            icon: const Icon(Icons.refresh),
            label: const Text('새로고침'),
            onPressed: () => ref.refresh(myInvitationsProvider),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, WidgetRef ref, Object error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 80,
            color: Theme.of(context).colorScheme.error.withOpacity(0.5),
          ),
          const SizedBox(height: 24),
          Text(
            '초대 목록을 불러올 수 없습니다',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Theme.of(context).colorScheme.error,
                ),
          ),
          const SizedBox(height: 12),
          Text(
            error.toString(),
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            icon: const Icon(Icons.refresh),
            label: const Text('다시 시도'),
            onPressed: () => ref.refresh(myInvitationsProvider),
          ),
        ],
      ),
    );
  }

  Widget _buildInvitationCard(BuildContext context, WidgetRef ref, TeamInvitation invitation) {
    final isExpired = invitation.isExpired;
    final canRespond = invitation.canAccept;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: invitation.statusColor.withOpacity(0.3),
            width: 1.5,
          ),
        ),
        child: Container(
          padding: EdgeInsets.all(isMobile(context) ? 16 : 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 헤더: 팀 정보와 상태
              Row(
                children: [
                  // 팀 아이콘
                  Container(
                    width: isMobile(context) ? 48 : 56,
                    height: isMobile(context) ? 48 : 56,
                    decoration: BoxDecoration(
                      color: invitation.team?.color ?? Theme.of(context).colorScheme.primary,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.group,
                      color: Colors.white,
                      size: isMobile(context) ? 24 : 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  // 팀 이름과 역할
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          invitation.team?.name ?? '알 수 없는 팀',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: _getRoleColor(invitation.role),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '${_getRoleText(invitation.role)} 역할',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            if (isExpired)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.grey,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Text(
                                  '만료됨',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // 상태 표시
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: invitation.statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: invitation.statusColor.withOpacity(0.3),
                      ),
                    ),
                    child: Text(
                      invitation.statusText,
                      style: TextStyle(
                        color: invitation.statusColor,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 16),
              
              // 초대 정보
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    _buildInfoRow(
                      context: context,
                      icon: Icons.person,
                      label: '초대한 사람',
                      value: invitation.inviter?.name ?? '알 수 없음',
                    ),
                    const SizedBox(height: 8),
                    _buildInfoRow(
                      context: context,
                      icon: Icons.schedule,
                      label: '초대 시간',
                      value: _formatDate(invitation.createdAt),
                    ),
                    const SizedBox(height: 8),
                    _buildInfoRow(
                      context: context,
                      icon: Icons.timer,
                      label: '만료 시간',
                      value: _formatDate(invitation.expiresAt),
                      isExpired: isExpired,
                    ),
                    if (invitation.team?.description?.isNotEmpty == true) ...[
                      const SizedBox(height: 8),
                      _buildInfoRow(
                        context: context,
                        icon: Icons.info_outline,
                        label: '팀 설명',
                        value: invitation.team!.description!,
                      ),
                    ],
                  ],
                ),
              ),
              
              // 액션 버튼들
              if (canRespond) ...[
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.close),
                        label: const Text('거절'),
                        onPressed: () => _declineInvitation(context, ref, invitation),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                          side: const BorderSide(color: Colors.red),
                          padding: EdgeInsets.symmetric(
                            vertical: isMobile(context) ? 12 : 16,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.check),
                        label: const Text('수락'),
                        onPressed: () => _acceptInvitation(context, ref, invitation),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: invitation.team?.color ?? Theme.of(context).colorScheme.primary,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(
                            vertical: isMobile(context) ? 12 : 16,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ] else if (!invitation.isPending) ...[
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: invitation.statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: invitation.statusColor.withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        invitation.status == InvitationStatus.accepted 
                            ? Icons.check_circle 
                            : invitation.status == InvitationStatus.declined
                                ? Icons.cancel
                                : Icons.schedule,
                        color: invitation.statusColor,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        invitation.status == InvitationStatus.accepted 
                            ? '이미 수락한 초대입니다'
                            : invitation.status == InvitationStatus.declined
                                ? '거절한 초대입니다'
                                : '만료된 초대입니다',
                        style: TextStyle(
                          color: invitation.statusColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow({
    required BuildContext context,
    required IconData icon,
    required String label,
    required String value,
    bool isExpired = false,
  }) {
    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: isExpired 
              ? Colors.red 
              : Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w500,
                  color: isExpired ? Colors.red : null,
                ),
            textAlign: TextAlign.end,
          ),
        ),
      ],
    );
  }

  Future<void> _acceptInvitation(BuildContext context, WidgetRef ref, TeamInvitation invitation) async {
    final shouldAccept = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('초대 수락'),
        content: Text('${invitation.team?.name ?? "이 팀"}에 참여하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('취소'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: invitation.team?.color ?? Theme.of(context).colorScheme.primary,
              foregroundColor: Colors.white,
            ),
            child: const Text('수락'),
          ),
        ],
      ),
    );

    if (shouldAccept == true) {
      try {
        await TeamService.acceptInvitation(invitation.token);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${invitation.team?.name ?? "팀"}에 성공적으로 참여했습니다!'),
              backgroundColor: Colors.green,
            ),
          );
          
          // 초대 목록 새로고침
          ref.refresh(myInvitationsProvider);
          
          // 로컬 상태 업데이트
          final currentUser = ref.read(currentUserProvider);
          if (currentUser != null && invitation.team != null) {
            // 1. 팀 목록에 새 팀 추가 (아직 없는 경우에만)
            final currentTeams = ref.read(teamsProvider);
            final teamExists = currentTeams.any((team) => team.id == invitation.team!.id);
            if (!teamExists) {
              ref.read(teamsProvider.notifier).addTeam(invitation.team!);
            }
            
            // 2. 팀원 목록에 새 멤버십 추가
            final newMembership = TeamMember(
              teamId: invitation.teamId,
              userId: currentUser.id,
              role: invitation.role,
              joinedAt: DateTime.now(),
            );
            ref.read(teamMembersProvider.notifier).addMember(newMembership);
            
            print('초대 수락 완료: 팀 ${invitation.team!.name}에 ${invitation.role.name} 역할로 참여');
          }
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('초대 수락 실패: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _declineInvitation(BuildContext context, WidgetRef ref, TeamInvitation invitation) async {
    final shouldDecline = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('초대 거절'),
        content: Text('${invitation.team?.name ?? "이 팀"} 초대를 거절하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('거절'),
          ),
        ],
      ),
    );

    if (shouldDecline == true) {
      try {
        await TeamService.declineInvitation(invitation.token);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${invitation.team?.name ?? "팀"} 초대를 거절했습니다'),
              backgroundColor: Colors.orange,
            ),
          );
          ref.refresh(myInvitationsProvider); // 목록 새로고침
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('초대 거절 실패: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays > 0) {
      if (difference.inDays == 1) {
        return '어제 ${DateFormat('HH:mm').format(date)}';
      } else if (difference.inDays < 7) {
        return '${difference.inDays}일 전';
      } else {
        return DateFormat('MM월 dd일').format(date);
      }
    } else if (difference.inHours > 0) {
      return '${difference.inHours}시간 전';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}분 전';
    } else {
      return '방금 전';
    }
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