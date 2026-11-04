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
        self.lo = None
        self.hi = None

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
        key = float(v) if k in ("int", "float") else v
        if k in ("int", "float", "date", "datetime", "time"):
            if self.lo is None or key < self.lo:
                self.lo = key
            if self.hi is None or key > self.hi:
                self.hi = key

    def kind(self):
        if not self.kinds:
            return "비어 있음"
        main = max(self.kinds, key=self.kinds.get)
        if main == "int" and "float" in self.kinds:
            main = "float"
        mixed = len(self.kinds) > 1 and not set(self.kinds) <= {"int", "float"}
        return main + (" (형식 섞임: " + ", ".join(sorted(self.kinds)) + ")" if mixed else "")

    def distinct(self):
        return f">{DISTINCT_CAP}" if self.capped else str(len(self.values))


def profile(path):
    with open(path, encoding="utf-8-sig", newline="") as f:
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
    return {"path": path, "rows": rows, "cols": cols, "bad_width": bad_width}


def fmt(x):
    if isinstance(x, float) and x.is_integer():
        return str(int(x))
    return str(x)


def main(argv):
    out_path = None
    if "--out" in argv:
        i = argv.index("--out")
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

    results = [profile(f) for f in files]
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

    for r in results:
        out.append(f"## {r['path'].name}  ({r['rows']:,}행)")
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
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
