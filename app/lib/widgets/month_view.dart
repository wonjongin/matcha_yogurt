import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import '../models/models.dart';
import '../providers/calendar_providers.dart';
import '../screens/event_form_screen.dart'; // EventFormScreen import 추가

class MonthView extends ConsumerStatefulWidget {
  final DateTime focusedDay;
  final DateTime selectedDay;
  final Function(DateTime selectedDay, DateTime focusedDay) onDaySelected;
  final Function(DateTime focusedDay) onPageChanged;

  const MonthView({
    super.key,
    required this.focusedDay,
    required this.selectedDay,
    required this.onDaySelected,
    required this.onPageChanged,
  });

  @override
  ConsumerState<MonthView> createState() => _MonthViewState();
}

class _MonthViewState extends ConsumerState<MonthView> {
  CalendarFormat _calendarFormat = CalendarFormat.month;
  
  // 플랫폼별 구분 (768px 기준)
  bool get isMobile => MediaQuery.of(context).size.width < 768;

  @override
  Widget build(BuildContext context) {
    final selectedEvents = ref.watch(eventsForSelectedDayProvider(widget.selectedDay));

    if (isMobile) {
      return _buildMobileLayout(selectedEvents);
    } else {
      return _buildDesktopLayout(selectedEvents);
    }
  }

  Widget _buildMobileLayout(List<Event> selectedEvents) {
    // 모바일: 전체화면 캘린더 (구글 캘린더 스타일)
    return Column(
      children: [
        // 간단한 헤더
        _buildMobileHeader(),
        // 전체화면 캘린더 (일정 제목들 표시)
        Expanded(
          child: _buildFullScreenCalendar(),
        ),
      ],
    );
  }

  Widget _buildDesktopLayout(List<Event> selectedEvents) {
    // 데스크톱+태블릿: 기존 방식 (사이드바 포함)
    final screenWidth = MediaQuery.of(context).size.width;
    
    if (screenWidth > 1200) {
      // 큰 화면: 사이드 바이 사이드 레이아웃
      return Row(
        children: [
          // 메인 캘린더 (좌측)
          Expanded(
            flex: 2,
            child: Column(
              children: [
                _buildDesktopHeader(),
                Expanded(child: _buildFullScreenCalendar()),
              ],
            ),
          ),
          const SizedBox(width: 16),
          // 이벤트 패널 (우측)
          SizedBox(
            width: 300,
            child: _buildEventPanel(selectedEvents),
          ),
        ],
      );
    } else {
      // 중간 화면: 전체화면 캘린더만
      return Column(
        children: [
          _buildDesktopHeader(),
          Expanded(child: _buildFullScreenCalendar()),
        ],
      );
    }
  }

  Widget _buildMobileHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4), // 패딩 줄임
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            DateFormat('yyyy년 MM월').format(widget.focusedDay),
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          TextButton(
            onPressed: () {
              final now = DateTime.now();
              widget.onDaySelected(now, now);
            },
            child: const Text('오늘'),
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8), // 패딩 줄임
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            DateFormat('yyyy년 MM월').format(widget.focusedDay),
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          Row(
            children: [
              TextButton.icon(
                icon: const Icon(Icons.today),
                label: const Text('오늘로 이동'),
                onPressed: () {
                  final now = DateTime.now();
                  widget.onDaySelected(now, now);
                },
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.add),
                onPressed: () => _addEvent(),
                tooltip: '일정 추가',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFullScreenCalendar() {
    final daysOfWeekHeight = isMobile ? 35.0 : 40.0;
    final headerHeight = isMobile ? 50.0 : 60.0;
    
    return Container(
      margin: EdgeInsets.symmetric(horizontal: isMobile ? 4 : 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(isMobile ? 12 : 16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: isMobile ? 8 : 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          // 사용 가능한 높이에서 헤더와 요일 행을 제외한 높이 계산
          final availableHeight = constraints.maxHeight - headerHeight - daysOfWeekHeight - 16; // 여백 16px
          
          // 현재 달의 주 수 계산 (5주 또는 6주)
          final firstDayOfMonth = DateTime(widget.focusedDay.year, widget.focusedDay.month, 1);
          final lastDayOfMonth = DateTime(widget.focusedDay.year, widget.focusedDay.month + 1, 0);
          
          // 첫 주의 시작일과 마지막 주의 끝일 계산
          final firstDayOfWeek = firstDayOfMonth.subtract(Duration(days: firstDayOfMonth.weekday % 7));
          final lastDayOfWeek = lastDayOfMonth.add(Duration(days: 6 - lastDayOfMonth.weekday % 7));
          
          final numberOfWeeks = ((lastDayOfWeek.difference(firstDayOfWeek).inDays + 1) / 7).ceil();
          
          // 실제 주 수에 맞춰 행 높이 계산
          final calculatedRowHeight = (availableHeight / numberOfWeeks).clamp(
            isMobile ? 50.0 : 60.0, // 최소 높이
            isMobile ? 110.0 : 130.0, // 최대 높이
          );
          
          return TableCalendar<Event>(
            firstDay: DateTime.utc(2020, 1, 1),
            lastDay: DateTime.utc(2030, 12, 31),
            focusedDay: widget.focusedDay,
            selectedDayPredicate: (day) => isSameDay(widget.selectedDay, day),
            onDaySelected: (selectedDay, focusedDay) {
              widget.onDaySelected(selectedDay, focusedDay);
              
              // 모바일에서는 하단 시트 표시
              if (isMobile) {
                _showEventBottomSheet(selectedDay);
              }
            },
            onFormatChanged: (format) {
              setState(() {
                _calendarFormat = format;
              });
            },
            onPageChanged: widget.onPageChanged,
            calendarFormat: _calendarFormat,
            eventLoader: (day) => ref.read(eventsForDayProvider(day)),
            
            // 커스텀 셀 빌더로 일정 제목들 표시
            calendarBuilders: CalendarBuilders(
              defaultBuilder: (context, day, focusedDay) => _buildDayCell(day, false, false, calculatedRowHeight),
              selectedBuilder: (context, day, focusedDay) => _buildDayCell(day, true, false, calculatedRowHeight),
              todayBuilder: (context, day, focusedDay) => _buildDayCell(day, false, true, calculatedRowHeight),
            ),
            
            daysOfWeekHeight: daysOfWeekHeight,
            rowHeight: calculatedRowHeight,
            
            calendarStyle: CalendarStyle(
              outsideDaysVisible: false,
              canMarkersOverflow: false,
              markersMaxCount: 0, // 마커(점) 완전 비활성화
              markerDecoration: const BoxDecoration(), // 마커 스타일 제거
            ),
            headerStyle: HeaderStyle(
              formatButtonVisible: !isMobile,
              titleCentered: true,
              titleTextFormatter: (date, locale) => '${date.year}년 ${date.month}월', // 한국식 날짜 포맷
              leftChevronIcon: Icon(
                Icons.chevron_left,
                size: isMobile ? 20 : 24,
              ),
              rightChevronIcon: Icon(
                Icons.chevron_right,
                size: isMobile ? 20 : 24,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildDayCell(DateTime day, bool isSelected, bool isToday, double rowHeight) {
    final events = ref.watch(eventsForDayProvider(day));
    
    // 날짜 숫자 높이와 여백을 제외한 공간으로 표시 가능한 이벤트 수 계산
    final dateHeight = isMobile ? 18 : 20;
    final eventHeight = isMobile ? 16 : 18; // 이벤트 하나당 높이 (margin 포함)
    final padding = 6; // 패딩과 여백
    final moreButtonHeight = isMobile ? 16 : 18; // "+N개 더보기" 버튼 높이
    
    // 더 안전한 계산: 여유 공간을 더 많이 둠
    final availableForEvents = rowHeight - dateHeight - padding;
    
    // "더보기" 버튼을 위한 공간을 미리 확보
    final maxEventsRaw = ((availableForEvents - moreButtonHeight) / eventHeight).floor();
    final maxEvents = events.length > maxEventsRaw 
        ? maxEventsRaw.clamp(1, 4) // 더보기가 필요하면 더 보수적으로
        : (availableForEvents / eventHeight).floor().clamp(1, 5); // 더보기가 불필요하면 더 많이 표시
    
    final fontSize = isMobile ? 8.0 : 9.0;
    
    return Container(
      margin: const EdgeInsets.all(1),
      decoration: BoxDecoration(
        color: isSelected
            ? Theme.of(context).colorScheme.primaryContainer
            : isToday
                ? Theme.of(context).colorScheme.secondaryContainer.withOpacity(0.3)
                : Colors.transparent,
        borderRadius: BorderRadius.circular(4),
        border: isToday && !isSelected
            ? Border.all(color: Theme.of(context).colorScheme.primary, width: 1)
            : null,
      ),
      child: Column(
        children: [
          // 날짜 숫자
          Container(
            height: dateHeight.toDouble(),
            child: Center(
              child: Text(
                '${day.day}',
                style: TextStyle(
                  fontSize: isMobile ? 12 : 14, // 줄임
                  fontWeight: isToday || isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected
                      ? Theme.of(context).colorScheme.onPrimaryContainer
                      : isToday
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ),
          ),
          // 일정들 (전체 폭 사용) - 오버플로우 방지를 위해 SingleChildScrollView 사용
          Expanded(
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 1), // 패딩 최소화
              child: LayoutBuilder(
                builder: (context, constraints) {
                  // 실제 사용 가능한 높이로 다시 계산
                  final actualMaxEvents = (constraints.maxHeight / eventHeight).floor();
                  final safeMaxEvents = actualMaxEvents > 1 
                      ? (events.length > actualMaxEvents ? actualMaxEvents - 1 : actualMaxEvents)
                      : 1;
                  final displayEvents = events.take(safeMaxEvents).toList();
                  
                  return SingleChildScrollView(
                    physics: const NeverScrollableScrollPhysics(), // 스크롤 비활성화
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // 실제 일정들 표시
                        ...displayEvents.map((event) => GestureDetector(
                          onTap: () => _showEventDetail(event), // 일정 상세보기
                          child: Container(
                            width: double.infinity, // 전체 폭 사용
                            height: eventHeight - 2, // 고정 높이
                            margin: const EdgeInsets.only(bottom: 1),
                            padding: EdgeInsets.symmetric(
                              horizontal: isMobile ? 1 : 2, // 내부 패딩 더 줄임
                              vertical: 0.5,
                            ),
                            decoration: BoxDecoration(
                              color: event.color ?? Theme.of(context).colorScheme.primary,
                              borderRadius: BorderRadius.circular(2),
                            ),
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                event.title,
                                style: TextStyle(
                                  fontSize: fontSize,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w500,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                        )).toList(),
                        
                        // 더 많은 일정이 있으면 "+N개 더보기" 표시
                        if (events.length > safeMaxEvents)
                          GestureDetector(
                            onTap: () => _showAllEventsForDay(day, events),
                            child: Container(
                              width: double.infinity,
                              height: eventHeight - 2, // 고정 높이
                              margin: const EdgeInsets.only(top: 1),
                              padding: EdgeInsets.symmetric(
                                horizontal: isMobile ? 1 : 2,
                                vertical: 1,
                              ),
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.8),
                                borderRadius: BorderRadius.circular(2),
                                border: Border.all(
                                  color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
                                  width: 0.5,
                                ),
                              ),
                              child: Center(
                                child: Text(
                                  '+${events.length - safeMaxEvents}개 더보기',
                                  style: TextStyle(
                                    fontSize: fontSize - 1,
                                    color: Theme.of(context).colorScheme.primary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 해당 날짜의 모든 일정 보기 (바텀 시트 또는 다이얼로그)
  void _showAllEventsForDay(DateTime day, List<Event> events) {
    if (isMobile) {
      _showEventBottomSheet(day);
    } else {
      // 데스크톱에서는 다이얼로그로 표시
      showDialog(
        context: context,
        builder: (context) => Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Container(
            width: 400,
            height: 500,
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    Text(
                      '${DateFormat('MM월 dd일').format(day)} 일정',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const Divider(),
                Expanded(
                  child: ListView.builder(
                    itemCount: events.length,
                    itemBuilder: (context, index) {
                      final event = events[index];
                      return EventCard(
                        event: event,
                        onTap: () {
                          Navigator.pop(context);
                          _showEventDetail(event);
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }
  }

  // 일정 상세보기 다이얼로그
  void _showEventDetail(Event event) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 제목
              Row(
                children: [
                  Container(
                    width: 4,
                    height: 24,
                    decoration: BoxDecoration(
                      color: event.color ?? Theme.of(context).colorScheme.primary,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      event.title,
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              // 일시 정보
              _buildDetailRow(
                Icons.schedule,
                '일시',
                event.isAllDay
                    ? '${DateFormat('yyyy년 MM월 dd일').format(event.startTime)} (종일)'
                    : '${DateFormat('yyyy년 MM월 dd일 HH:mm').format(event.startTime)} - ${DateFormat('HH:mm').format(event.endTime)}',
              ),
              
              const SizedBox(height: 12),
              
              // 타입 정보
              _buildDetailRow(
                _getEventTypeIcon(event.type),
                '유형',
                _getEventTypeText(event.type),
              ),
              
              // 설명 (있는 경우에만)
              if (event.description.isNotEmpty) ...[
                const SizedBox(height: 12),
                _buildDetailRow(
                  Icons.description,
                  '설명',
                  event.description,
                ),
              ],
              
              const SizedBox(height: 24),
              
              // 액션 버튼들
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.edit),
                      label: const Text('수정'),
                      onPressed: () {
                        Navigator.pop(context);
                        _editEvent(event);
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.delete),
                      label: const Text('삭제'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Theme.of(context).colorScheme.error,
                      ),
                      onPressed: () {
                        Navigator.pop(context);
                        _deleteEvent(event);
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 20,
          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
        ),
        const SizedBox(width: 12),
        SizedBox(
          width: 50,
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
      ],
    );
  }

  IconData _getEventTypeIcon(EventType type) {
    switch (type) {
      case EventType.meeting:
        return Icons.people;
      case EventType.deadline:
        return Icons.flag;
      case EventType.reminder:
        return Icons.notifications;
      case EventType.celebration:
        return Icons.celebration;
      case EventType.other:
        return Icons.event;
    }
  }

  String _getEventTypeText(EventType type) {
    switch (type) {
      case EventType.meeting:
        return '회의';
      case EventType.deadline:
        return '마감일';
      case EventType.reminder:
        return '알림';
      case EventType.celebration:
        return '축하 이벤트';
      case EventType.other:
        return '기타';
    }
  }

  void _editEvent(Event event) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => EventFormScreen(existingEvent: event),
      ),
    );
  }

  void _addEvent([DateTime? selectedDate]) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => EventFormScreen(
          initialDate: selectedDate ?? widget.selectedDay,
        ),
      ),
    );
  }

  void _deleteEvent(Event event) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('일정 삭제'),
        content: Text('\'${event.title}\' 일정을 삭제하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // TODO: 실제 삭제 로직 구현
              ref.read(eventsProvider.notifier).removeEvent(event.id);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('\'${event.title}\' 일정이 삭제되었습니다'),
                  duration: const Duration(seconds: 2),
                ),
              );
            },
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('삭제'),
          ),
        ],
      ),
    );
  }

  void _showEventBottomSheet(DateTime selectedDay) {
    final events = ref.read(eventsForDayProvider(selectedDay));
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      isDismissible: true, // 배경 탭으로 닫기 활성화
      enableDrag: true, // 드래그로 닫기 활성화
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.4,
        minChildSize: 0.2,
        maxChildSize: 0.8,
        builder: (context, scrollController) => Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
          ),
          child: Column(
            children: [
              // 핸들바
              Container(
                margin: const EdgeInsets.symmetric(vertical: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // 헤더
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      DateFormat('M월 d일 (E)').format(selectedDay),
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add),
                      onPressed: () {
                        Navigator.pop(context);
                        _addEvent(selectedDay);
                      },
                    ),
                  ],
                ),
              ),
              // 일정 리스트
              Expanded(
                child: events.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.event_available,
                              size: 48,
                              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              '이 날짜에는 일정이 없습니다',
                              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                                  ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        controller: scrollController,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: events.length,
                        itemBuilder: (context, index) {
                          final event = events[index];
                          return EventCard(
                            event: event,
                            onTap: () {
                              Navigator.pop(context); // 하단 시트 닫기
                              _showEventDetail(event); // 상세보기 표시
                            },
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEventPanel(List<Event> selectedEvents) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  DateFormat('MMM d일').format(widget.selectedDay),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                IconButton(
                  icon: const Icon(Icons.add, size: 20),
                  onPressed: () => _addEvent(),
                ),
              ],
            ),
          ),
          Expanded(
            child: _buildEventsList(selectedEvents),
          ),
        ],
      ),
    );
  }

  Widget _buildEventsList(List<Event> selectedEvents) {
    return selectedEvents.isEmpty
        ? Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.event_available,
                  size: isMobile ? 48 : 64,
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
                ),
                SizedBox(height: isMobile ? 12 : 16),
                Text(
                  '이 날짜에는 일정이 없습니다',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                      ),
                ),
                SizedBox(height: isMobile ? 8 : 12),
                TextButton.icon(
                  icon: const Icon(Icons.add),
                  label: const Text('새 일정 만들기'),
                  onPressed: () => _addEvent(),
                ),
              ],
            ),
          )
        : ListView.builder(
            padding: EdgeInsets.all(isMobile ? 8 : 16),
            itemCount: selectedEvents.length,
            itemBuilder: (context, index) {
              final event = selectedEvents[index];
              return EventCard(
                event: event,
                onTap: () {
                  _showEventDetail(event);
                },
              );
            },
          );
  }
}

class EventCard extends StatelessWidget {
  final Event event;
  final Function()? onTap;

  const EventCard({
    super.key,
    required this.event,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // color가 null인 경우 기본 색상 사용
    final eventColor = event.color ?? Theme.of(context).colorScheme.primary;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: eventColor.withOpacity(0.1),
        border: Border.all(color: eventColor, width: 1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            children: [
              // 색상 인디케이터
              Container(
                width: 4,
                height: 40,
                decoration: BoxDecoration(
                  color: eventColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 12),
              // 일정 정보
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      event.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                    if (event.description?.isNotEmpty == true) ...[
                      const SizedBox(height: 4),
                      Text(
                        event.description!,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                            ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.schedule,
                          size: 14,
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          event.isAllDay
                              ? '종일'
                              : '${DateFormat('HH:mm').format(event.startTime)} - ${DateFormat('HH:mm').format(event.endTime)}',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                              ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: eventColor.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            _getEventTypeText(event.type),
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: eventColor,
                                  fontWeight: FontWeight.w500,
                                  fontSize: 11,
                                ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getEventTypeText(EventType type) {
    switch (type) {
      case EventType.meeting:
        return '회의';
      case EventType.deadline:
        return '마감일';
      case EventType.reminder:
        return '알림';
      case EventType.celebration:
        return '축하';
      case EventType.other:
        return '기타';
    }
  }
} 