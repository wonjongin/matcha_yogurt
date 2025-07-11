import { Injectable } from '@nestjs/common';
import { PrismaService } from '../prisma.service';
import { Team, TeamMember, Prisma, TeamRole } from '@prisma/client';

@Injectable()
export class TeamsService {
  constructor(private prisma: PrismaService) {}

  async create(data: Prisma.TeamCreateInput): Promise<Team> {
    // Create team and automatically add owner as team member
    return this.prisma.$transaction(async (prisma) => {
      const team = await prisma.team.create({
        data,
        include: {
          owner: {
            select: {
              id: true,
              name: true,
              email: true,
              createdAt: true,
              updatedAt: true,
            },
          },
          members: {
            include: {
              user: {
                select: {
                  id: true,
                  name: true,
                  email: true,
                  createdAt: true,
                  updatedAt: true,
                },
              },
            },
          },
        },
      });

      // Add owner as team member
      await prisma.teamMember.create({
        data: {
          teamId: team.id,
          userId: team.ownerId,
          role: TeamRole.OWNER,
        },
      });

      return team;
    });
  }

  async findAll(): Promise<Team[]> {
    return this.prisma.team.findMany({
      include: {
        owner: true,
        members: {
          include: {
            user: true,
          },
        },
        events: true,
        _count: {
          select: {
            members: true,
            events: true,
          },
        },
      },
    });
  }

  async findOne(id: string): Promise<Team | null> {
    return this.prisma.team.findUnique({
      where: { id },
      include: {
        owner: true,
        members: {
          include: {
            user: true,
          },
        },
        events: true,
        _count: {
          select: {
            members: true,
            events: true,
          },
        },
      },
    });
  }

  async findUserTeams(userId: string): Promise<Team[]> {
    return this.prisma.team.findMany({
      where: {
        members: {
          some: {
            userId,
          },
        },
      },
      include: {
        owner: true,
        members: {
          include: {
            user: true,
          },
        },
        _count: {
          select: {
            members: true,
            events: true,
          },
        },
      },
    });
  }

  async update(id: string, data: Prisma.TeamUpdateInput): Promise<Team> {
    return this.prisma.team.update({
      where: { id },
      data,
      include: {
        owner: true,
        members: {
          include: {
            user: true,
          },
        },
      },
    });
  }

  async remove(id: string): Promise<Team> {
    return this.prisma.team.delete({
      where: { id },
    });
  }

  // Team member management
  async addMember(
    teamId: string,
    userId: string,
    role: TeamRole = TeamRole.MEMBER,
  ): Promise<TeamMember> {
    return this.prisma.teamMember.create({
      data: {
        teamId,
        userId,
        role,
      },
      include: {
        user: true,
        team: true,
      },
    });
  }

  async removeMember(teamId: string, userId: string): Promise<TeamMember> {
    return this.prisma.teamMember.delete({
      where: {
        teamId_userId: {
          teamId,
          userId,
        },
      },
    });
  }

  async updateMemberRole(
    teamId: string,
    userId: string,
    role: TeamRole,
  ): Promise<TeamMember> {
    return this.prisma.teamMember.update({
      where: {
        teamId_userId: {
          teamId,
          userId,
        },
      },
      data: {
        role,
      },
      include: {
        user: true,
        team: true,
      },
    });
  }

  async getTeamMembers(teamId: string): Promise<TeamMember[]> {
    return this.prisma.teamMember.findMany({
      where: { teamId },
      include: {
        user: true,
      },
    });
  }
}
