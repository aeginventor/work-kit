#!/usr/bin/env bash
# work-kit 시작 스크립트
# 과제 루트(README.md가 있는 곳)에서 실행: bash work-kit/setup.sh
# 하는 일: git 준비 -> work-kit을 git에서 제외 -> 초기 상태 커밋 -> 템플릿 복사
# 이미 있는 파일은 덮어쓰지 않는다.

set -u

kit_dir="$(cd "$(dirname "$0")" && pwd -P)"
kit_name="$(basename "$kit_dir")"
root="$(pwd -P)"

if [ "$kit_dir" = "$root" ]; then
  echo "과제 루트에서 실행해줘: bash work-kit/setup.sh"
  exit 1
fi

# 안전장치 1: 과제 루트가 아니면 멈춘다 (README가 안 보이면 위치가 틀렸을 가능성이 크다)
if ! ls -1 | grep -qi '^readme' && [ "${FORCE:-}" != "1" ]; then
  echo "여기($root)에 README가 없어. 과제 루트가 맞는지 pwd, ls로 확인해줘."
  echo "정말 여기가 과제 루트면: FORCE=1 bash $kit_name/setup.sh"
  exit 1
fi

# 안전장치 2: 이미 있는 git 저장소의 하위 폴더면 멈춘다 (저장소 안에 저장소를 또 만들지 않게)
top="$(git rev-parse --show-toplevel 2>/dev/null || true)"
if [ -n "$top" ] && [ "$top" != "$root" ]; then
  echo "여기는 $top 저장소의 하위 폴더야. 과제 루트로 가서 다시 실행해줘: cd $top"
  exit 1
fi

echo "== work-kit setup: $root"

# 1. git 준비
if [ ! -d .git ]; then
  git init -q
  echo "[git] 새 저장소를 만들었어"
fi
if [ -z "$(git config user.name 2>/dev/null)" ]; then
  git config user.name "San"
fi
if [ -z "$(git config user.email 2>/dev/null)" ]; then
  git config user.email "san@example.com"
fi

# 2. work-kit과 흔한 빌드 산출물은 이 컴퓨터에서만 git 제외 (과제 파일은 안 건드림)
mkdir -p .git/info
touch .git/info/exclude
for pattern in "$kit_name/" "node_modules/" ".venv/" "__pycache__/" ".env"; do
  grep -qxF "$pattern" .git/info/exclude || echo "$pattern" >> .git/info/exclude
done
echo "[git] $kit_name/ 를 git 추적에서 제외했어"

# 3. 커밋이 하나도 없을 때만 제공된 초기 상태를 커밋
if ! git rev-parse HEAD >/dev/null 2>&1; then
  git add -A
  if git commit -qm "chore: 제공된 초기 상태"; then
    echo "[git] 초기 상태 커밋 완료"
  else
    echo "[git] 초기 상태 커밋 실패. git status 확인 필요"
  fi
else
  echo "[git] 기존 커밋이 있어서 초기 커밋은 건너뜀"
fi

# 4. 템플릿 복사
for f in DECISIONS.md HANDOFF.md; do
  if [ -e "$f" ]; then
    echo "[skip] $f 이미 있음. 덮어쓰지 않음 (EXAM.md 1단계 참고)"
  else
    cp "$kit_dir/templates/$f" "$f"
    echo "[copy] $f"
  fi
done

if [ -e AGENTS.md ]; then
  if grep -q "응시자 작업 규칙 (추가)" AGENTS.md; then
    echo "[skip] AGENTS.md 에 이미 내 규칙이 있음"
  else
    cat "$kit_dir/templates/AGENTS.append.md" >> AGENTS.md
    echo "[append] 기존 AGENTS.md 뒤에 내 규칙을 붙였어"
  fi
else
  cp "$kit_dir/templates/AGENTS.md" AGENTS.md
  echo "[copy] AGENTS.md"
fi

# 5. DECISIONS.md 의 사용한 자료에 work-kit 주소 채우기
kit_url="$(git -C "$kit_dir" remote get-url origin 2>/dev/null || echo "work-kit 공개 저장소")"
if [ -e DECISIONS.md ] && grep -q "WORKKIT_URL" DECISIONS.md; then
  sed -i "s#WORKKIT_URL#$kit_url#" DECISIONS.md
fi

echo
echo "== 끝. 지금 상태"
git status -s
echo
echo "다음: 에디터에서 $kit_name/EXAM.md 를 열고 1단계 체크박스부터"
