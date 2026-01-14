# Project Name

## Overview

[One paragraph describing what this project does and its primary purpose]

## Tech Stack

| Layer | Technology |
|-------|------------|
| Language | TypeScript |
| Runtime | Node.js 20+ |
| Framework | [e.g., Express, Next.js, Fastify] |
| Database | [e.g., PostgreSQL, MongoDB, SQLite] |
| ORM | [e.g., Prisma, Drizzle, TypeORM] |
| Testing | [e.g., Vitest, Jest, Playwright] |

## Getting Started

```bash
# Install dependencies
npm install

# Set up environment
cp .env.example .env
# Edit .env with your values

# Run database migrations (if applicable)
npm run db:migrate

# Start development server
npm run dev
```

## Commands

| Command | Description |
|---------|-------------|
| `npm run dev` | Start development server with hot reload |
| `npm run build` | Build for production |
| `npm run start` | Start production server |
| `npm test` | Run test suite |
| `npm run lint` | Check code style |
| `npm run typecheck` | Run TypeScript compiler |

## Environment Variables

> ⚠️ Copy `.env.example` to `.env` and fill in values. Never commit `.env`!

| Variable | Description | Required |
|----------|-------------|----------|
| `DATABASE_URL` | Database connection string | Yes |
| `API_KEY` | External API key | Yes |
| `PORT` | Server port (default: 3000) | No |
| `NODE_ENV` | Environment (development/production) | No |

## Architecture

```
src/
├── app/                 # Application entry points
│   ├── api/             # API routes
│   └── pages/           # Page components (if applicable)
├── components/          # Reusable UI components
├── lib/                 # Shared utilities and helpers
│   ├── db/              # Database client and queries
│   └── api/             # API client wrappers
├── types/               # TypeScript type definitions
└── config/              # Configuration and constants
```

## Key Patterns

### Error Handling
- All async functions use try/catch
- Errors are logged with context
- User-facing errors are generic; detailed errors in logs only

### Database
- Queries are parameterized (no string concatenation)
- Connections are pooled
- Migrations are version controlled

### API
- All endpoints require authentication (unless public)
- Rate limiting is enabled
- Input is validated before processing

## Testing

```bash
# Run all tests
npm test

# Run tests in watch mode
npm test -- --watch

# Run specific test file
npm test -- src/lib/auth.test.ts

# Run with coverage
npm test -- --coverage
```

## Deployment

1. Build: `npm run build`
2. Run migrations: `npm run db:migrate`
3. Start: `npm run start`

## Notes for Claude

### Do
- Follow existing code patterns and naming conventions
- Add tests for new functionality
- Update types when changing data structures
- Use existing utilities in `src/lib/`

### Don't
- Hardcode credentials or secrets
- Skip error handling
- Commit directly to main branch
- Ignore TypeScript errors

---

*Last updated: [DATE]*
