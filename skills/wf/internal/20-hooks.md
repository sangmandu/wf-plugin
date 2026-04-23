---
name: 20-hooks
description: wf가 사용하는 Claude Code hook 2종(Stop, UserPromptSubmit)의 발화 조건·stdin 페이로드·state.json과의 상호작용. session_id 기반 매칭
type: reference
---

# Hooks

wf는 Claude Code의 **글로벌 hook**을 활용한다. Claude Code는 세션 시작 dir에서 `.claude/settings.json`을 로드하고, Bash tool의 `cd`는 Claude 본체 프로세스 pwd를 바꾸지 못하기 때문에 worktree 내부 `.claude/`는 로드되지 않음. 그래서 hook은 글로벌 등록이고, 세션 소속은 **`session_id`** 로 판별한다 (cwd가 아님).

## 등록된 hook 목록

`~/.claude/settings.json`에 등록된 wf 관련 hook:

| Event | Script | 역할 |
|---|---|---|
| `Stop` | `wf/stop-guard.sh` | 스텝 중간에 에이전트가 멈추는 걸 막음 |
| `UserPromptSubmit` | `wf/user-interrupt.sh` | 유저 메시지를 "interrupt"로 마킹, 응답 후 resume 가이드 주입 |

## 공통 stdin 페이로드

모든 hook은 stdin으로 JSON을 받음. wf가 쓰는 핵심 필드:

```json
{
  "session_id": "<uuid>",
  "cwd": "<repo-root>",
  "transcript_path": "...",
  "tool_name": "...",
  "tool_input": {...}
}
```

**중요**: `cwd`는 Claude Code **세션 프로세스의 현재 pwd**를 반영한다. Bash tool의 `cd`는 subshell에서만 유효해 대부분 `cwd`는 세션 launch dir(=main repo)에 고정됨. 따라서 state.json을 찾을 때 `$CWD/.workflow/state.json` 한 경로만 보면 worktree 내 state를 놓친다. 해결: **git worktree 목록을 스캔**하고 **`.data.owner_session_id`가 현재 `session_id`와 일치하는 state.json**을 선택.

## 공통 lookup 로직 (Stop / UserPromptSubmit)

```bash
INPUT="$(cat)"
SESSION_ID="$(echo "$INPUT" | jq -r '.session_id // empty')"
CWD="$(echo "$INPUT" | jq -r '.cwd // empty')"
[ -z "$SESSION_ID" ] && exit 0

# git worktree 목록에서 state.json 후보 수집
STATE_FILES=( )
while IFS= read -r WT; do
  [ -f "$WT/.workflow/state.json" ] && STATE_FILES+=("$WT/.workflow/state.json")
done < <(git -C "$CWD" worktree list --porcelain | awk '/^worktree / {print $2}')

# Pass 1: owner_session_id == session_id & status=running
# Pass 2: owner_session_id == "" & status=running → claim (owner=session_id 쓰기)
```

**claim semantics**: hook이 소유자 없는 running state를 자기 세션으로 claim함으로써, init-workflow 이후의 첫 프롬프트가 자동으로 세션을 state.json에 박는다. `resume-workflow.sh`는 owner를 비우므로 세션이 바뀌어 이어 작업할 때 새 세션이 재claim한다.

**기존 state.json (필드 자체가 없음)** 은 claim 대상에서 제외(필드 존재 여부까지 검사). 이 불변 덕에 이전 포맷의 state.json은 손대지 않음.

## Stop hook — `stop-guard.sh`

### 발화 시점
에이전트가 응답을 끝내려 할 때마다 (매 턴).

### 로직 플로우

```
Stop hook 발화
   │
   ▼
state.json 존재? ── no ──▶ exit 0 (wf 아님)
   │ yes
   ▼
status=running? ── no ──▶ exit 0
   │ yes
   ▼
interrupted=true?
   │
   ├─ yes ─▶ flag=false 리셋 → exit 0 (유저 응답 허용)
   │
   └─ no
       ▼
   interrupted=true?
   │
   ├─ yes ─▶ exit 0 (interrupt 모드 — 유저 답변 대기)
   │
   └─ no
       ▼
   current_step ∈ INTERRUPT_STEPS?
   │
   ├─ yes ─▶ flag=true 세팅 + reason="step: <K>" → exit 0
   │        (자동 interrupt 진입: EXPLAIN_PLAN 등 질문형 스텝)
   │
   └─ no
       ▼
   {"decision": "block", "reason": "..."} 출력
   → 에이전트는 멈출 수 없고 3가지 선택지 제공:
     1. complete-step.sh 실행
     2. 워크플로우 계속
     3. agent-interrupt.sh 실행
```

### INTERRUPT_STEPS
질문/승인이 본질인 스텝들. 이 스텝에서는 Stop이 "에이전트가 유저에게 질문 대기" 신호.

```
INVESTIGATE / VERIFY / REPORT
DEBATE_FOR_PLAN / EXPLAIN_PLAN / EXPLAIN_TEST
BRAINSTORM_EXPLORE / BRAINSTORM_REPORT
COMPLETE_MERGE
```

## UserPromptSubmit hook — `user-interrupt.sh`

### 발화 시점
유저가 메시지를 제출할 때마다. ESC+메시지와 에이전트 loop 중 끼어든 메시지를 **구별하지 않음** (stdin에 구별 신호 없음).

### 로직 플로우

```
UserPromptSubmit 발화
   │
   ▼
pre-check 통과
   │
   ▼
interrupted=true?
   │
   ├─ yes ─▶ exit 0 (interrupt 모드 — 유저 답변은 정상 입력, 플래그 변경 없음)
   │
   └─ no
       ▼
   interrupted=true 세팅
   │
   ▼
   additionalContext 주입:
   "[wf interrupt] User sent a message during the workflow
    (current step: <K>). Respond to the user first.
    After responding, run bash <WF_DIR>/lib/resume-workflow.sh
    to resume the workflow."
```

### 왜 interrupt 모드에서 no-op?
interrupt 중의 유저 메시지는 **정답 제공**이지 방해가 아님. interrupt 플래그를 켜면 Stop hook이 이걸 소비해 플래그를 끄고, 그 후 에이전트가 답변을 이어가기 시작하면 interrupt 모드가 깨짐. 그래서 interrupt 동안은 hook이 건드리지 않고 평소처럼 지나감.

## 두 flag의 상호작용

| 상황 | interrupted | interrupted | Stop 동작 |
|---|---|---|---|
| 일반 스텝 진행 중 | false | false | block |
| 유저가 끼어듦 | true | false | 허용 + 리셋 |
| 에이전트가 interrupt 호출 | false | true | 허용 (유지) |
| INTERRUPT_STEPS 진입 | false | true (자동) | 허용 (유지) |
| interrupt 중 유저 답변 | false | true | 허용 (유지) |

**불변**: 두 플래그가 동시에 true 되는 정상 경로는 없음. UserPromptSubmit이 interrupt 모드면 no-op이고, 아니면 interrupt만 set.

## Flag를 끄는 주체

| Flag | Set 주체 | Clear 주체 |
|---|---|---|
| `interrupted` | UserPromptSubmit hook | Stop hook (1회 소비 즉시) |
| `interrupted` | `agent-interrupt.sh` 또는 stop-guard (INTERRUPT_STEPS 자동) | `resume-workflow.sh` 또는 `complete-step.sh` (safety) |

## 왜 글로벌 hook + session_id인가

초기엔 worktree별 `.claude/settings.json`에 hook을 넣거나, hook input의 `cwd`로 worktree를 식별하는 방식을 고려했으나:
- Claude Code는 **세션 시작 dir**에서 settings를 로드. worktree에 박아도 main에서 띄운 세션엔 적용 안 됨
- Claude Bash tool의 `cd`는 각 호출이 subshell이라 **Claude 본체 pwd를 바꾸지 못함** → hook input `cwd`는 대부분 세션 launch dir(=main). cwd 기반 식별은 worktree state.json을 놓침
- `claude`를 매번 worktree에서 재시작하는 건 UX 비용이 크고 `/cd` 같은 런타임 cwd 변경은 Claude Code가 지원 안 함 (2026-04 기준)

결론: 글로벌 hook + `session_id ↔ state.json.data.owner_session_id` 매칭. cwd에 의존하지 않으므로 Claude 프로세스가 어느 dir에 있든 동작.

## 관련 문서

- flag 생명주기 상세: `21-flags.md`
- 병렬 세션 격리: `22-parallel-sessions.md`
- 스크립트 역할: `30-scripts.md`
