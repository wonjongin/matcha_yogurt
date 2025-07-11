# Matcha Yogurt Server

팀 캘린더 애플리케이션의 백엔드 서버입니다. NestJS와 Prisma를 사용하여 구축되었습니다.

## 🚀 기능

- **사용자 인증**: JWT 기반 로그인/회원가입, 이메일 인증
- **팀 관리**: 팀 생성, 멤버 초대, 권한 관리
- **일정 관리**: 개인/팀 일정 생성, 수정, 삭제
- **사용자 제한**: 출시 초기 사용자 수 제한 기능
- **보안**: bcrypt 비밀번호 해싱, 강력한 비밀번호 정책

## 📋 요구사항

- Node.js 18+
- pnpm
- SQLite (개발용) / PostgreSQL (프로덕션)

## ⚙️ 설정

### 1. 패키지 설치

```bash
pnpm install
```

### 2. 환경변수 설정

`.env` 파일을 생성하고 다음 내용을 추가하세요:

```env
# 데이터베이스
DATABASE_URL="file:./dev.db"

# JWT 토큰
JWT_SECRET="your-super-secret-jwt-key-change-this-in-production"

# 이메일 설정 (개발 중에는 콘솔로 출력)
SMTP_HOST="localhost"
SMTP_PORT="587"
SMTP_USER=""
SMTP_PASS=""
FROM_EMAIL="noreply@matcha-yogurt.com"

# 사용자 수 제한 (출시 초기)
MAX_USERS="50"  # 초기에는 50명으로 제한, 0 = 제한 없음

# 서버 포트
PORT="3000"
```

### 3. 데이터베이스 설정

```bash
# Prisma 클라이언트 생성
npx prisma generate

# 데이터베이스 동기화
npx prisma db push

# (선택사항) 데이터베이스 브라우저로 확인
npx prisma studio
```

## 🏃‍♂️ 서버 실행

```bash
# 개발 모드 (파일 변경 감지)
pnpm run start:dev

# 일반 실행
pnpm run start

# 프로덕션 빌드 후 실행
pnpm run build
pnpm run start:prod
```

## 👥 사용자 수 제한 기능

출시 초기에 서비스를 안정적으로 운영하기 위해 사용자 수 제한 기능을 제공합니다.

### 설정 방법

1. **환경변수로 제한**: `.env` 파일에서 `MAX_USERS=50` 설정
2. **제한 해제**: `MAX_USERS=0` 또는 변수 삭제
3. **실시간 변경**: 서버 재시작 없이 환경변수 변경 후 적용

### 작동 방식

- 이메일 인증이 완료된 사용자만 카운트
- 제한에 도달하면 새로운 회원가입 차단
- 기존 사용자 로그인은 정상 작동
- 친화적인 한국어 에러 메시지 제공

### 사용자 수 확인

현재 등록된 사용자 수를 확인하려면:

```bash
# SQLite 데이터베이스 직접 조회
sqlite3 prisma/dev.db "SELECT COUNT(*) FROM users WHERE emailVerified = 1;"

# 또는 Prisma Studio 사용
npx prisma studio
```

## 🔒 보안 설정

### 비밀번호 정책

- 최소 8자, 최대 128자
- 대소문자, 숫자, 특수문자 각각 최소 1개
- 연속된 문자/숫자 금지 (abc, 123 등)
- 일반적인 약한 비밀번호 패턴 금지

### JWT 설정

- 강력한 JWT_SECRET 사용 권장
- 토큰 만료 시간: 24시간 (기본값)

## 📧 이메일 설정

### 개발 환경

- 이메일이 콘솔에 출력됩니다
- SMTP 설정이 비어있어도 정상 작동

### 프로덕션 환경

```env
SMTP_HOST="your-smtp-host.com"
SMTP_PORT="587"
SMTP_USER="your-email@domain.com"
SMTP_PASS="your-app-password"
FROM_EMAIL="noreply@yourdomain.com"
```

## 🧪 테스트

```bash
# 단위 테스트
pnpm run test

# E2E 테스트
pnpm run test:e2e

# 테스트 커버리지
pnpm run test:cov
```

## 📦 빌드 및 배포

```bash
# 프로덕션 빌드
pnpm run build

# 프로덕션 실행
pnpm run start:prod
```

## 🛠️ 개발 도구

- **ESLint**: 코드 품질 검사
- **Prettier**: 코드 포맷팅
- **Prisma Studio**: 데이터베이스 GUI

## 📚 API 문서

서버 실행 후 다음 주소에서 API 문서를 확인할 수 있습니다:
- Swagger: `http://localhost:3000/api` (예정)

## 🆘 문제 해결

### 일반적인 문제

1. **Prisma 에러**: `npx prisma generate` 재실행
2. **포트 충돌**: `.env`에서 PORT 변경
3. **데이터베이스 에러**: `npx prisma db push` 재실행

### 로그 확인

```bash
# 개발 모드에서 자세한 로그 확인
DEBUG=* pnpm run start:dev
```

## 🔄 업데이트

```bash
# 의존성 업데이트
pnpm update

# Prisma 스키마 변경 후
npx prisma db push
npx prisma generate
```
