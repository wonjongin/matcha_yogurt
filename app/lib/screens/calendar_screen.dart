import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart'; // kIsWeb을 위해 추가
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import '../models/models.dart';
import '../providers/calendar_providers.dart';
import '../providers/invitation_providers.dart';
import '../widgets/month_view.dart';
import '../widgets/google_style_three_day_view.dart';
import '../widgets/week_view.dart';
import '../services/auth_service.dart';
import '../services/event_service.dart';
import 'login_screen.dart';
import 'team_management_screen.dart';
import 'invitations_screen.dart';
import 'event_form_screen.dart'; // Added import for EventFormScreen

class CalendarScreen extends ConsumerStatefulWidget {
  const CalendarScreen({super.key});

  @override
  ConsumerState<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends ConsumerState<CalendarScreen> {
  DateTime _focusedDay = DateTime.now();

  // 플랫폼 구분: 768px 기준으로 모바일 vs 데스크톱+태블릿
  bool get isMobile => MediaQuery.of(context).size.width < 768;

  @override
  void initState() {
    super.initState();
    // 앱 시작 시 일정 데이터 로드
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadUserEventsIfLoggedIn();
    });
  }

  Future<void> _loadUserEventsIfLoggedIn() async {
    final currentUser = ref.read(currentUserProvider);
    print('DEBUG: CalendarScreen initState - currentUser = $currentUser');
    
    if (currentUser != null) {
      print('DEBUG: 사용자 발견, 일정 로드 시도 중... userId = ${currentUser.id}');
      await _loadEventsForUser(currentUser.id);
    } else {
      print('DEBUG: currentUser가 null입니다. 로그인 상태를 확인하세요.');
      
      // 개발 환경에서 임시 해결책: 마지막으로 로그인한 사용자의 일정을 로드
      // TODO: 실제 앱에서는 저장된 인증 토큰으로 사용자 정보를 복원해야 함
      print('DEBUG: 개발 환경 - 마지막 사용자 정보로 일정 로드 시도');
      try {
        // 서버에서 모든 일정을 가져와서 첫 번째 사용자의 일정을 로드
        final allEvents = await EventService.getEvents();
        if (allEvents.isNotEmpty) {
          final firstEventUserId = allEvents.first.createdBy;
          print('DEBUG: 발견된 사용자 ID: $firstEventUserId');
          await _loadEventsForUser(firstEventUserId);
        }
      } catch (e) {
        print('DEBUG: 임시 일정 로드도 실패: $e');
      }
    }
  }

  Future<void> _loadEventsForUser(String userId) async {
    try {
      // 서버에서 사용자의 일정 데이터 가져오기
      final events = await EventService.getUserEvents(userId: userId);
      
      print('DEBUG: 서버에서 받은 일정 수: ${events.length}개');
      for (final event in events) {
        print('DEBUG: 일정 - ${event.title} (${event.startTime})');
      }
      
      // 로컬 상태에 일정 데이터 설정
      final eventsNotifier = ref.read(eventsProvider.notifier);
      eventsNotifier.state = events;
      
      print('일정 데이터 로드 완료: ${events.length}개');
    } catch (e) {
      print('일정 데이터 로드 실패: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectedDate = ref.watch(selectedDateProvider);
    final currentView = ref.watch(currentViewProvider);
    final currentUser = ref.watch(currentUserProvider);

    return Scaffold(
      appBar: _buildAppBar(currentView, selectedDate, currentUser),
      body: isMobile 
          ? _buildMobileLayout(currentView, selectedDate)
          : _buildDesktopLayout(currentView, selectedDate),
      floatingActionButton: _buildFloatingActionButton(),
    );
  }

  Widget _buildFloatingActionButton() {
    final invitationCount = ref.watch(invitationCountProvider);
    
    return Stack(
      children: [
        FloatingActionButton(
          onPressed: () {
            _showActionMenu();
          },
          backgroundColor: Theme.of(context).colorScheme.primary,
          child: const Icon(Icons.menu, color: Colors.white),
        ),
        if (invitationCount > 0)
          Positioned(
            right: 0,
            top: 0,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.white, width: 2),
              ),
              constraints: const BoxConstraints(
                minWidth: 20,
                minHeight: 20,
              ),
              child: Text(
                invitationCount > 99 ? '99+' : invitationCount.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
      ],
    );
  }

  void _showActionMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(top: 12, bottom: 20),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            _buildActionItem(
              icon: Icons.mail,
              title: '받은 초대',
              subtitle: '팀 초대 확인하기',
              color: Colors.orange,
              badge: ref.watch(invitationCountProvider),
              onTap: () {
                Navigator.pop(context);
                _navigateToInvitations();
              },
            ),
            _buildActionItem(
              icon: Icons.groups,
              title: '팀 관리',
              subtitle: '팀 만들기 및 관리',
              color: Colors.blue,
              badge: 0,
              onTap: () {
                Navigator.pop(context);
                _navigateToTeamManagement();
              },
            ),
            _buildActionItem(
              icon: Icons.add,
              title: '일정 추가',
              subtitle: '새로운 일정 만들기',
              color: Colors.green,
              badge: 0,
              onTap: () {
                Navigator.pop(context);
                _navigateToEventForm();
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildActionItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
    int badge = 0,
  }) {
    return ListTile(
      leading: Stack(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: color,
              size: 24,
            ),
          ),
          if (badge > 0)
            Positioned(
              right: 0,
              top: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.white, width: 1),
                ),
                child: Text(
                  badge > 99 ? '99+' : badge.toString(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
        ],
      ),
      title: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
      ),
      subtitle: Text(subtitle),
      onTap: onTap,
    );
  }

  AppBar _buildAppBar(CalendarView currentView, DateTime selectedDate, User? currentUser) {
    return AppBar(
      title: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Matcha',
            style: TextStyle(
              fontSize: isMobile ? 16 : 18,
              fontWeight: FontWeight.bold,
              height: 1.0,
            ),
          ),
          Text(
            'Yogurt',
            style: TextStyle(
              fontSize: isMobile ? 14 : 16,
              fontWeight: FontWeight.w500,
              height: 1.0,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
            ),
          ),
        ],
      ),
      actions: [
        // 현재 사용자 표시
        if (currentUser != null) ...[
          if (!isMobile) // 데스크톱에서는 이름 표시
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Center(
                child: Text(
                  currentUser.name,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                ),
              ),
            ),
          _buildUserMenu(currentUser),
        ],
        const SizedBox(width: 8),
        // View switcher - 플랫폼별 다른 스타일
        _buildViewSwitcher(currentView),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildUserMenu(User currentUser) {
    return PopupMenuButton<String>(
      icon: CircleAvatar(
        radius: isMobile ? 16 : 18, // 데스크톱에서 약간 크게
        backgroundColor: Theme.of(context).colorScheme.primary,
        child: Text(
          currentUser.name.isNotEmpty ? currentUser.name[0].toUpperCase() : 'U',
          style: TextStyle(
            color: Theme.of(context).colorScheme.onPrimary,
            fontWeight: FontWeight.bold,
            fontSize: isMobile ? 14 : 16,
          ),
        ),
      ),
      itemBuilder: (context) => [
        PopupMenuItem(
          enabled: false, // 비활성화된 계정 이름 표시
          child: Row(
            children: [
              Icon(
                Icons.account_circle,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      currentUser.name,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    Text(
                      currentUser.email,
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const PopupMenuDivider(), // 구분선 추가
        PopupMenuItem(
          value: 'logout',
          child: Row(
            children: [
              const Icon(Icons.logout),
              const SizedBox(width: 8),
              Text('로그아웃'),
            ],
          ),
        ),
      ],
      onSelected: (value) async {
        if (value == 'logout') {
          await _handleLogout();
        }
      },
    );
  }

  Widget _buildViewSwitcher(CalendarView currentView) {
    if (isMobile) {
      // 모바일: 간단한 아이콘 + 짧은 텍스트
      return SegmentedButton<CalendarView>(
        segments: const [
          ButtonSegment<CalendarView>(
            value: CalendarView.month,
            label: Text('월'),
            icon: Icon(Icons.calendar_view_month, size: 18),
          ),
          ButtonSegment<CalendarView>(
            value: CalendarView.threeDay,
            label: Text('일'),
            icon: Icon(Icons.view_day, size: 18),
          ),
        ],
        selected: {currentView == CalendarView.week ? CalendarView.threeDay : currentView},
        onSelectionChanged: (newSelection) {
          ref.read(currentViewProvider.notifier).state = newSelection.first;
        },
      );
    } else {
      // 데스크톱+태블릿: 전체 옵션 + 명확한 텍스트
      return SegmentedButton<CalendarView>(
        segments: const [
          ButtonSegment<CalendarView>(
            value: CalendarView.month,
            label: Text('월간'),
            icon: Icon(Icons.calendar_view_month),
          ),
          ButtonSegment<CalendarView>(
            value: CalendarView.week,
            label: Text('주간'),
            icon: Icon(Icons.calendar_view_week),
          ),
          ButtonSegment<CalendarView>(
            value: CalendarView.threeDay,
            label: Text('3일'),
            icon: Icon(Icons.view_day),
          ),
        ],
        selected: {currentView},
        onSelectionChanged: (newSelection) {
          ref.read(currentViewProvider.notifier).state = newSelection.first;
        },
      );
    }
  }

  Widget _buildMobileLayout(CalendarView view, DateTime selectedDate) {
    // 모바일: 풀스크린, 간단한 레이아웃
    return _buildCalendarView(view, selectedDate);
  }

  Widget _buildDesktopLayout(CalendarView view, DateTime selectedDate) {
    // 데스크톱+태블릿: 좌우 최소 여백만, 상하는 꽉 채움
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: _buildCalendarView(view, selectedDate),
    );
  }

  Widget _buildCalendarView(CalendarView view, DateTime selectedDate) {
    switch (view) {
      case CalendarView.month:
        return MonthView(
          focusedDay: _focusedDay,
          selectedDay: selectedDate,
          onDaySelected: (selectedDay, focusedDay) {
            ref.read(selectedDateProvider.notifier).state = selectedDay;
            setState(() {
              _focusedDay = focusedDay;
            });
          },
          onPageChanged: (focusedDay) {
            setState(() {
              _focusedDay = focusedDay;
            });
          },
        );
      case CalendarView.week:
        return WeekView(
          selectedWeek: selectedDate,
          onWeekChanged: (newWeek) {
            ref.read(selectedDateProvider.notifier).state = newWeek;
          },
        );
      case CalendarView.threeDay:
        return GoogleStyleThreeDayView(
          selectedDay: selectedDate,
          onDayChanged: (newDay) {
            ref.read(selectedDateProvider.notifier).state = newDay;
          },
        );
    }
  }

  String _getTitle(CalendarView view, DateTime date) {
    switch (view) {
      case CalendarView.month:
        return DateFormat('MMMM yyyy').format(date);
      case CalendarView.week:
        return DateFormat('yyyy년 MM월 w주').format(date);
      case CalendarView.threeDay:
        return DateFormat('yyyy년 MM월 dd일').format(date);
    }
  }

  Future<void> _handleLogout() async {
    try {
      await AuthService.logout();
      ref.read(currentUserProvider.notifier).state = null;
      
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const LoginScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('로그아웃 실패: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _navigateToTeamManagement() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const TeamManagementScreen(),
      ),
    );
  }

  void _navigateToInvitations() async {
    // 초대 화면에서 돌아올 때 초대 목록 새로고침
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const InvitationsScreen(),
      ),
    );
    
    // 돌아왔을 때 초대 목록 새로고침
    ref.read(refreshInvitationsProvider)();
  }

  void _navigateToEventForm() {
    final currentUser = ref.read(currentUserProvider);
    if (currentUser != null) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => EventFormScreen(
            initialDate: ref.read(selectedDateProvider),
          ),
        ),
      );
    }
  }
}

 
 