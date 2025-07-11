import { NestFactory } from '@nestjs/core';
import { AppModule } from './app.module';

async function bootstrap() {
  const app = await NestFactory.create(AppModule);
  
  // CORS 활성화 - 웹 브라우저에서의 요청 허용
  app.enableCors({
    origin: true, // 모든 origin 허용 (개발용)
    methods: ['GET', 'POST', 'PUT', 'DELETE', 'PATCH', 'OPTIONS'],
    allowedHeaders: ['Content-Type', 'Authorization'],
    credentials: true, // 쿠키/인증 헤더 허용
  });
  
  await app.listen(process.env.PORT ?? 3000);
  console.log('🚀 Server running on http://localhost:3000 with CORS enabled');
}
bootstrap();
