#!/usr/bin/env bash
# 공통 검사. 작업공간 루트에서:
#   bash work-kit/tools/check.sh        빠른 검사 (작업 단위가 끝날 때마다)
#   bash work-kit/tools/check.sh full   + 도커 빌드, checks/full/ (검증 단계와 제출 직전)
#
# 과제 고유 검증은 여기 적지 않는다. tests/ 나 checks/ 에 두면 자동으로 돈다.
#   checks/*.sh, checks/*.py        매번
#   checks/full/*.sh, *.py          full 일 때만 (도커 재시작 확인처럼 오래 걸리는 것)
# 테스트 명령을 직접 정하고 싶으면 notes/test_cmd.txt 에 한 줄로 적는다.

set -u
mode="${1:-quick}"
pass=0; warn=0; fail=0
lines=()

ok()   { pass=$((pass+1)); lines+=("PASS  $*"); }
wn()   { warn=$((warn+1)); lines+=("WARN  $*"); }
bad()  { fail=$((fail+1)); lines+=("FAIL  $*"); }

run_quiet() {  # 명령을 돌리고 마지막 15줄만 보여준다
  local label="$1"; shift
  local out
  out="$("$@" 2>&1)"; local code=$?
  echo "---- $label (exit $code)"
  echo "$out" | tail -15
  return $code
}

if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  echo "git 저장소가 아니야. 작업공간 루트에서 실행하거나 setup.sh를 먼저 돌려."
  exit 2
fi

# 제출물 목록 (제공 파일이어도 내가 채워야 하는 양식 파일은 바뀌는 게 정상)
deliverables=()
if [ -s notes/deliverables.txt ]; then
  while IFS= read -r f; do
    f="${f%%#*}"; f="$(echo "$f" | xargs)"
    [ -n "$f" ] && deliverables+=("$f")
  done < notes/deliverables.txt
fi
is_deliverable() { local x; for x in "${deliverables[@]+"${deliverables[@]}"}"; do [ "$x" = "$1" ] && return 0; done; return 1; }

# 1. 처음 받은 파일이 그대로인가 (제출물 목록에 있는 파일은 제외)
if [ -s notes/kit/provided.txt ] && [ -s notes/kit/provided_commit.txt ]; then
  base="$(cat notes/kit/provided_commit.txt)"
  changed=()
  while IFS= read -r f; do
    [ -z "$f" ] && continue
    is_deliverable "$f" && continue
    if [ ! -e "$f" ]; then changed+=("$f(삭제됨)")
    elif ! git diff --quiet "$base" -- "$f" 2>/dev/null; then changed+=("$f"); fi
  done < notes/kit/provided.txt
  if [ ${#changed[@]} -eq 0 ]; then ok "제공 파일 그대로 ($(wc -l < notes/kit/provided.txt | tr -d ' ')개)"
  else
    bad "제공 파일이 바뀜: ${changed[*]:0:5}"
    lines+=("      내가 채우라고 받은 양식 파일이면 정상이다 → notes/deliverables.txt 에 그 파일 이름을 한 줄 추가")
    lines+=("      과제 문서나 제공 데이터를 실수로 고친 거면 그때만 되돌린다: git checkout $base -- 파일이름")
  fi
else
  wn "notes/kit/provided.txt 없음. setup.sh를 돌렸는지 확인"
fi

# 2. 제출물이 있는가 (notes/deliverables.txt: 한 줄에 파일 하나)
if [ ${#deliverables[@]} -gt 0 ]; then
  missing=()
  for f in "${deliverables[@]}"; do
    [ -e "$f" ] || missing+=("$f")
  done
  if [ ${#missing[@]} -eq 0 ]; then ok "제출물 목록의 파일이 모두 있음"
  else wn "아직 없는 제출물: ${missing[*]}"; fi
else
  wn "notes/deliverables.txt 비어 있음. 과제가 요구한 제출 파일을 한 줄에 하나씩 적을 것"
fi

# 3. 비밀값
if git ls-files | grep -qE '(^|/)\.env$'; then bad ".env 파일이 git에 들어가 있음 (git rm --cached .env)"; fi
quote="[\"']"                                     # " 또는 '
value="[^\"'\$<{[:space:]][^\"'[:space:]]{5,}"     # 6글자 이상. $ < { 로 시작하면 자리표시(${X}, <키>)라 뺀다
skip=(':!work-kit' ':!*.example' ':!notes/*' ':!*.md')
hits="$({
  # a. SECRET_KEY = "abcd1234", "db.password": "..."
  #    타입이 붙은 설정도: secret_key: str = "changeme1"
  git grep --untracked -nIiE "(api[_.-]?key|secret|passw(or)?d|token|access[_.-]?key|private[_.-]?key)[A-Za-z0-9_.-]*${quote}?([[:space:]]*:[[:space:]]*[A-Za-z][A-Za-z0-9_.]*)?[[:space:]]*[:=][[:space:]]*${quote}${value}" -- . "${skip[@]}"
  # b. 환경변수 기본값: os.getenv("API_KEY", "dev-secret-123")
  git grep --untracked -nIE "${quote}[A-Z0-9_]*(KEY|SECRET|TOKEN|PASSWORD|PASSWD)[A-Z0-9_]*${quote}[[:space:]]*,[[:space:]]*${quote}${value}" -- . "${skip[@]}"
  #    JS 기본값: process.env.JWT_SECRET || "secret123"
  git grep --untracked -nIE "[A-Z0-9_]*(KEY|SECRET|TOKEN|PASSWORD|PASSWD)[A-Z0-9_]*[[:space:]]*(\\|\\||\\?\\?)[[:space:]]*${quote}${value}" -- . "${skip[@]}"
  # c. 스프링 기본값: @Value("${jwt.secret:mydefaultsecret}")
  git grep --untracked -nIiE '[$][{][A-Za-z0-9_.-]*(secret|password|token|key)[A-Za-z0-9_.-]*:[^{}$[:space:]]{6,}[}]' -- . "${skip[@]}"
  # d. 설정 파일의 따옴표 없는 값: jwt.secret=abcdef123 (password=${DB_PASSWORD} 는 아님)
  git grep --untracked -nIiE "(secret|passw(or)?d|token|api[_.-]?key|access[_.-]?key)[A-Za-z0-9_.-]*[[:space:]]*[:=][[:space:]]*[^\"'\$<{#[:space:]][^[:space:]]{5,}" \
    -- '*.properties' '*.yml' '*.yaml' '*.toml' '*.ini' '*.cfg' '*.conf' "${skip[@]}"
} 2>/dev/null | awk '!seen[$0]++' \
  | grep -vE "[:=,|?][[:space:]]*[\"']?https?://" \
  | grep -vE "[:=][[:space:]]*[0-9]+[[:space:]]*,?[[:space:]]*(#.*)?$" | head -8)"   # URL, 따옴표 없는 숫자(만료 시간 등)는 뺀다
if [ -n "$hits" ]; then
  wn "비밀값처럼 보이는 줄 (진짜 값이면 환경변수로):"
  while IFS= read -r h; do lines+=("      $h"); done <<< "$hits"
else ok "코드에 박힌 비밀값 패턴 없음"; fi

# 4. 테스트
test_cmd=""
if [ -s notes/test_cmd.txt ]; then test_cmd="$(head -1 notes/test_cmd.txt)"
elif [ -f package.json ] && grep -q '"test"' package.json; then test_cmd="npm test --silent"
elif [ -x ./gradlew ]; then test_cmd="./gradlew test -q"
elif [ -x ./mvnw ]; then test_cmd="./mvnw -q test"
elif [ -f go.mod ]; then test_cmd="go test ./..."
elif [ -d tests ] || ls test_*.py >/dev/null 2>&1; then
  if [ -x .venv/bin/python ]; then test_cmd=".venv/bin/python -m pytest -q"; else test_cmd="python3 -m pytest -q"; fi
fi
n_checks=0
if [ "$test_cmd" = "npm test --silent" ] && grep -q 'no test specified' package.json 2>/dev/null; then
  wn "package.json의 test 스크립트가 기본값(no test specified). 실제 테스트 명령을 notes/test_cmd.txt에 한 줄로"
elif [ -n "$test_cmd" ]; then
  n_checks=$((n_checks+1))
  test_out="$(bash -c "$test_cmd" 2>&1)"; test_code=$?
  echo "---- 테스트: $test_cmd (exit $test_code)"; echo "$test_out" | tail -15
  if [ $test_code -eq 0 ]; then ok "테스트 통과: $test_cmd"
  elif echo "$test_out" | grep -qiE "No module named pytest|command not found|not found: (npm|gradle|mvn|go)"; then
    bad "테스트 도구가 설치돼 있지 않음: $test_cmd (예: pip install pytest). 설치 후 다시"
  else bad "테스트 실패: $test_cmd"; fi
else
  # 루트에는 없지만 backend/ 같은 하위 폴더에 테스트가 있는 경우
  sub_test="$(find . -maxdepth 4 \( -path ./work-kit -o -path ./.git -o -name node_modules -o -name .venv \) -prune -o -type f \
    \( -name 'test_*.py' -o -name '*_test.py' -o -name '*.test.js' -o -name '*.test.ts' -o -name '*.spec.ts' -o -name '*Test.java' -o -name '*_test.go' \) \
    -print 2>/dev/null | LC_ALL=C sort | head -1)"
  if [ -n "$sub_test" ]; then
    wn "루트에서 테스트 실행 방법을 못 찾았는데 하위 폴더에 테스트 파일이 있음 (예: ${sub_test#./}). notes/test_cmd.txt에 실행 명령을 한 줄로 (예: cd backend && python3 -m pytest -q)"
  fi
fi

# 5. 과제 고유 검증 checks/
run_dir() {
  local d="$1"
  [ -d "$d" ] || return 0
  for c in "$d"/*.sh "$d"/*.py; do
    [ -e "$c" ] || continue
    n_checks=$((n_checks+1))
    case "$c" in
      *.sh) cmd=(bash "$c") ;;
      *.py) if [ -x .venv/bin/python ]; then cmd=(.venv/bin/python "$c"); else cmd=(python3 "$c"); fi ;;
    esac
    if run_quiet "검증: $c" "${cmd[@]}"; then ok "검증 통과: $c"; else bad "검증 실패: $c"; fi
  done
}
run_dir checks
[ "$mode" = "full" ] && run_dir checks/full

if [ "$n_checks" -eq 0 ]; then
  wn "요구사항 검증이 하나도 없음. tests/ 나 checks/ 에 요구를 확인하는 검증을 만들 것"
fi

# 5-1. 요구 번호(R1, R2 …)마다 검증이 있는가: tests/, checks/ 의 파일 이름이나 내용에 R 번호가 있는지
#      대문자 R만 센다. 앞에 영문·숫자가 붙거나 뒤에 숫자가 붙으면 다른 것으로 본다
#      (test_R2_total, # R2:, R2_check.sh 는 R2. user4.json, R20, PR2 는 R2·R4가 아님)
if [ -s notes/PLAN.md ]; then
  reqs="$(LC_ALL=C grep -oE '(^|[^A-Za-z0-9])R[0-9]+' notes/PLAN.md | LC_ALL=C grep -oE 'R[0-9]+' | sort -uV | tr '\n' ' ')"
  if [ -n "$reqs" ]; then
    uncovered=()
    for r in $reqs; do
      re="(^|[^A-Za-z0-9])$r([^0-9]|\$)"
      found=""
      for d in tests checks; do
        [ -d "$d" ] || continue
        if find "$d" \( -name __pycache__ -o -name .pytest_cache \) -prune -o -type f -print 2>/dev/null | LC_ALL=C grep -qE "$re" \
           || LC_ALL=C grep -rqIE --exclude-dir=__pycache__ --exclude-dir=.pytest_cache -- "$re" "$d" 2>/dev/null; then found=1; break; fi
      done
      [ -n "$found" ] || uncovered+=("$r")
    done
    total=$(echo $reqs | wc -w | tr -d ' ')
    if [ ${#uncovered[@]} -eq 0 ]; then ok "요구 $total개 모두 검증에 R 번호가 걸려 있음"
    else wn "검증에 R 번호가 안 보이는 요구: ${uncovered[*]} (전체 $total개. 테스트 이름이나 주석에 R 번호를 넣었는지, 검증이 없는지 확인)"; fi
  fi
fi

# 6. full: 도커 빌드
if [ "$mode" = "full" ]; then
  if [ -f Dockerfile ]; then
    if command -v docker >/dev/null 2>&1; then
      if run_quiet "docker build" docker build -q -t workkit-check .; then ok "도커 빌드 성공"; else bad "도커 빌드 실패"; fi
    else wn "docker 명령 없음. 빌드 확인 못 함"; fi
  else
    wn "Dockerfile 없음 (과제가 요구하지 않으면 무시)"
  fi
fi

# 결과
echo
echo "==== check ($mode)  PASS $pass / WARN $warn / FAIL $fail"
printf '%s\n' "${lines[@]}"

mkdir -p notes/kit
echo "$(date '+%Y-%m-%d %H:%M') $mode PASS $pass WARN $warn FAIL $fail $(git rev-parse --short HEAD 2>/dev/null)" >> notes/kit/check_log.txt

[ "$fail" -eq 0 ]
