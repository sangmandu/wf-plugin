# wf Internals — Overview

이 디렉토리는 **wf 스킬을 수정하는 사람**을 위한 문서입니다.
에이전트 실행 규칙은 `../SKILL.md`와 `../helpers.yaml`에 있습니다.

## Core Architecture

```
Claude Code session
  │
  │  (agent is the runtime — no orchestrator)
  ▼
SKILL.md          ← "you are a checklist executor"
  │
  │  delegates to
  ▼
init-workflow.sh / complete-step.sh / resume-workflow.sh
  │
  │  manage
  ▼
<worktree>/.workflow/state.json   ← single source of truth per workflow
  │
  │  outputs one step file at a time
  ▼
agent context (stdout)
```

- 에이전트 자체가 runtime. 별도 오케스트레이터 프로세스 없음
- 쉘 스크립트는 state 변이 + 다음 step md 전달만 담당. 의사결정 없음
- 한 worktree = 한 workflow. state.json은 그 worktree에 영속

## Execution Model

- `.workflow/state.json`은 **worktree 안에** 위치 → worktree path가 자연스러운 영속 key
- 훅은 세션 stdin의 `cwd` 필드로 자기 worktree를 식별 (상세: `20-hooks.md`)
- N개 세션이 N개 worktree에서 동시 진행 가능 (상세: `22-parallel-sessions.md`)

## Document Map

| 파일 | 내용 |
|---|---|
| [00-overview.md](00-overview.md) | 이 문서 — 전체 구조 개괄 |
| [10-state-machine.md](10-state-machine.md) | state.json 스키마, step 전이, track 정의 |
| [20-hooks.md](20-hooks.md) | Stop/UserPromptSubmit 훅 발화 로직 + 플로우 다이어그램 |
| [21-flags.md](21-flags.md) | `interrupted` / `interrupted` / `interrupt_reason` lifecycle |
| [22-parallel-sessions.md](22-parallel-sessions.md) | 다중 세션 병렬 격리 원리 |
| [30-scripts.md](30-scripts.md) | 각 쉘 스크립트 역할과 동작 |
| [40-observers.md](40-observers.md) | observe-ci / observe-reviews 설계 |
| [50-steps.md](50-steps.md) | Step 추가법, registry, INTERRUPT_STEPS |
| [90-troubleshooting.md](90-troubleshooting.md) | false positive, 좀비 state 등 엣지 케이스 |

## Design Principles

1. **Worktree = 격리 단위**
   - 한 workflow의 모든 상태/아티팩트는 그 worktree 안
   - 세션 죽어도 state 영속, 새 세션이 이어받기 가능

2. **Agent가 runtime**
   - 쉘은 상태 변이 + 출력만, 판단 X
   - 흐름 제어는 에이전트가 step md를 읽고 수행

3. **Hooks는 규율 강제용**
   - Stop hook: 워크플로우 도중 에이전트가 멈추는 걸 차단
   - UserPromptSubmit hook: 유저 끼어듦 감지 → 에이전트 우회 경로 열기

4. **명시적 전이만**
   - `complete-step.sh <KEY>`: 이 스텝 끝났다는 선언
   - `agent-interrupt.sh "<reason>"`: 유저 입력 필요하다는 선언
   - 이 두 가지만 워크플로우 진행을 바꿈

5. **침묵 금지**
   - 에러/예외는 유저에게 정형 보고 (상세: `90-troubleshooting.md`의 에러 리포트 정책)
