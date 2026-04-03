# pi-mono 当前项目结构与功能分析

## 1. 项目整体定位
`pi-mono` 是一个 TypeScript Monorepo，核心是“可组合的终端 AI Agent 体系”，由多个可独立发布的包组成：
- AI 抽象层（`packages/ai`）
- Agent 执行循环（`packages/agent`）
- 终端 UI 基础库（`packages/tui`）
- 编码 Agent 产品层（`packages/coding-agent`，`pi` 命令）
- Slack 智能体（`packages/mom`，`mom` 命令）
- GPU Pod/vLLM 管理（`packages/pods`，`pi-pods` 命令）
- Web 端组件层（`packages/web-ui`）

仓库根 `package.json` 使用 npm workspaces，统一构建顺序为：`tui -> ai -> agent -> coding-agent -> mom -> web-ui -> pods`。

---

## 2. Monorepo 结构（按职责）

### 根目录
- `README.md`: 仓库总览，列出所有包。
- `AGENTS.md`: 项目开发与协作规则。
- `scripts/`: 发布、版本同步、浏览器 smoke 检查、会话脚本等。
- `test.sh` / `pi-test.sh`: 顶层测试或从源码启动 pi 的脚本。

### packages/
- `ai`: 统一多模型/多供应商流式 API。
- `agent`: 通用 Agent Loop + 工具调用执行引擎。
- `tui`: 终端组件与差分渲染引擎。
- `coding-agent`: 终端编码 Agent（产品主入口）。
- `mom`: Slack Bot 版本的 Agent 运行器。
- `pods`: 远程 GPU Pod 与 vLLM 模型部署管理 CLI。
- `web-ui`: 基于 Web Components 的聊天 UI 组件。

---

## 3. 各模块作用与边界

本节按「职责—边界—包内阅读顺序」描述各包；全局学习路径见 **3.8**。

### 3.1 依赖层级（与阅读前提）

```
pi-ai（无本仓 TS 依赖）
  ↑
pi-agent-core
  ↑
pi-coding-agent ←── pi-mom（再叠 Slack/沙箱）
     ↑              pi-web-ui（另依赖 pi-tui，类型/集成上依赖 Agent）
pi-tui（独立 UI 库，与 agent 无 package 依赖）

pi（npm 名，bin: pi-pods）: 仅声明 chalk + pi-agent-core；与 pi-ai 无直接依赖
```

- 想理解「一次对话如何从模型流到工具再回模型」：必须先有 **ai → agent**，再进 **coding-agent** 或 **web-ui**。
- **tui** 可与 **agent** 并行阅读：二者在 package 层互不依赖，只在 **coding-agent** 里粘合。
- **mom / web-ui / pods** 是三条产品或工具线，都假设你已掌握各自底座（见 3.8）。

---

### 3.2 `packages/ai`（`@mariozechner/pi-ai`）

| 维度 | 说明 |
|------|------|
| **职责** | 将多厂商 LLM HTTP/API 差异收敛为统一**流式事件**（text / tool_call / thinking / usage / stop 等），供上层循环消费。 |
| **边界** | 不包含 Agent 状态机、不执行用户工具、不提供终端或 Web UI；不管会话持久化与业务 system prompt。 |
| **扩展方式** | 新 provider：`types.ts` 声明 → `providers/<name>.ts` 实现 → `register-builtins.ts` 懒注册 → `generate-models.ts` 与测试矩阵（见 `AGENTS.md`）。 |

**包内建议阅读顺序**

1. `src/types.ts`：消息、工具、API 联合类型与选项映射。
2. `src/stream.ts`：`stream` / `complete`、`streamSimple` / `completeSimple`（上层默认入口多为 simple 路径）。
3. `src/providers/register-builtins.ts`：`registerApiProvider` 与懒加载约定。
4. 任选一条已熟悉的厂商链：`providers/<vendor>.ts` + `transform-messages` 一类共用逻辑。
5. `src/env-api-keys.ts`（及 OAuth 相关）：凭据发现与配置来源。

---

### 3.3 `packages/agent`（`@mariozechner/pi-agent-core`）

| 维度 | 说明 |
|------|------|
| **职责** | 与传输/UI 解耦的 **Agent 运行时**：消息状态、`Agent` 事件流、多轮 **tool loop**（串行/并行）、steering 队列、abort/continue。 |
| **边界** | 不实现「读文件/bash」等业务工具；不内置 CLI；不直接渲染终端；**convertToLlm / transformContext** 由宿主注入，本包只约定调用时机。 |
| **与 ai 的关系** | 依赖 `pi-ai` 发起流式补全；循环内如何把 `AgentMessage` 转成 LLM 消息由宿主提供。 |

**包内建议阅读顺序**

1. `src/agent.ts`：`Agent` 类、订阅模型、队列与生命周期事件。
2. `src/agent-loop.ts`：`runAgentLoop` / `runAgentLoopContinue`（一轮 turn 内：上下文变换 → 调模型 → 解析 tool → 钩子 → 执行 → 写回消息）。
3. 与工具相关的类型与执行分支（与 `AgentTool`、并行策略同目录或相邻模块，以仓库当前结构为准）。
4. `package.json` 仅依赖 `pi-ai`，确认没有反向依赖 **coding-agent**。

---

### 3.4 `packages/tui`（`@mariozechner/pi-tui`）

| 维度 | 说明 |
|------|------|
| **职责** | 终端 **组件树 + 差分渲染**、焦点/overlay/光标/IME、键位解析与可配置快捷键；可复用于任意 TUI 应用。 |
| **边界** | 不感知 LLM、不实现 Agent loop；不包含会话文件格式与模型配置。 |
| **与 agent 的关系** | Package 层独立；**coding-agent** 的 interactive 模式把两者接在一起。 |

**包内建议阅读顺序**

1. `src/tui.ts`（或入口导出的核心 TUI 控制器）：渲染调度与 diff 策略。
2. 键位与输入：项目中的 keybinding 默认表与解析流程（与 `AGENTS.md`「键位须可配置」规则一致）。
3. 按需深入组件：`Editor`、`Input`、`Markdown` 等与产品交互相关的实现。

---

### 3.5 `packages/coding-agent`（`@mariozechner/pi-coding-agent`，bin: `pi`）

| 维度 | 说明 |
|------|------|
| **职责** | **pi 编码 Agent 产品**：CLI 参数、会话 JSONL、内建工具、扩展/技能、多模式（interactive / print / rpc）、主题与导出等。 |
| **边界** | 不是通用 Slack/Web 宿主；不把 GPU 运维作为核心（那是 **pods**）；模型供应商细节仍下沉在 **pi-ai**。 |

**包内建议阅读顺序**

1. `src/cli.ts` → `src/main.ts`：启动、两阶段参数解析、模式分发。
2. `src/core/agent-session.ts`：单会话生命周期、重试、compaction、分支树、与扩展事件桥接。
3. `src/core/agent-session-runtime.ts`：`AgentSessionRuntimeHost` 与 `/new`、`/resume`、`/fork` 一致语义。
4. `src/core/tools/*`：工具 schema、执行与安全边界。
5. `src/core/extensions/*`、`src/core/skills.ts`：TS 扩展与 Markdown skills 加载。
6. `src/modes/interactive`（及 print/rpc）：TUI 与无 TUI 路径如何共用同一 session 抽象。

---

### 3.6 `packages/mom`（`@mariozechner/pi-mom`，bin: `mom`）

| 维度 | 说明 |
|------|------|
| **职责** | **Slack 集成层**：Socket Mode、按 channel 的 runner、把 **pi-coding-agent** 的会话能力嵌进聊天产品形态。 |
| **边界** | 不重写核心 tool loop；不替代 **pi-ai**；Slack 协议与定时任务细节封装在本包，与通用 Agent 文档分离。 |

**包内建议阅读顺序**

1. `src/main.ts`：进程入口、Socket、channel runner 生命周期。
2. `src/agent.ts`：`AgentSession` / `SessionManager` 的组装、Slack system prompt、消息/thread 映射。
3. `src/sandbox.ts`：host/docker 执行策略（与 Slack 侧安全模型相关）。

**前置知识**：至少粗读过 **coding-agent** 的 `agent-session` 与 **agent** 的 `Agent` 事件，否则难以跟上 thread 与工具回显映射。

---

### 3.7 `packages/pods`（npm: `@mariozechner/pi`，bin: `pi-pods`）

| 维度 | 说明 |
|------|------|
| **职责** | 远程 **GPU Pod** 配置、SSH、**vLLM** 启停、日志、本地 `~/.pi` 风格配置；CLI 命令空间以 `pi pods` / `pi start` 等为主（见 `src/cli.ts` 帮助文案）。 |
| **边界** | 不是完整 pi 编码产品；当前仓库中 **`commands/prompt.ts` 内 `pi agent` 路径为占位**（`throw new Error("Not implemented")`），与 README 中描述的 agent 体验可能尚未在源码对齐；**package.json** 已声明 `@mariozechner/pi-agent-core`，但源码树内可无直接 import，可视为预留或与后续子命令相关。 |
| **与 pi-ai** | 无直接 npm 依赖；对话侧若落地，通常通过 OpenAI 兼容 HTTP 端点对接，而非在 pods 内再实现一套 provider。 |

**包内建议阅读顺序**

1. `src/cli.ts`：命令路由与帮助。
2. `src/commands/pods.ts`：setup、active、SSH 与初始化脚本。
3. `src/commands/models.ts`：start/stop/list/logs 与资源校验。
4. `src/config.ts`、SSH 工具模块：配置结构与远程执行原语。

---

### 3.8 `packages/web-ui`（`@mariozechner/pi-web-ui`）

| 维度 | 说明 |
|------|------|
| **职责** | 浏览器侧 **Web Components** 聊天 UI：`ChatPanel`、`AgentInterface`、消息渲染注册、Artifacts、IndexedDB 存储（settings、keys、sessions、自定义 provider 等）、部分本地模型 SDK（如 ollama、lmstudio）适配。 |
| **边界** | **Agent 类本体在 pi-agent-core**；本包侧重展示、存储与宿主应用集成；不把终端 interactive 模式搬上网。 |
| **依赖注意** | `package.json` 显式依赖 **pi-ai** 与 **pi-tui**；源码大量 `import type` **pi-agent-core**。集成时须按 **packages/web-ui/README.md** 与 **pi-agent-core** 一起安装/解析类型，避免只装 web-ui 导致类型或链接缺失。 |

**包内建议阅读顺序**

1. `src/index.ts`：对外导出与类型再导出约定。
2. `src/ChatPanel.ts`、`src/components/AgentInterface.ts`：与 `Agent` / `AgentEvent` 的边界。
3. `src/components/Messages.ts`、`message-renderer-registry.ts`：消息与工具 UI 扩展点。
4. `src/storage/*`：持久化模型与 session 形状。
5. `example/`：最小可运行宿主（如何 new `Agent` 并挂上 UI）。

---

### 3.9 推荐阅读与学习顺序（全局）

按目标选一条主线，再在交叉点补读相邻包。

**路径 A — 搞懂「模型 → Agent 循环」（最通用）**

1. `pi-ai`：`types.ts` → `stream.ts` → 一个 provider 实现。  
2. `pi-agent-core`：`agent.ts` → `agent-loop.ts`。  
3. `pi-coding-agent`：`main.ts` → `agent-session.ts` → `modes` 之一。

**路径 B — 只做终端产品或改 TUI**

1. `pi-tui`：核心 TUI + 键位。  
2. `pi-coding-agent`：`modes/interactive` 如何把 session、agent、tui 串起来。

**路径 C — Slack 运维/二次开发 mom**

1. 完成路径 A 中 **agent-session** 级别理解。  
2. `pi-mom`：`main.ts` → `agent.ts` → `sandbox.ts`。

**路径 D — Web 嵌入**

1. 路径 A 的第 1～2 步（至少能读懂 `Agent` 事件类型）。  
2. `pi-web-ui`：`AgentInterface` + `example/`。  
3. 需要自定义工具消息渲染时：再读 `Messages` 与 module augmentation 文档（README）。

**路径 E — GPU / vLLM 运维（与 Agent 源码弱相关）**

1. `pi`（pods）：`cli.ts` → `pods.ts` → `models.ts`。  
2. 若要与 pi 生态对话能力打通：同步关注 **pi-ai** 的 OpenAI 兼容 API 选项与 **coding-agent** 的 `--base-url` 类参数（以各包 README 为准）。

**路径间的依赖建议**

- **A** 是 **B / C / D** 的公共底座；**E** 可几乎独立，直到你要把 pod 上的模型接进 Agent。  
- **mom** 与 **web-ui** 不必互相读；二者都依赖「session + Agent 事件」同一套概念。  
- 与仓库构建顺序一致时：**tui → ai → agent → coding-agent** 再向外延伸到 mom / web-ui / pods，可减少「类型/包未 build」带来的干扰。

---

## 4. 核心运行流程（以 `pi` coding-agent 为主）

## 4.1 启动阶段
1. `cli.ts` 设置进程环境，调用 `main(args)`。
2. `main.ts` 解析参数（两阶段：先加载扩展 flag，再二次解析）。
3. 初始化：migrations、settings、auth storage、model registry、resource loader。
4. 加载资源：extensions/skills/prompts/themes/AGENTS.md/SYSTEM.md。
5. 创建或恢复 session manager（`--continue/--resume/--session/--fork`）。
6. 创建 runtime：`createAgentSessionRuntime(...)`，产出 `session + runtimeHost`。
7. 根据模式进入：
   - interactive（默认）
   - print/json
   - rpc

## 4.2 单轮 Agent 执行
1. 用户输入进入 `AgentSession.prompt()`。
2. `Agent` 触发 `runAgentLoop`。
3. `agent-loop.ts`：
   - `transformContext`（可选）
   - `convertToLlm`（AgentMessage -> LLM Message）
   - 调 `streamSimple`（默认）请求模型
4. 流式事件回传：`message_start/update/end`。
5. 若 assistant 产生 tool calls：
   - 参数校验
   - `beforeToolCall`
   - 执行工具（串行或并行）
   - `afterToolCall`
   - 生成 `toolResult` 消息
6. 若还有 tool calls 继续下一 turn；否则 `agent_end`。

## 4.3 会话与上下文管理
- 消息持久化：JSONL session（带 parentId，可树状分支）。
- `/tree`：切换历史节点继续分支。
- `/fork`：从选定节点生成新会话文件。
- compaction：阈值触发或溢出触发，摘要旧上下文，保留近期上下文。
- retry：可对可重试错误做指数退避自动重试。

---

## 5. 关键扩展点（当前实现）

1. Extensions（TypeScript）
- 通过生命周期事件插入：工具前后拦截、session 切换、UI 注入、命令注册、provider 注册。

2. Skills（Markdown）
- 按需加载，`SKILL.md` 描述能力与步骤，避免全量 prompt 污染。

3. Prompt Templates / Themes / Context Files
- `AGENTS.md`、`SYSTEM.md`、模板与主题共同影响最终行为。

4. 多模式输出
- Interactive TUI：人机交互主模式。
- Print/JSON：脚本化和流水线友好。
- RPC：嵌入其它宿主应用。

---

## 6. 模块依赖关系（简化）
- `pi-ai`：最底层模型访问抽象。
- `pi-agent-core` 依赖 `pi-ai`。
- `pi-tui`：独立 UI 库（与 `pi-agent-core` 无 package 依赖）。
- `pi-coding-agent` 依赖 `pi-ai + pi-agent-core + pi-tui`。
- `pi-mom` 依赖 `pi-coding-agent + pi-agent-core + pi-ai`（及 Slack 等）。
- `pi-web-ui`：npm 依赖含 `pi-ai`、`pi-tui`；源码类型与集成面向 `pi-agent-core`（安装组合见 `packages/web-ui/README.md`）。
- `@mariozechner/pi`（pods，`pi-pods`）：npm 依赖含 `pi-agent-core`、chalk；与 `pi-ai` 无直接依赖；`pi agent` 子命令实现状态见 **3.7**。

---

## 7. 当前项目特征总结

1. 架构上是“能力分层 + 产品组合”，不是单体 Agent 框架。
2. `coding-agent` 是核心产品面；`ai/agent/tui` 是可复用底座。
3. 通过 `AgentSessionRuntimeHost` 支持会话运行时替换，保证 `/new`、`/resume`、`/fork` 一致行为。
4. 扩展体系（extensions/skills/prompts/themes）已经是一级公民，默认路径与 package 安装流程完整。
5. 除终端主线外，Slack（mom）、Web（web-ui）、GPU 部署（pods）形成了三条平行业务线。
