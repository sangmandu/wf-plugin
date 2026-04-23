---
name: 40-observers
description: CI / PR 리뷰 polling observer 스크립트 2종 — 결정적 JSON 출력과 next_action 기반 분기
type: reference
---

# Observers

wf는 외부 시스템(GitHub CI, PR 리뷰) 상태를 **결정적 observer 스크립트**로 감시한다. 에이전트가 GitHub 응답을 자유롭게 해석하지 않도록, observer가 정해진 JSON 스키마로 요약해 돌려준다. 에이전트는 `next_action` 필드만 보고 분기.

## 설계 원칙

1. **Deterministic output**: 같은 입력 → 같은 JSON. 에이전트가 해석할 여지 제거
2. **next_action 기반 분기**: `DONE` / `WAIT` / `FETCH_LOGS_AND_FIX` / `ALERT_USER` 중 하나. 에이전트는 분기 트리만 따름
3. **외부 실패는 exit 0 + status 필드로**: 네트워크/인증 오류도 JSON으로 보고해 에이전트가 정형 처리 가능

## `observe-ci.sh <PR>`

### 역할
PR의 CI check-run 상태를 aggregate해 JSON 요약.

### CI 플랫폼 감지
- `.github/workflows/*.yml` 존재 → `github-actions`
- `Jenkinsfile` → `jenkins` (unsupported)
- `.gitlab-ci.yml` → `gitlab` (unsupported)
- 없음 → `none` (스킵)

### 필터링
- 리뷰 봇 check-run (`review`, `Claude Auto PR Code Review` 등) 제외 — REVIEW 스텝에서 다루므로 CI 사이클과 분리
- 환경변수 `CI_OBSERVE_EXCLUDE_PATTERN`으로 패턴 오버라이드 가능 (case-insensitive regex)

### 출력 스키마
```json
{
  "platform": "github-actions|jenkins|gitlab|none",
  "status": "all_passed | some_failed | pending | missing | skipped | error",
  "passed": N, "failed": N, "pending": N, "skipped": N, "total": N,
  "missing_reason": "draft | rebase_conflict | not_registered_yet | null",
  "is_draft": bool,
  "mergeable": "MERGEABLE | CONFLICTING | ...",
  "merge_state": "...",
  "failed_jobs": [{"name", "conclusion", "url"}],
  "next_action": "DONE | WAIT | FETCH_LOGS_AND_FIX | ALERT_USER",
  "remediation": "..." | null
}
```

### next_action 매트릭스

| 상황 | next_action | 에이전트 행동 |
|---|---|---|
| `status=all_passed` | `DONE` | 다음 스텝 진행 |
| `pending > 0` | `WAIT` | 일정 시간 후 재호출 |
| `failed > 0` | `FETCH_LOGS_AND_FIX` | `gh run view <id> --log-failed`로 로그 수집 후 수정 |
| `missing_reason=not_registered_yet` | `WAIT` | 30-60s 대기 후 재호출 |
| `missing_reason=draft` | `ALERT_USER` | draft 해제 요청 |
| `missing_reason=rebase_conflict` | `ALERT_USER` | rebase 필요 안내 |
| `platform=none` | `DONE` | CI 없음, 스킵 |
| `platform=jenkins/gitlab` | `ALERT_USER` | 수동 확인 요청 |

## `observe-reviews.sh <PR>`

### 역할
PR 리뷰 + 코멘트 상태를 이전 snapshot과 비교해 **diff 리포트** 생성.

### 수집 대상
- Reviews: approve / request-changes / comment
- Review comments: 코드 라인 인라인 코멘트
- Issue comments: PR 일반 코멘트 (bot 판정 포함)

### Snapshot 저장
```
<worktree>/.workflow/observations/
  reviews-<PR>.json        # 현재 snapshot
  reviews-<PR>-prev.json   # 직전 snapshot (diff용)
```

### Diff 검출
- **New reviews**: 이번에 새로 달림
- **New comments**: 이번에 새로 달림
- **Modified comments**: 같은 id인데 `updated_at` 변경 (리뷰어가 수정)
- **Bot vs human**: `user.type`으로 구분해 봇 판정과 사람 피드백 분리

### 에이전트 사용 흐름
1. PR 생성 직후 `observe-reviews.sh`를 한 번 돌려 초기 snapshot 기록
2. 주기적으로 재호출 → diff 리포트로 새 피드백 식별
3. 새 코멘트/리뷰에 대응해 IMPLEMENT 스텝으로 rewind 또는 답변

## 왜 observer 패턴인가

에이전트가 `gh pr view --json ...` 결과를 직접 해석하면:
- 출력 포맷 변경에 취약
- 같은 상황을 다르게 해석할 수 있음 (비결정적)
- "CI가 아직 안 끝났나?" 판단이 매번 달라질 수 있음

observer 스크립트가 결정적 JSON을 주면 에이전트는 **lookup table만 따름**. 행동이 안정적.

## 관련 문서

- 스크립트 호출 규약: `30-scripts.md`
- state.json payload 영역에 observer 결과 저장 (앞으로): `10-state-machine.md`
