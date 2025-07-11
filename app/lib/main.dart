import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'screens/login_screen.dart';
import 'screens/calendar_screen.dart';
import 'services/auth_service.dart';
import 'services/api_service.dart';
import 'services/team_service.dart';
import 'providers/calendar_providers.dart';
import 'models/models.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // 환경변수 로드
  try {
    await dotenv.load(fileName: ".env");
  } catch (e) {
    // .env 파일이 없는 경우 기본값 사용
    print('Warning: .env file not found, using default values');
  }
  
  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '팀 캘린더',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF10B981), // matcha green
          brightness: Brightness.light,
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: ColorScheme.fromSeed(
            seedColor: const Color(0xFF10B981),
            brightness: Brightness.light,
          ).surface, // 바탕색과 완전히 동일하게
          foregroundColor: ColorScheme.fromSeed(
            seedColor: const Color(0xFF10B981),
            brightness: Brightness.light,
          ).onSurface, // 바탕색에 맞는 텍스트 색상
          elevation: 0,
          centerTitle: false,
          surfaceTintColor: Colors.transparent, // 웹에서 색상 변화 방지
          scrolledUnderElevation: 0, // 스크롤 시에도 색상 유지
        ),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF10B981), // matcha green
          brightness: Brightness.dark,
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: ColorScheme.fromSeed(
            seedColor: const Color(0xFF10B981),
            brightness: Brightness.dark,
          ).surface, // 다크 모드 바탕색과 완전히 동일하게
          foregroundColor: ColorScheme.fromSeed(
            seedColor: const Color(0xFF10B981),
            brightness: Brightness.dark,
          ).onSurface, // 다크 모드 텍스트 색상
          elevation: 0,
          centerTitle: false,
          surfaceTintColor: Colors.transparent, // 웹에서 색상 변화 방지
          scrolledUnderElevation: 0, // 스크롤 시에도 색상 유지
        ),
        useMaterial3: true,
      ),
      home: const AuthWrapper(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class AuthWrapper extends ConsumerStatefulWidget {
  const AuthWrapper({super.key});

  @override
  ConsumerState<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends ConsumerState<AuthWrapper> {
  bool _isLoading = true;
  bool _isAuthenticated = false;

  @override
  void initState() {
    super.initState();
    _checkAuthStatus();
  }

  Future<void> _checkAuthStatus() async {
    try {
      // 토큰이 있는지 확인
      final hasToken = await AuthService.hasToken();
      
      if (hasToken) {
        // 토큰이 있으면 현재 사용자 정보를 가져옴
        final user = await AuthService.getCurrentUser();
        ref.read(currentUserProvider.notifier).state = user;
        
        // 사용자의 팀 데이터 동기화
        await _syncUserTeamData(user.id);
        
        _isAuthenticated = true;
      } else {
        _isAuthenticated = false;
      }
    } catch (e) {
      // 토큰이 무효하거나 에러가 발생하면 로그아웃 처리
      await AuthService.logout();
      _isAuthenticated = false;
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
      
      print('사용자 팀 데이터 동기화 완료: 팀 ${teamData.teams.length}개, 멤버십 ${teamData.members.length}개, 사용자 ${teamData.users.length}명');
    } catch (e) {
      print('팀 데이터 동기화 실패: $e');
      // 동기화 실패해도 앱은 정상 동작하도록 함
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      // 로딩 화면
      return Scaffold(
        backgroundColor: Theme.of(context).colorScheme.surface,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.calendar_month,
                size: 80,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 24),
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text(
                '팀 캘린더',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // 인증 상태에 따라 화면 전환
    return _isAuthenticated ? const CalendarScreen() : const LoginScreen();
  }
}
