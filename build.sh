#!/bin/bash
set -euo pipefail

OUT="script.sql"

normalize_all() {
  for d in tables views types packages jobs; do
    [[ -d "$d" ]] || continue
    find "$d" -type f -name "*.sql" -print0 \
    | xargs -0 -I{} perl -0777 -i -pe 's/[ \t\r\n]*\z/\n/s' "{}"
  done
}

append_dir() {
  local dir="$1"; shift || true
  [[ -d "$dir" ]] || return 0
  find "$dir" -type f -name "*.sql" "$@" -print \
  | LC_ALL=C sort \
  | while IFS= read -r f; do
      cat "$f" >> "$OUT"
      printf '\n' >> "$OUT"
    done
}

: > "$OUT"
normalize_all

append_dir "tables"
append_dir "views"
append_dir "types"

if [[ -f "packages/T24_UTILS_PKG.sql" ]]; then
  cat "packages/T24_UTILS_PKG.sql" >> "$OUT"
  printf '\n' >> "$OUT"
fi

append_dir "packages" ! -name "T24_UTILS_PKG.sql"
append_dir "jobs"

perl -0777 -pe 's/\n+\z/\n/' -i -- "$OUT"
