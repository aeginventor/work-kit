# 스택 고르기

스택은 05 단계의 첫 결정 카드다. 정답은 없고, 고른 이유를 말할 수 있으면 된다.

## 고를 때 기준

1. 이미 코드가 있으면 그 스택을 유지한다 (고치기, 확장)
2. 과제의 실행 조건을 바로 만족하나: DB 저장, 컨테이너, 화면, 로그인·역할, 데이터 처리량
3. 3시간 안에 만들고 검증까지 하나: 빌드 시간, 설정 양, 내가 실행해 본 적 있는지
4. 내가 흐름을 설명할 수 있나: 서술형은 내 코드에서 나온다. 코드가 짧을수록 설명하기 쉽다

## Python + FastAPI + SQLite

어울릴 때: 데이터 처리·집계가 많을 때, 빠르게 뼈대를 세우고 싶을 때, DB 서버를 따로 띄우기 싫을 때
주의: SQLite는 동시에 한 곳만 쓴다(쓰기 잠금). 동시성 질문에는 "쓰기 잠금 + 버전 비교"로 설명할 수 있게 만든다

뼈대 지시
```text
FastAPI 뼈대를 만들어줘. 기능은 아직 없이 끝까지 도는 게 목표.
설정은 환경변수(PORT, DB_PATH 등 과제에 필요한 것), .env.example 포함. 시작 시 SQLite 테이블 자동 생성.
서버는 0.0.0.0. pytest 테스트 1개. 과제가 요구하면 상태 확인 주소와 Dockerfile(python slim, 데이터는 볼륨 경로)도.
끝나면 로컬 실행 + pytest 결과를 보여줘.
```
확인: `uvicorn app.main:app --host 0.0.0.0 --port 8000`, `curl -s localhost:8000/`, `python3 -m pytest -q`

## Java + Spring Boot

어울릴 때: 이미 Spring 코드가 있을 때, 계층 구조(컨트롤러·서비스·저장소)로 설명하고 싶을 때, 익숙한 스택일 때
주의: 첫 빌드가 의존성 내려받기로 몇 분 걸린다. 뼈대를 일찍 만들어 빌드를 미리 한 번 돌려 둔다. Gradle 래퍼(gradlew)를 쓴다

뼈대 지시
```text
Spring Boot 뼈대를 만들어줘 (Gradle 래퍼, Java 17 또는 설치된 버전). 기능은 아직 없이 끝까지 도는 게 목표.
설정은 환경변수(SERVER_PORT, DB 접속 등 과제에 필요한 것), .env.example 포함. server.address=0.0.0.0.
DB는 파일 기반(H2 file 또는 SQLite) 또는 과제가 정한 DB. 시작 시 스키마 자동 생성.
테스트 1개. 과제가 요구하면 상태 확인 주소(actuator 등)와 Dockerfile(멀티스테이지 빌드)도.
끝나면 ./gradlew test, bootRun 결과를 보여줘.
```
확인: `./gradlew test`, `./gradlew bootRun`, `curl -s localhost:8080/`

## 그 밖

Node(Express/Next) 등 다른 스택도 같은 기준으로 고른다. 뼈대 지시는 위 문장에서 스택 이름과 명령만 바꾸면 된다.
