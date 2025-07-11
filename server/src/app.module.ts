import { Module } from '@nestjs/common';
import { AppController } from './app.controller';
import { AppService } from './app.service';
import { PrismaModule } from './prisma.module';
import { UsersModule } from './users/users.module';
import { TeamsModule } from './teams/teams.module';
import { EventsModule } from './events/events.module';
import { AuthModule } from './auth/auth.module';
import { InvitationsModule } from './invitations/invitations.module';

@Module({
  imports: [PrismaModule, UsersModule, TeamsModule, EventsModule, AuthModule, InvitationsModule],
  controllers: [AppController],
  providers: [AppService],
})
export class AppModule {}
