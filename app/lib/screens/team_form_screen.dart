import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import '../models/models.dart';
import '../providers/calendar_providers.dart';

class TeamFormScreen extends ConsumerStatefulWidget {
  final Team? existingTeam;

  const TeamFormScreen({
    super.key,
    this.existingTeam,
  });

  @override
  ConsumerState<TeamFormScreen> createState() => _TeamFormScreenState();
}

class _TeamFormScreenState extends ConsumerState<TeamFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;
  late Color _selectedColor;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.existingTeam?.name ?? '');
    _descriptionController = TextEditingController(text: widget.existingTeam?.description ?? '');
    _selectedColor = widget.existingTeam?.color ?? Colors.blue;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(currentUserProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.existingTeam != null ? '팀 편집' : '새 팀 만들기'),
        actions: [
          if (widget.existingTeam != null)
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
            // Team preview
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: _selectedColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: _selectedColor.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: _selectedColor,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.group,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _nameController.text.isEmpty ? '팀 이름' : _nameController.text,
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _descriptionController.text.isEmpty 
                              ? '팀 설명을 입력해주세요' 
                              : _descriptionController.text,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                              ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Team name field
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: '팀 이름 *',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.group),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return '팀 이름을 입력해주세요';
                }
                return null;
              },
              onChanged: (value) => setState(() {}),
            ),
            const SizedBox(height: 16),

            // Team description field
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: '팀 설명',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.description),
              ),
              maxLines: 3,
              onChanged: (value) => setState(() {}),
            ),
            const SizedBox(height: 16),

            // Color picker
            _ColorPickerField(
              label: '팀 색상',
              color: _selectedColor,
              onChanged: (color) {
                setState(() {
                  _selectedColor = color;
                });
              },
            ),
            const SizedBox(height: 32),

            // Save button
            ElevatedButton(
              onPressed: _saveTeam,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: _selectedColor,
                foregroundColor: Colors.white,
              ),
              child: Text(
                widget.existingTeam != null ? '팀 수정하기' : '팀 만들기',
                style: const TextStyle(fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _saveTeam() {
    if (_formKey.currentState!.validate()) {
      final currentUser = ref.read(currentUserProvider);

      if (currentUser == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('사용자 정보를 찾을 수 없습니다')),
        );
        return;
      }

      final team = Team(
        id: widget.existingTeam?.id,
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        color: _selectedColor,
        ownerId: widget.existingTeam?.ownerId ?? currentUser.id,
      );

      if (widget.existingTeam != null) {
        ref.read(teamsProvider.notifier).updateTeam(team);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('팀이 수정되었습니다')),
        );
      } else {
        ref.read(teamsProvider.notifier).addTeam(team);
        
        // Add the creator as owner
        final membership = TeamMember(
          teamId: team.id,
          userId: currentUser.id,
          role: TeamRole.owner,
        );
        ref.read(teamMembersProvider.notifier).addMember(membership);
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('팀이 생성되었습니다')),
        );
      }

      Navigator.of(context).pop();
    }
  }

  void _showDeleteDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('팀 삭제'),
        content: const Text('이 팀을 삭제하시겠습니까?\n모든 팀 멤버와 관련 일정이 함께 삭제됩니다.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () {
              // Remove all team members
              ref.read(teamMembersProvider.notifier).removeAllMembersFromTeam(widget.existingTeam!.id);
              
              // Remove team
              ref.read(teamsProvider.notifier).removeTeam(widget.existingTeam!.id);
              
              Navigator.of(context).pop(); // Close dialog
              Navigator.of(context).pop(); // Close form screen
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('팀이 삭제되었습니다')),
              );
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('삭제'),
          ),
        ],
      ),
    );
  }
}

class _ColorPickerField extends StatelessWidget {
  final String label;
  final Color color;
  final Function(Color) onChanged;

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
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    border: Border.all(color: Theme.of(context).dividerColor),
                  ),
                ),
                const SizedBox(width: 12),
                const Text('팀 색상 선택'),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _showColorPicker(BuildContext context) {
    Color pickerColor = color;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('팀 색상 선택'),
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