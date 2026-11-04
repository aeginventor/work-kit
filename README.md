# work-kit

AI 코딩 에이전트(Codex)와 일할 때 쓰는 개인 작업 하네스.
작업 규칙(AGENTS.md), 기록 양식, 단계별 체크리스트, 범용 검사 스크립트만 있다. 과제 답 코드는 없다.

SK하이닉스 AI 해커톤 2026 2차 예선에서 공개 저장소 활용 규정에 따라 사용한다. 결과 통지 전까지 공개 상태로 둔다.
10/31 응시 때 쓴 버전은 커밋 `663a05d`에 그대로 남아 있다 (github.com/aeginventor/work-kit/tree/663a05d).

## 시작 (과제 README가 보이는 위치에서)

```bash
git clone https://github.com/aeginventor/work-kit && bash work-kit/setup.sh
```

그다음 에디터에서 `work-kit/steps/01_start.md`를 연다. 시험 중에는 steps/ 폴더만 번호순으로 따라간다.

## 기억할 다섯 줄 (clone이 안 돼도 이것만은)

1. 과제 문서를 내가 직접 읽고, 요구에 R 번호를 붙인다. 담당자에게는 업무 의미만 작은 질문으로
2. 무거운 결정은 Codex가 선택지로 묻고 내가 이유와 함께 고른다. 결정 카드로 남긴다
3. 한 번에 한 단위. 끝날 때마다 diff를 보고, 기대값 한 줄을 판단하고, 내 말로 커밋 메시지
4. AI 설명이 아니라 실행 결과로 믿는다. 요구마다 검증, 핵심 요구는 일부러 깨 본다
5. 문서에는 실제로 한 것만. 서술형은 내 문서와 코드에서 나온다

## 지도

| 위치 | 언제 |
| --- | --- |
| steps/01~05 | 모든 과제 공통: 시작, 읽기, 데이터, 질문, 계획 |
| steps/06_*.md | 과제 유형에 맞는 파일 하나만 (02에서 정함) |
| steps/07~09 | 모든 과제 공통: 검증, 문서, 제출과 서술형 |
| ref/ | 막혔을 때만: 프롬프트, 키보드, 명령어, 배포 점검, 스택, 채점 기준 |
| tools/check.sh | 단위가 끝날 때마다: `bash work-kit/tools/check.sh` (제출 전엔 `full`) |
| tools/profile_csv.py | 데이터가 있을 때: `python3 work-kit/tools/profile_csv.py 데이터폴더` |
| AGENTS.md, templates/ | setup.sh가 작업공간으로 복사하는 원본 |

## setup.sh가 하는 일

1. 과제 README가 있는 위치인지, 다른 저장소의 하위 폴더는 아닌지 확인한다. 아니면 아무것도 안 하고 멈춘다.
2. git이 없으면 만들고, 홈 디렉터리 환경 파일(.bashrc 같은 숨김 파일)과 work-kit/을 git에서 뺀다.
3. 처음 받은 상태를 커밋하고, 그 파일 목록을 notes/kit/provided.txt에 남긴다. check.sh가 이 파일들이 바뀌지 않았는지 본다.
4. 시험이 준 AGENTS.md가 있으면 notes/from-exam/AGENTS.md로 보존한 뒤 내 AGENTS.md로 바꾼다.
5. notes/에 기록 양식(DECISIONS, HANDOFF, DATA, UNITS)을 만든다.

작업공간의 notes/는 이렇게 나뉜다.

| 위치 | 무엇 | 누가 |
| --- | --- | --- |
| notes/*.md, deliverables.txt | 내 기록 (계획, 결정, 데이터 해석, 단위 설명, 인수인계) | 나와 Codex |
| notes/from-exam/ | 시험이 준 원본 보존본 (예: AGENTS.md). 수정하지 않는다 | setup.sh |
| notes/kit/ | 검사 도구용 기록 (제공 파일 목록, 검사 이력) | setup.sh, check.sh |

이미 있는 기록 파일은 덮어쓰지 않는다. 두 번 실행해도 결과가 같다.
