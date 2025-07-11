import {
  Controller,
  Get,
  Post,
  Body,
  Patch,
  Param,
  Delete,
  HttpException,
  HttpStatus,
  Query,
} from '@nestjs/common';
import { TeamsService } from './teams.service';
import { Prisma, TeamRole } from '@prisma/client';

interface AddMemberDto {
  userId: string;
  role?: TeamRole;
}

interface UpdateMemberRoleDto {
  role: TeamRole;
}

@Controller('teams')
export class TeamsController {
  constructor(private readonly teamsService: TeamsService) {}

  @Post()
  async create(@Body() createTeamDto: Prisma.TeamCreateInput) {
    return this.teamsService.create(createTeamDto);
  }

  @Get()
  async findAll(@Query('userId') userId?: string) {
    if (userId) {
      return this.teamsService.findUserTeams(userId);
    }
    return this.teamsService.findAll();
  }

  @Get(':id')
  async findOne(@Param('id') id: string) {
    const team = await this.teamsService.findOne(id);
    if (!team) {
      throw new HttpException('Team not found', HttpStatus.NOT_FOUND);
    }
    return team;
  }

  @Patch(':id')
  async update(
    @Param('id') id: string,
    @Body() updateTeamDto: Prisma.TeamUpdateInput,
  ) {
    try {
      return await this.teamsService.update(id, updateTeamDto);
    } catch (error) {
      if (error.code === 'P2025') {
        throw new HttpException('Team not found', HttpStatus.NOT_FOUND);
      }
      throw error;
    }
  }

  @Delete(':id')
  async remove(@Param('id') id: string) {
    try {
      return await this.teamsService.remove(id);
    } catch (error) {
      if (error.code === 'P2025') {
        throw new HttpException('Team not found', HttpStatus.NOT_FOUND);
      }
      throw error;
    }
  }

  // Team member management endpoints
  @Get(':id/members')
  async getMembers(@Param('id') teamId: string) {
    return this.teamsService.getTeamMembers(teamId);
  }

  @Post(':id/members')
  async addMember(
    @Param('id') teamId: string,
    @Body() addMemberDto: AddMemberDto,
  ) {
    try {
      return await this.teamsService.addMember(
        teamId,
        addMemberDto.userId,
        addMemberDto.role,
      );
    } catch (error) {
      if (error.code === 'P2002') {
        throw new HttpException(
          'User is already a member of this team',
          HttpStatus.BAD_REQUEST,
        );
      }
      if (error.code === 'P2003') {
        throw new HttpException(
          'Team or user not found',
          HttpStatus.NOT_FOUND,
        );
      }
      throw error;
    }
  }

  @Delete(':id/members/:userId')
  async removeMember(
    @Param('id') teamId: string,
    @Param('userId') userId: string,
  ) {
    try {
      return await this.teamsService.removeMember(teamId, userId);
    } catch (error) {
      if (error.code === 'P2025') {
        throw new HttpException(
          'Team member not found',
          HttpStatus.NOT_FOUND,
        );
      }
      throw error;
    }
  }

  @Patch(':id/members/:userId/role')
  async updateMemberRole(
    @Param('id') teamId: string,
    @Param('userId') userId: string,
    @Body() updateRoleDto: UpdateMemberRoleDto,
  ) {
    try {
      return await this.teamsService.updateMemberRole(
        teamId,
        userId,
        updateRoleDto.role,
      );
    } catch (error) {
      if (error.code === 'P2025') {
        throw new HttpException(
          'Team member not found',
          HttpStatus.NOT_FOUND,
        );
      }
      throw error;
    }
  }
}
