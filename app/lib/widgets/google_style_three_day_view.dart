import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart'; // kIsWeb 추가
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
      child: Row(
        children: [
          // Empty space for time column
          SizedBox(
            width: _timeColumnWidth,
            height: 80,
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
                           height: 80,
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
                                 DateFormat('E').format(day),
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
            // Events
            ...events.where((event) => !event.isAllDay).map((event) {
              return _buildEventWidget(event, day);
            }).toList(),
            // All-day events at the top
            if (events.any((event) => event.isAllDay))
              Positioned(
                top: 0,
                left: 2,
                right: 2,
                child: Column(
                  children: events
                      .where((event) => event.isAllDay)
                      .map((event) => _buildAllDayEventWidget(event))
                      .toList(),
                ),
              ),
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

  Widget _buildAllDayEventWidget(Event event) {
    return Container(
      margin: const EdgeInsets.only(bottom: 2),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: (event.color ?? Theme.of(context).colorScheme.primary).withOpacity(0.8),
        borderRadius: BorderRadius.circular(4),
      ),
      child: GestureDetector(
        onTap: () => _navigateToEventForm(existingEvent: event),
        child: Text(
          event.title,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
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

  bool isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }
} 