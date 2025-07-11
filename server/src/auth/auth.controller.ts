import { 
  Controller, 
  Post, 
  Body, 
  Get, 
  UseGuards, 
  Request,
  HttpException,
  HttpStatus,
  Query 
} from '@nestjs/common';
import { AuthService, LoginDto, RegisterDto } from './auth.service';
import { JwtAuthGuard } from './jwt-auth.guard';

@Controller('auth')
export class AuthController {
  constructor(private readonly authService: AuthService) {}

  @Post('register')
  async register(@Body() registerDto: RegisterDto) {
    try {
      return await this.authService.register(registerDto);
    } catch (error) {
      if (error instanceof HttpException) {
        throw error;
      }
      throw new HttpException(
        'Registration failed',
        HttpStatus.INTERNAL_SERVER_ERROR,
      );
    }
  }

  @Post('login')
  async login(@Body() loginDto: LoginDto) {
    try {
      return await this.authService.login(loginDto);
    } catch (error) {
      if (error instanceof HttpException) {
        throw error;
      }
      throw new HttpException(
        'Login failed',
        HttpStatus.INTERNAL_SERVER_ERROR,
      );
    }
  }

  @UseGuards(JwtAuthGuard)
  @Get('me')
  async getProfile(@Request() req) {
    const { password, ...userWithoutPassword } = req.user;
    return {
      user: userWithoutPassword,
    };
  }

  @Post('verify-email')
  async verifyEmail(@Body() body: { token: string }) {
    try {
      return await this.authService.verifyEmail(body.token);
    } catch (error) {
      if (error instanceof HttpException) {
        throw error;
      }
      throw new HttpException(
        'Email verification failed',
        HttpStatus.BAD_REQUEST,
      );
    }
  }

  @Post('resend-verification')
  async resendVerificationEmail(@Body() body: { email: string }) {
    try {
      return await this.authService.resendVerificationEmail(body.email);
    } catch (error) {
      if (error instanceof HttpException) {
        throw error;
      }
      throw new HttpException(
        'Failed to resend verification email',
        HttpStatus.INTERNAL_SERVER_ERROR,
      );
    }
  }

  @Get('verify-email')
  async verifyEmailByQuery(@Query('token') token: string) {
    if (!token) {
      throw new HttpException(
        'Verification token is required',
        HttpStatus.BAD_REQUEST,
      );
    }

    try {
      const result = await this.authService.verifyEmail(token);
      // 성공 시 프론트엔드로 리다이렉트 (토큰과 함께)
      return `
        <!DOCTYPE html>
        <html>
          <head>
            <title>이메일 인증 완료</title>
            <meta charset="utf-8">
            <meta name="viewport" content="width=device-width, initial-scale=1.0">
            <style>
              * { box-sizing: border-box; margin: 0; padding: 0; }
              body { 
                font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif; 
                background: #f8fffe; 
                min-height: 100vh; 
                display: flex; 
                align-items: center; 
                justify-content: center;
                padding: 20px;
              }
              .container { 
                max-width: 400px; 
                width: 100%; 
                background: white; 
                border-radius: 16px; 
                padding: 40px 30px; 
                box-shadow: 0 4px 20px rgba(0,0,0,0.1);
                text-align: center;
              }
              .icon { 
                width: 80px; 
                height: 80px; 
                background: #dcfce7; 
                border-radius: 50%; 
                display: flex; 
                align-items: center; 
                justify-content: center; 
                margin: 0 auto 24px auto;
                font-size: 40px;
              }
              .title { 
                color: #10B981; 
                font-size: 24px; 
                font-weight: bold; 
                margin-bottom: 16px; 
              }
              .message { 
                color: #6b7280; 
                font-size: 16px; 
                line-height: 1.5; 
                margin-bottom: 32px; 
              }
              .info { 
                background: #f0fdf4; 
                border: 1px solid #bbf7d0; 
                border-radius: 8px; 
                padding: 16px; 
                color: #065f46; 
                font-size: 14px;
                margin-bottom: 24px;
              }
              .footer { 
                color: #9ca3af; 
                font-size: 12px; 
                line-height: 1.4;
              }
            </style>
          </head>
          <body>
            <div class="container">
              <div class="icon">✅</div>
              <div class="title">인증 완료!</div>
              <div class="message">
                이메일 인증이 성공적으로 완료되었습니다.<br>
                이제 Matcha Yogurt의 모든 기능을 사용하실 수 있습니다.
              </div>
              <div class="info">
                ✨ 로그인 정보가 자동으로 저장되었습니다.<br>
                앱이나 웹사이트로 돌아가서 계속 사용해보세요!
              </div>
              <div class="footer">
                이 창을 닫고 앱으로 돌아가세요.<br>
                문제가 있다면 다시 로그인해주세요.
              </div>
            </div>
            <script>
              // 토큰을 localStorage에 저장 (웹에서만)
              if (typeof Storage !== "undefined") {
                localStorage.setItem('jwt_token', '${result.access_token}');
              }
            </script>
          </body>
        </html>
      `;
    } catch (error) {
      return `
        <!DOCTYPE html>
        <html>
          <head>
            <title>이메일 인증 실패</title>
            <meta charset="utf-8">
            <meta name="viewport" content="width=device-width, initial-scale=1.0">
            <style>
              * { box-sizing: border-box; margin: 0; padding: 0; }
              body { 
                font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif; 
                background: #fef2f2; 
                min-height: 100vh; 
                display: flex; 
                align-items: center; 
                justify-content: center;
                padding: 20px;
              }
              .container { 
                max-width: 400px; 
                width: 100%; 
                background: white; 
                border-radius: 16px; 
                padding: 40px 30px; 
                box-shadow: 0 4px 20px rgba(0,0,0,0.1);
                text-align: center;
              }
              .icon { 
                width: 80px; 
                height: 80px; 
                background: #fee2e2; 
                border-radius: 50%; 
                display: flex; 
                align-items: center; 
                justify-content: center; 
                margin: 0 auto 24px auto;
                font-size: 40px;
              }
              .title { 
                color: #ef4444; 
                font-size: 24px; 
                font-weight: bold; 
                margin-bottom: 16px; 
              }
              .message { 
                color: #6b7280; 
                font-size: 16px; 
                line-height: 1.5; 
                margin-bottom: 32px; 
              }
              .info { 
                background: #fff7ed; 
                border: 1px solid #fed7aa; 
                border-radius: 8px; 
                padding: 16px; 
                color: #9a3412; 
                font-size: 14px;
                margin-bottom: 24px;
              }
              .footer { 
                color: #9ca3af; 
                font-size: 12px; 
                line-height: 1.4;
              }
            </style>
          </head>
          <body>
            <div class="container">
              <div class="icon">❌</div>
              <div class="title">인증 실패</div>
              <div class="message">
                이메일 인증에 실패했습니다.<br>
                토큰이 유효하지 않거나 만료되었습니다.
              </div>
              <div class="info">
                ⚠️ 인증 링크가 만료되었을 수 있습니다.<br>
                새로운 인증 이메일을 요청해주세요.
              </div>
              <div class="footer">
                이 창을 닫고 앱에서 다시 시도해주세요.<br>
                문제가 계속되면 새로 회원가입을 진행하세요.
              </div>
            </div>
          </body>
        </html>
      `;
    }
  }
}
