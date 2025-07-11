import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/models.dart';
import '../services/team_service.dart';

// 받은 초대 목록을 관리하는 provider
final myInvitationsProvider = FutureProvider<List<TeamInvitation>>((ref) async {
  try {
    return await TeamService.getMyInvitations();
  } catch (e) {
    // 에러가 발생하면 빈 리스트 반환
    return [];
  }
});

// 받은 초대 개수를 계산하는 provider
final invitationCountProvider = Provider<int>((ref) {
  final invitationsAsync = ref.watch(myInvitationsProvider);
  return invitationsAsync.when(
    data: (invitations) => invitations.where((i) => i.isPending && !i.isExpired).length,
    loading: () => 0,
    error: (_, __) => 0,
  );
});

// 초대 목록을 새로고침하는 provider
final refreshInvitationsProvider = Provider<void Function()>((ref) {
  return () {
    ref.invalidate(myInvitationsProvider);
  };
}); 