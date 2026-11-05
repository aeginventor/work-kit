# 01 시작

외워 둘 명령 (복사·붙여넣기가 안 될 수 있다): `git clone https://github.com/aeginventor/work-kit && bash work-kit/setup.sh`

시간은 화면 위 "남은 시간"으로 네 번만 본다. 타이머는 '과제 시작'을 누르는 순간부터 돈다.
**남음 2:15** 계획 끝, 구현 시작 · **1:30** 중간 점검 · **0:45** 새 기능 중단, 검증·문서 · **0:10** 제출 시작

## 할 일

1. 터미널 1: `pwd && ls` → 과제 README가 보이는지 확인
   - 안 보이면 `find . -maxdepth 3 -name "*.md" -not -path "./.*"` 로 과제 문서를 찾아서 그 폴더로 `cd`. 문서 이름이 README가 아니면 setup은 `FORCE=1 bash work-kit/setup.sh`
2. 터미널 1:
   ```bash
   git clone https://github.com/aeginventor/work-kit && bash work-kit/setup.sh
   ```
   멈추면 화면 안내대로. 아예 안 되면 맨 아래 "수동 준비".
3. 터미널 1: `codex` → 신뢰 확인이 뜨면 작업 폴더(README가 있는 곳)가 맞는지 보고 신뢰 → `/status` 로 모델 확인 (업데이트 안내는 건너뛴다. 느리면 ref/commands.md "Codex 속도") → 이렇게 보낸다
   ```text
   notes/prompt.md 읽고 그대로 진행해
   ```
   첫 프롬프트는 setup이 notes/prompt.md에 넣어 뒀다 (과제 문서 읽기, PLAN·R 번호·제출물·ASK 만들기). 보내기 전에 에디터로 한 번 훑어봐도 된다
   승인 대기로 멈추면 화면의 명령을 읽고 승인 또는 거절. 기다리기만 하면 진행되지 않는다
4. Codex가 도는 동안
   - 터미널 `+` 로 터미널 2 열기 (서버, 테스트, git diff 용)
   - 에디터 배치 (ref/keys.md 1절): 오른쪽 창 = steps 파일 고정, 왼쪽 창 = 작업 파일
   - 에디터에서 AGENTS.md 맨 위 "시험 제공 규칙"을 30초 훑는다 (setup이 시험 원본을 그대로 넣어 둠. 없었으면 "없음")
   - 데이터 파일이 있으면 터미널 2: `python3 work-kit/tools/profile_csv.py 데이터폴더 --out notes/DATA_PROFILE.md`
   - 그리고 바로 02_read.md (README를 내가 직접 읽는다)

## 끝 기준

- Codex에 첫 프롬프트를 보냈다, 터미널 2가 열렸다

## 수동 준비 (setup.sh가 안 될 때)

```bash
[ -d .git ] || git init
git config user.name San; git config user.email san@example.com
printf '/work-kit/\n/.*\n!/.env.example\n.env\nnode_modules/\n.venv/\n' >> .git/info/exclude
git add -A && git commit -m "chore: 제공된 초기 상태"
mkdir -p notes/from-exam notes/kit && cp work-kit/templates/*.md notes/
[ -f AGENTS.md ] && [ ! -f notes/from-exam/AGENTS.md ] && cp AGENTS.md notes/from-exam/
cp work-kit/AGENTS.md . && [ -f notes/from-exam/AGENTS.md ] && cat notes/from-exam/AGENTS.md >> AGENTS.md
```

마지막 줄은 시험 원본을 AGENTS.md 맨 끝에 붙인다. 위치만 다르고 시험 규칙이 우선인 건 같다.

clone 자체가 안 되면: AGENTS.md에 "판단은 내가 한다, 무거운 결정은 선택지로 묻고 기다려, 단위마다 바뀐 파일·3줄 설명·커밋 메시지 보고하고 멈춰" 세 줄만 손으로 쓰고 진행.

다음: 02_read.md
