import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart'; // kIsWeb을 위해 추가
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import '../models/models.dart';
import '../providers/calendar_providers.dart';
import '../widgets/month_view.dart';
import '../widgets/google_style_three_day_view.dart';
import '../widgets/week_view.dart';
import '../services/auth_service.dart';
import 'login_screen.dart';

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
  Widget build(BuildContext context) {
    final selectedDate = ref.watch(selectedDateProvider);
    final currentView = ref.watch(currentViewProvider);
    final currentUser = ref.watch(currentUserProvider);

    return Scaffold(
      appBar: _buildAppBar(currentView, selectedDate, currentUser),
      body: isMobile 
          ? _buildMobileLayout(currentView, selectedDate)
          : _buildDesktopLayout(currentView, selectedDate),
    );
  }

  AppBar _buildAppBar(CalendarView currentView, DateTime selectedDate, User? currentUser) {
    return AppBar(
      title: Text(_getTitle(currentView, selectedDate)),
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
          value: 'profile',
          child: Row(
            children: [
              const Icon(Icons.person),
              const SizedBox(width: 8),
              Text('프로필'),
            ],
          ),
        ),
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
        // 프로필 기능은 나중에 구현
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
            label: Text('월간 보기'),
            icon: Icon(Icons.calendar_view_month),
          ),
          ButtonSegment<CalendarView>(
            value: CalendarView.week,
            label: Text('주간 보기'),
            icon: Icon(Icons.calendar_view_week),
          ),
          ButtonSegment<CalendarView>(
            value: CalendarView.threeDay,
            label: Text('3일 보기'),
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
    // 데스크톱+태블릿: 여백과 더 큰 컴포넌트
    return Padding(
      padding: const EdgeInsets.all(16.0),
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
}

 
 