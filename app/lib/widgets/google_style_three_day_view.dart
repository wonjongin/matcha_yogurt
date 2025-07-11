import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart'; // kIsWeb 추가
import 'package:flutter/services.dart'; // HapticFeedback 추가
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import '../models/models.dart';
import '../providers/calendar_providers.dart';
import '../screens/event_form_screen.dart';

class GoogleStyleThreeDayView extends ConsumerStatefulWidget {
  final DateTime selectedDay;
  final Function(DateTime) onDayChanged;

  const GoogleStyleThreeDayView({
    super.key,
    required this.selectedDay,
    required this.onDayChanged,
  });

  @override
  ConsumerState<GoogleStyleThreeDayView> createState() => _GoogleStyleThreeDayViewState();
}

class _GoogleStyleThreeDayViewState extends ConsumerState<GoogleStyleThreeDayView> {
  late ScrollController _scrollController;
  late ScrollController _horizontalScrollController;
  late ScrollController _headerHorizontalScrollController;
  late ScrollController _timeScrollController; // Added for time column scroll
  
  static const double _hourHeight = 60.0;
  static const double _timeColumnWidth = 60.0;
  static const int _totalHours = 24;
  
  // 플랫폼별 컬럼 너비 (768px 기준)
  bool get isMobile => MediaQuery.of(context).size.width < 768;
  
  double get _dayColumnWidth {
    if (isMobile) {
      // 모바일: 3일을 화면에 꽉 채우기
      final screenWidth = MediaQuery.of(context).size.width;
      final availableWidth = screenWidth - _timeColumnWidth - 32; // 패딩 고려
      return availableWidth / 3; // 3일 균등 분할
    } else {
      // 데스크톱+태블릿: 여유로운 고정 크기 (3일뷰는 더 넓게)
      final screenWidth = MediaQuery.of(context).size.width;
      if (screenWidth > 1400) return 280; // 큰 화면
      if (screenWidth > 1000) return 240; // 중간 화면
      return 200; // 작은 데스크톱/태블릿
    }
  }

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _horizontalScrollController = ScrollController();
    _headerHorizontalScrollController = ScrollController();
    _timeScrollController = ScrollController(); // Initialize new controller
    
    // 헤더와 본문의 가로 스크롤 동기화
    _horizontalScrollController.addListener(() {
      if (_headerHorizontalScrollController.hasClients && 
          _headerHorizontalScrollController.offset != _horizontalScrollController.offset) {
        _headerHorizontalScrollController.jumpTo(_horizontalScrollController.offset);
      }
    });
    
    _headerHorizontalScrollController.addListener(() {
      if (_horizontalScrollController.hasClients && 
          _horizontalScrollController.offset != _headerHorizontalScrollController.offset) {
        _horizontalScrollController.jumpTo(_headerHorizontalScrollController.offset);
      }
    });

    // 시간대 컬럼과 일정 영역의 세로 스크롤 동기화
    _scrollController.addListener(() {
      if (_timeScrollController.hasClients && 
          _timeScrollController.offset != _scrollController.offset) {
        _timeScrollController.jumpTo(_scrollController.offset);
      }
    });
    
    _timeScrollController.addListener(() {
      if (_scrollController.hasClients && 
          _scrollController.offset != _timeScrollController.offset) {
        _scrollController.jumpTo(_timeScrollController.offset);
      }
    });
    
    // 아침 8시 위치로 스크롤
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollController.animateTo(
        8 * _hourHeight,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _horizontalScrollController.dispose();
    _headerHorizontalScrollController.dispose();
    _timeScrollController.dispose(); // Dispose new controller
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final selectedDate = DateTime(widget.selectedDay.year, widget.selectedDay.month, widget.selectedDay.day);
    
    // Get three days: yesterday, today, tomorrow relative to selected day
    final threeDays = [
      selectedDate.subtract(const Duration(days: 1)),
      selectedDate,
      selectedDate.add(const Duration(days: 1)),
    ];

    return Column(
      children: [
        // Header with dates
        _buildHeader(threeDays),
        // Time grid with separated structure like WeekView
        Expanded(
          child: Row(
            children: [
              // Time column (고정) - 세로 스크롤만
              Container(
                width: _timeColumnWidth,
                child: SingleChildScrollView(
                  controller: _timeScrollController,
                  child: _buildTimeColumn(),
                ),
              ),
              // Days grid (가로 + 세로 스크롤)
              Expanded(
                child: SingleChildScrollView(
                  controller: _horizontalScrollController,
                  scrollDirection: Axis.horizontal,
                  child: SingleChildScrollView(
                    controller: _scrollController,
                    child: SizedBox(
                      width: threeDays.length * _dayColumnWidth,
                      height: _totalHours * _hourHeight,
                      child: Row(
                        children: threeDays.map((day) {
                          return SizedBox(
                            width: _dayColumnWidth,
                            child: _buildDayColumn(day),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHeader(List<DateTime> threeDays) {
    // 하루종일 이벤트 수집
    final allDayEvents = <DateTime, List<Event>>{};
    for (final day in threeDays) {
      final dayEvents = ref.watch(eventsForDayProvider(day));
      allDayEvents[day] = dayEvents.where((event) => event.isAllDay).toList();
    }
    
    // 하루종일 이벤트가 있는지 확인
    final hasAllDayEvents = allDayEvents.values.any((events) => events.isNotEmpty);
    final allDayEventRows = hasAllDayEvents ? _calculateAllDayEventRows(allDayEvents, threeDays) : 0;
    
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).dividerColor,
            width: 1,
          ),
        ),
      ),
      child: Column(
        children: [
          // 날짜 헤더 행
          Row(
            children: [
              // 이전 날 버튼
              SizedBox(
                width: 48,
                height: 60,
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => _navigateToPreviousDay(),
                    child: Icon(
                      Icons.chevron_left,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                ),
              ),
              // Time column과 날짜 헤더들
              Expanded(
                child: Row(
                  children: [
                    // Time column
                    SizedBox(
                      width: _timeColumnWidth - 48,
                      height: 60,
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border(
                            right: BorderSide(
                              color: Theme.of(context).dividerColor,
                              width: 1,
                            ),
                          ),
                        ),
                      ),
                    ),
                    // Date headers with horizontal scroll
                    Expanded(
                      child: SingleChildScrollView(
                        controller: _headerHorizontalScrollController,
                        scrollDirection: Axis.horizontal,
                        child: SizedBox(
                          width: threeDays.length * _dayColumnWidth,
                          child: Row(
                            children: threeDays.map((day) {
                              final isToday = isSameDay(day, DateTime.now());
                              final isSelected = isSameDay(day, widget.selectedDay);

                              return SizedBox(
                                width: _dayColumnWidth,
                                child: GestureDetector(
                                  onTap: () => widget.onDayChanged(day),
                                  child: Container(
                                    height: 60,
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? Theme.of(context).colorScheme.primaryContainer
                                          : Colors.transparent,
                                      border: Border(
                                        right: BorderSide(
                                          color: Theme.of(context).dividerColor,
                                          width: 1,
                                        ),
                                      ),
                                    ),
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          _getDayOfWeekKorean(day),
                                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                                color: isToday
                                                    ? Theme.of(context).colorScheme.primary
                                                    : Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                                              ),
                                        ),
                                        const SizedBox(height: 4),
                                        Container(
                                          width: 32,
                                          height: 32,
                                          decoration: BoxDecoration(
                                            color: isToday
                                                ? Theme.of(context).colorScheme.primary
                                                : Colors.transparent,
                                            shape: BoxShape.circle,
                                          ),
                                          child: Center(
                                            child: Text(
                                              '${day.day}',
                                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                                    color: isToday
                                                        ? Theme.of(context).colorScheme.onPrimary
                                                        : Theme.of(context).colorScheme.onSurface,
                                                    fontWeight: FontWeight.w600,
                                                    fontSize: 18, // 날짜 글씨 크기 증가
                                                  ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // 다음 날 버튼
              SizedBox(
                width: 48,
                height: 60,
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => _navigateToNextDay(),
                    child: Icon(
                      Icons.chevron_right,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                ),
              ),
            ],
          ),
          // 하루종일 이벤트 영역 (있을 때만 표시)
          if (hasAllDayEvents) _buildAllDayEventsSection(allDayEvents, threeDays, allDayEventRows),
        ],
      ),
    );
  }

  Widget _buildTimeColumn() {
    return SizedBox(
      height: _totalHours * _hourHeight,
      child: Column(
        children: List.generate(_totalHours, (hour) {
          return Container(
            width: _timeColumnWidth,
            height: _hourHeight,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              border: Border(
                right: BorderSide(
                  color: Theme.of(context).dividerColor,
                  width: 1,
                ),
                bottom: BorderSide(
                  color: Theme.of(context).dividerColor.withOpacity(0.3),
                  width: 0.5,
                ),
              ),
            ),
            child: Center(
              child: Text(
                DateFormat('HH:00').format(DateTime(2023, 1, 1, hour)),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                    ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildDayColumn(DateTime day) {
    final events = ref.watch(eventsForDayProvider(day));
    
    return GestureDetector(
      onDoubleTap: () => _navigateToEventForm(initialDate: day),
      onLongPressStart: (details) => _handleLongPress(day, details),
      child: Container(
        decoration: BoxDecoration(
          border: Border(
            right: BorderSide(
              color: Theme.of(context).dividerColor,
              width: 1,
            ),
          ),
        ),
        child: Stack(
          children: [
            // Hour lines
            Column(
              children: List.generate(_totalHours, (hour) {
                return Container(
                  height: _hourHeight,
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: Theme.of(context).dividerColor.withOpacity(0.3),
                        width: 0.5,
                      ),
                    ),
                  ),
                );
              }),
            ),
            // Events (하루종일 이벤트는 헤더에서 처리하므로 시간 이벤트만)
            ...events.where((event) => !event.isAllDay).map((event) {
              return _buildEventWidget(event, day);
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildEventWidget(Event event, DateTime day) {
    final startTime = event.startTime;
    final endTime = event.endTime;
    
    // Calculate position and height
    final startHour = startTime.hour + (startTime.minute / 60.0);
    final endHour = endTime.hour + (endTime.minute / 60.0);
    final duration = endHour - startHour;
    
    final top = startHour * _hourHeight;
    final height = duration * _hourHeight;

    return Positioned(
      top: top,
      left: 2,
      right: 2,
      height: height.clamp(20.0, double.infinity), // Minimum height
      child: GestureDetector(
        onTap: () => _navigateToEventForm(existingEvent: event),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 1),
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: event.color ?? Theme.of(context).colorScheme.primary,
            borderRadius: BorderRadius.circular(4),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 2,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                event.title,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 12, // 일정 제목 글씨 크기 증가
                    ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (height > 30) // Show time if there's enough space
                Text(
                  '${DateFormat('HH:mm').format(startTime)} - ${DateFormat('HH:mm').format(endTime)}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 10,
                      ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              if (height > 50 && event.description.isNotEmpty) // Show description if there's space
                Expanded(
                  child: Text(
                    event.description,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.white.withOpacity(0.8),
                          fontSize: 10,
                        ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // 하루종일 이벤트 행 수 계산
  int _calculateAllDayEventRows(Map<DateTime, List<Event>> allDayEvents, List<DateTime> threeDays) {
    int maxRows = 0;
    for (final day in threeDays) {
      final events = allDayEvents[day] ?? [];
      if (events.length > maxRows) {
        maxRows = events.length;
      }
    }
    return maxRows.clamp(0, 4); // 최대 4행까지 표시
  }

  // 하루종일 이벤트 섹션 구성
  Widget _buildAllDayEventsSection(Map<DateTime, List<Event>> allDayEvents, List<DateTime> threeDays, int maxRows) {
    return Container(
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: Theme.of(context).dividerColor.withOpacity(0.5),
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        children: [
          // 좌측 버튼 공간 + 시간 컬럼 공간
          SizedBox(
            width: 48 + (_timeColumnWidth - 48),
            child: Container(
              height: maxRows * 28.0 + 12, // 각 행 28px + 패딩
              decoration: BoxDecoration(
                border: Border(
                  right: BorderSide(
                    color: Theme.of(context).dividerColor,
                    width: 1,
                  ),
                ),
              ),
              child: const Center(
                child: Text(
                  '하루종일',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey,
                  ),
                ),
              ),
            ),
          ),
          // 하루종일 이벤트 그리드
          Expanded(
            child: SingleChildScrollView(
              controller: _headerHorizontalScrollController,
              scrollDirection: Axis.horizontal,
              child: SizedBox(
                width: threeDays.length * _dayColumnWidth,
                height: maxRows * 28.0 + 12,
                child: Row(
                  children: threeDays.map((day) {
                    final events = allDayEvents[day] ?? [];
                    return SizedBox(
                      width: _dayColumnWidth,
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border(
                            right: BorderSide(
                              color: Theme.of(context).dividerColor,
                              width: 1,
                            ),
                          ),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                        child: Column(
                          children: [
                            for (int i = 0; i < maxRows; i++)
                              if (i < events.length)
                                _buildAllDayEventWidget(events[i])
                              else
                                const SizedBox(height: 28),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          ),
          // 우측 버튼 공간
          const SizedBox(width: 48),
        ],
      ),
    );
  }

  Widget _buildAllDayEventWidget(Event event) {
    return Container(
      width: double.infinity, // 전체 너비 사용
      height: 24,
      margin: const EdgeInsets.only(bottom: 2),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: event.color ?? Theme.of(context).colorScheme.primary,
        borderRadius: BorderRadius.circular(4), // 적당한 둥글기
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: GestureDetector(
        onTap: () => _navigateToEventForm(existingEvent: event),
        child: Align(
          alignment: Alignment.centerLeft,
          child: Text(
            event.title,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 13, // 하루종일 이벤트 제목 글씨 크기 증가
                ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
    );
  }

  void _handleLongPress(DateTime day, LongPressStartDetails details) {
    // 터치한 Y 좌표에서 시간 계산
    final yPosition = details.localPosition.dy;
    final hourDecimal = yPosition / _hourHeight;
    
    // 30분 단위로 스냅 (0.5 = 30분)
    final snappedHour = (hourDecimal * 2).round() / 2;
    final hour = snappedHour.floor();
    final minute = ((snappedHour - hour) * 60).round();
    
    // 유효한 시간 범위 체크 (0-23시)
    if (hour >= 0 && hour < 24) {
      final selectedDateTime = DateTime(
        day.year,
        day.month,
        day.day,
        hour,
        minute,
      );
      
      // 햅틱 피드백
      HapticFeedback.mediumImpact();
      
      // 선택된 시간으로 일정 생성 화면 이동
      _navigateToEventForm(initialDate: selectedDateTime);
    }
  }

  void _navigateToEventForm({Event? existingEvent, DateTime? initialDate}) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => EventFormScreen(
          existingEvent: existingEvent,
          initialDate: initialDate,
        ),
      ),
    );
  }

  void _navigateToPreviousDay() {
    final previousDay = widget.selectedDay.subtract(const Duration(days: 1));
    widget.onDayChanged(previousDay);
  }

  void _navigateToNextDay() {
    final nextDay = widget.selectedDay.add(const Duration(days: 1));
    widget.onDayChanged(nextDay);
  }

  bool isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  String _getDayOfWeekKorean(DateTime day) {
    const dayNames = ['일', '월', '화', '수', '목', '금', '토'];
    return dayNames[day.weekday % 7]; // weekday는 1(월)부터 7(일)까지
  }
} 