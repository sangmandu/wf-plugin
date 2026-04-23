---
name: 21-flags
description: state.json의 interrupt/interrupt 플래그 3종 — 의미와 생명주기 (hook 동작은 20-hooks.md, 전이는 10-state-machine.md)
type: reference
---

# Flags

state.json의 **제어용 플래그 3개**. hook/스크립트 간 신호 전달용.

| Flag | 타입 | 기본값 | 의미 |
|---|---|---|---|
| `interrupted` | bool | `false` | 유저가 한 턴 끼어듦 (1회성) |
| `interrupted` | bool | `false` | 핑퐁 모드 활성 (지속성) |
| `interrupt_reason` | string | `""` | 핑퐁 진입 사유 (짧은 라벨) |

## `interrupted` — 1회성 끼어듦

유저가 스텝 진행 중 잠깐 질문/메모를 던진 상황. Stop hook이 **1회 소비 즉시 리셋**한다.

- Set: `user-interrupt.sh` (interrupt 모드가 아닐 때만)
- Clear: `stop-guard.sh` (다음 Stop에서 즉시)
- interrupt 모드 중에는 아예 세팅되지 않음 (유저 답변은 정상 입력이므로)

## `interrupted` — 지속성 핑퐁

에이전트가 "유저 판단 필요" 라고 선언한 상태. 유저-에이전트 핑퐁이 몇 턴이든 가능.

### 세팅 경로 2가지
- (A) 에이전트 명시적 호출: `bash scripts/agent-interrupt.sh "<label>"`
- (B) INTERRUPT_STEPS 자동 interrupt: `stop-guard.sh`가 `current_step ∈ INTERRUPT_STEPS`일 때 자동으로 세팅

### 해제 경로 2가지
- (1) `resume-workflow.sh` — 정상 복귀
- (2) `complete-step.sh` — 다음 스텝 진행 시 safety 리셋 (에이전트가 resume 건너뛴 경우 대비)

### 특성
- Stop hook이 소비하지 않음 — 유저 답변이 N번 와도 유지
- 쌍불변: `interrupted=true`면 `interrupt_reason`은 비어있으면 안 됨 (`10-state-machine.md` invariant #4)

## `interrupt_reason` — 진입 사유 라벨

- 디버깅/로그용 짧은 문자열. 긴 문장 금지
- 관례: `"plan review"`, `"test design"`, `"step: EXPLAIN_PLAN"`
- INTERRUPT_STEPS 자동 interrupt는 `"step: <STEP_KEY>"` 고정

## 조합별 상태

| `interrupted` | `interrupted` | 상태 |
|---|---|---|
| false | false | 평시 스텝 작업 |
| true | false | 유저 1회 끼어듦 |
| false | true | 핑퐁 모드 |
| true | true | **발생 불가** (hook이 방지) |

Stop hook이 이 조합을 어떻게 소비하는지는 `20-hooks.md` 참조.

## 관련 문서

- state.json 스키마·전이 다이어그램: `10-state-machine.md`
- hook 로직·Stop 디시전 트리: `20-hooks.md`
- 스크립트 인덱스: `30-scripts.md`
