# State Machine

## Location

각 워크플로우는 **자기 worktree 안에** state를 가집니다:
```
<worktree>/.workflow/state.json
```

이것이 **단일 진실 소스**. 글로벌 레지스트리 없음. 세션 id 키링 없음. worktree 경로 자체가 식별자.

## state.json 스키마

state.json은 `control`과 `data` 두 네임스페이스로 분리됨.

```json
{
  "control": {
    "workflow_id": "uuid",
    "track": "feature | fix | light | brainstorm",
    "status": "running | completed | paused",
    "current_step": "<STEP_KEY>",
    "interrupted": false,
    "interrupted": false,
    "interrupt_reason": "",
    "steps": {
      "SETUP": {"status": "completed"},
      "LINEAR_TICKET": {"status": "completed"},
      "MAKE_UNIT_TEST": {"status": "running"},
      "MAKE_E2E_TEST": {"status": "pending"},
      "DO_RED_TEST": {"status": "pending"},
      "IMPLEMENT": {"status": "pending"},
      ...
    },
    "created_at": "2026-04-17T...",
    "updated_at": "2026-04-17T...",
    "error": null
  },
  "data": {
    "task_description": "...",
    "ticket_id": "POP-123",
    "branch_name": "POP-123",
    "pr_number": 687,
    "debate_for_plan_count": 0,
    "review_comments": [],
    ...
  }
}
```

### 네임스페이스 규칙

| 네임스페이스 | 누가 쓰는가 | 무엇을 담는가 |
|---|---|---|
| `control.*` | wf 스크립트만 (`init-workflow`, `complete-step`, `resume-workflow`, `rewind-step`) | 상태 머신 — status, current_step, steps, interrupt flags, timestamps |
| `data.*` | 에이전트가 `set-data.sh`로만 | 스텝이 생산하는 metadata — 티켓/PR 정보, 카운터, 피드백, 리뷰 코멘트 등 |

**금지 사항**:
- 에이전트는 `control.*`을 절대 직접 쓰지 않음 (읽기는 OK — `jq -r '.control.status'` 등).
- 에이전트는 `data.*`도 직접 쓰지 않음 — 반드시 `set-data.sh` 경유 (reserved key 차단 + `control.updated_at` 자동 갱신).
- 읽기는 `get-data.sh`를 쓰거나 `jq`로 직접 읽어도 됨.

### `control` 필드

| 필드 | 의미 |
|---|---|
| `workflow_id` | 워크플로우 UUID (생성 시 고정) |
| `track` | 어떤 트랙으로 초기화되었는지 (feature/fix/light/brainstorm) |
| `status` | 워크플로우 전체 상태. `running` → `completed`/`paused` |
| `current_step` | 지금 `running`인 스텝 키 (편의용 포인터) |
| `interrupted` | 유저가 끼어들었다는 플래그 → Stop 훅이 허용 신호로 소비 |
| `interrupted` | 핑퐁 모드 활성 플래그 (상세: `21-flags.md`) |
| `interrupt_reason` | 핑퐁 진입 사유 (짧은 라벨) |
| `steps` | 스텝별 상태 (아래 참고) |
| `created_at`, `updated_at` | 타임스탬프 (감사용) |
| `error` | 워크플로우 실패 시 에러 메시지 |

### `control.steps` 필드

**삽입 순서 = 실행 순서**. 각 스텝은 `pending` → `running` → `completed` 전이만 함 (역행 없음).

## 전체 생명주기 다이어그램

```
 ┌──────────────────┐
 │ /wf <track>      │  user triggers workflow
 └────────┬─────────┘
          │
          ▼
 ┌────────────────────┐       ┌──────────────────┐
 │ init-workflow.sh   │──────▶│ track-steps.json │   (load step list)
 │                    │       └──────────────────┘
 │ • create state.json│
 │ • all → pending    │
 │ • first → running  │
 └────────┬───────────┘
          │
          │  output first step md → agent context
          ▼
 ┌────────────────────┐
 │  Agent works on    │◀────────────┐
 │  current step      │             │
 └────────┬───────────┘             │
          │                         │
          │ agent decides:          │
          │                         │
          ├─ step done ─▶ ┌────────────────────┐
          │              │ complete-step.sh K │
          │              │                    │
          │              │ • K → completed    │
          │              │ • interrupt flags reset │
          │              │ • find next pending│
          │              │ • next → running   │
          │              └─────┬──────┬───────┘
          │                    │      │
          │          next exists│      │no more
          │                    │      │
          │        output next │      ▼
          │        md ─────────┘  ┌─────────────┐
          │                       │ status =    │
          │                       │ "completed" │
          │                       └─────────────┘
          │
          ├─ need user input ─▶ [interrupt mode: see 21-flags.md]
          │
          └─ session died ────▶ [next session calls resume-workflow.sh]
                                  │
                                  ▼
                            ┌──────────────────┐
                            │ resume-workflow  │
                            │                  │
                            │ • interrupt flags off │
                            │ • find running   │
                            │   or first       │
                            │   pending        │
                            │ • re-output md   │
                            └──────────────────┘
```

## 개별 스크립트 상세 플로우

### `init-workflow.sh <track>` — 워크플로우 시작

```
[input] track name (feature / fix / light / brainstorm)
   │
   ▼
┌─ load track-steps.json ──┐
│ feature: [SETUP, LINEAR_ │
│          TICKET, ...]    │
└──────────┬───────────────┘
           │
           ▼
┌─ create .workflow/state.json ────────────────┐
│ {                                            │
│   status: "running",                         │
│   track: "<track>",                          │
│   steps: { K1: pending, K2: pending, ... },  │
│   current_step: "",                          │
│   interrupted: false,                  │
│   interrupt_reason: "",                     │
│ }                                            │
└──────────┬───────────────────────────────────┘
           │
           ▼
┌─ mark first step running ─┐
│ steps[K1] = running       │
│ current_step = K1         │
└──────────┬────────────────┘
           │
           ▼
[output] content of K1's md file  →  agent reads & starts working
```

### `complete-step.sh <STEP_KEY>` — 스텝 전이

```
[input] STEP_KEY (must be currently running)
   │
   ▼
┌─ mark completed ──────────┐
│ steps[KEY] = completed    │
│ interrupt flags → reset (safe) │
└──────────┬────────────────┘
           │
           ▼
 ┌─ scan for next pending (insertion order) ─┐
 └──────────┬────────────────────────────────┘
            │
     ┌──────┴──────┐
     │             │
 found NEXT     no more
     │             │
     ▼             ▼
┌──────────┐  ┌──────────────────┐
│ NEXT →   │  │ status=completed │
│ running  │  │ current_step=""  │
│ current_ │  └──────────────────┘
│ step=NEXT│         │
└────┬─────┘         │
     │               ▼
     ▼         [output] "ALL STEPS COMPLETED"
[output] NEXT's md  →  agent continues
```

### `resume-workflow.sh` — 복귀 / 재개

```
[no args]
   │
   ▼
┌─ clear interrupt flags ─┐
│ interrupted  │
│   = false          │
│ interrupt_reason  │
│   = ""             │
└──────┬─────────────┘
       │
       ▼
 ┌─ find current step ─────────┐
 │ 1st: status=="running"      │
 │ fallback: 1st pending       │
 │   (promotes to running)     │
 └──────────┬──────────────────┘
            │
            ▼
[output] current step's md  →  agent re-reads & continues
```

**사용 케이스**:
- 세션 재시작 (이전 세션 죽고 새 세션이 이어받음)
- interrupt 모드 탈출 (핑퐁 끝내고 작업 복귀)

### `rewind-step.sh <TARGET> [RESET...]` — 역행 / 루프백

```
[input] TARGET + optional RESET list
   │
   ▼
┌─ for each key in RESET list ─┐
│   steps[key] = pending       │   (RESET 생략 시 이 단계 스킵)
└──────────┬───────────────────┘
           │
           ▼
┌─ mark TARGET running ───┐
│ steps[TARGET] = running │
│ current_step = TARGET   │
└──────────┬──────────────┘
           │
           ▼
[output] TARGET's md (with "loop back" 배너)  →  agent restarts
```

**중요**: 모든 스텝을 자동 역행하지 않음. 리셋해야 할 스텝 키를 **명시**해야 함. 예:

```bash
bash ${CLAUDE_PLUGIN_ROOT}/skills/wf/lib/rewind-step.sh IMPLEMENT DO_GREEN_TEST SELF_REVIEW COMMIT PR
# → IMPLEMENT로 점프, DO_GREEN_TEST~PR은 pending으로 리셋
```

**사용 케이스**:
- CI 실패 → `rewind-step.sh COMMIT CI_WAIT_*` (CI 관련만 리셋)
- 리뷰 반영 → `rewind-step.sh IMPLEMENT ...` (IMPLEMENT 이후 재실행할 스텝 명시)
- 수동 복구

## Track vs Registry

```
step-registry.json   →  STEP_KEY: filename      (전체 스텝 → md 파일 매핑)
track-steps.json     →  track:   [STEP_KEY,...] (트랙별 실행 순서 정의)
```

- **STEP_KEY**: 안정적 식별자 (파일명 접두사와 무관)
- **filename 접두사 (005, 006, ...)**: 카테고리 그룹용. **실행 순서 아님**
- **실행 순서**: `track-steps.json`의 배열 순서

예: feature 트랙은 `SETUP, LINEAR_TICKET, RENAME_BRANCH, SPECIFY, ...` 순서로 실행. 파일 번호 순 아님.

## Invariants (불변 조건)

1. **한 워크트리 = 한 state.json**. 여러 개 있으면 버그
2. **step 상태 전이는 단방향**: `pending` → `running` → `completed`. 되돌림은 `rewind-step`만 허용
3. **`current_step`은 `running` 스텝을 가리켜야 함** (없으면 `""` 또는 status=completed)
4. **interrupt flag 2개는 쌍으로 켜짐/꺼짐**: `interrupted=true`면 항상 `interrupt_reason`이 세팅되어 있어야 함

## 관련 문서

- 스텝 추가법: `50-steps.md`
- interrupt flag 상세: `21-flags.md`
- 훅이 state 읽는 방식: `20-hooks.md`
