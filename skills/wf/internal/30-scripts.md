---
name: 30-scripts
description: wf 스크립트 디렉토리 인덱스 — 용도·호출자 한 줄 요약. 동작 상세는 각 연결 문서 참조
type: reference
---

# Scripts (Index)

에이전트는 **state.json을 직접 편집하지 않는다**. 모든 변경은 아래 스크립트를 경유한다. state.json은 `control`(상태 머신)과 `data`(step metadata) 두 네임스페이스로 나뉘며 각각 전담 스크립트가 다르다 (스키마 상세: `10-state-machine.md`).

경로 기준: `${CLAUDE_PLUGIN_ROOT}/skills/wf/`. `scripts/` 접두사는 하위 폴더.

## 상태 전이 (`control.*`) — 상세: `10-state-machine.md`

| 스크립트 | 용도 | 호출자 |
|---|---|---|
| `init-workflow.sh <track>` | 워크플로우 시작 | 에이전트 (`/wf` 직후) |
| `complete-step.sh <KEY>` | 스텝 완료 + 다음으로 전이 | 에이전트 |
| `resume-workflow.sh` | running 스텝 재출력, interrupt 해제 | 에이전트 (세션 복귀 / interrupt 종료) |
| `rewind-step.sh <TARGET> [RESET...]` | 지정 스텝으로 역행 | 에이전트 (수동 복구 / 루프백) |

## Step metadata (`data.*`)

| 스크립트 | 용도 | 호출자 |
|---|---|---|
| `set-data.sh <key> <value> [--append]` | `data.<key>` 저장. 예약된 control.* 키 차단. `control.updated_at` 자동 갱신 | 에이전트 (스텝 실행 중) |
| `get-data.sh <key>` | `data.<key>` 읽기 (없으면 exit 1) | 에이전트 |

## interrupt 제어 — 상세: `21-flags.md`

| 스크립트 | 용도 | 호출자 |
|---|---|---|
| `scripts/agent-interrupt.sh "<label>"` | 핑퐁 모드 진입 (유저 판단 필요 선언) | 에이전트 |

## hook entrypoint — 상세: `20-hooks.md`

| 스크립트 | 용도 | 호출자 |
|---|---|---|
| `stop-guard.sh` | Stop hook: 중간 정지 차단 / interrupt 허용 | Claude Code |
| `user-interrupt.sh` | UserPromptSubmit hook: 끼어듦 감지 | Claude Code |

## Observer (장기 실행) — 상세: `40-observers.md`

| 스크립트 | 용도 | 호출자 |
|---|---|---|
| `scripts/observe-ci.sh` | CI 상태 polling | 에이전트 (PR 생성 후) |
| `scripts/observe-reviews.sh` | PR 리뷰 polling | 에이전트 (리뷰 대기) |

## 보조

| 스크립트 | 용도 | 호출자 |
|---|---|---|
| `lib/preflight-check.sh` | 환경 전제 조건 검증 (git / gh / brew / Linear 로그인) | 에이전트 (SETUP 스텝) |
| `lib/cleanup-stale-worktrees.sh` | merged/abandoned worktree 삭제 안내 | 유저 (수동) |

## 보조 (스텝 md 내부에서 사용)

| 스크립트 | 용도 |
|---|---|
| `scripts/check-merge-status.sh` | PR 머지 여부 확인 (COMPLETE_MERGE에서 사용) |

## 에이전트 호출 규약

1. **state.json 직접 편집 금지** — 모든 변경은 스크립트 경유
2. **worktree 안에서만 실행** — 스크립트는 `pwd` 기준으로 state.json을 찾음
3. **stdout은 지시사항** — 스크립트가 출력하는 스텝 md는 그대로 따름
4. **실패 전파** — exit code + stderr로 보고. 에이전트는 유저에게 정형 보고 (정책: `90-troubleshooting.md`)
