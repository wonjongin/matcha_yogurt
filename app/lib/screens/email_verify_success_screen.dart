import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/auth_service.dart';
import '../services/team_service.dart';
import '../services/event_service.dart';
import '../providers/calendar_providers.dart';
import 'calendar_screen.dart';

class EmailVerifySuccessScreen extends ConsumerStatefulWidget {
  final String token;

  const EmailVerifySuccessScreen({
    super.key,
    required this.token,
  });

  @override
  ConsumerState<EmailVerifySuccessScreen> createState() => _EmailVerifySuccessScreenState();
}

class _EmailVerifySuccessScreenState extends ConsumerState<EmailVerifySuccessScreen> {
  bool _isLoading = true;
  bool _isSuccess = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _verifyEmail();
  }

  Future<void> _verifyEmail() async {
    try {
      final response = await AuthService.verifyEmail(widget.token);
      
      // 현재 사용자 정보를 상태에 저장
      ref.read(currentUserProvider.notifier).state = response.user;

      // 사용자의 팀 데이터 동기화
      await _syncUserTeamData(response.user.id);
      
      // 사용자의 일정 데이터 로드
      await _loadUserEvents(response.user.id);

      setState(() {
        _isSuccess = true;
        _isLoading = false;
      });

      // 3초 후 메인 화면으로 자동 이동
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => const CalendarScreen()),
            (route) => false,
          );
        }
      });
    } catch (e) {
      setState(() {
        _isSuccess = false;
        _isLoading = false;
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  Future<void> _syncUserTeamData(String userId) async {
    try {
      // 서버에서 사용자의 팀 데이터 가져오기
      final teamData = await TeamService.getUserTeamData(userId);
      
      // 로컬 상태 업데이트: 기존 로컬 데이터는 유지하고 서버 데이터 추가
      for (final team in teamData.teams) {
        final currentTeams = ref.read(teamsProvider);
        final teamExists = currentTeams.any((t) => t.id == team.id);
        if (!teamExists) {
          ref.read(teamsProvider.notifier).addTeam(team);
        } else {
          ref.read(teamsProvider.notifier).updateTeam(team);
        }
      }
      
      // 멤버십 데이터 동기화
      for (final member in teamData.members) {
        final currentMembers = ref.read(teamMembersProvider);
        final memberExists = currentMembers.any((m) => m.teamId == member.teamId && m.userId == member.userId);
        if (!memberExists) {
          ref.read(teamMembersProvider.notifier).addMember(member);
        }
      }
      
      // 사용자 정보 동기화
      for (final user in teamData.users) {
        final currentUsers = ref.read(usersProvider);
        final userExists = currentUsers.any((u) => u.id == user.id);
        if (!userExists) {
          ref.read(usersProvider.notifier).addUser(user);
        } else {
          ref.read(usersProvider.notifier).updateUser(user);
        }
      }
    } catch (e) {
      print('팀 데이터 동기화 실패: $e');
      // 동기화 실패해도 인증은 성공으로 처리
    }
  }

  Future<void> _loadUserEvents(String userId) async {
    try {
      // 서버에서 사용자의 일정 데이터 가져오기
      final events = await EventService.getUserEvents(userId: userId);
      
      // 로컬 상태에 일정 데이터 설정
      final eventsNotifier = ref.read(eventsProvider.notifier);
      eventsNotifier.state = events;
      
      print('이메일 인증 후 일정 데이터 로드 완료: ${events.length}개');
    } catch (e) {
      print('일정 데이터 로드 실패: $e');
      // 일정 로드 실패해도 인증은 성공으로 처리
    }
  }

  void _goToCalendar() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const CalendarScreen()),
      (route) => false,
    );
  }

  void _goBackToLogin() {
    Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (_isLoading) ...[
                // 로딩 중
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: CircularProgressIndicator(),
                  ),
                ),
                const SizedBox(height: 32),
                Text(
                  '이메일 인증 중...',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  '잠시만 기다려주세요',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
              ] else if (_isSuccess) ...[
                // 성공
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_circle,
                    size: 60,
                    color: Colors.green,
                  ),
                ),
                const SizedBox(height: 32),
                Text(
                  '인증 완료! 🎉',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Matcha Yogurt에 오신 것을 환영합니다!\n'
                  '이제 모든 기능을 사용하실 수 있습니다.',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.timer,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          '3초 후 자동으로 앱으로 이동합니다',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton.icon(
                    onPressed: _goToCalendar,
                    icon: const Icon(Icons.calendar_month),
                    label: const Text('지금 시작하기'),
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ] else ...[
                // 실패
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.error,
                    size: 60,
                    color: Colors.red,
                  ),
                ),
                const SizedBox(height: 32),
                Text(
                  '인증 실패',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  _errorMessage.isNotEmpty
                      ? _errorMessage
                      : '인증 링크가 유효하지 않거나 만료되었습니다.',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton.icon(
                    onPressed: _goBackToLogin,
                    icon: const Icon(Icons.login),
                    label: const Text('로그인으로 돌아가기'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey[600],
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
} 