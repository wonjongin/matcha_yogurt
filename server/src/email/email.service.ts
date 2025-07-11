import { Injectable } from '@nestjs/common';
import * as nodemailer from 'nodemailer';

@Injectable()
export class EmailService {
  private transporter: nodemailer.Transporter;

  constructor() {
    // Gmail SMTP 설정 (개발용)
    // 실제 운영에서는 SendGrid, AWS SES 등 사용 권장
    this.transporter = nodemailer.createTransport({
      service: 'gmail',
      auth: {
        user: process.env.EMAIL_USER || 'your-email@gmail.com',
        pass: process.env.EMAIL_PASS || 'your-app-password', // Gmail 앱 비밀번호
      },
    });
  }

  async sendVerificationEmail(email: string, name: string, token: string): Promise<void> {
    const backendUrl = process.env.API_BASE_URL || 'http://localhost:3000';
    const verificationUrl = `${backendUrl}/auth/verify-email?token=${token}`;

    const mailOptions = {
      from: process.env.EMAIL_FROM || 'Matcha Yogurt <noreply@matchayogurt.com>',
      to: email,
      subject: '이메일 인증을 완료해주세요 - Matcha Yogurt',
      html: `
        <div style="max-width: 600px; margin: 0 auto; padding: 20px; font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;">
          <div style="text-align: center; margin-bottom: 30px;">
            <h1 style="color: #10B981; margin: 0; font-size: 28px;">🍃 Matcha Yogurt</h1>
            <p style="color: #6B7280; margin: 5px 0;">팀과 함께하는 스마트한 일정 관리</p>
          </div>
          
          <div style="background: #F9FAFB; padding: 30px; border-radius: 12px; margin-bottom: 20px;">
            <h2 style="color: #111827; margin: 0 0 15px 0;">안녕하세요, ${name}님!</h2>
            <p style="color: #374151; line-height: 1.6; margin: 0 0 20px 0;">
              Matcha Yogurt에 가입해 주셔서 감사합니다.<br>
              이메일 인증을 완료하여 서비스를 시작해보세요.
            </p>
            
            <div style="text-align: center; margin: 25px 0;">
              <a href="${verificationUrl}" 
                 style="background: #10B981; color: white; padding: 12px 24px; border-radius: 8px; text-decoration: none; display: inline-block; font-weight: 500;">
                이메일 인증하기
              </a>
            </div>
            
            <p style="color: #6B7280; font-size: 14px; margin: 20px 0 0 0;">
              위 버튼이 작동하지 않는다면, 아래 링크를 브라우저에 복사해서 붙여넣어 주세요:<br>
              <a href="${verificationUrl}" style="color: #10B981; word-break: break-all;">${verificationUrl}</a>
            </p>
          </div>
          
          <div style="text-align: center; color: #9CA3AF; font-size: 12px;">
            <p>이 링크는 24시간 후 만료됩니다.</p>
            <p>만약 이 이메일을 요청하지 않으셨다면, 무시하셔도 됩니다.</p>
          </div>
        </div>
      `,
    };

    try {
      await this.transporter.sendMail(mailOptions);
      console.log(`Verification email sent to ${email}`);
    } catch (error) {
      console.error('Email sending failed:', error);
      throw new Error('Failed to send verification email');
    }
  }

  async sendWelcomeEmail(email: string, name: string): Promise<void> {
    const frontendUrl = process.env.FRONTEND_URL || 'http://localhost:64672';

    const mailOptions = {
      from: process.env.EMAIL_FROM || 'Matcha Yogurt <noreply@matchayogurt.com>',
      to: email,
      subject: '환영합니다! - Matcha Yogurt',
      html: `
        <div style="max-width: 600px; margin: 0 auto; padding: 20px; font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;">
          <div style="text-align: center; margin-bottom: 30px;">
            <h1 style="color: #10B981; margin: 0; font-size: 28px;">🎉 환영합니다!</h1>
          </div>
          
          <div style="background: #F9FAFB; padding: 30px; border-radius: 12px;">
            <h2 style="color: #111827; margin: 0 0 15px 0;">${name}님, 인증이 완료되었습니다!</h2>
            <p style="color: #374151; line-height: 1.6; margin: 0 0 20px 0;">
              이제 Matcha Yogurt의 모든 기능을 사용하실 수 있습니다:
            </p>
            
            <ul style="color: #374151; line-height: 1.8; padding-left: 20px;">
              <li>📅 개인 및 팀 일정 관리</li>
              <li>👥 팀 생성 및 멤버 초대</li>
              <li>🔔 일정 알림 및 공유</li>
              <li>📱 모바일과 웹에서 동기화</li>
            </ul>
            
            <div style="text-align: center; margin: 25px 0;">
              <a href="${frontendUrl}" 
                 style="background: #10B981; color: white; padding: 12px 24px; border-radius: 8px; text-decoration: none; display: inline-block; font-weight: 500;">
                지금 시작하기
              </a>
            </div>
          </div>
          
          <div style="text-align: center; color: #9CA3AF; font-size: 12px; margin-top: 20px;">
            <p>궁금한 점이 있으시면 언제든 문의해 주세요.</p>
          </div>
        </div>
      `,
    };

    try {
      await this.transporter.sendMail(mailOptions);
      console.log(`Welcome email sent to ${email}`);
    } catch (error) {
      console.error('Welcome email sending failed:', error);
      // Welcome 이메일 실패는 치명적이지 않으므로 에러를 던지지 않음
    }
  }
} 