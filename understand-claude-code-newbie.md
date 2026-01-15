# Hướng dẫn toàn tập về Claude Code V2

> **Lưu ý:** Đây là phiên bản V2 của hướng dẫn đã được cộng đồng đón nhận nồng nhiệt. Cảm ơn rất nhiều đến u/headset38, u/tulensrma, u/jcheroske và tất cả những người đã bình luận. Bạn đã chỉ ra rằng các quy tắc trong CLAUDE.md chỉ là gợi ý mà Claude có thể bỏ qua — và bạn đã đúng. Phiên bản này bổ sung **Phần 7: Skills & Hooks**, bao gồm lớp thực thi (enforcement layer) để đảm bảo Claude tuân thủ các quy tắc một cách nghiêm ngặt.

### Những gì mới trong V2:

- **Phần 7: Skills & Hooks** — Thực thi xác định thay vì gợi ý hành vi
- [GitHub repo](https://github.com/TheDecipherist/claude-code-mastery) với các template, hooks và skills sẵn sàng sử dụng

## Tóm tắt (TL;DR)

File `~/.claude/CLAUDE.md` toàn cục của bạn đóng vai trò là **người gác cổng bảo mật** (ngăn chặn rò rỉ bí mật ra môi trường production) VÀ là **bản thiết kế khung dự án** (đảm bảo mọi dự án mới đều tuân theo cùng một cấu trúc).

### Các thành phần chính

- **MCP Servers** — Mở rộng khả năng của Claude theo cấp số nhân
- **Context7** — Cung cấp cho Claude quyền truy cập vào tài liệu cập nhật nhất
- **Custom Commands** (Lệnh tùy chỉnh) và **Agents** — Tự động hóa các quy trình lặp lại
- **Hooks** — Thực thi các quy tắc một cách xác định (deterministic) ở những nơi mà `CLAUDE.md` có thể thất bại
- **Skills** — Đóng gói các chuyên môn có thể tái sử dụng

### ⚠️ Lưu ý quan trọng

Nghiên cứu cho thấy việc trộn lẫn nhiều chủ đề trong một đoạn chat gây ra **sự suy giảm hiệu suất 39%** — vì vậy hãy giữ cho các đoạn chat tập trung vào một nhiệm vụ duy nhất.

---

## Phần 1: Global CLAUDE.md như một Người gác cổng bảo mật

### Phân cấp bộ nhớ (The Memory Hierarchy)

Claude Code tải các file `CLAUDE.md` theo thứ tự cụ thể:

| Cấp độ | Vị trí | Mục đích |
|:---|:---|:---|
| **Enterprise** | `/etc/claude-code/CLAUDE.md` | Chính sách toàn tổ chức |
| **Global User** | `~/.claude/CLAUDE.md` | Tiêu chuẩn của BẠN cho TẤT CẢ dự án |
| **Project** | `./CLAUDE.md` | Hướng dẫn chung cho team trong dự án |
| **Project Local** | `./CLAUDE.local.md` | Các ghi đè cá nhân cho dự án |

> **Lưu ý:** File toàn cục (Global) của bạn áp dụng cho **mọi dự án đơn lẻ** mà bạn làm việc.

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

> **Tại sao lại là toàn cục?** Bạn sử dụng cùng một tài khoản ở khắp mọi nơi. Định nghĩa một lần, kế thừa mọi nơi.

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

[Các nhà nghiên cứu bảo mật đã phát hiện](https://www.knostic.ai/blog/claude-loads-secrets-without-permission) rằng Claude Code **tự động đọc các file `.env`** mà không cần sự cho phép rõ ràng. [Backslash Security cảnh báo](https://www.backslash.security/blog/claude-code-security-best-practices):

> "Nếu không bị hạn chế, Claude có thể đọc `.env`, thông tin đăng nhập AWS, hoặc `secrets.json` và làm lộ chúng thông qua các 'gợi ý hữu ích'."

File `CLAUDE.md` toàn cục của bạn tạo ra một **người gác cổng hành vi** — ngay cả khi Claude có quyền truy cập, nó sẽ không xuất ra các bí mật này.

### Phòng thủ theo chiều sâu (Defense in Depth)

| Lớp | Cơ chế | Cách thức |
|:---|:---|:---|
| 1 | Quy tắc hành vi | Global `CLAUDE.md` "NEVER" rules |
| 2 | Kiểm soát truy cập | Deny list trong `settings.json` |
| 3 | An toàn Git | `.gitignore` |

---

## Phần 2: Các quy tắc Global cho Khung dự án mới (Scaffolding)

Đây là nơi `CLAUDE.md` toàn cục trở thành một **nhà máy dự án**. Mọi dự án mới bạn tạo ra sẽ tự động thừa hưởng các tiêu chuẩn, cấu trúc và yêu cầu an toàn của bạn.

### Vấn đề khi không có Quy tắc Scaffolding

[Nghiên cứu từ các chuyên gia về project scaffolding](https://github.com/madison-hutson/claude-project-scaffolding) giải thích:

> "Phát triển được hỗ trợ bởi LLM thất bại bằng cách mở rộng phạm vi một cách im lặng, làm suy giảm chất lượng và mất đi ý định kiến trúc."

Nếu không có các quy tắc scaffolding toàn cục:

- Mỗi dự án có cấu trúc khác nhau
- Các file bảo mật bị lãng quên (`.gitignore`, `.dockerignore`)
- Xử lý lỗi không nhất quán
- Các mẫu tài liệu (documentation patterns) thay đổi liên tục
- Bạn tốn thời gian giải thích lại cùng một yêu cầu

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

```javascript
process.on('unhandledRejection', (reason, promise) => {
  console.error('Unhandled Rejection at:', promise, 'reason:', reason);
  process.exit(1);
});

process.on('uncaughtException', (error) => {
  console.error('Uncaught Exception:', error);
  process.exit(1);
});
```

### 5. Required CLAUDE.md Sections
Every project CLAUDE.md must include:
- Project overview (what it does)
- Tech stack
- Build commands
- Test commands
- Architecture overview
```

### Advanced: Framework-Specific Rules

```markdown
## Framework-Specific Setup

### Next.js Projects
- Use App Router (not Pages Router)
- Create `src/app/` directory structure
- Include `next.config.js` with strict mode enabled
- Add analytics to layout.tsx

### Python Projects
- Create `pyproject.toml` (not setup.py)
- Use `src/` layout
- Include `requirements.txt` AND `requirements-dev.txt`
- Add `.python-version` file

### Docker Projects
- Multi-stage builds ALWAYS
- Never run as root (use non-root user)
- Include health checks
- `.dockerignore` must mirror `.gitignore` + include `.git/`
```

### Tại sao nó hiệu quả?

Khi bạn bảo Claude "tạo một dự án Node.js mới", nó sẽ đọc `CLAUDE.md` toàn cục trước và **tự động**:

1. Tạo `.env` và `.env.example`
2. Thiết lập `.gitignore` chuẩn
3. Tạo cấu trúc thư mục
4. Thêm xử lý lỗi
5. Tạo `CLAUDE.md` cho dự án

> **Kết quả:** Bạn không bao giờ phải nhớ những yêu cầu này nữa.

### Các cổng chất lượng (Quality Gates) trong Scaffolding

[Phương pháp claude-project-scaffolding](https://github.com/madison-hutson/claude-project-scaffolding) thêm sự thực thi:

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

### CI/CD Requirements
Every project must include:
- `.github/workflows/ci.yml` for GitHub Actions
- Pre-commit hooks via Husky (Node.js) or pre-commit (Python)
```

### Ví dụ: Điều gì xảy ra khi bạn tạo một dự án

**Bạn nói:** "Tạo một dự án e-commerce Next.js mới tên là shopify-clone"

**Claude đọc global CLAUDE.md và tự động tạo:**

```
shopify-clone/
├── .env                          ← Created (empty, for secrets)
├── .env.example                  ← Created (with placeholder vars)
├── .gitignore                    ← Created (with ALL required entries)
├── .dockerignore                 ← Created (mirrors .gitignore)
├── README.md                     ← Created (references env vars)
├── CLAUDE.md                     ← Created (with required sections)
├── src/
│   └── app/                      ← App Router structure
├── tests/
├── docs/
├── .claude/
│   ├── commands/
│   └── settings.json
└── scripts/
```

> **Kết quả:** Không cần thiết lập thủ công. Mọi dự án đều bắt đầu an toàn và nhất quán.

---

## Phần 3: MCP Servers — Các tích hợp của Claude

[MCP (Model Context Protocol)](https://www.anthropic.com/news/model-context-protocol) cho phép Claude tương tác với các công cụ và dịch vụ bên ngoài.

### MCP Servers làm gì?

> "MCP là một giao thức mở chuẩn hóa cách các ứng dụng cung cấp ngữ cảnh cho LLM."

MCP servers cung cấp cho Claude:

- Truy cập cơ sở dữ liệu
- Tích hợp với API
- Khả năng hệ thống tệp tin mở rộng ngoài dự án
- Tự động hóa trình duyệt
- Và nhiều hơn nữa

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
|:---|:---|:---|
| **Context7** | Tài liệu trực tuyến (Live documentation) | `claude mcp add context7 -- npx -y @anthropic-ai/context7-mcp` |
| **Playwright** | Kiểm thử trình duyệt | `claude mcp add playwright -- npx -y @anthropic-ai/playwright-mcp` |
| **GitHub** | Quản lý repo | `claude mcp add github -- npx -y @modelcontextprotocol/server-github` |
| **PostgreSQL** | Truy vấn DB | `claude mcp add postgres -- npx -y @modelcontextprotocol/server-postgres` |
| **Filesystem** | Truy cập file mở rộng | `claude mcp add fs -- npx -y @anthropic-ai/filesystem-mcp` |

### MCP trong CLAUDE.md

Ghi lại các MCP servers bắt buộc trong file global của bạn:

```markdown
## Required MCP Servers

These MCP servers must be installed for full functionality:

### context7
Live documentation access for all libraries.
Install: `claude mcp add context7 -- npx -y @anthropic-ai/context7-mcp`

### playwright
Browser automation for testing.
Install: `claude mcp add playwright -- npx -y @anthropic-ai/playwright-mcp`
```

---

## Phần 4: Context7 — Tài liệu trực tuyến (Live Documentation)

[Context7](https://github.com/upstash/context7) là một bước ngoặt. Nó cung cấp cho Claude quyền truy cập vào **tài liệu cập nhật** cho bất kỳ thư viện nào.

### Vấn đề

Dữ liệu huấn luyện của Claude có thời điểm cắt (cutoff). Khi bạn hỏi về:

- Một thư viện được phát hành sau khi huấn luyện
- Thay đổi API gần đây
- Các tính năng framework mới

Claude có thể đưa ra thông tin lỗi thời hoặc không chính xác.

### Giải pháp

Context7 lấy tài liệu trực tuyến (live documentation):

```
Bạn: "Using context7, show me how to use the new Next.js 15 cache API"

Claude: *tải tài liệu Next.js hiện tại*
        *cung cấp code chính xác, cập nhật*
```

### Cài đặt

```bash
claude mcp add context7 -- npx -y @anthropic-ai/context7-mcp
```

### Các mẫu sử dụng

| Mẫu | Ví dụ |
|:---|:---|
| **Explicit** | "Using context7, look up Prisma's createMany" |
| **Research** | "Check context7 for React Server Components patterns" |
| **Debugging** | "Use context7 to find the correct Tailwind v4 syntax" |

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

[Slash commands](https://code.claude.com/docs/en/slash-commands) là các prompt tái sử dụng giúp tự động hóa quy trình làm việc.

### Tạo Commands

Commands nằm trong `.claude/commands/` dưới dạng file markdown:

#### Ví dụ: `/fix-types`

**File:** `.claude/commands/fix-types.md`

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

**Sử dụng:** `/fix-types`

### Lợi ích của Commands

| Lợi ích | Mô tả |
|:---|:---|
| **Workflow efficiency** | Một từ thay vì đoạn prompt dài |
| **Team sharing** | Commit vào git, mọi người đều có |
| **Parameterization** | Sử dụng `$ARGUMENTS` cho input động |
| **Orchestration** | Commands có thể spawn sub-agents |

### Sub-Agents (Tác nhân con)

[Sub-agents](https://www.arsturn.com/blog/commands-vs-sub-agents-in-claude-code-a-guide-to-supercharging-your-workflow) chạy trong **cửa sổ ngữ cảnh bị cô lập** (isolated context window) — chúng không làm "ô nhiễm" cuộc hội thoại chính của bạn.

> "Mỗi sub-agent hoạt động trong ngữ cảnh riêng của nó. Điều này có nghĩa là nó có thể tập trung vào một nhiệm vụ cụ thể mà không bị 'ô nhiễm' bởi cuộc hội thoại chính."

### Thư viện lệnh toàn cục (Global Commands Library)

Thêm các lệnh thường dùng vào cấu hình global của bạn:

```markdown
## Global Commands

Store these in ~/.claude/commands/ for use in ALL projects:

### /new-project
Creates new project with all scaffolding rules applied.

### /security-check
Scans for secrets, validates .gitignore, checks .env handling.

### /pre-commit
Runs all quality gates before committing.

### /docs-lookup
Spawns sub-agent with Context7 to research documentation.
```

---

## Phần 6: Tại sao Chat Đơn mục đích (Single-Purpose Chats) lại Quan trọng

Đây có thể là phần quan trọng nhất. **Nghiên cứu liên tục chỉ ra rằng việc trộn lẫn các chủ đề phá hủy độ chính xác.**

### Nghiên cứu

[Nghiên cứu về các cuộc hội thoại đa lượt](https://arxiv.org/pdf/2505.06120) phát hiện:

> "Giảm trung bình **39% hiệu suất** khi hướng dẫn được phân phối qua nhiều lượt, với các mô hình đưa ra giả định sớm và không thể điều chỉnh lại."

[Nghiên cứu về context rot của Chroma](https://research.trychroma.com/context-rot):

> "Khi số lượng token trong cửa sổ ngữ cảnh tăng lên, khả năng nhớ lại thông tin chính xác của mô hình giảm đi."

[Nghiên cứu về context pollution](https://kurtiskemple.com/blog/measuring-context-pollution/):

> "Một **sự lệch 2%** sớm trong chuỗi hội thoại có thể tạo ra **tỷ lệ thất bại 40%** vào cuối."

### Tại sao điều này xảy ra

**1. Vấn đề Lost-in-the-Middle**

LLM nhớ thông tin tốt nhất từ **đầu và cuối** ngữ cảnh. Nội dung ở giữa dễ bị quên.

**2. Context Drift**

[Nghiên cứu cho thấy](https://arxiv.org/html/2510.07777) context drift là:

> "Sự suy giảm hoặc biến dạng dần dần của trạng thái hội thoại mà mô hình sử dụng để tạo phản hồi."

Khi bạn chuyển chủ đề, ngữ cảnh trước đó trở thành **nhiễu gây nhầm lẫn** cho suy luận sau này.

**3. Attention Budget**

[Hướng dẫn context engineering của Anthropic](https://www.anthropic.com/engineering/effective-context-engineering-for-ai-agents) giải thích:

> "Transformers yêu cầu mối quan hệ cặp n² giữa các token. Khi ngữ cảnh mở rộng, 'ngân sách chú ý' của mô hình bị kéo căng mỏng."

### Điều gì xảy ra khi bạn trộn lẫn chủ đề

```
Turn 1-5: Thảo luận về hệ thống xác thực
Turn 6-10: Chuyển sang thiết kế database schema
Turn 11-15: Hỏi lại về hệ thống xác thực

Kết quả: Claude nhầm lẫn khái niệm database với auth,
         đưa ra giả định sai, câu trả lời suy giảm
```

Cuộc thảo luận về auth trước đó giờ bị chôn vùi trong ngữ cảnh "giữa", cạnh tranh với thảo luận database để được chú ý.

### Quy tắc Vàng

> **"Một Nhiệm vụ, Một Chat" (One Task, One Chat)**

Từ [best practices về quản lý ngữ cảnh](https://www.arsturn.com/blog/beyond-prompting-a-guide-to-managing-context-in-claude-code):

> "Nếu bạn chuyển từ brainstorming nội dung marketing sang phân tích PDF, hãy bắt đầu một chat mới. Đừng để ngữ cảnh bị trộn lẫn. Điều này giữ cho 'bảng trắng' của AI sạch sẽ."

### Hướng dẫn thực tế

| Tình huống | Hành động |
|:---|:---|
| Tính năng mới | **Chat mới** |
| Sửa lỗi (không liên quan đến việc hiện tại) | **/clear** rồi làm |
| File/module khác | Cân nhắc **Chat mới** |
| Nghiên cứu vs Thực thi | Tách biệt các chat |
| Quá 20 lượt | Bắt đầu lại (**Fresh start**) |

### Sử dụng /clear thường xuyên

```bash
/clear
```

Lệnh này reset ngữ cảnh. [Anthropic khuyến nghị](https://www.anthropic.com/engineering/claude-code-best-practices):

> "Sử dụng `/clear` thường xuyên giữa các nhiệm vụ để reset cửa sổ ngữ cảnh, đặc biệt là trong các phiên dài nơi các cuộc hội thoại không liên quan tích lũy."

### Sub-Agents để cô lập chủ đề

Nếu bạn cần nghiên cứu điều gì đó giữa nhiệm vụ mà không làm ô nhiễm ngữ cảnh:

```
Spawn một sub-agent để nghiên cứu React Server Components.
Chỉ trả về tóm tắt các pattern chính.
```

Sub-agent hoạt động trong ngữ cảnh cô lập và chỉ trả về câu trả lời.

---

## Phần 7: Skills & Hooks — Sự thực thi thay vì Gợi ý

Phần này được thêm vào dựa trên phản hồi cộng đồng. Đặc biệt cảm ơn u/headset38 và u/tulensrma vì đã chỉ ra rằng **Claude không phải lúc nào cũng tuân theo các quy tắc CLAUDE.md một cách nghiêm ngặt**.

### Tại sao các quy tắc CLAUDE.md có thể thất bại

[Nghiên cứu về prompt-based guardrails](https://paddo.dev/blog/claude-code-hooks-guardrails/) giải thích:

> "Prompts được diễn giải tại runtime bởi một LLM có thể bị thuyết phục theo cách khác. Bạn cần một cái gì đó xác định (deterministic)."

Các chế độ thất bại phổ biến:

- **Context window pressure:** Các cuộc hội thoại dài có thể đẩy các quy tắc ra khỏi sự chú ý tích cực
- **Conflicting instructions:** Các ngữ cảnh khác có thể ghi đè quy tắc của bạn
- **Copy-paste propagation:** Ngay cả khi Claude không chỉnh sửa `.env`, nó có thể sao chép bí mật sang file khác

Một thành viên cộng đồng lưu ý rằng PreToolUse hook của họ bắt được Claude cố gắng truy cập file `.env` "vài lần mỗi tuần" — mặc dù có quy tắc CLAUDE.md rõ ràng nói không được làm vậy.

### Sự khác biệt quan trọng

| Cơ chế | Loại | Độ tin cậy |
|:---|:---|:---|
| **CLAUDE.md rules** | Gợi ý (Suggestion) | Tốt, nhưng có thể bị ghi đè |
| **Hooks** | Thực thi (Enforcement) | Xác định — Luôn luôn chạy |
| **settings.json deny list** | Thực thi | Tốt |
| **.gitignore** | Giải pháp cuối cùng | Chỉ ngăn chặn commit |

**So sánh:**

```
PreToolUse hook chặn chỉnh sửa .env:
  → Luôn chạy
  → Trả về exit code 2
  → Hoạt động bị chặn. Kết thúc.

CLAUDE.md nói "đừng chỉnh sửa .env":
  → Được phân tích bởi LLM
  → Cân nhắc với ngữ cảnh khác
  → Có thể được tuân theo
```

### Hooks: Kiểm soát xác định

[Hooks](https://code.claude.com/docs/en/hooks) là các lệnh shell thực thi tại các điểm cụ thể trong vòng đời. Chúng không phải là gợi ý — chúng là code chạy mỗi lần.

#### Hook Events

| Event | Khi nào kích hoạt | Use Case |
|:---|:---|:---|
| **PreToolUse** | Trước khi bất kỳ công cụ nào thực thi | Chặn các hoạt động nguy hiểm |
| **PostToolUse** | Sau khi công cụ hoàn thành | Chạy linters, formatters, tests |
| **Stop** | Khi Claude kết thúc phản hồi | Cổng chất lượng cuối lượt |
| **UserPromptSubmit** | Khi người dùng gửi prompt | Validate/enhance prompts |
| **SessionStart** | Phiên mới bắt đầu | Load context, khởi tạo |
| **Notification** | Claude gửi cảnh báo | Desktop notifications |

#### Ví dụ: Chặn truy cập Secrets (PreToolUse)

Thêm vào `~/.claude/settings.json`:

```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Read|Edit|Write",
        "hooks": [
          {
            "type": "command",
            "command": "python3 ~/.claude/hooks/block-secrets.py"
          }
        ]
      }
    ]
  }
}
```

Script hook (`~/.claude/hooks/block-secrets.py`):

```python
#!/usr/bin/env python3
"""
PreToolUse hook để chặn truy cập các file nhạy cảm.
Exit code 2 = chặn hoạt động và gửi stderr cho Claude.
"""
import json
import sys
from pathlib import Path

SENSITIVE_PATTERNS = {
    '.env', '.env.local', '.env.production',
    'secrets.json', 'secrets.yaml',
    'id_rsa', 'id_ed25519', '.npmrc', '.pypirc'
}

def main():
    try:
        data = json.load(sys.stdin)
        tool_input = data.get('tool_input', {})
        file_path = tool_input.get('file_path') or tool_input.get('path') or ''
        
        if not file_path:
            sys.exit(0)
        
        path = Path(file_path)
        
        if path.name in SENSITIVE_PATTERNS or '.env' in str(path):
            print(f"BLOCKED: Access to '{path.name}' denied.", file=sys.stderr)
            print("Use environment variables instead.", file=sys.stderr)
            sys.exit(2)  # Exit 2 = chặn và gửi stderr cho Claude
        
        sys.exit(0)
    except Exception:
        sys.exit(0)  # Fail open

if __name__ == '__main__':
    main()
```

#### Ví dụ: Cổng chất lượng khi Stop

Chạy linters và tests khi Claude kết thúc mỗi lượt:

```json
{
  "hooks": {
    "Stop": [
      {
        "matcher": "*",
        "hooks": [
          {
            "type": "command",
            "command": "~/.claude/hooks/end-of-turn.sh"
          }
        ]
      }
    ]
  }
}
```

#### Hook Exit Codes

| Code | Ý nghĩa |
|:---|:---|
| 0 | Thành công, cho phép hoạt động |
| 1 | Lỗi (chỉ hiển thị cho người dùng) |
| **2** | **Chặn hoạt động, gửi stderr cho Claude** |

### Skills: Chuyên môn được đóng gói

[Skills](https://code.claude.com/docs/en/skills) là các file markdown dạy Claude cách làm một việc cụ thể — giống như tài liệu hướng dẫn cho nhân viên mới.

Từ [engineering blog của Anthropic](https://www.anthropic.com/engineering/equipping-agents-for-the-real-world-with-agent-skills):

> "Xây dựng một skill cho một agent giống như soạn một hướng dẫn onboarding cho nhân viên mới."

#### Cách Skills hoạt động

**Tiết lộ dần dần (Progressive disclosure)** là nguyên tắc chính:

1. **Startup:** Claude chỉ tải *tên và mô tả* skill vào ngữ cảnh
2. **Triggered:** Khi liên quan, Claude đọc toàn bộ file `SKILL.md`
3. **As needed:** Các tài nguyên bổ sung chỉ tải khi được tham chiếu

Điều này có nghĩa là bạn có thể cài đặt hàng chục skills với chi phí ngữ cảnh tối thiểu.

#### Cấu trúc Skill

```
.claude/skills/
└── commit-messages/
    ├── SKILL.md           ← Bắt buộc: instructions + frontmatter
    ├── templates.md       ← Tùy chọn: tài liệu tham khảo
    └── validate.py        ← Tùy chọn: script thực thi
```

**SKILL.md** (bắt buộc):

```markdown
---
name: commit-messages
description: Generate clear commit messages from git diffs. Use when writing commit messages or reviewing staged changes.
---

# Commit Message Skill

When generating commit messages:
1. Run `git diff --staged` to see changes
2. Use conventional commit format: `type(scope): description`
3. Keep subject line under 72 characters

## Types
- feat: New feature
- fix: Bug fix  
- docs: Documentation
- refactor: Code restructuring
```

#### Khi nào sử dụng Skills vs các tùy chọn khác

| Nhu cầu | Giải pháp |
|:---|:---|
| Hướng dẫn cụ thể cho dự án | Project `CLAUDE.md` |
| Workflow tái sử dụng qua các dự án | **Skill** |
| Tích hợp công cụ bên ngoài | MCP Server |
| Thực thi xác định | **Hook** |
| Tự động hóa một lần | Slash Command |

### Kết hợp Hooks và Skills

Thiết lập mạnh mẽ nhất sử dụng cả hai:

- Một **skill** `secrets-handling` dạy Claude *cách* làm việc với bí mật đúng cách
- Một **hook** (PreToolUse) *cưỡng chế* việc Claude không bao giờ được phép đọc file `.env`

### Phòng thủ theo chiều sâu được cập nhật

| Lớp | Cơ chế | Loại |
|:---|:---|:---|
| 1 | CLAUDE.md behavioral rules | Suggestion |
| **2** | **PreToolUse hooks** | **Enforcement** |
| 3 | settings.json deny list | Enforcement |
| 4 | .gitignore | Prevention |
| **5** | **Skills với security checklists** | **Guidance** |

---

## Tổng hợp: Đặt tất cả lại với nhau

### Mẫu Global CLAUDE.md hoàn chỉnh

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

---

## Tham khảo nhanh (Quick Reference)

| Thành phần | Vị trí | Mục đích |
|:---|:---|:---|
| **Global CLAUDE.md** | `~/.claude/CLAUDE.md` | Bảo mật + Scaffolding |
| **Project CLAUDE.md** | `./CLAUDE.md` | Kiến trúc + Lệnh dự án |
| **MCP Servers** | `claude mcp add` | Tích hợp bên ngoài |
| **Slash Commands** | `.claude/commands/*.md` | Tự động hóa workflow |
| **Skills** | `.claude/skills/*/SKILL.md` | Đóng gói chuyên môn |
| **Hooks** | `~/.claude/settings.json` | Thực thi xác định |
| **/clear** | Command | Reset ngữ cảnh (Rất quan trọng!) |
| **/init** | Command | Generate project CLAUDE.md |

---

## GitHub Repo

Tất cả templates, hooks và skills từ hướng dẫn này có sẵn tại:

**[github.com/TheDecipherist/claude-code-mastery](https://github.com/TheDecipherist/claude-code-mastery)**

### Bao gồm:

- Template CLAUDE.md hoàn chỉnh (global + project)
- Hooks sẵn sàng sử dụng (block-secrets.py, end-of-turn.sh, v.v.)
- Skills ví dụ (commit-messages, security-audit)
- settings.json với hooks được cấu hình sẵn

---

## Nguồn tham khảo

- [Claude Code: Best practices for agentic coding](https://www.anthropic.com/engineering/claude-code-best-practices) — Anthropic
- [Effective context engineering for AI agents](https://www.anthropic.com/engineering/effective-context-engineering-for-ai-agents) — Anthropic
- [Introducing the Model Context Protocol](https://www.anthropic.com/news/model-context-protocol) — Anthropic
- [Equipping agents for the real world with Agent Skills](https://www.anthropic.com/engineering/equipping-agents-for-the-real-world-with-agent-skills) — Anthropic
- [Agent Skills Documentation](https://code.claude.com/docs/en/skills) — Claude Code Docs
- [Hooks Reference](https://code.claude.com/docs/en/hooks) — Claude Code Docs
- [Claude Project Scaffolding](https://github.com/madison-hutson/claude-project-scaffolding) — Madison Hutson
- [CLAUDE.md Templates](https://github.com/ruvnet/claude-flow/wiki/CLAUDE-MD-Templates) — Claude-Flow
- [Context7 MCP Server](https://github.com/upstash/context7) — Upstash
- [Context Rot Research](https://research.trychroma.com/context-rot) — Chroma
- [LLMs Get Lost In Multi-Turn Conversation](https://arxiv.org/pdf/2505.06120) — arXiv
- [Claude Code Security Best Practices](https://www.backslash.security/blog/claude-code-security-best-practices) — Backslash
- [Claude Code Hooks: Guardrails That Actually Work](https://paddo.dev/blog/claude-code-hooks-guardrails/) — Paddo.dev
- [Claude Code Hooks Mastery](https://github.com/disler/claude-code-hooks-mastery) — GitHub
- [Claude loads secrets without permission](https://www.knostic.ai/blog/claude-loads-secrets-without-permission) — Knostic
- [Slash Commands Documentation](https://code.claude.com/docs/en/slash-commands) — Claude Code Docs
- [Writing a good CLAUDE.md](https://www.humanlayer.dev/blog/writing-a-good-claude-md) — HumanLayer
- [Context Management Guide](https://www.arsturn.com/blog/beyond-prompting-a-guide-to-managing-context-in-claude-code) — Arsturn
- [CLAUDE.md Best Practices from Prompt Learning](https://arize.com/blog/claude-md-best-practices-learned-from-optimizing-claude-code-with-prompt-learning/) — Arize

---

> **Bạn có gì trong global CLAUDE.md của mình? Chia sẻ hooks, skills và patterns của bạn bên dưới.**
>
> *Được viết với ❤️ bởi [TheDecipherist](https://thedecipherist.com?utm_source=reddit&utm_medium=readme&utm_campaign=claude-code-mastery&utm_content=author-link) và cộng đồng Claude Code*