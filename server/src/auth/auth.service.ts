import { Injectable, UnauthorizedException, BadRequestException } from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import { PrismaService } from '../prisma.service';
import { User } from '@prisma/client';
import * as bcrypt from 'bcrypt';
import { v4 as uuidv4 } from 'uuid';
import { EmailService } from '../email/email.service';

export interface AuthPayload {
  sub: string; // user id
  email: string;
  name: string;
}

export interface LoginDto {
  email: string;
  password: string;
}

export interface RegisterDto {
  name: string;
  email: string;
  password: string;
}

export interface AuthResponse {
  access_token: string;
  user: {
    id: string;
    name: string;
    email: string;
    profileImageUrl?: string;
  };
}

@Injectable()
export class AuthService {
  constructor(
    private prisma: PrismaService,
    private jwtService: JwtService,
    private emailService: EmailService,
  ) {}

  async hashPassword(password: string): Promise<string> {
    const saltRounds = 12; // 2024년 기준 권장값 (더 안전)
    return bcrypt.hash(password, saltRounds);
  }

  async validatePassword(password: string, hashedPassword: string): Promise<boolean> {
    return bcrypt.compare(password, hashedPassword);
  }

  // 비밀번호 강도 검증 추가
  validatePasswordStrength(password: string): { isValid: boolean; message?: string } {
    // 최소 8자 이상
    if (password.length < 8) {
      return { isValid: false, message: '비밀번호는 최소 8자 이상이어야 합니다.' };
    }

    // 최대 128자 제한 (DoS 공격 방지)
    if (password.length > 128) {
      return { isValid: false, message: '비밀번호는 128자를 초과할 수 없습니다.' };
    }

    // 최소 하나의 소문자
    if (!/[a-z]/.test(password)) {
      return { isValid: false, message: '비밀번호에는 최소 하나의 소문자가 포함되어야 합니다.' };
    }

    // 최소 하나의 대문자
    if (!/[A-Z]/.test(password)) {
      return { isValid: false, message: '비밀번호에는 최소 하나의 대문자가 포함되어야 합니다.' };
    }

    // 최소 하나의 숫자
    if (!/[0-9]/.test(password)) {
      return { isValid: false, message: '비밀번호에는 최소 하나의 숫자가 포함되어야 합니다.' };
    }

    // 최소 하나의 특수문자
    if (!/[!@#$%^&*()_+\-=\[\]{};':"\\|,.<>\/?~`]/.test(password)) {
      return { isValid: false, message: '비밀번호에는 최소 하나의 특수문자가 포함되어야 합니다.' };
    }

    // 연속된 문자 금지 (예: 123, abc, 111)
    if (/(.)\1{2,}/.test(password) || /012|123|234|345|456|567|678|789|890|abc|bcd|cde|def|efg|fgh|ghi|hij|ijk|jkl|klm|lmn|mno|nop|opq|pqr|qrs|rst|stu|tuv|uvw|vwx|wxy|xyz/i.test(password)) {
      return { isValid: false, message: '연속된 문자나 숫자는 사용할 수 없습니다.' };
    }

    // 일반적인 약한 비밀번호 패턴 금지
    const weakPatterns = [
      'password', 'admin', 'user', 'test', 'guest', 
      'qwerty', 'asdf', '1234', 'abcd'
    ];
    
    if (weakPatterns.some(pattern => password.toLowerCase().includes(pattern))) {
      return { isValid: false, message: '일반적으로 사용되는 약한 비밀번호는 사용할 수 없습니다.' };
    }

    return { isValid: true };
  }

  async register(registerDto: RegisterDto): Promise<{ message: string }> {
    // 사용자 수 제한 확인 (출시 초기 제한)
    const MAX_USERS = parseInt(process.env.MAX_USERS || '100'); // 환경변수로 설정 가능
    const currentUserCount = await this.prisma.user.count({
      where: { emailVerified: true }, // 인증된 사용자만 카운트
    });

    if (currentUserCount >= MAX_USERS) {
      throw new BadRequestException(
        `서비스 출시 초기로 사용자 수가 제한되어 있습니다. 현재 ${MAX_USERS}명의 사용자가 등록되어 있습니다. 곧 더 많은 사용자를 받을 예정입니다.`
      );
    }

    // 비밀번호 강도 검증
    const passwordValidation = this.validatePasswordStrength(registerDto.password);
    if (!passwordValidation.isValid) {
      throw new BadRequestException(passwordValidation.message);
    }

    // 이메일 중복 확인
    const existingUser = await this.prisma.user.findUnique({
      where: { email: registerDto.email },
    });

    if (existingUser) {
      throw new BadRequestException('이미 사용 중인 이메일입니다.');
    }

    // 비밀번호 해싱
    const hashedPassword = await this.hashPassword(registerDto.password);

    // 인증 토큰 생성 (24시간 유효)
    const verificationToken = uuidv4();
    const verificationTokenExpiresAt = new Date();
    verificationTokenExpiresAt.setHours(verificationTokenExpiresAt.getHours() + 24);

    // 사용자 생성 (이메일 미인증 상태)
    const user = await this.prisma.user.create({
      data: {
        name: registerDto.name,
        email: registerDto.email,
        password: hashedPassword,
        emailVerified: false,
        verificationToken,
        verificationTokenExpiresAt,
      },
    });

    // 인증 이메일 발송
    try {
      await this.emailService.sendVerificationEmail(
        user.email,
        user.name,
        verificationToken,
      );
    } catch (error) {
      // 이메일 발송 실패 시 사용자 삭제
      await this.prisma.user.delete({ where: { id: user.id } });
      throw new BadRequestException('Failed to send verification email');
    }

    return {
      message: '회원가입이 완료되었습니다. 이메일을 확인하여 인증을 완료해주세요.',
    };
  }

  async login(loginDto: LoginDto): Promise<AuthResponse> {
    // 사용자 조회
    const user = await this.prisma.user.findUnique({
      where: { email: loginDto.email },
    });

    if (!user) {
      throw new UnauthorizedException('이메일 또는 비밀번호가 올바르지 않습니다.');
    }

    // 비밀번호 검증
    const isValidPassword = await this.validatePassword(loginDto.password, user.password);

    if (!isValidPassword) {
      throw new UnauthorizedException('이메일 또는 비밀번호가 올바르지 않습니다.');
    }

    // 이메일 인증 확인
    if (!user.emailVerified) {
      throw new UnauthorizedException('로그인하기 전에 이메일 인증을 완료해주세요.');
    }

    // JWT 토큰 생성
    const payload: AuthPayload = {
      sub: user.id,
      email: user.email,
      name: user.name,
    };

    const access_token = this.jwtService.sign(payload);

    return {
      access_token,
      user: {
        id: user.id,
        name: user.name,
        email: user.email,
      },
    };
  }

  async validateUser(payload: AuthPayload): Promise<User | null> {
    return this.prisma.user.findUnique({
      where: { id: payload.sub },
    });
  }

  async getUserFromToken(token: string): Promise<User | null> {
    try {
      const payload = this.jwtService.verify(token) as AuthPayload;
      return this.validateUser(payload);
    } catch (error) {
      return null;
    }
  }

  async verifyEmail(token: string): Promise<AuthResponse> {
    // 토큰으로 사용자 찾기
    const user = await this.prisma.user.findFirst({
      where: {
        verificationToken: token,
        verificationTokenExpiresAt: {
          gt: new Date(), // 만료되지 않은 토큰
        },
      },
    });

    if (!user) {
      throw new BadRequestException('Invalid or expired verification token');
    }

    // 이메일 인증 완료
    const verifiedUser = await this.prisma.user.update({
      where: { id: user.id },
      data: {
        emailVerified: true,
        verificationToken: null,
        verificationTokenExpiresAt: null,
      },
    });

    // 환영 이메일 발송 (백그라운드에서)
    this.emailService.sendWelcomeEmail(verifiedUser.email, verifiedUser.name).catch(
      (error) => console.error('Failed to send welcome email:', error),
    );

    // JWT 토큰 생성
    const payload: AuthPayload = {
      sub: verifiedUser.id,
      email: verifiedUser.email,
      name: verifiedUser.name,
    };

    const access_token = this.jwtService.sign(payload);

    return {
      access_token,
      user: {
        id: verifiedUser.id,
        name: verifiedUser.name,
        email: verifiedUser.email,
      },
    };
  }

  async resendVerificationEmail(email: string): Promise<{ message: string }> {
    // 사용자 조회
    const user = await this.prisma.user.findUnique({
      where: { email },
    });

    if (!user) {
      throw new BadRequestException('User not found');
    }

    if (user.emailVerified) {
      throw new BadRequestException('Email is already verified');
    }

    // 새로운 인증 토큰 생성
    const verificationToken = uuidv4();
    const verificationTokenExpiresAt = new Date();
    verificationTokenExpiresAt.setHours(verificationTokenExpiresAt.getHours() + 24);

    // 토큰 업데이트
    await this.prisma.user.update({
      where: { id: user.id },
      data: {
        verificationToken,
        verificationTokenExpiresAt,
      },
    });

    // 인증 이메일 재발송
    try {
      await this.emailService.sendVerificationEmail(
        user.email,
        user.name,
        verificationToken,
      );
    } catch (error) {
      throw new BadRequestException('Failed to send verification email');
    }

    return {
      message: '인증 이메일이 재발송되었습니다.',
    };
  }
}
