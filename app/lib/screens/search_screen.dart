import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../models/models.dart';
import '../providers/calendar_providers.dart';
import '../providers/search_providers.dart';
import '../screens/event_form_screen.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  late final TextEditingController _searchController;
  bool _showFilters = false;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    // Delay provider modification until after widget build is complete
    Future(() => ref.read(searchProvider.notifier).setActive(true));
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final searchState = ref.watch(searchProvider);
    final filteredEvents = ref.watch(filteredEventsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('일정 검색'),
        actions: [
          IconButton(
            icon: Icon(
              _showFilters ? Icons.filter_list : Icons.filter_list_outlined,
            ),
            onPressed: () {
              setState(() {
                _showFilters = !_showFilters;
              });
            },
          ),
          if (searchState.hasActiveFilters)
            IconButton(
              icon: const Icon(Icons.clear),
              onPressed: () {
                _searchController.clear();
                ref.read(searchProvider.notifier).clearFilters();
              },
            ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Container(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: '일정 제목 또는 설명 검색...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Theme.of(context).colorScheme.surface,
              ),
              onChanged: (value) {
                ref.read(searchProvider.notifier).updateQuery(value);
              },
            ),
          ),

          // Filters
          if (_showFilters) _buildFiltersSection(),

          // Active filters summary
          if (searchState.hasActiveFilters) _buildActiveFiltersSummary(),

          // Results
          Expanded(
            child: filteredEvents.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: filteredEvents.length,
                    itemBuilder: (context, index) {
                      final event = filteredEvents[index];
                      return SearchEventCard(
                        event: event,
                        onTap: () => _navigateToEventForm(event),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFiltersSection() {
    final teams = ref.watch(teamsProvider);
    final searchState = ref.watch(searchProvider);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).dividerColor,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '필터',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 16),

          // Team filters
          Text(
            '팀',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: teams.map((team) {
              final isSelected = searchState.selectedTeams.contains(team.id);
              return FilterChip(
                label: Text(team.name),
                selected: isSelected,
                selectedColor: team.color.withOpacity(0.3),
                checkmarkColor: team.color,
                onSelected: (selected) {
                  ref.read(searchProvider.notifier).toggleTeam(team.id);
                },
                avatar: Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    color: team.color,
                    shape: BoxShape.circle,
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),

          // Event type filters
          Text(
            '일정 유형',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: EventType.values.map((type) {
              final isSelected = searchState.selectedTypes.contains(type);
              return FilterChip(
                label: Text(_getEventTypeText(type)),
                selected: isSelected,
                onSelected: (selected) {
                  ref.read(searchProvider.notifier).toggleEventType(type);
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 16),

          // Date range filter
          Text(
            '날짜 범위',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _selectStartDate(),
                  child: Text(
                    searchState.startDate != null
                        ? DateFormat('yyyy-MM-dd').format(searchState.startDate!)
                        : '시작 날짜',
                  ),
                ),
              ),
              const SizedBox(width: 8),
              const Text('~'),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _selectEndDate(),
                  child: Text(
                    searchState.endDate != null
                        ? DateFormat('yyyy-MM-dd').format(searchState.endDate!)
                        : '종료 날짜',
                  ),
                ),
              ),
            ],
          ),
          if (searchState.startDate != null || searchState.endDate != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: TextButton(
                onPressed: () {
                  ref.read(searchProvider.notifier).setDateRange(null, null);
                },
                child: const Text('날짜 필터 제거'),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildActiveFiltersSummary() {
    final searchState = ref.watch(searchProvider);
    final teams = ref.watch(teamsProvider);

    List<String> activeFilters = [];

    if (searchState.query.isNotEmpty) {
      activeFilters.add('검색: "${searchState.query}"');
    }

    if (searchState.selectedTeams.isNotEmpty) {
      final teamNames = searchState.selectedTeams
          .map((teamId) => teams.where((t) => t.id == teamId).firstOrNull?.name)
          .where((name) => name != null)
          .join(', ');
      activeFilters.add('팀: $teamNames');
    }

    if (searchState.selectedTypes.isNotEmpty) {
      final typeNames = searchState.selectedTypes
          .map((type) => _getEventTypeText(type))
          .join(', ');
      activeFilters.add('유형: $typeNames');
    }

    if (searchState.startDate != null || searchState.endDate != null) {
      final start = searchState.startDate != null
          ? DateFormat('MM/dd').format(searchState.startDate!)
          : '';
      final end = searchState.endDate != null
          ? DateFormat('MM/dd').format(searchState.endDate!)
          : '';
      
      if (start.isNotEmpty && end.isNotEmpty) {
        activeFilters.add('기간: $start ~ $end');
      } else if (start.isNotEmpty) {
        activeFilters.add('시작: $start');
      } else if (end.isNotEmpty) {
        activeFilters.add('종료: $end');
      }
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '활성 필터',
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            activeFilters.join(' • '),
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    final searchState = ref.watch(searchProvider);

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            searchState.hasActiveFilters ? Icons.search_off : Icons.search,
            size: 64,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
          ),
          const SizedBox(height: 16),
          Text(
            searchState.hasActiveFilters
                ? '검색 조건에 맞는 일정이 없습니다'
                : '검색어를 입력하거나 필터를 설정해보세요',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            searchState.hasActiveFilters
                ? '다른 조건으로 다시 검색해보세요'
                : '일정 제목, 설명, 팀, 유형 등으로 검색할 수 있습니다',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Future<void> _selectStartDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: ref.read(searchProvider).startDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );

    if (date != null) {
      ref.read(searchProvider.notifier).setDateRange(
        date,
        ref.read(searchProvider).endDate,
      );
    }
  }

  Future<void> _selectEndDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: ref.read(searchProvider).endDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );

    if (date != null) {
      ref.read(searchProvider.notifier).setDateRange(
        ref.read(searchProvider).startDate,
        date,
      );
    }
  }

  void _navigateToEventForm(Event event) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => EventFormScreen(existingEvent: event),
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
        return '기념일';
      case EventType.other:
        return '기타';
    }
  }
}

class SearchEventCard extends ConsumerWidget {
  final Event event;
  final VoidCallback? onTap;

  const SearchEventCard({
    super.key,
    required this.event,
    this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final teams = ref.watch(teamsProvider);
    final team = teams.where((t) => t.id == event.teamId).firstOrNull;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: event.color ?? Theme.of(context).colorScheme.primary,
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: event.color ?? Theme.of(context).colorScheme.primary,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        event.title,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ),
                    if (team != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: team.color.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          team.name,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: team.color,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                      ),
                  ],
                ),
                if (event.description.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    event.description,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
                        ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(
                      Icons.schedule,
                      size: 16,
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      event.isAllDay
                          ? DateFormat('MM/dd (E)').format(event.startTime)
                          : '${DateFormat('MM/dd (E) HH:mm').format(event.startTime)} - ${DateFormat('HH:mm').format(event.endTime)}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                          ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.secondary.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _getEventTypeText(event.type),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.secondary,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
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
        return '기념일';
      case EventType.other:
        return '기타';
    }
  }
} 