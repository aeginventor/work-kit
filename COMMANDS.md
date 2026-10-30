# COMMANDS.md

터미널 1은 Codex, 터미널 2는 테스트와 서버.
시험장 터미널은 내 윈도우가 아니라 브라우저 안의 리눅스(bash)다. 명령어는 리눅스 기준이다.

## 윈도우 키

| 하고 싶은 것 | 키 |
| --- | --- |
| 터미널에 붙여넣기 | Ctrl+Shift+V |
| 에디터·채팅에 붙여넣기 | Ctrl+V |
| 복사 | 글자 선택 후 Ctrl+C |
| 실행 중인 명령 끄기 | 선택 없이 Ctrl+C (서버 끌 때만) |
| 파일 이름으로 열기 | Ctrl+P |
| 전체 내용 검색 | Ctrl+Shift+F |
| 파일 탐색기 접기 | Ctrl+B |

Ctrl+W는 탭이 닫히니 누르지 않는다. 명령어를 치기 전에 한/영 상태 확인.

## 시작

```bash
pwd && ls
git clone https://github.com/aeginventor/work-kit && bash work-kit/setup.sh
```

## Codex

| 하고 싶은 것 | 입력 |
| --- | --- |
| 시작 | `codex` (신뢰 확인이 뜨면 작업 폴더 경로 보고 승인) |
| 모델과 권한 확인 | `/status` |
| 모델 바꾸기 | `/model` (사전 체험에서 정한 것 하나로 거의 안 바꿈) |
| 바뀐 내용 보기 | `/diff` (안 되면 터미널 2에서 `git diff`) |
| 대화 압축 | `/compact` |
| 새 대화 | `/new` (먼저 PROMPTS.md C15로 HANDOFF 갱신) |
| 작업 멈추기 | `Esc` |
| 지난 세션 이어가기 | `codex resume --last` |
| 끝내기 | `/quit` |

- 업데이트 권유가 떠도 업데이트하지 않는다 (금지)
- `/init`은 쓰지 않는다. AGENTS.md는 setup.sh가 이미 만들었다
- 화면이 멈춰 있으면 승인 대기인지 본다. 명령을 읽고 승인 또는 거절

## 둘러보기와 검색

```bash
ls -la
find . -maxdepth 2 -not -path "*/node_modules*" -not -path "*/.git*" -not -path "./work-kit*"
head -50 파일

# 검색 (work-kit 문서가 결과에 섞이지 않게 제외)
grep -rn "키워드" . --exclude-dir={node_modules,.git,.venv,work-kit}
grep -rln "키워드" . --exclude-dir={node_modules,.git,.venv,work-kit}   # 파일 이름만

# rg(ripgrep)는 설치돼 있을 때만. 먼저 확인
command -v rg
rg -n "키워드" -g '!work-kit'
rg -n "키워드" -t ts          # 확장자로 좁히기 (ts, js, py)
```

## 테스트

| 스택 | 전체 | 하나만 |
| --- | --- | --- |
| Node | `npm test` | `npx vitest run 파일` 또는 `npx jest 파일` |
| TypeScript 타입 검사 | `npx tsc --noEmit` | |
| Python | `pytest -q` | `pytest 파일::테스트이름 -x` |

설치

```bash
npm install
python3 -m venv .venv && source .venv/bin/activate && pip install -r requirements.txt
```

## 서버와 미리보기 (0.0.0.0 필수)

```bash
HOST=0.0.0.0 PORT=3000 npm run dev
npm run dev -- --host 0.0.0.0                 # Vite 계열
uvicorn main:app --host 0.0.0.0 --port 8000   # FastAPI
flask run --host 0.0.0.0 --port 5000          # Flask
python3 -m http.server 8080 --bind 0.0.0.0    # 정적 파일
```

미리보기 연결: 왼쪽 Browser 도구 → PORT에 터미널에 찍힌 실제 포트 → 경로(/) → 원형 화살표.
안 뜨면 이 순서로 확인: 서버 에러 → 실제 포트 → 0.0.0.0 바인딩 → 경로.

```bash
ss -ltnp | grep 3000        # 그 포트에 뭐가 떠 있는지
kill PID                    # 남은 프로세스 끄기
curl -s localhost:3000/     # 서버가 응답하는지
```

서버를 띄운 터미널 탭은 닫지 않는다. 닫으면 서버도 꺼진다.

## 보안 확인

```bash
git grep -niE "api_?key|secret|password|token"   # 코드에 진짜 비밀값이 박혀 있지 않은지 눈으로 확인
```

## git

```bash
git status -s                          # 바뀐 파일
git diff                               # 커밋 전 변경 내용 읽기
git diff --stat                        # 파일별 변경 양
git add -A && git commit -m "메시지"   # 커밋
git log --oneline -10                  # 최근 커밋
git restore 파일                       # 커밋 안 한 변경 되돌리기
git show HEAD --stat                   # 마지막 커밋에 뭐가 들어갔나
```

커밋 메시지 형식: `fix: (무엇을) - (확인한 것)`, `feat: ...`, `test: ...`, `docs: ...`
