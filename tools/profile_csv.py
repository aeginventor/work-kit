"""CSV 폴더 한 번에 훑어보기 (표준 라이브러리만 사용)

사용:
    python3 work-kit/tools/profile_csv.py 데이터폴더 [--out notes/DATA_PROFILE.md]
    python3 work-kit/tools/profile_csv.py a.csv b.csv

파일마다 행 수, 열, 빈 값, 값 종류 수, 최소·최대, 예시 값, 짐작한 형식을 보여준다.
키로 쓸 만한 열(빈 값 없고 모두 다름)과, 다른 파일의 키와 값이 겹치는 열(연결 후보)도 찾는다.
결과는 짐작이다. 한 행의 뜻과 업무 의미는 문서와 담당자에게 확인한다.
"""
import csv
import re
import sys
from pathlib import Path

DISTINCT_CAP = 50000   # 열마다 기억할 값 종류 상한 (메모리 보호)
SAMPLE_N = 3

INT_RE = re.compile(r"^-?\d+$")
FLOAT_RE = re.compile(r"^-?\d+\.\d+$")
DATE_RE = re.compile(r"^\d{4}-\d{2}-\d{2}$")
DATETIME_RE = re.compile(r"^\d{4}-\d{2}-\d{2}[T ]\d{2}:\d{2}")
TIME_RE = re.compile(r"^\d{1,2}:\d{2}(:\d{2})?$")
BOOL_SET = {"true", "false", "y", "n", "yes", "no", "0", "1"}
# 최소·최대는 서로 비교되는 형식끼리 따로 잰다 (숫자와 날짜 글자는 크기 비교가 안 됨)
FAMILY = {"int": "num", "float": "num", "date": "date", "datetime": "date", "time": "time"}


def guess_kind(value):
    if INT_RE.match(value):
        return "int"
    if FLOAT_RE.match(value):
        return "float"
    if DATETIME_RE.match(value):
        return "datetime"
    if DATE_RE.match(value):
        return "date"
    if TIME_RE.match(value):
        return "time"
    if value.lower() in BOOL_SET:
        return "bool"
    return "text"


class Col:
    def __init__(self, name):
        self.name = name
        self.filled = 0
        self.empty = 0
        self.values = set()
        self.capped = False
        self.kinds = {}
        self.samples = []
        self.ranges = {}  # FAMILY 값마다 [최소, 최대]

    def add(self, raw):
        v = (raw or "").strip()
        if v == "":
            self.empty += 1
            return
        self.filled += 1
        if not self.capped:
            self.values.add(v)
            if len(self.values) > DISTINCT_CAP:
                self.capped = True
        if len(self.samples) < SAMPLE_N and v not in self.samples:
            self.samples.append(v)
        k = guess_kind(v)
        self.kinds[k] = self.kinds.get(k, 0) + 1
        fam = FAMILY.get(k)
        if fam:
            key = float(v) if fam == "num" else v
            lohi = self.ranges.setdefault(fam, [key, key])
            if key < lohi[0]:
                lohi[0] = key
            if key > lohi[1]:
                lohi[1] = key

    def main_kind(self):
        main = max(self.kinds, key=self.kinds.get)
        if main == "int" and "float" in self.kinds:
            main = "float"
        return main

    def kind(self):
        if not self.kinds:
            return "비어 있음"
        main = self.main_kind()
        mixed = len(self.kinds) > 1 and not set(self.kinds) <= {"int", "float"}
        return main + (" (형식 섞임: " + ", ".join(sorted(self.kinds)) + ")" if mixed else "")

    # 최소 ~ 최대는 그 열의 주된 형식 쪽 값으로만 보여준다
    def _lohi(self):
        if not self.kinds:
            return None
        return self.ranges.get(FAMILY.get(self.main_kind()))

    @property
    def lo(self):
        r = self._lohi()
        return r[0] if r else None

    @property
    def hi(self):
        r = self._lohi()
        return r[1] if r else None

    def distinct(self):
        return f">{DISTINCT_CAP}" if self.capped else str(len(self.values))


def profile(path):
    # 엑셀에서 저장한 한글 CSV는 cp949인 경우가 많다.
    # 안 맞는 글자가 파일 중간에 나올 수 있어서 인코딩을 바꿀 때마다 처음부터 다시 읽는다
    for enc in ("utf-8-sig", "cp949"):
        try:
            return scan(path, enc)
        except UnicodeDecodeError:
            pass
    r = scan(path, "utf-8-sig", errors="replace")
    r["encoding"] = None  # 어느 쪽으로도 안 읽혀서 깨진 글자를 대신 넣고 읽음
    return r


def scan(path, encoding, errors="strict"):
    with open(path, encoding=encoding, errors=errors, newline="") as f:
        reader = csv.reader(f)
        header = next(reader, [])
        cols = [Col(h.strip()) for h in header]
        rows = 0
        bad_width = 0
        for row in reader:
            rows += 1
            if len(row) != len(cols):
                bad_width += 1
            for c, v in zip(cols, row):
                c.add(v)
    return {"path": path, "rows": rows, "cols": cols, "bad_width": bad_width, "encoding": encoding}


def fmt(x):
    if isinstance(x, float) and x.is_integer():
        return str(int(x))
    return str(x)


def main(argv):
    csv.field_size_limit(2**31 - 1)  # 아주 긴 글이 든 칸도 읽는다 (기본 한도는 131072자)
    out_path = None
    if "--out" in argv:
        i = argv.index("--out")
        if i + 1 >= len(argv):
            print(__doc__)
            print("--out 뒤에 저장할 파일 경로가 없어. 예: --out notes/DATA_PROFILE.md")
            return 1
        out_path = argv[i + 1]
        argv = argv[:i] + argv[i + 2:]
    if not argv:
        print(__doc__)
        return 1
    files = []
    for a in argv:
        p = Path(a)
        files += sorted(p.rglob("*.csv")) if p.is_dir() else [p]
    if not files:
        print("CSV 파일을 못 찾았어:", argv)
        return 1

    results = []
    failed = []  # (경로, 이유). 한 파일이 이상해도 나머지는 계속 본다
    for f in files:
        try:
            results.append(profile(f))
        except Exception as e:
            why = f"{type(e).__name__}: {e}"
            failed.append((f, why))
            print(f"읽기 실패: {f} ({why})", file=sys.stderr)

    out = ["# 데이터 프로파일 (자동 생성, 짐작이 섞여 있음)", ""]
    out.append("| 파일 | 행 수 | 열 수 | 키 후보 |")
    out.append("| --- | --- | --- | --- |")
    keys = {}  # (file, col) -> value set
    for r in results:
        cand = [c.name for c in r["cols"] if c.empty == 0 and not c.capped and c.filled == r["rows"] and len(c.values) == r["rows"] and r["rows"] > 0 and not c.kind().startswith("float")]
        for c in r["cols"]:
            if c.name in cand:
                keys[(r["path"].name, c.name)] = c.values
        out.append(f"| {r['path']} | {r['rows']:,} | {len(r['cols'])} | {', '.join(cand) or '없음 (여러 열을 묶어야 할 수 있음)'} |")
    out.append("")
    if failed:
        out.append("## 읽지 못한 파일")
        out.append("")
        out += [f"- {p} ({why})" for p, why in failed]
        out.append("")

    for r in results:
        out.append(f"## {r['path'].name}  ({r['rows']:,}행)")
        enc = r["encoding"]
        if enc is None:
            out.append("- 인코딩: 알 수 없음 (깨진 글자로 읽음, 원본 확인 필요)")
        elif enc != "utf-8-sig":
            out.append(f'- 인코딩: {enc} (코드에서 읽을 때 encoding="{enc}" 필요)')
        if r["bad_width"]:
            out.append(f"- 주의: 열 개수가 헤더와 다른 행 {r['bad_width']}개")
        out.append("")
        out.append("| 열 | 형식(짐작) | 빈 값 | 값 종류 | 최소 ~ 최대 | 예시 |")
        out.append("| --- | --- | --- | --- | --- | --- |")
        for c in r["cols"]:
            rng = f"{fmt(c.lo)} ~ {fmt(c.hi)}" if c.lo is not None else ""
            ex = " / ".join(s[:30] for s in c.samples)
            out.append(f"| {c.name} | {c.kind()} | {c.empty} | {c.distinct()} | {rng} | {ex} |")
        notes = []
        for c in r["cols"]:
            if r["rows"] >= 20 and not c.capped and 1 < len(c.values) <= 12:
                notes.append(f"{c.name}: 값이 {len(c.values)}종류뿐 ({', '.join(sorted(c.values)[:12])})")
            if c.empty and c.filled:
                notes.append(f"{c.name}: 빈 값 {c.empty}개. 빈 값의 뜻을 확인")
        if notes:
            out.append("")
            out.append("- " + "\n- ".join(notes))
        out.append("")

    # 연결 후보: 다른 파일 키 열과 값이 90% 이상 겹치는 열
    links = []
    for r in results:
        for c in r["cols"]:
            if c.capped or not c.values:
                continue
            for (kf, kc), kv in keys.items():
                if kf == r["path"].name and kc == c.name:
                    continue
                if kf == r["path"].name:
                    continue
                hit = len(c.values & kv)
                total = len(c.values)
                if hit and hit / total >= 0.9:
                    line = f"- {r['path'].name}.{c.name} → {kf}.{kc}  (값 {total}종 중 {hit}종이 존재)"
                    if hit < total:
                        miss = sorted(c.values - kv)[:5]
                        line += f"  ← 없는 값 {total - hit}종: {', '.join(miss)}"
                    links.append(line)
    out.append("## 연결 후보 (다른 파일의 키와 값이 겹치는 열)")
    out.append("")
    out += links or ["- 찾지 못함. 열 이름이 같은 열끼리 직접 확인"]
    out.append("")
    out.append("## 사람이 확인할 것")
    out.append("- 파일마다 '한 행 = 무엇 하나'를 한 문장으로 말할 수 있나")
    out.append("- 값 종류가 적은 숫자 열이 상세 행마다 반복되는 상위 합계는 아닌가 (그러면 합산 금지)")
    out.append("- 날짜·시각 열이 업무 기준일인지 실제 발생 시각인지, 시간대와 날짜 경계는 어떤지")
    out.append("- 연결 후보 중 겹침이 100%가 아닌 것: 없는 ID 참조인지, 의도된 차이인지")

    text = "\n".join(out) + "\n"
    if out_path:
        Path(out_path).parent.mkdir(parents=True, exist_ok=True)
        Path(out_path).write_text(text, encoding="utf-8")
        print(f"저장: {out_path}  (파일 {len(results)}개)")
    else:
        print(text)
    return 0 if results else 1


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
