# 01 시작 · 끝 19:08

시간표: 01 ~19:08 · 02 ~19:18 · 03·04 ~19:30 · 05 ~19:42 · 06 ~21:15 (20:30 점검) · 07 ~21:35 · 08 ~21:50 · 09 22:00 제출
시작이 늦었으면 모든 시각을 같은 만큼 민다. 23:00 종료는 고정이라 과제 제출은 늦어도 22:15.

## 할 일

1. 터미널 1: `pwd && ls` → 과제 README가 보이는지 확인
   - 안 보이면 `find . -maxdepth 3 -name "*.md" -not -path "./.*"` 로 과제 문서를 찾아서 그 폴더로 `cd`. 문서 이름이 README가 아니면 setup은 `FORCE=1 bash work-kit/setup.sh`
2. 터미널 1:
   ```bash
   git clone https://github.com/aeginventor/work-kit && bash work-kit/setup.sh
   ```
   멈추면 화면 안내대로. 아예 안 되면 맨 아래 "수동 준비".
3. 터미널 1: `codex` → `/status` 로 모델 확인 (업데이트 안내는 건너뛴다. 느리면 ref/commands.md "Codex 속도") → 아래 첫 프롬프트 보내기
   (길어서 치기 힘들면 notes/prompt.md에 붙여 넣고 Codex에는 `notes/prompt.md 읽고 그대로 진행해`)
4. Codex가 도는 동안
   - 터미널 `+` 로 터미널 2 열기 (서버, 테스트, git diff 용)
   - 에디터 배치 (ref/keys.md 1절): 오른쪽 창 = steps 파일 고정, 왼쪽 창 = 작업 파일
   - setup이 "AGENTS.md를 보존했어"라고 했으면 `cat notes/from-exam/AGENTS.md` 30초. Codex가 옮긴 규칙과 비교해 빠진 게 있으면 말해 준다
   - 데이터 파일이 있으면 터미널 2: `python3 work-kit/tools/profile_csv.py 데이터폴더 --out notes/DATA_PROFILE.md`
   - 그리고 바로 02_read.md (README를 내가 직접 읽는다)

## 첫 프롬프트 (과제가 뭐든 그대로)

```text
AGENTS.md를 먼저 읽어. notes/from-exam/AGENTS.md가 있으면 읽고, 지켜야 할 규칙(환경, 금지 사항, 작업 방식)을 AGENTS.md "시험 제공 규칙" 칸에 원문 그대로 옮겨줘. 없으면 "없음". 화면에는 옮긴 줄만.
그다음 과제 문서를 찾아 읽어: README, README가 가리키는 문서, docs/ 같은 폴더의 설명 문서. 먼저 작업공간 구조를 2단계 깊이로 보고, 이전 과제와 다를 수 있으니 실제 있는 파일만 근거로 해. 데이터 파일은 열 이름과 앞 5줄만. 코드는 아직 만들지 마.
notes/PLAN.md에 아래를 써줘.
1. 과제 한 줄 요약, 유형 판단(새로 만들기 / 고치기 / 기존 코드 확장 / 분석·리포트 / 성능·장애 / 설계·문서, 섞였으면 주된 것)과 이유
2. 필수 요구: R1부터 번호를 붙여서 요구 / 문서 근거 위치 / 내가 확인할 방법. 빠짐없이. 결과를 크게 좌우하는 핵심 요구에는 ★
3. 하지 않는 것(제외 범위)과 응시 환경 제약
4. 제출물: 파일 이름 그대로, 정해진 양식이 있는지. 같은 파일 경로를 notes/deliverables.txt에 한 줄에 하나씩
5. 업무 의미가 모호한 것: 담당자에게 물을 질문 후보, 결과에 미치는 영향이 큰 순서
6. 내가 정해야 할 결정 후보: 목록만, 아직 묻지 마
7. 담당자 확인 항목: 과제 문서가 확인하라고 한 것과 위 5번을 빠짐없이 notes/ASK.md 표로 (번호, 근거 위치, 질문 초안, 답 칸은 비워 둠)
끝나면 화면에는 요약 5줄만.
```

## 끝 기준

- Codex에 첫 프롬프트를 보냈다, 터미널 2가 열렸다

## 수동 준비 (setup.sh가 안 될 때)

```bash
[ -d .git ] || git init
printf '/work-kit/\n/.*\n!/.env.example\n.env\nnode_modules/\n.venv/\n' >> .git/info/exclude
git add -A && git commit -m "chore: 제공된 초기 상태"
mkdir -p notes/from-exam notes/kit && cp work-kit/templates/*.md notes/ && cp AGENTS.md notes/from-exam/ 2>/dev/null; cp work-kit/AGENTS.md .
```

clone 자체가 안 되면: AGENTS.md에 "판단은 내가 한다, 무거운 결정은 선택지로 묻고 기다려, 단위마다 바뀐 파일·3줄 설명·커밋 메시지 보고하고 멈춰" 세 줄만 손으로 쓰고 진행.

다음: 02_read.md
