# work-kit

AI 코딩 에이전트(Codex)와 일할 때 쓰는 개인 작업 방식 템플릿.
문서 양식과 시작 스크립트만 있고, 과제 코드는 없다.

SK하이닉스 AI 해커톤 2026 2차 예선에서 공개 저장소 활용 규정에 따라 사용한다. 결과 통지 전까지 공개 상태로 둔다.

## 시작하는 법 (과제 루트, 터미널 1)

```bash
git clone https://github.com/aeginventor/work-kit.git
bash work-kit/setup.sh
```

그다음 에디터에서 `work-kit/EXAM.md`를 열고 위에서부터 따라간다.

## 파일 지도

| 파일 | 언제 보나 |
| --- | --- |
| EXAM.md | 처음부터 끝까지 이것만 보고 진행. 단계별로 지금 할 일이 있다 |
| PROMPTS.md | EXAM.md가 부르는 번호(C1~C15는 Codex, M1~M8은 업무 담당자) |
| COMMANDS.md | codex, 터미널, git, 서버, 테스트 명령 |
| EXAMPLES.md | 채워진 예시(합의 메시지, AGENTS.md, DECISIONS.md, 서술형 답) |
| templates/ | setup.sh가 과제 루트로 복사하는 AGENTS.md, DECISIONS.md, HANDOFF.md |
| setup.sh | 템플릿 복사, git 준비, work-kit을 git에서 제외 |
