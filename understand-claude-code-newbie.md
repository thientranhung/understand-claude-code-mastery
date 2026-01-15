# Hướng dẫn toàn tập về Claude Code V2: CLAUDE.md, MCP, Commands, Skills & Hooks — Cập nhật dựa trên phản hồi của bạn

> **Lưu ý:** Đây là phiên bản V2 của hướng dẫn đã được cộng đồng đón nhận nồng nhiệt. Phiên bản này bổ sung **Phần 7: Skills & Hooks**, bao gồm lớp thực thi (enforcement layer) để đảm bảo Claude tuân thủ các quy tắc một cách nghiêm ngặt.

## Tóm tắt (TL;DR)
File `~/.claude/CLAUDE.md` toàn cục của bạn đóng vai trò là **người gác cổng bảo mật** (ngăn chặn rò rỉ bí mật ra môi trường production) VÀ là **bản thiết kế khung dự án** (đảm bảo mọi dự án mới đều tuân theo cùng một cấu trúc). 
- **MCP Servers** mở rộng khả năng của Claude theo cấp số nhân.
- **Context7** cung cấp cho Claude quyền truy cập vào tài liệu cập nhật nhất.
- **Custom commands** (Lệnh tùy chỉnh) và **Agents** tự động hóa các quy trình lặp lại.
- **Hooks** thực thi các quy tắc một cách xác định (deterministic) ở những nơi mà `CLAUDE.md` có thể thất bại.
- **Skills** đóng gói các chuyên môn có thể tái sử dụng.
- Và nghiên cứu cho thấy việc trộn lẫn nhiều chủ đề trong một đoạn chat gây ra **sự suy giảm hiệu suất 39%** — vì vậy hãy giữ cho các đoạn chat tập trung vào một nhiệm vụ duy nhất.

---

## Phần 1: Global CLAUDE.md như một Người gác cổng bảo mật

### Phân cấp bộ nhớ (The Memory Hierarchy)
Claude Code tải các file `CLAUDE.md` theo thứ tự cụ thể:

| Cấp độ | Vị trí | Mục đích |
| :--- | :--- | :--- |
| **Enterprise** | `/etc/claude-code/CLAUDE.md` | Chính sách toàn tổ chức |
| **Global User** | `~/.claude/CLAUDE.md` | Tiêu chuẩn của BẠN cho TẤT CẢ dự án |
| **Project** | `./CLAUDE.md` | Hướng dẫn chung cho team trong dự án |
| **Project Local** | `./CLAUDE.local.md` | Các ghi đè cá nhân cho dự án |

File toàn cục (Global) của bạn áp dụng cho **mọi dự án đơn lẻ** mà bạn làm việc.

### Những gì thuộc về Global (Toàn cục)

#### 1. Định danh & Xác thực (Identity & Authentication)
```markdown
## GitHub Account
**ALWAYS** use **YourUsername** for all projects:
- SSH: `git@github.com:YourUsername/<repo>.git`

## Docker Hub
Already authenticated. Username in `~/.env` as `DOCKER_HUB_USER`

## Deployment
Use Dokploy MCP for production. API URL in `~/.env`
```
*Tại sao lại là toàn cục?* Bạn sử dụng cùng một tài khoản ở khắp mọi nơi. Định nghĩa một lần, kế thừa mọi nơi.

#### 2. Các quy tắc "Người gác cổng" (The Gatekeeper Rules)
```markdown
## NEVER EVER DO

These rules are ABSOLUTE:

### NEVER Publish Sensitive Data
- NEVER publish passwords, API keys, tokens to git/npm/docker
- Before ANY commit: verify no secrets included

### NEVER Commit .env Files
- NEVER commit `.env` to git
- ALWAYS verify `.env` is in `.gitignore`

### NEVER Hardcode Credentials
- ALWAYS use environment variables
```

### Tại sao điều này quan trọng: Claude đọc file .env của bạn
Các nhà nghiên cứu bảo mật đã phát hiện ra rằng Claude Code tự động đọc các file `.env` mà không cần sự cho phép rõ ràng. Nếu không bị hạn chế, Claude có thể đọc `.env`, thông tin đăng nhập AWS, hoặc `secrets.json` và làm lộ chúng thông qua các "gợi ý hữu ích".

File `CLAUDE.md` toàn cục của bạn tạo ra một **người gác cổng hành vi** — ngay cả khi Claude có quyền truy cập, nó sẽ không xuất ra các bí mật này.

### Phòng thủ theo chiều sâu (Defense in Depth)
| Lớp | Cơ chế | Cách thức |
| :--- | :--- | :--- |
| 1 | Quy tắc hành vi | Global `CLAUDE.md` "NEVER" rules |
| 2 | Kiểm soát truy cập | Deny list trong `settings.json` |
| 3 | An toàn Git | `.gitignore` |

---

## Phần 2: Các quy tắc Global cho Khung dự án mới (Scaffolding)

Đây là nơi `CLAUDE.md` toàn cục trở thành một **nhà máy dự án**. Mọi dự án mới bạn tạo ra sẽ tự động thừa hưởng các tiêu chuẩn, cấu trúc và yêu cầu an toàn của bạn.

### Vấn đề khi không có Quy tắc Scaffolding
Nếu không có các quy tắc scaffolding toàn cục:
- Mỗi dự án có cấu trúc khác nhau.
- Các file bảo mật bị lãng quên (`.gitignore`, `.dockerignore`).
- Xử lý lỗi không nhất quán.
- Các mẫu tài liệu (documentation patterns) thay đổi liên tục.
- Bạn tốn thời gian giải thích lại cùng một yêu cầu.

### Giải pháp: Thêm mục "New Project Setup" vào Global CLAUDE.md

```markdown
## New Project Setup

When creating ANY new project, ALWAYS do the following:

### 1. Required Files (Create Immediately)
- `.env` — Environment variables (NEVER commit)
- `.env.example` — Template with placeholder values
- `.gitignore` — Must include: .env, .env.*, node_modules/, dist/, .claude/
- `.dockerignore` — Must include: .env, .git/, node_modules/
- `README.md` — Project overview (reference env vars, don't hardcode)

### 2. Required Directory Structure
project-root/
├── src/               # Source code
├── tests/             # Test files
├── docs/              # Documentation (gitignored for generated docs)
├── .claude/           # Claude configuration
│   ├── commands/      # Custom slash commands
│   └── settings.json  # Project-specific settings
└── scripts/           # Build/deploy scripts

### 3. Required .gitignore Entries
# Environment
.env
.env.*
.env.local

# Dependencies
node_modules/
vendor/
pycache/

# Build outputs
dist/
build/
.next/

# Claude local files
.claude/settings.local.json
CLAUDE.local.md

# Generated docs
docs/.generated.

### 4. Node.js Projects — Required Error Handling
Add to entry point (index.ts, server.ts, app.ts):
// [Code snippet xử lý unhandledRejection và uncaughtException]

### 5. Required CLAUDE.md Sections
Every project CLAUDE.md must include:
- Project overview
- Tech stack
- Build commands
- Test commands
- Architecture overview
```

### Tại sao nó hiệu quả?
Khi bạn bảo Claude "tạo một dự án Node.js mới", nó sẽ đọc `CLAUDE.md` toàn cục trước và **tự động**:
1. Tạo `.env` và `.env.example`.
2. Thiết lập `.gitignore` chuẩn.
3. Tạo cấu trúc thư mục.
4. Thêm xử lý lỗi.
5. Tạo `CLAUDE.md` cho dự án.

**Bạn không bao giờ phải nhớ những yêu cầu này nữa.**

### Các cổng chất lượng (Quality Gates) trong Scaffolding
Thêm sự thực thi chất lượng:
```markdown
## Quality Requirements

### File Size Limits
- No file > 300 lines (split if larger)
- No function > 50 lines

### Required Before Commit
- All tests pass
- TypeScript compiles with no errors
- Linter passes with no warnings
- No secrets in staged files
```

---

## Phần 3: MCP Servers — Các tích hợp của Claude

**MCP (Model Context Protocol)** là một giao thức mở chuẩn hóa cách các ứng dụng cung cấp ngữ cảnh cho LLM. Nó cho phép Claude:
- Truy cập cơ sở dữ liệu.
- Tích hợp với API.
- Tương tác với hệ thống tệp tin bên ngoài dự án.
- Tự động hóa trình duyệt.

### Các lệnh MCP cơ bản
```bash
# Thêm server
claude mcp add <server-name> -- <command>

# Liệt kê server
claude mcp list

# Xóa server
claude mcp remove <server-name>
```

### Các MCP Server thiết yếu
| Server | Mục đích | Cài đặt |
| :--- | :--- | :--- |
| **Context7** | Tài liệu trực tuyến (Live documentation) | `claude mcp add context7 -- npx -y @anthropic-ai/context7-mcp` |
| **Playwright** | Kiểm thử trình duyệt | `claude mcp add playwright -- npx -y @anthropic-ai/playwright-mcp` |
| **GitHub** | Quản lý repo | `claude mcp add github -- npx -y @modelcontextprotocol/server-github` |
| **PostgreSQL** | Truy vấn DB | `claude mcp add postgres -- npx -y @modelcontextprotocol/server-postgres` |
| **Filesystem** | Truy cập file mở rộng | `claude mcp add fs -- npx -y @anthropic-ai/filesystem-mcp` |

---

## Phần 4: Context7 — Tài liệu trực tuyến (Live Documentation)

**Vấn đề:** Dữ liệu huấn luyện của Claude có thời điểm cắt (cutoff). Nó có thể không biết về các thư viện mới, thay đổi API gần đây.
**Giải pháp:** Context7 lấy tài liệu trực tuyến (live documentation).

```
Bạn: "Using context7, show me how to use the new Next.js 15 cache API"
Claude: *tải tài liệu Next.js hiện tại* -> *cung cấp code chính xác*
```

### Thêm vào Global CLAUDE.md
```markdown
## Documentation Lookup

When unsure about library APIs or recent changes:
1. Use Context7 MCP to fetch current documentation
2. Prefer official docs over training knowledge
3. Always verify version compatibility
```

---

## Phần 5: Custom Commands và Sub-Agents

**Slash commands** (Lệnh gạch chéo) là các prompt tái sử dụng giúp tự động hóa quy trình làm việc. Chúng nằm trong `.claude/commands/`.

### Ví dụ: `/fix-types`
File: `.claude/commands/fix-types.md`
```markdown
---
description: Fix TypeScript errors
---

Run `npx tsc --noEmit` and fix any type errors.
For each error:
1. Identify the root cause
2. Fix with minimal changes
3. Verify the fix compiles

After fixing all errors, run the check again to confirm.
```
Sử dụng: `/fix-types`

### Sub-Agents (Tác nhân con)
Sub-agents chạy trong **cửa sổ ngữ cảnh bị cô lập** (isolated context window).
> "Mỗi sub-agent hoạt động trong ngữ cảnh riêng của nó. Điều này có nghĩa là nó có thể tập trung vào một nhiệm vụ cụ thể mà không bị 'ô nhiễm' bởi cuộc hội thoại chính."

### Thư viện lệnh toàn cục (Global Commands Library)
Lưu trong `~/.claude/commands/`:
- `/new-project`: Tạo dự án mới với quy tắc scaffolding.
- `/security-check`: Quét bí mật, kiểm tra `.gitignore`.
- `/pre-commit`: Chạy tất cả các cổng chất lượng.
- `/docs-lookup`: Gọi sub-agent với Context7 để tra cứu tài liệu.

---

## Phần 6: Tại sao Chat Đơn mục đích (Single-Purpose Chats) lại Quan trọng

Nghiên cứu chỉ ra rằng việc trộn lẫn các chủ đề trong một đoạn chat làm **hủy hoại độ chính xác**.
- Giảm 39% hiệu suất khi hướng dẫn bị phân tán qua nhiều lượt (turns).
- "Ngữ cảnh trôi dạt" (Context Drift): Khi bạn chuyển chủ đề, ngữ cảnh cũ trở thành "nhiễu" gây nhầm lẫn cho suy luận sau này.
- Vấn đề "Lost-in-the-Middle": LLM nhớ tốt nhất ở đầu và cuối ngữ cảnh. Nội dung ở giữa dễ bị quên.

### Quy tắc Vàng: "Một Nhiệm vụ, Một Chat" (One Task, One Chat)
> "Nếu bạn chuyển từ brainstorming nội dung marketing sang phân tích PDF, hãy bắt đầu một chat mới. Đừng để ngữ cảnh bị trộn lẫn."

### Hướng dẫn thực tế
- Tính năng mới -> **Chat mới**.
- Sửa lỗi (không liên quan đến việc hiện tại) -> **/clear** rồi làm.
- File/module khác -> Cân nhắc **Chat mới**.
- Nghiên cứu vs Thực thi -> Tách biệt các chat.
- Quá 20 lượt -> Bắt đầu lại (**Fresh start**).
- Sử dụng **/clear** thường xuyên để reset ngữ cảnh.

---

## Phần 7: Skills & Hooks — Sự thực thi thay vì Gợi ý

Phần này được thêm vào dựa trên phản hồi cộng đồng: `CLAUDE.md` chỉ là gợi ý, Claude có thể bỏ qua. **Hooks** mang lại sự kiểm soát xác định (deterministic).

### Sự khác biệt quan trọng

| Cơ chế | Loại | Độ tin cậy |
| :--- | :--- | :--- |
| **CLAUDE.md rules** | Gợi ý (Suggestion) | Tốt, nhưng có thể bị ghi đè |
| **Hooks** | Thực thi (Enforcement) | Xác định — Luôn luôn chạy |
| **settings.json deny list** | Thực thi | Tốt |
| **.gitignore** | Giải pháp cuối cùng | Chỉ ngăn chặn commit |

### Hooks: Kiểm soát xác định
Hooks là các lệnh shell chạy tại các điểm cụ thể trong vòng đời.
- **PreToolUse**: Trước khi công cụ chạy (Chặn các hành động nguy hiểm).
- **PostToolUse**: Sau khi công cụ chạy.
- **Stop**: Khi Claude kết thúc lượt trả lời (Chạy linter, test).
- **UserPromptSubmit**: Khi người dùng gửi prompt.

#### Ví dụ: Chặn truy cập Secrets (PreToolUse)
Cấu hình trong `~/.claude/settings.json` để chạy script Python chặn truy cập vào `.env` hoặc các file nhạy cảm và trả về **exit code 2** (chặn hoạt động).

### Skills: Chuyên môn được đóng gói
Skills là các file markdown dạy Claude cách làm một việc cụ thể — giống như tài liệu hướng dẫn cho nhân viên mới.
- **Tiết lộ dần dần (Progressive disclosure)**: Claude chỉ tải tên và mô tả skill vào ngữ cảnh. Chỉ khi cần thiết, nó mới đọc toàn bộ file `SKILL.md`.

#### Cấu trúc Skill
```
.claude/skills/
└── commit-messages/
    ├── SKILL.md           ← Bắt buộc
    ├── templates.md       ← Tùy chọn
    └── validate.py        ← Tùy chọn
```

### Kết hợp Hooks và Skills
Thiết lập mạnh mẽ nhất sử dụng cả hai:
- Một **Skill** dạy Claude *cách làm việc* với bí mật đúng cách.
- Một **Hook** (PreToolUse) *cưỡng chế* việc Claude không bao giờ được phép đọc file `.env`.

---

## Tổng kết: Mẫu Global CLAUDE.md hoàn chỉnh

```markdown
# Global CLAUDE.md

## Identity & Accounts
- GitHub: YourUsername (SSH key: ~/.ssh/id_ed25519)
- Docker Hub: authenticated via ~/.docker/config.json
- Deployment: Dokploy (API URL in ~/.env)

## NEVER EVER DO (Security Gatekeeper)
- NEVER commit .env files
- NEVER hardcode credentials
- NEVER publish secrets to git/npm/docker
- NEVER skip .gitignore verification

## New Project Setup (Scaffolding Rules)

### Required Files
- .env (NEVER commit)
- .env.example (with placeholders)
- .gitignore (with all required entries)
- .dockerignore
- README.md
- CLAUDE.md

### Required Structure
project/
├── src/
├── tests/
├── docs/
├── .claude/commands/
└── scripts/

### Required .gitignore
.env
.env.*
node_modules/
dist/
.claude/settings.local.json
CLAUDE.local.md

### Node.js Requirements
- Error handlers in entry point
- TypeScript strict mode
- ESLint + Prettier configured

### Quality Gates
- No file > 300 lines
- All tests must pass
- No linter warnings
- CI/CD workflow required

## Framework-Specific Rules
[Your framework patterns here]

## Required MCP Servers
- context7 (live documentation)
- playwright (browser testing)

## Global Commands
- /new-project — Apply scaffolding rules
- /security-check — Verify no secrets exposed
- /pre-commit — Run all quality gates
```

### Tham khảo nhanh (Quick Reference)
- **Global CLAUDE.md**: `~/.claude/CLAUDE.md` (Bảo mật + Scaffolding)
- **Project CLAUDE.md**: `./CLAUDE.md` (Kiến trúc + Lệnh dự án)
- **MCP Servers**: `claude mcp add` (Tích hợp bên ngoài)
- **Slash Commands**: `.claude/commands/*.md` (Tự động hóa workflow)
- **Skills**: `.claude/skills/*/SKILL.md` (Đóng gói chuyên môn)
- **Hooks**: `~/.claude/settings.json` (Thực thi xác định)
- **/clear**: Reset ngữ cảnh (Rất quan trọng!)