---
name: 90-troubleshooting
description: wf 엣지 케이스·실패 원인·에러 보고 정책. Stop hook false-positive, state 불일치, 유령 interrupt 등
type: reference
---

# Troubleshooting

wf가 꼬이는 전형적 상황과 복구법. 그리고 스크립트 실패 시 에이전트가 유저에게 보고해야 할 정형 템플릿.

## 에러 보고 정책

스크립트가 실패하거나 예상치 못한 상태를 만나면 에이전트는 **침묵으로 넘어가지 않는다**. 유저에게 아래 템플릿으로 보고.

### 템플릿

```
[wf error] <짧은 한 줄 요약>

- 현재 스텝: <STEP_KEY> (<N>/<TOTAL>)
- 실패 지점: <script or action>
- 증상: <stderr 요지 또는 관찰된 이상>
- 가능한 원인: <1~3줄>
- 제안 조치:
  1. <조치 A>
  2. <조치 B>
```

### 언제 보고하나
- 스크립트 exit code ≠ 0
- state.json 필드가 invariant 위반 (`10-state-machine.md#invariants`)
- observer가 `ALERT_USER` next_action 반환
- CI 실패 로그 fetch 중 네트워크/인증 실패
- rewind 대상 STEP_KEY가 registry에 없음

### 언제 보고 안 하나
- observer가 `WAIT` 반환 → 재시도
- `complete-step.sh`가 정상 종료 → 다음 스텝 진행
- Stop hook이 block 반환 → hook 안내대로 처리 (에러 아님)

## 자주 겪는 엣지 케이스

### 1. `state.json not found. Are you in the worktree?`
**원인**: 스크립트를 worktree 밖에서 실행. 스크립트는 cwd 기준으로 `.workflow/state.json`을 찾음.
**해결**: `cd <worktree>` 후 재실행. 이미 worktree 안이라면 `.workflow/` 디렉토리 존재 확인.

### 2. Stop hook이 무한 block
**증상**: 에이전트가 응답 끝내려 하면 계속 `decision: block` 반환.
**원인 1**: 현재 스텝이 INTERRUPT_STEPS에도 없고, 플래그도 안 켜진 상태에서 에이전트가 "그냥 멈추려" 함.
**해결**: 다음 3가지 중 하나 실행
  - 스텝 완료면 `complete-step.sh <KEY>`
  - 유저 질문 필요면 `scripts/agent-interrupt.sh "<label>"`
  - 계속 작업 (Stop 안 함)

**원인 2**: state.json의 `control.current_step`과 실제 running 스텝이 불일치.
**해결**: `resume-workflow.sh` 실행으로 running 스텝 재탐색.

### 3. 유령 interrupt — 플래그가 안 꺼짐
**증상**: interrupt 끝낸 줄 알았는데 Stop이 계속 "허용" 상태.
**원인**: `interrupted=true`가 유지됨. 이전 interrupt가 resume/complete-step 없이 끝남.
**해결**: `resume-workflow.sh` 실행 — 두 interrupt flag를 명시적으로 false로 리셋.
**예방**: `complete-step.sh`가 safety reset을 이미 포함함 (`21-flags.md`).

### 4. Wrong worktree에서 hook이 발화
**증상**: 전혀 관련없는 세션에서 `[wf interrupt]` 또는 `[wf guard]` 메시지가 나타남.
**원인**: hook은 cwd 기준. 유저가 `cd`로 wf 워크트리에 들어갔다가 그 터미널에서 관련 없는 Claude 세션을 시작했을 때.
**해결**: 해당 워크트리의 `.workflow/state.json`의 `control.status`를 확인. 이미 완료됐다면 `"completed"`여야 함. 남아있는 `running` 상태면 진행/abandon 결정.

### 5. `step-registry.json`에 없는 STEP_KEY
**증상**: `ERROR: <KEY> not in step-registry.json`.
**원인**: track-steps.json에만 추가하고 registry에 빠뜨림.
**해결**: `step-registry.json`에 `"STEP_KEY": "NNN-name.md"` 추가 + 해당 md 파일 생성 (`50-steps.md#새-스텝-추가-절차`).

### 6. rewind 후 무한 루프
**증상**: 같은 스텝을 반복 돌다 멈춤.
**원인**: CI 실패 → rewind IMPLEMENT → 같은 수정 반복 → 같은 CI 실패.
**해결**: 근본 원인 디버깅. rewind는 재시도 수단이지 해결책이 아님. 3회 이상 같은 실패 반복하면 `agent-interrupt.sh`로 유저에게 보고.

### 7. 동시 워크트리의 state 교차 오염
**증상**: AI-9999 state가 PLAT-1234 값으로 덮어써짐.
**원인**: 원칙적으로 발생 불가 (각 state.json은 worktree-local). 발생했다면 스크립트 버그 또는 수동 편집 실수.
**해결**: git 히스토리(있다면) 또는 `.workflow/` 백업 확인. 없으면 해당 워크플로우는 `rewind-step.sh`로 안전한 지점까지 되돌림.

### 8. `set-data.sh: '<key>' is reserved`
**원인**: `status`, `current_step`, `steps` 등 control.* 키를 data로 쓰려 함.
**해결**: 키 이름 변경. control.* 네임스페이스는 스크립트 전용.

### 9. 세션이 죽고 재개 시 스텝 md가 안 나옴
**증상**: 새 세션에서 `resume-workflow.sh` 실행했는데 스텝 내용이 안 뜸.
**원인**: 마지막으로 running이었던 스텝이 registry에 없거나 md 파일이 삭제됨.
**해결**: `state.json`의 `control.current_step` 확인 → 해당 키가 `step-registry.json`에 있는지 검증 → 없으면 `rewind-step.sh`로 복원 가능한 직전 스텝으로.

### 10. Observer가 `ALERT_USER`인데 remediation이 모호
**원인**: 네트워크/gh 인증/draft PR 등.
**해결**: `remediation` 필드 그대로 유저에게 전달 + 에러 보고 템플릿 사용.

## 복구 커맨드 치트시트

| 상황 | 커맨드 |
|---|---|
| 세션 복귀 / interrupt 탈출 | `bash <WF_DIR>/lib/resume-workflow.sh` |
| 직전 스텝으로 역행 | `bash <WF_DIR>/lib/rewind-step.sh <TARGET> [RESET...]` |
| state.json 수동 확인 | `jq . .workflow/state.json` |
| 현재 스텝 확인 | `jq -r '.control.current_step' .workflow/state.json` |
| interrupt flag 상태 확인 | `jq '.control | {interrupted, interrupted, interrupt_reason}' .workflow/state.json` |
| 완료된 스텝 수 | `jq '[.control.steps[] | select(.status=="completed")] | length' .workflow/state.json` |

## 관련 문서

- 불변 조건: `10-state-machine.md#invariants`
- 플래그 생명주기: `21-flags.md`
- observer next_action: `40-observers.md`
