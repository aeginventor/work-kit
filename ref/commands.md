# 명령어

터미널 1은 Codex, 터미널 2는 서버·테스트·git diff.

## work-kit

```bash
bash work-kit/tools/check.sh          # 단위마다
bash work-kit/tools/check.sh full     # 검증 단계, 제출 직전
python3 work-kit/tools/profile_csv.py 데이터폴더 --out notes/DATA_PROFILE.md
```

## Codex

| 하고 싶은 것 | 입력 |
| --- | --- |
| 시작 | `codex` |
| 모델·권한 확인 | `/status` |
| 모델 바꾸기 | `/model` |
| 새 대화 | `/new` (안 되면 종료 후 다시 `codex`). 먼저 HANDOFF 갱신 |
| 끝내기 | `/quit` |

공식 안내로 확인된 건 `codex`, `/status`, `/model` 뿐이다. 나머지는 안 되면 위 괄호의 대체 방법.

## 둘러보기

```bash
pwd && ls -la
find . -maxdepth 2 -not -path "./.*" -not -path "./work-kit*" | head -50
wc -l 파일 ; head -5 파일
grep -rn "키워드" . --exclude-dir={node_modules,.git,.venv,work-kit}
```

## git

```bash
git status -s
git diff --stat ; git diff           # 커밋 전에 읽기
git add -A && git commit -m "종류: 무엇을 - 무엇으로 확인했나"
git log --oneline -10
git restore 파일                      # 커밋 안 한 변경 되돌리기
git checkout $(cat notes/kit/provided_commit.txt) -- 파일   # 제공 파일 원래대로
```

## 서버와 미리보기 (0.0.0.0 필수)

```bash
uvicorn app.main:app --host 0.0.0.0 --port 8000            # FastAPI
./gradlew bootRun                                          # Spring (server.address=0.0.0.0)
HOST=0.0.0.0 PORT=3000 npm run dev                         # Node
python3 -m http.server 8080 --bind 0.0.0.0                 # 정적 파일
curl -s localhost:8000/health
ss -ltnp | grep 8000 ; kill PID
```

미리보기가 안 뜨면: 서버 에러 → 실제 포트 → 0.0.0.0 바인딩 → 경로 순서로 본다. 서버 띄운 터미널 탭은 닫지 않는다.

## 도커

```bash
docker build -t app .
docker run -d --name app --env-file .env -p 8000:8000 -v app_data:/app/data app
docker logs app --tail 50
docker restart app && sleep 3 && curl -s localhost:8000/health
docker rm -f app ; docker volume rm app_data       # 데이터 없이 처음부터
```

## 설치

```bash
python3 -m venv .venv && . .venv/bin/activate && pip install -r requirements.txt
npm install
```
