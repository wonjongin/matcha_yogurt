import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/auth_service.dart';
import '../services/team_service.dart';
import '../services/event_service.dart';
import '../providers/calendar_providers.dart';
import '../utils/error_utils.dart';
import 'calendar_screen.dart';
import 'email_verification_screen.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _nameController = TextEditingController();
  
  bool _isLogin = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      if (_isLogin) {
        // 로그인
        final response = await AuthService.login(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );

        // 현재 사용자 정보를 상태에 저장
        ref.read(currentUserProvider.notifier).state = response.user;

        // 사용자의 팀 데이터 동기화
        await _syncUserTeamData(response.user.id);
        
        // 사용자의 일정 데이터 로드
        await _loadUserEvents(response.user.id);

        // 성공 시 메인 화면으로 이동
        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (context) => const CalendarScreen(),
            ),
          );
        }
      } else {
        // 회원가입
        final message = await AuthService.register(
          name: _nameController.text.trim(),
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );

        // 성공 시 이메일 인증 화면으로 이동
        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (context) => EmailVerificationScreen(
                email: _emailController.text.trim(),
                name: _nameController.text.trim(),
              ),
            ),
          );
        }
      }
    } catch (e) {
      // 에러 처리
      if (mounted) {
        ErrorUtils.showErrorSnackBar(context, e);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
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
      
      print('로그인 후 팀 데이터 동기화 완료: 팀 ${teamData.teams.length}개, 멤버십 ${teamData.members.length}개, 사용자 ${teamData.users.length}명');
    } catch (e) {
      print('팀 데이터 동기화 실패: $e');
      // 동기화 실패해도 로그인은 성공으로 처리
    }
  }

  Future<void> _loadUserEvents(String userId) async {
    try {
      // 서버에서 사용자의 일정 데이터 가져오기
      final events = await EventService.getUserEvents(userId: userId);
      
      // 로컬 상태에 일정 데이터 설정
      final eventsNotifier = ref.read(eventsProvider.notifier);
      eventsNotifier.state = events;
      
      print('로그인 후 일정 데이터 로드 완료: ${events.length}개');
    } catch (e) {
      print('일정 데이터 로드 실패: $e');
      // 일정 로드 실패해도 로그인은 성공으로 처리
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 로고/제목
                  Icon(
                    Icons.calendar_month,
                    size: 80,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '팀 캘린더',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '팀과 함께하는 스마트한 일정 관리',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 48),

                  // 회원가입 시에만 이름 필드 표시
                  if (!_isLogin) ...[
                    TextFormField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        labelText: '이름',
                        prefixIcon: const Icon(Icons.person),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return '이름을 입력해주세요';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                  ],

                  // 이메일 필드
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      labelText: '이메일',
                      prefixIcon: const Icon(Icons.email),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return '이메일을 입력해주세요';
                      }
                      if (!value.contains('@')) {
                        return '올바른 이메일 형식이 아닙니다';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // 비밀번호 필드
                  TextFormField(
                    controller: _passwordController,
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: '비밀번호',
                      prefixIcon: const Icon(Icons.lock),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return '비밀번호를 입력해주세요';
                      }
                      if (value.length < 6) {
                        return '비밀번호는 6자 이상이어야 합니다';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // 회원가입 시에만 비밀번호 확인 필드 표시
                  if (!_isLogin) ...[
                    TextFormField(
                      controller: _confirmPasswordController,
                      obscureText: true,
                      decoration: InputDecoration(
                        labelText: '비밀번호 확인',
                        prefixIcon: const Icon(Icons.lock_outline),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return '비밀번호 확인을 입력해주세요';
                        }
                        if (value != _passwordController.text) {
                          return '비밀번호가 일치하지 않습니다';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                  ],

                  const SizedBox(height: 8),

                  // 로그인/회원가입 버튼
                  SizedBox(
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(
                              _isLogin ? '로그인' : '회원가입',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // 로그인/회원가입 전환 버튼
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _isLogin = !_isLogin;
                        // 폼 필드 초기화
                        _nameController.clear();
                        _emailController.clear();
                        _passwordController.clear();
                        _confirmPasswordController.clear();
                      });
                    },
                    child: Text(
                      _isLogin 
                          ? '계정이 없으신가요? 회원가입'
                          : '이미 계정이 있으신가요? 로그인',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
} 