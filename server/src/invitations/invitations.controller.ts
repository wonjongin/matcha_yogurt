import {
  Controller,
  Post,
  Get,
  Patch,
  Delete,
  Body,
  Param,
  Query,
  Request,
  UseGuards,
  HttpStatus,
  HttpCode,
} from '@nestjs/common';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { InvitationsService } from './invitations.service';
import { TeamRole } from '@prisma/client';

interface CreateInvitationDto {
  email: string;
  role: TeamRole;
}

@Controller('invitations')
@UseGuards(JwtAuthGuard)
export class InvitationsController {
  constructor(private readonly invitationsService: InvitationsService) {}

  // 팀 초대 발송
  @Post('teams/:teamId/invite')
  async inviteToTeam(
    @Param('teamId') teamId: string,
    @Body() createInvitationDto: CreateInvitationDto,
    @Request() req: any,
  ) {
    return this.invitationsService.createInvitation(
      teamId,
      createInvitationDto.email,
      createInvitationDto.role,
      req.user.id,
    );
  }

  // 내가 받은 초대 목록 조회
  @Get('my-invitations')
  async getMyInvitations(@Request() req: any) {
    return this.invitationsService.getUserInvitations(req.user.email);
  }

  // 팀의 초대 목록 조회 (팀 관리자용)
  @Get('teams/:teamId')
  async getTeamInvitations(
    @Param('teamId') teamId: string,
    @Request() req: any,
  ) {
    return this.invitationsService.getTeamInvitations(teamId, req.user.id);
  }

  // 초대 수락
  @Patch(':token/accept')
  @HttpCode(HttpStatus.NO_CONTENT)
  async acceptInvitation(
    @Param('token') token: string,
    @Request() req: any,
  ) {
    await this.invitationsService.acceptInvitation(token, req.user.id);
  }

  // 초대 거절
  @Patch(':token/decline')
  @HttpCode(HttpStatus.NO_CONTENT)
  async declineInvitation(
    @Param('token') token: string,
    @Request() req: any,
  ) {
    await this.invitationsService.declineInvitation(token, req.user.id);
  }

  // 초대 취소 (팀 관리자용)
  @Delete(':invitationId')
  @HttpCode(HttpStatus.NO_CONTENT)
  async cancelInvitation(
    @Param('invitationId') invitationId: string,
    @Request() req: any,
  ) {
    await this.invitationsService.cancelInvitation(invitationId, req.user.id);
  }
} 