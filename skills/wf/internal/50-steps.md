---
name: 50-steps
description: 스텝 추가·수정·INTERRUPT_STEPS 등록 가이드. step md 작성 관례와 track 구성
type: reference
---

# Steps

wf의 스텝은 **3개 파일의 일관성**으로 정의된다:

```
<NNN>-<name>.md          ← 스텝 내용 (에이전트 지시사항)
step-registry.json       ← STEP_KEY → md 파일명 매핑
track-steps.json         ← track별 실행 순서
```

## 파일명 접두사 규칙

```
001-          → SETUP
010- ~ 012-   → fix 전용: INVESTIGATE / VERIFY / REPORT (plan은 031- 공용)
020- ~ 021-   → LINEAR_TICKET / RENAME_BRANCH
030- ~ 033-   → PLAN 계열 (SPECIFY, PLAN, DEBATE_FOR_PLAN, EXPLAIN_PLAN)
040- ~ 044-   → TEST 계열 (MAKE_UNIT_TEST, MAKE_E2E_TEST, DEBATE_TEST, EXPLAIN_TEST, DO_RED_TEST)
050- ~ 053-   → IMPLEMENT / DO_GREEN_TEST / SELF_REVIEW / SELF_REVIEW_VERDICT
060- ~ 061-   → COMMIT / PR
070- ~ 072-   → CI_WAIT 계열 (rebase, poll, evaluate)
080- ~ 084-   → REVIEW 계열 (check-verdict, fetch-comments, reply, apply-fixes, exit-approved)
090- ~ 093-   → COMPOUND / COMPLETE
100- ~ 103-   → BRAINSTORM 트랙 전용
```

**규칙**: 작은 번호가 항상 먼저 실행된다. 번호는 카테고리 그룹을 나타내지만, track에 등장하는 순서가 반드시 **오름차순**이어야 한다. 실행 순서 자체는 `track-steps.json` 배열이 결정한다.

## 새 스텝 추가 절차

### 1. md 파일 작성
해당 카테고리 번호 범위에서 다음 빈 번호로 `NNN-name.md` 생성.

**md 파일 관례**:
- 에이전트가 그대로 읽고 실행할 **지시사항**으로 작성
- 마지막에 `bash <WF_DIR>/lib/complete-step.sh <STEP_KEY>` 호출 안내
- 외부 명령 실행 시 결과 해석이 자유로우면 안 됨 → observer 스크립트 사용 권장

### 2. `step-registry.json`에 등록
```json
"MY_NEW_STEP": "035-my-new-step.md"
```

STEP_KEY는 **대문자 + 언더스코어**. 파일명과 무관한 안정적 식별자.

### 3. `track-steps.json`에 삽입
실행되어야 할 track(들)의 배열에 위치를 정해 삽입.

```json
"feature": [
  "SETUP",
  ...
  "IMPLEMENT",
  "MY_NEW_STEP",   ← 여기
  "DO_GREEN_TEST",
  ...
]
```

### 4. (필요 시) `stop-guard.sh`의 `INTERRUPT_STEPS`에 추가
스텝이 **본질적으로 유저 답변을 기다려야** 한다면 등록. 상세: 아래 `INTERRUPT_STEPS 규칙`.

## INTERRUPT_STEPS 규칙

`stop-guard.sh` 상단의 배열:

```bash
INTERRUPT_STEPS=(
  INVESTIGATE VERIFY REPORT
  DEBATE_FOR_PLAN EXPLAIN_PLAN EXPLAIN_TEST
  BRAINSTORM_EXPLORE BRAINSTORM_REPORT
  COMPLETE_MERGE
)
```

### 등록 조건
스텝이 **질문/승인/판단을 유저에게 맡기는 성격**일 때만 등록.
- ✅ `EXPLAIN_PLAN`: 계획을 유저에게 설명하고 승인 요청
- ✅ `VERIFY`: 재현 결과를 유저와 함께 확인
- ✅ `COMPLETE_MERGE`: 머지 타이밍 결정을 유저에게
- ❌ `IMPLEMENT`: 에이전트가 자율적으로 코딩, 유저 질문 없음
- ❌ `COMMIT`: 자동 커밋, 질문 없음

### 등록 효과
- Stop hook에서 `current_step ∈ INTERRUPT_STEPS` → 자동으로 `interrupted=true` 세팅 + 허용
- 즉 **에이전트가 명시적으로 `agent-interrupt.sh` 호출 안 해도** 자동 interrupt 진입
- 유저가 `resume-workflow.sh` 또는 `complete-step.sh` 부를 때까지 핑퐁 모드 유지

상세: `20-hooks.md`, `21-flags.md`.

## 스텝 md 작성 관례

### 헤더
```markdown
# <STEP_KEY>

<한 줄 목적>
```

### 본문 구조
1. **목표**: 이 스텝에서 달성해야 할 것
2. **입력**: 사용할 state.json payload / 앞 스텝 결과
3. **행동**: 순차 지시 (bash 명령, 파일 편집 등)
4. **검증**: 완료 조건 (테스트 통과, PR 생성 확인 등)
5. **완료**: `bash <WF_DIR>/lib/complete-step.sh <KEY>` 호출

### state.json 접근
state는 `control.*` / `data.*` 네임스페이스로 분리됨. 스텝에서 payload를 읽고/쓸 때:
- 쓰기: `bash <WF_DIR>/lib/set-data.sh <key> <value> [--append]`
- 읽기: `bash <WF_DIR>/lib/get-data.sh <key>` (없으면 exit 1) 또는 `jq -r '.data.<key>' .workflow/state.json`
- `control.*` 직접 편집 금지 — 모든 상태 전이는 전용 스크립트 경유 (불변 조건)

## Track 수정

### 트랙 추가
```json
"mytrack": ["SETUP", "MY_STEP1", "MY_STEP2", "COMPLETE_REPORT"]
```

추가 후 `/wf:mytrack` 호출로 사용. `init-workflow.sh`는 track-steps.json만 보고 움직이므로 코드 변경 불필요.

### 기존 track 순서 변경
배열 순서만 바꾸면 다음 `/wf` 실행부터 적용됨. **진행 중인 워크플로우엔 영향 없음** (이미 state.json에 스텝 목록이 박혀있음).

## 관련 문서

- STEP_KEY vs filename 구분: `10-state-machine.md#track-vs-registry`
- INTERRUPT 자동 진입 메커니즘: `20-hooks.md#interrupt_steps`
- 플래그 세팅 주체: `21-flags.md`
