import { Injectable } from '@nestjs/common';
import { PrismaService } from '../prisma.service';
import { Event, Prisma, EventType } from '@prisma/client';

interface EventFilters {
  teamIds?: string[];
  eventTypes?: EventType[];
  startDate?: Date;
  endDate?: Date;
  userId?: string;
  search?: string;
}

@Injectable()
export class EventsService {
  constructor(private prisma: PrismaService) {}

  async create(data: Prisma.EventCreateInput): Promise<Event> {
    return this.prisma.event.create({
      data,
      include: {
        team: true,
        user: true,
      },
    });
  }

  async findAll(filters?: EventFilters): Promise<Event[]> {
    const where: Prisma.EventWhereInput = {};

    if (filters?.teamIds?.length) {
      where.teamId = {
        in: filters.teamIds,
      };
    }

    if (filters?.eventTypes?.length) {
      where.eventType = {
        in: filters.eventTypes,
      };
    }

    if (filters?.userId) {
      where.userId = filters.userId;
    }

    if (filters?.search) {
      where.OR = [
        {
          title: {
            contains: filters.search,
          },
        },
        {
          description: {
            contains: filters.search,
          },
        },
      ];
    }

    // Date range filter
    if (filters?.startDate || filters?.endDate) {
      where.AND = [];

      if (filters.startDate) {
        where.AND.push({
          endTime: {
            gte: filters.startDate,
          },
        });
      }

      if (filters.endDate) {
        where.AND.push({
          startTime: {
            lte: filters.endDate,
          },
        });
      }
    }

    return this.prisma.event.findMany({
      where,
      include: {
        team: true,
        user: true,
      },
      orderBy: {
        startTime: 'asc',
      },
    });
  }

  async findByDateRange(startDate: Date, endDate: Date): Promise<Event[]> {
    return this.prisma.event.findMany({
      where: {
        AND: [
          {
            startTime: {
              lte: endDate,
            },
          },
          {
            endTime: {
              gte: startDate,
            },
          },
        ],
      },
      include: {
        team: true,
        user: true,
      },
      orderBy: {
        startTime: 'asc',
      },
    });
  }

  async findByDay(date: Date): Promise<Event[]> {
    const startOfDay = new Date(date);
    startOfDay.setHours(0, 0, 0, 0);

    const endOfDay = new Date(date);
    endOfDay.setHours(23, 59, 59, 999);

    return this.findByDateRange(startOfDay, endOfDay);
  }

  async findTeamEvents(teamId: string, filters?: EventFilters): Promise<Event[]> {
    return this.findAll({
      ...filters,
      teamIds: [teamId],
    });
  }

  async findUserEvents(userId: string, filters?: EventFilters): Promise<Event[]> {
    return this.findAll({
      ...filters,
      userId,
    });
  }

  async findOne(id: string): Promise<Event | null> {
    return this.prisma.event.findUnique({
      where: { id },
      include: {
        team: true,
        user: true,
      },
    });
  }

  async update(id: string, data: Prisma.EventUpdateInput): Promise<Event> {
    return this.prisma.event.update({
      where: { id },
      data,
      include: {
        team: true,
        user: true,
      },
    });
  }

  async remove(id: string): Promise<Event> {
    return this.prisma.event.delete({
      where: { id },
    });
  }

  // Get events count by type for statistics
  async getEventStats(userId?: string, teamId?: string) {
    const where: Prisma.EventWhereInput = {};
    
    if (userId) {
      where.userId = userId;
    }
    
    if (teamId) {
      where.teamId = teamId;
    }

    const stats = await this.prisma.event.groupBy({
      by: ['eventType'],
      where,
      _count: true,
    });

    return stats.map(stat => ({
      eventType: stat.eventType,
      count: stat._count,
    }));
  }
}
