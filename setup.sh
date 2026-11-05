#!/usr/bin/env bash
# work-kit 시작 스크립트
# 과제 README가 보이는 위치(작업공간 루트)에서: bash work-kit/setup.sh
# 이미 있는 기록 파일은 덮어쓰지 않는다. 두 번 실행해도 결과가 같다.

set -u

kit_dir="$(cd "$(dirname "$0")" && pwd -P)"
kit_name="$(basename "$kit_dir")"
root="$(pwd -P)"

say() { echo "[setup] $*"; }

if [ "$kit_dir" = "$root" ]; then
  echo "work-kit 폴더 안이 아니라 과제 루트에서 실행해줘: bash $kit_name/setup.sh"
  exit 1
fi

# 안전장치 1: 과제 README가 안 보이면 멈춘다
if ! ls -1 | grep -qi '^readme' && [ "${FORCE:-}" != "1" ]; then
  echo "여기($root)에 README가 없어. 과제 문서 후보:"
  find . -maxdepth 3 \( -iname 'readme*' -o -iname '*.md' \) -not -path './.*' -not -path "./$kit_name/*" 2>/dev/null | head -10
  echo "README가 있는 폴더가 과제 루트다. 그 폴더로 work-kit을 옮겨서 다시 (폴더 이름은 위 목록에서):"
  echo "  cd 그폴더 && mv \"$kit_dir\" . && bash $kit_name/setup.sh"
  echo "여기가 맞으면: FORCE=1 bash $kit_name/setup.sh"
  exit 1
fi

# 안전장치 2: 다른 git 저장소의 하위 폴더면 멈춘다
top="$(git rev-parse --show-toplevel 2>/dev/null || true)"
if [ -n "$top" ] && [ "$(cd "$top" && pwd -P)" != "$root" ]; then
  echo "여기는 $top 저장소의 하위 폴더야. 과제 루트가 $top 이면 거기로 cd 해서 다시 실행해."
  echo "정말 여기가 맞으면: FORCE=1 bash $kit_name/setup.sh"
  [ "${FORCE:-}" = "1" ] || exit 1
fi

say "작업공간: $root"

# 1. git 준비
if [ ! -d .git ]; then
  git init -q && say "git 저장소를 새로 만들었어"
else
  say "기존 git 저장소를 그대로 써"
fi
[ -n "$(git config user.name 2>/dev/null)" ] || git config user.name "San"
[ -n "$(git config user.email 2>/dev/null)" ] || git config user.email "san@example.com"

# 2. git에서 뺄 것: work-kit, 루트의 숨김 파일(홈 디렉터리 환경 파일), 빌드 산출물, 비밀값
mkdir -p .git/info && touch .git/info/exclude
for pattern in "/$kit_name/" "/.*" "!/.gitignore" "!/.gitattributes" "!/.dockerignore" "!/.env.example" "!/.github/" \
               ".env" "node_modules/" ".venv/" "venv/" "__pycache__/" ".pytest_cache/" "build/" "target/" ".gradle/"; do
  grep -qxF -- "$pattern" .git/info/exclude || echo "$pattern" >> .git/info/exclude
done
say "git에서 제외: $kit_name/, 루트 숨김 파일(.bashrc 등), node_modules, .venv, .env 등"

# 3. 처음 받은 상태 커밋 (커밋이 하나도 없을 때만)
if ! git rev-parse HEAD >/dev/null 2>&1; then
  git add -A
  if git commit -qm "chore: 제공된 초기 상태"; then
    say "처음 받은 상태를 커밋했어"
  else
    say "초기 커밋 실패. git status 확인 필요"
  fi
else
  say "기존 커밋이 있어서 초기 커밋은 건너뜀"
fi

mkdir -p notes notes/kit

# 처음 받은 파일 목록 (check.sh가 이 파일들이 바뀌지 않았는지 본다)
if [ ! -s notes/kit/provided.txt ]; then
  first="$(git rev-list --max-parents=0 HEAD 2>/dev/null | tail -1)"
  if [ -n "$first" ]; then
    git -c core.quotepath=false ls-tree -r --name-only "$first" | grep -v -x 'AGENTS.md' > notes/kit/provided.txt
    echo "$first" > notes/kit/provided_commit.txt
    say "제공 파일 $(wc -l < notes/kit/provided.txt | tr -d ' ')개를 notes/kit/provided.txt에 기록했어"
  fi
fi

# 4-0. Codex는 AGENTS.override.md가 있으면 그걸 AGENTS.md보다 우선한다. 시험이 그 파일을 줬다면 알린다
if [ -e AGENTS.override.md ]; then
  say "주의: AGENTS.override.md가 있어. Codex가 내 AGENTS.md보다 이걸 먼저 따른다. cat AGENTS.override.md 로 내용 확인"
fi

# 4. AGENTS.md: 시험 원본은 보존하고, 내 규칙의 "시험 제공 규칙" 칸에 원본을 그대로 넣는다
make_agents() {  # $1: 시험 원본 경로 (없으면 빈 값)
  local src="$1" tmp
  tmp="$(mktemp)"
  awk -v src="$src" '
    index($0, "(시험 제공 규칙 자리)") {
      if (src == "") { print "- 없음 (시험이 준 AGENTS.md가 없었다)"; next }
      print "<!-- 시험 원본 시작: notes/from-exam/AGENTS.md 그대로. 제목만 두 단계 내림 -->"
      while ((getline line < src) > 0) { sub(/\r$/, "", line); if (line ~ /^#/) line = "##" line; print line }
      print "<!-- 시험 원본 끝 -->"
      next
    }
    { print }' "$kit_dir/AGENTS.md" > "$tmp" && mv "$tmp" AGENTS.md
}
if [ -e AGENTS.md ] && ! grep -q '<!-- work-kit -->' AGENTS.md; then
  if [ ! -e notes/from-exam/AGENTS.md ]; then
    mkdir -p notes/from-exam
    cp AGENTS.md notes/from-exam/AGENTS.md
    say "시험이 준 AGENTS.md를 notes/from-exam/AGENTS.md로 보존했어"
  fi
  make_agents notes/from-exam/AGENTS.md
  say "AGENTS.md를 내 작업 규칙으로 바꾸고, 맨 위 '시험 제공 규칙' 칸에 시험 원본을 그대로 넣었어 (시험 규칙이 우선)"
elif [ ! -e AGENTS.md ]; then
  if [ -e notes/from-exam/AGENTS.md ]; then make_agents notes/from-exam/AGENTS.md; else make_agents ""; fi
  say "AGENTS.md를 만들었어"
else
  say "AGENTS.md는 이미 내 규칙이야. 건너뜀"
fi

# 5. 기록 양식
for f in DECISIONS.md HANDOFF.md DATA.md UNITS.md ASK.md; do
  if [ -e "notes/$f" ]; then
    say "notes/$f 이미 있음. 덮어쓰지 않음"
  else
    cp "$kit_dir/templates/$f" "notes/$f"
    say "notes/$f 만들었어"
  fi
done
if [ ! -e notes/prompt.md ]; then
  cp "$kit_dir/templates/prompt.md" notes/prompt.md
  say "notes/prompt.md에 첫 프롬프트를 넣어 뒀어"
fi
[ -e notes/memo.md ] || printf '# 메모 (내 메모. 떠오른 질문, 확인할 것)\n\n' > notes/memo.md

# 6. 준비 커밋
git add -A
if git diff --cached --quiet; then
  say "새로 커밋할 변경 없음"
else
  git commit -qm "chore: 작업 규칙과 기록 양식 준비 (work-kit)" && say "준비 상태를 커밋했어"
fi

echo
echo "== 끝. 지금 상태"
git status -s | head -20
echo
echo "다음: 에디터에서 $kit_name/steps/01_start.md 의 3번부터"
