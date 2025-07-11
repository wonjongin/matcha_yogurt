import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:intl/intl.dart';
import '../models/models.dart';
import '../providers/calendar_providers.dart';
import '../providers/event_form_providers.dart';
import 'team_form_screen.dart';
import 'invitations_screen.dart';

class EventFormScreen extends ConsumerStatefulWidget {
  final Event? existingEvent;
  final DateTime? initialDate;

  const EventFormScreen({
    super.key,
    this.existingEvent,
    this.initialDate,
  });

  @override
  ConsumerState<EventFormScreen> createState() => _EventFormScreenState();
}

class _EventFormScreenState extends ConsumerState<EventFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.existingEvent?.title ?? '');
    _descriptionController = TextEditingController(text: widget.existingEvent?.description ?? '');
    
    // Initialize form state
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.existingEvent != null) {
        ref.read(eventFormProvider.notifier).loadEvent(widget.existingEvent!);
      } else if (widget.initialDate != null) {
        ref.read(eventFormProvider.notifier).setInitialDate(widget.initialDate!);
      }
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final formState = ref.watch(eventFormProvider);
    final formNotifier = ref.read(eventFormProvider.notifier);
    final currentUser = ref.watch(currentUserProvider);
    
    // 현재 사용자가 속한 팀만 가져오기
    final userTeams = currentUser != null 
        ? ref.watch(userTeamsProvider(currentUser.id))
        : <Team>[];

    // 현재 선택된 팀ID가 사용자 팀 리스트에 없으면 초기화
    final currentTeamId = formState.teamId;
    final isValidTeamId = userTeams.any((team) => team.id == currentTeamId);
    
    if (currentTeamId != null && !isValidTeamId && userTeams.isNotEmpty) {
      // 유효하지 않은 팀ID인 경우 첫 번째 팀으로 설정
      WidgetsBinding.instance.addPostFrameCallback((_) {
        formNotifier.updateTeamId(userTeams.first.id);
      });
    } else if (currentTeamId != null && userTeams.isEmpty) {
      // 팀이 없는 경우 teamId 초기화 (null로 설정)
      WidgetsBinding.instance.addPostFrameCallback((_) {
        formNotifier.clearTeamId();
      });
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.existingEvent != null ? '일정 편집' : '새 일정'),
        actions: [
          if (widget.existingEvent != null)
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () => _showDeleteDialog(),
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Title field
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: '일정 제목 *',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.title),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return '제목을 입력해주세요';
                }
                return null;
              },
              onChanged: (value) => formNotifier.updateTitle(value),
            ),
            const SizedBox(height: 16),

            // Description field
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: '설명',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.description),
              ),
              maxLines: 3,
              onChanged: (value) => formNotifier.updateDescription(value),
            ),
            const SizedBox(height: 16),

            // Event type selection
            DropdownButtonFormField<EventType>(
              value: formState.type,
              decoration: const InputDecoration(
                labelText: '일정 유형',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.category),
              ),
              items: EventType.values.map((type) {
                return DropdownMenuItem(
                  value: type,
                  child: Text(_getEventTypeText(type)),
                );
              }).toList(),
              onChanged: (type) {
                if (type != null) formNotifier.updateType(type);
              },
            ),
            const SizedBox(height: 16),

            // Team selection or team creation guide
            if (userTeams.isNotEmpty)
              DropdownButtonFormField<String>(
                value: isValidTeamId ? formState.teamId : null,
                decoration: const InputDecoration(
                  labelText: '팀 선택 *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.group),
                ),
                items: userTeams.map((team) {
                  return DropdownMenuItem(
                    value: team.id,
                    child: Row(
                      children: [
                        Container(
                          width: 16,
                          height: 16,
                          decoration: BoxDecoration(
                            color: team.color,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(team.name),
                      ],
                    ),
                  );
                }).toList(),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '팀을 선택해주세요';
                  }
                  // 선택된 팀이 실제 사용자 팀 목록에 있는지 확인
                  final isValidTeam = userTeams.any((team) => team.id == value);
                  if (!isValidTeam) {
                    return '유효하지 않은 팀입니다';
                  }
                  return null;
                },
                onChanged: (teamId) {
                  if (teamId != null) formNotifier.updateTeamId(teamId);
                },
              )
            else
              // No teams - guide to create a team
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                  ),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.group_add,
                      size: 48,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '팀이 없습니다',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '일정을 생성하려면 먼저 팀을 만들어야 합니다.\n팀을 만들거나 기존 팀에 초대받아 보세요.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => _navigateToTeamCreation(),
                            icon: const Icon(Icons.add),
                            label: const Text('팀 만들기'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextButton.icon(
                            onPressed: () => _navigateToInvitations(),
                            icon: const Icon(Icons.mail),
                            label: const Text('초대 확인'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 16),

            // All day toggle
            SwitchListTile(
              title: const Text('하루 종일'),
              subtitle: const Text('종일 일정으로 설정'),
              value: formState.isAllDay,
              onChanged: formNotifier.updateIsAllDay,
              secondary: const Icon(Icons.today),
            ),
            const SizedBox(height: 16),

            // Date and time selection
            Row(
              children: [
                Expanded(
                  child: _DateTimeField(
                    label: '시작',
                    dateTime: formState.startTime,
                    isAllDay: formState.isAllDay,
                    onChanged: formNotifier.updateStartTime,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _DateTimeField(
                    label: '종료',
                    dateTime: formState.endTime,
                    isAllDay: formState.isAllDay,
                    onChanged: formNotifier.updateEndTime,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Color picker
            _ColorPickerField(
              label: '색상',
              color: formState.color,
              onChanged: formNotifier.updateColor,
            ),
            const SizedBox(height: 32),

            // Save button
            ElevatedButton(
              onPressed: _saveEvent,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: Text(
                widget.existingEvent != null ? '수정하기' : '생성하기',
                style: const TextStyle(fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveEvent() async {
    if (_formKey.currentState!.validate()) {
      final formState = ref.read(eventFormProvider);
      final currentUser = ref.read(currentUserProvider);

      if (currentUser == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('사용자 정보를 찾을 수 없습니다')),
        );
        return;
      }

      // teamId 유효성 검사
      if (formState.teamId == null || formState.teamId!.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('팀을 선택해주세요')),
        );
        return;
      }

      final event = Event(
        id: widget.existingEvent?.id,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        startTime: formState.startTime,
        endTime: formState.endTime,
        teamId: formState.teamId!,
        createdBy: widget.existingEvent?.createdBy ?? currentUser.id,
        type: formState.type,
        color: formState.color,
        isAllDay: formState.isAllDay,
      );

      try {
        if (widget.existingEvent != null) {
          await ref.read(eventsProvider.notifier).updateEvent(event);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('일정이 수정되었습니다')),
            );
          }
        } else {
          await ref.read(eventsProvider.notifier).addEvent(event, currentUser.id);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('일정이 생성되었습니다')),
            );
          }
        }

        if (mounted) {
          Navigator.of(context).pop();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(e.toString().replaceFirst('Exception: ', '')),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  void _showDeleteDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('일정 삭제'),
        content: const Text('이 일정을 삭제하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () {
              ref.read(eventsProvider.notifier).removeEvent(widget.existingEvent!.id);
              Navigator.of(context).pop(); // Close dialog
              Navigator.of(context).pop(); // Close form screen
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('일정이 삭제되었습니다')),
              );
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('삭제'),
          ),
        ],
      ),
    );
  }

  void _navigateToTeamCreation() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const TeamFormScreen(),
      ),
    );
  }

  void _navigateToInvitations() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const InvitationsScreen(),
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

class _DateTimeField extends StatelessWidget {
  final String label;
  final DateTime dateTime;
  final bool isAllDay;
  final Function(DateTime) onChanged;

  const _DateTimeField({
    required this.label,
    required this.dateTime,
    required this.isAllDay,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.labelMedium,
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: () => _selectDate(context),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              border: Border.all(color: Theme.of(context).dividerColor),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.calendar_today,
                  size: 20,
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    DateFormat('MM/dd (E)').format(dateTime),
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              ],
            ),
          ),
        ),
        if (!isAllDay) ...[
          const SizedBox(height: 8),
          InkWell(
            onTap: () => _selectTime(context),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                border: Border.all(color: Theme.of(context).dividerColor),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.access_time,
                    size: 20,
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      DateFormat('HH:mm').format(dateTime),
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    final date = await showDatePicker(
      context: context,
      initialDate: dateTime,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );

    if (date != null) {
      final newDateTime = DateTime(
        date.year,
        date.month,
        date.day,
        dateTime.hour,
        dateTime.minute,
      );
      onChanged(newDateTime);
    }
  }

  Future<void> _selectTime(BuildContext context) async {
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(dateTime),
    );

    if (time != null) {
      final newDateTime = DateTime(
        dateTime.year,
        dateTime.month,
        dateTime.day,
        time.hour,
        time.minute,
      );
      onChanged(newDateTime);
    }
  }
}

class _ColorPickerField extends StatelessWidget {
  final String label;
  final Color? color;
  final Function(Color?) onChanged;

  const _ColorPickerField({
    required this.label,
    required this.color,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.labelMedium,
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: () => _showColorPicker(context),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              border: Border.all(color: Theme.of(context).dividerColor),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Row(
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: color ?? Theme.of(context).colorScheme.primary,
                    shape: BoxShape.circle,
                    border: Border.all(color: Theme.of(context).dividerColor),
                  ),
                ),
                const SizedBox(width: 8),
                const Text('색상 선택'),
                const Spacer(),
                if (color != null)
                  IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () => onChanged(null),
                    constraints: const BoxConstraints(),
                    padding: EdgeInsets.zero,
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _showColorPicker(BuildContext context) {
    Color pickerColor = color ?? Theme.of(context).colorScheme.primary;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('색상 선택'),
        content: SingleChildScrollView(
          child: ColorPicker(
            pickerColor: pickerColor,
            onColorChanged: (color) => pickerColor = color,
            enableAlpha: false,
            pickerAreaHeightPercent: 0.8,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () {
              onChanged(pickerColor);
              Navigator.of(context).pop();
            },
            child: const Text('선택'),
          ),
        ],
      ),
    );
  }
} 