import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/models.dart';
import 'calendar_providers.dart';

// Search state
class SearchState {
  final String query;
  final Set<String> selectedTeams;
  final Set<EventType> selectedTypes;
  final DateTime? startDate;
  final DateTime? endDate;
  final bool isActive;

  SearchState({
    this.query = '',
    this.selectedTeams = const {},
    this.selectedTypes = const {},
    this.startDate,
    this.endDate,
    this.isActive = false,
  });

  SearchState copyWith({
    String? query,
    Set<String>? selectedTeams,
    Set<EventType>? selectedTypes,
    DateTime? startDate,
    DateTime? endDate,
    bool? isActive,
  }) {
    return SearchState(
      query: query ?? this.query,
      selectedTeams: selectedTeams ?? this.selectedTeams,
      selectedTypes: selectedTypes ?? this.selectedTypes,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      isActive: isActive ?? this.isActive,
    );
  }

  bool get hasActiveFilters => 
      query.isNotEmpty || 
      selectedTeams.isNotEmpty || 
      selectedTypes.isNotEmpty ||
      startDate != null ||
      endDate != null;
}

// Search notifier
class SearchNotifier extends StateNotifier<SearchState> {
  SearchNotifier() : super(SearchState());

  void updateQuery(String query) {
    state = state.copyWith(query: query.trim());
  }

  void toggleTeam(String teamId) {
    final newTeams = Set<String>.from(state.selectedTeams);
    if (newTeams.contains(teamId)) {
      newTeams.remove(teamId);
    } else {
      newTeams.add(teamId);
    }
    state = state.copyWith(selectedTeams: newTeams);
  }

  void toggleEventType(EventType type) {
    final newTypes = Set<EventType>.from(state.selectedTypes);
    if (newTypes.contains(type)) {
      newTypes.remove(type);
    } else {
      newTypes.add(type);
    }
    state = state.copyWith(selectedTypes: newTypes);
  }

  void setDateRange(DateTime? start, DateTime? end) {
    state = state.copyWith(startDate: start, endDate: end);
  }

  void setActive(bool active) {
    state = state.copyWith(isActive: active);
  }

  void clearFilters() {
    state = SearchState();
  }
}

// Search provider
final searchProvider = StateNotifierProvider<SearchNotifier, SearchState>((ref) {
  return SearchNotifier();
});

// Filtered events provider
final filteredEventsProvider = Provider<List<Event>>((ref) {
  final allEvents = ref.watch(eventsProvider);
  final searchState = ref.watch(searchProvider);

  if (!searchState.hasActiveFilters) {
    return allEvents;
  }

  return allEvents.where((event) {
    // Text search
    if (searchState.query.isNotEmpty) {
      final query = searchState.query.toLowerCase();
      if (!event.title.toLowerCase().contains(query) &&
          !event.description.toLowerCase().contains(query)) {
        return false;
      }
    }

    // Team filter
    if (searchState.selectedTeams.isNotEmpty) {
      if (!searchState.selectedTeams.contains(event.teamId)) {
        return false;
      }
    }

    // Event type filter
    if (searchState.selectedTypes.isNotEmpty) {
      if (!searchState.selectedTypes.contains(event.type)) {
        return false;
      }
    }

    // Date range filter
    if (searchState.startDate != null || searchState.endDate != null) {
      final eventDate = DateTime(
        event.startTime.year,
        event.startTime.month,
        event.startTime.day,
      );

      if (searchState.startDate != null && eventDate.isBefore(searchState.startDate!)) {
        return false;
      }

      if (searchState.endDate != null && eventDate.isAfter(searchState.endDate!)) {
        return false;
      }
    }

    return true;
  }).toList();
});

// Events for specific week provider
final eventsForWeekProvider = Provider.family<List<Event>, DateTime>((ref, weekStart) {
  final allEvents = ref.watch(eventsProvider);
  final weekEnd = weekStart.add(const Duration(days: 6));

  return allEvents.where((event) {
    final eventDate = DateTime(
      event.startTime.year,
      event.startTime.month,
      event.startTime.day,
    );
    
    return !eventDate.isBefore(weekStart) && !eventDate.isAfter(weekEnd);
  }).toList();
}); 