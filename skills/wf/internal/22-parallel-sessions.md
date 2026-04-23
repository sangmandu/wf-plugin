---
name: 22-parallel-sessions
description: 여러 worktree에서 동시에 wf가 돌 때 세션 간 간섭이 없는 이유 — session_id 기반 owner 매칭
type: reference
---

# Parallel Sessions

wf는 동시에 여러 개가 돌아간다. 티켓 A는 이 worktree, 티켓 B는 저 worktree. 각자 자기 스텝을 밟고 자기 interrupt 플래그를 켠다. 서로 건드리지 않는다.

## 격리 원리 한 줄

**state.json은 worktree 안에만 산다. hook은 stdin의 `session_id`와 `data.owner_session_id`가 일치하는 state.json만 자기 scope으로 본다.**

cwd에 의존하지 않음. 글로벌 레지스트리도 없음.

## 구조도

```
<repo>/                      ← 일반 세션 (wf 없음)
  └─ (.workflow 없음 → hook exit 0)

<repo>/<wt-A>                ← 세션 A 소유 worktree
  └─ .workflow/state.json    { control.status: running,
                               control.current_step: IMPLEMENT,
                               data.owner_session_id: "<uuid-A>" }

<repo>/<wt-B>                ← 세션 B 소유 worktree
  └─ .workflow/state.json    { control.status: running,
                               control.current_step: EXPLAIN_PLAN,
                               data.interrupted: true,
                               data.owner_session_id: "<uuid-B>" }

<repo>/<wt-C>                ← 완료된 worktree
  └─ .workflow/state.json    { control.status: completed }

─────────────────────────────────────────────────────
글로벌 hook (~/.claude/settings.json 에 한 번 등록)
─────────────────────────────────────────────────────
    각 세션의 모든 Stop / UserPromptSubmit 이벤트에서 호출
                        │
                        ▼
 git worktree 목록을 스캔해 `.workflow/state.json` 후보 수집
                        │
 stdin.session_id 와 .data.owner_session_id 가 일치하는 항목 선택
                        │
     ┌──────────────────┼──────────────────┐
     ▼                  ▼                  ▼
 session=uuid-A     session=uuid-B     session=other
     │                  │                  │
 state A 읽음      state B 읽음       매칭 없음 → exit 0
     │                  │
 guard 적용         interrupt 유지
```

## 왜 간섭이 없나

### 1. 파일이 별개
각 worktree는 다른 디렉토리. `.workflow/state.json`은 worktree 내부 파일. 읽기/쓰기가 자연히 분리됨.

### 2. hook이 session_id로 scope 판단
글로벌 hook이지만, 모든 스크립트는 **현재 세션의 `session_id`**를 꺼내 git worktree 전체를 훑고 `data.owner_session_id`가 일치하는 state.json만 손댐. 세션 B의 Stop 이벤트가 세션 A state를 건드리는 경로가 없음.

### 3. 플래그가 로컬
`interrupted`, `interrupted` 모두 worktree-local. 세션 A에서 유저가 끼어들어도 세션 B 상태는 그대로.

## 세션이 죽으면?

세션 종료 = state.json은 디스크에 남음. 다음에 같은 worktree 대상으로 새 Claude Code 세션을 띄워 `resume-workflow.sh`를 실행하면:
- `data.owner_session_id`가 빈 문자열로 초기화됨
- 새 세션의 다음 UserPromptSubmit hook이 "unclaimed running"을 발견해 자동 claim (owner 갱신)
- 이후 그 worktree의 hook은 새 세션으로 라우팅됨

```
세션 A 죽음 → state.json.data.owner_session_id = "<uuid-A>" 로 남음

다음 세션 B (동일 worktree 대상)에서:
  bash ${CLAUDE_PLUGIN_ROOT}/skills/wf/lib/resume-workflow.sh
      │
      ▼ owner_session_id = "" 로 비움
      │
  다음 프롬프트 submit:
      │
      ▼ UserPromptSubmit hook → Pass 2 claim
      │   owner_session_id = "<uuid-B>"
      │
  이후 hook은 세션 B로 정상 라우팅
```

## 한 worktree에 두 세션?

권장되지 않음. 두 세션이 동시에 프롬프트를 submit하면 양쪽 hook이 같은 state.json을 경쟁적으로 읽고 쓸 수 있음. 또한 최근에 claim한 세션이 이전 세션을 밀어냄 → 먼저 claim했던 세션은 그 worktree 스코프를 잃음.

필요하면 future work:
- 파일 락 (fcntl / lockfile)
- owner를 배열로 관리하고 active-session 개념 도입

## 동시 interrupt / interrupt

세션 여러 개가 각자 interrupt/interrupt 상태여도 문제없음. 각 hook 호출은 독립적이고 수정 대상 파일도 독립적.

```
세션 A: interrupted=true (EXPLAIN_PLAN interrupt)
세션 B: interrupted=true  (유저가 끼어듦)
세션 C: 평시 진행 중

→ 세션 A에서 Stop 발화: state A만 본다 → 허용
→ 세션 B에서 Stop 발화: state B만 본다 → 허용 + 리셋
→ 세션 C에서 Stop 발화: state C만 본다 → block
```

## 비-wf 세션에 미치는 영향

wf와 무관한 세션 (그냥 코드 보는 중, main repo에서 Claude 띄운 세션 등):
- owner_session_id 매칭 실패 → hook 전부 exit 0
- **완전 무해**. wf가 이 세션과 무관하다는 걸 hook이 스스로 감지

## 관련 문서

- state.json 구조: `10-state-machine.md`
- hook의 session_id 매칭: `20-hooks.md`
- 플래그 독립성: `21-flags.md`
