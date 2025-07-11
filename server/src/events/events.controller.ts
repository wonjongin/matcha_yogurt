import {
  Controller,
  Get,
  Post,
  Body,
  Patch,
  Param,
  Delete,
  Query,
  HttpException,
  HttpStatus,
} from '@nestjs/common';
import { EventsService } from './events.service';
import { Prisma, EventType } from '@prisma/client';

@Controller('events')
export class EventsController {
  constructor(private readonly eventsService: EventsService) {}

  @Post()
  async create(@Body() createEventDto: any) {
    // 날짜 필드를 Date 객체로 변환
    const processedDto: Prisma.EventCreateInput = { ...createEventDto };
    
    if (createEventDto.startTime) {
      processedDto.startTime = new Date(createEventDto.startTime);
    }
    
    if (createEventDto.endTime) {
      processedDto.endTime = new Date(createEventDto.endTime);
    }

    return this.eventsService.create(processedDto);
  }

  @Get()
  async findAll(
    @Query('teamIds') teamIds?: string,
    @Query('eventTypes') eventTypes?: string,
    @Query('startDate') startDate?: string,
    @Query('endDate') endDate?: string,
    @Query('userId') userId?: string,
    @Query('search') search?: string,
  ) {
    const filters = {
      teamIds: teamIds ? teamIds.split(',') : undefined,
      eventTypes: eventTypes 
        ? eventTypes.split(',').map(type => type as EventType)
        : undefined,
      startDate: startDate ? new Date(startDate) : undefined,
      endDate: endDate ? new Date(endDate) : undefined,
      userId,
      search,
    };

    return this.eventsService.findAll(filters);
  }

  @Get('date-range')
  async findByDateRange(
    @Query('startDate') startDate: string,
    @Query('endDate') endDate: string,
  ) {
    if (!startDate || !endDate) {
      throw new HttpException(
        'startDate and endDate are required',
        HttpStatus.BAD_REQUEST,
      );
    }

    return this.eventsService.findByDateRange(
      new Date(startDate),
      new Date(endDate),
    );
  }

  @Get('day/:date')
  async findByDay(@Param('date') date: string) {
    try {
      const eventDate = new Date(date);
      return this.eventsService.findByDay(eventDate);
    } catch (error) {
      throw new HttpException(
        'Invalid date format',
        HttpStatus.BAD_REQUEST,
      );
    }
  }

  @Get('team/:teamId')
  async findTeamEvents(
    @Param('teamId') teamId: string,
    @Query('startDate') startDate?: string,
    @Query('endDate') endDate?: string,
    @Query('eventTypes') eventTypes?: string,
    @Query('search') search?: string,
  ) {
    const filters = {
      startDate: startDate ? new Date(startDate) : undefined,
      endDate: endDate ? new Date(endDate) : undefined,
      eventTypes: eventTypes 
        ? eventTypes.split(',').map(type => type as EventType)
        : undefined,
      search,
    };

    return this.eventsService.findTeamEvents(teamId, filters);
  }

  @Get('user/:userId')
  async findUserEvents(
    @Param('userId') userId: string,
    @Query('startDate') startDate?: string,
    @Query('endDate') endDate?: string,
    @Query('eventTypes') eventTypes?: string,
    @Query('search') search?: string,
  ) {
    const filters = {
      startDate: startDate ? new Date(startDate) : undefined,
      endDate: endDate ? new Date(endDate) : undefined,
      eventTypes: eventTypes 
        ? eventTypes.split(',').map(type => type as EventType)
        : undefined,
      search,
    };

    return this.eventsService.findUserEvents(userId, filters);
  }

  @Get('stats')
  async getEventStats(
    @Query('userId') userId?: string,
    @Query('teamId') teamId?: string,
  ) {
    return this.eventsService.getEventStats(userId, teamId);
  }

  @Get(':id')
  async findOne(@Param('id') id: string) {
    const event = await this.eventsService.findOne(id);
    if (!event) {
      throw new HttpException('Event not found', HttpStatus.NOT_FOUND);
    }
    return event;
  }

  @Patch(':id')
  async update(
    @Param('id') id: string,
    @Body() updateEventDto: any,
  ) {
    try {
      // 날짜 필드를 Date 객체로 변환
      const processedDto: Prisma.EventUpdateInput = { ...updateEventDto };
      
      if (updateEventDto.startTime) {
        processedDto.startTime = new Date(updateEventDto.startTime);
      }
      
      if (updateEventDto.endTime) {
        processedDto.endTime = new Date(updateEventDto.endTime);
      }

      return await this.eventsService.update(id, processedDto);
    } catch (error) {
      if (error.code === 'P2025') {
        throw new HttpException('Event not found', HttpStatus.NOT_FOUND);
      }
      throw error;
    }
  }

  @Delete(':id')
  async remove(@Param('id') id: string) {
    try {
      return await this.eventsService.remove(id);
    } catch (error) {
      if (error.code === 'P2025') {
        throw new HttpException('Event not found', HttpStatus.NOT_FOUND);
      }
      throw error;
    }
  }
}
