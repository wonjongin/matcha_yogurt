import { Injectable, NotFoundException, BadRequestException, ForbiddenException } from '@nestjs/common';
import { PrismaService } from '../prisma.service';
import { TeamInvitation, InvitationStatus, TeamRole } from '@prisma/client';

@Injectable()
export class InvitationsService {
  constructor(private prisma: PrismaService) {}

  // 팀 초대장 발송
  async createInvitation(
    teamId: string,
    email: string,
    role: TeamRole,
    invitedBy: string,
  ): Promise<TeamInvitation> {
    // 팀이 존재하는지 확인
    const team = await this.prisma.team.findUnique({
      where: { id: teamId },
      include: { 
        members: {
          include: { user: true }
        }
      },
    });

    if (!team) {
      throw new NotFoundException('팀을 찾을 수 없습니다');
    }

    // 초대하는 사용자가 팀을 관리할 권한이 있는지 확인
    const inviterMembership = team.members.find(m => m.userId === invitedBy);
    if (!inviterMembership || !['OWNER', 'ADMIN'].includes(inviterMembership.role)) {
      throw new ForbiddenException('팀 멤버를 초대할 권한이 없습니다');
    }

    // 이미 팀 멤버인지 확인
    const existingUserMember = team.members.find(m => m.user.email === email);
    if (existingUserMember) {
      throw new BadRequestException('이미 팀 멤버입니다');
    }

    // 이미 대기 중인 초대가 있는지 확인
    const existingInvitation = await this.prisma.teamInvitation.findUnique({
      where: {
        email_teamId: {
          email,
          teamId,
        },
      },
    });

    if (existingInvitation && existingInvitation.status === 'PENDING') {
      throw new BadRequestException('이미 초대가 발송되었습니다');
    }

    // 기존 초대가 있다면 새로 생성하기 전에 삭제
    if (existingInvitation) {
      await this.prisma.teamInvitation.delete({
        where: { id: existingInvitation.id },
      });
    }

    // 새 초대장 생성 (7일 후 만료)
    const expiresAt = new Date();
    expiresAt.setDate(expiresAt.getDate() + 7);

    return this.prisma.teamInvitation.create({
      data: {
        email,
        teamId,
        invitedBy,
        role,
        expiresAt,
      },
      include: {
        team: true,
        inviter: {
          select: {
            id: true,
            name: true,
            email: true,
          },
        },
      },
    });
  }

  // 사용자가 받은 초대 목록 조회
  async getUserInvitations(email: string): Promise<TeamInvitation[]> {
    return this.prisma.teamInvitation.findMany({
      where: {
        email,
        status: 'PENDING',
        expiresAt: {
          gt: new Date(), // 만료되지 않은 초대만
        },
      },
      include: {
        team: true,
        inviter: {
          select: {
            id: true,
            name: true,
            email: true,
          },
        },
      },
      orderBy: {
        createdAt: 'desc',
      },
    });
  }

  // 팀의 초대 목록 조회 (팀 관리자용)
  async getTeamInvitations(teamId: string, userId: string): Promise<TeamInvitation[]> {
    // 권한 확인
    const membership = await this.prisma.teamMember.findFirst({
      where: {
        teamId,
        userId,
      },
    });

    if (!membership || !['OWNER', 'ADMIN'].includes(membership.role)) {
      throw new ForbiddenException('팀 초대를 조회할 권한이 없습니다');
    }

    return this.prisma.teamInvitation.findMany({
      where: {
        teamId,
        status: 'PENDING',
      },
      include: {
        inviter: {
          select: {
            id: true,
            name: true,
            email: true,
          },
        },
      },
      orderBy: {
        createdAt: 'desc',
      },
    });
  }

  // 초대 수락
  async acceptInvitation(token: string, userId: string): Promise<void> {
    const invitation = await this.prisma.teamInvitation.findUnique({
      where: { token },
      include: { team: true },
    });

    if (!invitation) {
      throw new NotFoundException('초대를 찾을 수 없습니다');
    }

    if (invitation.status !== 'PENDING') {
      throw new BadRequestException('이미 처리된 초대입니다');
    }

    if (invitation.expiresAt < new Date()) {
      throw new BadRequestException('만료된 초대입니다');
    }

    // 사용자 정보 확인
    const user = await this.prisma.user.findUnique({
      where: { id: userId },
    });

    if (!user || user.email !== invitation.email) {
      throw new ForbiddenException('초대받은 사용자만 수락할 수 있습니다');
    }

    // 이미 팀 멤버인지 다시 확인
    const existingMember = await this.prisma.teamMember.findFirst({
      where: {
        teamId: invitation.teamId,
        userId,
      },
    });

    if (existingMember) {
      throw new BadRequestException('이미 팀 멤버입니다');
    }

    // 트랜잭션으로 멤버 추가 및 초대 상태 업데이트
    await this.prisma.$transaction([
      this.prisma.teamMember.create({
        data: {
          teamId: invitation.teamId,
          userId,
          role: invitation.role,
        },
      }),
      this.prisma.teamInvitation.update({
        where: { id: invitation.id },
        data: { status: 'ACCEPTED' },
      }),
    ]);
  }

  // 초대 거절
  async declineInvitation(token: string, userId: string): Promise<void> {
    const invitation = await this.prisma.teamInvitation.findUnique({
      where: { token },
    });

    if (!invitation) {
      throw new NotFoundException('초대를 찾을 수 없습니다');
    }

    if (invitation.status !== 'PENDING') {
      throw new BadRequestException('이미 처리된 초대입니다');
    }

    // 사용자 정보 확인
    const user = await this.prisma.user.findUnique({
      where: { id: userId },
    });

    if (!user || user.email !== invitation.email) {
      throw new ForbiddenException('초대받은 사용자만 거절할 수 있습니다');
    }

    await this.prisma.teamInvitation.update({
      where: { id: invitation.id },
      data: { status: 'DECLINED' },
    });
  }

  // 초대 취소 (팀 관리자용)
  async cancelInvitation(invitationId: string, userId: string): Promise<void> {
    const invitation = await this.prisma.teamInvitation.findUnique({
      where: { id: invitationId },
      include: {
        team: {
          include: {
            members: true,
          },
        },
      },
    });

    if (!invitation) {
      throw new NotFoundException('초대를 찾을 수 없습니다');
    }

    // 권한 확인
    const membership = invitation.team.members.find(m => m.userId === userId);
    if (!membership || !['OWNER', 'ADMIN'].includes(membership.role)) {
      throw new ForbiddenException('초대를 취소할 권한이 없습니다');
    }

    await this.prisma.teamInvitation.delete({
      where: { id: invitationId },
    });
  }

  // 만료된 초대 정리 (크론 작업용)
  async cleanupExpiredInvitations(): Promise<void> {
    await this.prisma.teamInvitation.updateMany({
      where: {
        status: 'PENDING',
        expiresAt: {
          lt: new Date(),
        },
      },
      data: {
        status: 'EXPIRED',
      },
    });
  }
} 