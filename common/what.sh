#!/usr/bin/env bash
# =============================================================================
# sqlite-inspect — SQLite database schema inspector
# Author: github.com/jblarson
# License: MIT
# =============================================================================
# Usage: sqlite-inspect <path/to/database.sqlite>
# =============================================================================

set -euo pipefail

# ── ANSI color / style palette ───────────────────────────────────────────────
RESET='\033[0m'
BOLD='\033[1m'
DIM='\033[2m'
ITALIC='\033[3m'
UNDERLINE='\033[4m'

BLACK='\033[0;30m'
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[0;37m'

BRIGHT_BLACK='\033[0;90m'
BRIGHT_RED='\033[0;91m'
BRIGHT_GREEN='\033[0;92m'
BRIGHT_YELLOW='\033[0;93m'
BRIGHT_BLUE='\033[0;94m'
BRIGHT_MAGENTA='\033[0;95m'
BRIGHT_CYAN='\033[0;96m'
BRIGHT_WHITE='\033[0;97m'

BG_BLACK='\033[40m'
BG_BLUE='\033[44m'
BG_CYAN='\033[46m'

# ── Terminal width helper ─────────────────────────────────────────────────────
term_width() {
  local w
  w=$(tput cols 2>/dev/null || echo 80)
  echo "$w"
}

# ── Drawing helpers ───────────────────────────────────────────────────────────
repeat_char() {
  # repeat_char <char> <count>
  local char="$1"
  local count="$2"
  printf '%*s' "$count" '' | tr ' ' "$char"
}

rule() {
  # rule [char] [color]
  local char="${1:-─}"
  local color="${2:-$BRIGHT_BLACK}"
  local w
  w=$(term_width)
  printf "${color}"
  repeat_char "$char" "$w"
  printf "${RESET}\n"
}

thin_rule() {
  rule "─" "$BRIGHT_BLACK"
}

thick_rule() {
  rule "═" "$BRIGHT_BLUE"
}

# ── Usage / error helpers ─────────────────────────────────────────────────────
usage() {
  printf "\n"
  printf "  ${BOLD}${BRIGHT_CYAN}USAGE${RESET}\n"
  printf "      ${BRIGHT_WHITE}sqlite-inspect${RESET} ${YELLOW}<database-path>${RESET}\n"
  printf "\n"
  printf "  ${BOLD}${BRIGHT_CYAN}ARGUMENTS${RESET}\n"
  printf "      ${YELLOW}<database-path>${RESET}   Path to the SQLite database file (required)\n"
  printf "\n"
  printf "  ${BOLD}${BRIGHT_CYAN}EXAMPLES${RESET}\n"
  printf "      ${DIM}sqlite-inspect ./data/app.db${RESET}\n"
  printf "      ${DIM}sqlite-inspect /var/lib/myapp/production.sqlite${RESET}\n"
  printf "\n"
}

die() {
  printf "\n  ${BOLD}${BRIGHT_RED}✗ ERROR${RESET}  %s\n" "$1" >&2
  printf "\n" >&2
  usage >&2
  exit 1
}

warn() {
  printf "  ${BOLD}${YELLOW}⚠ WARN${RESET}   %s\n" "$1"
}

info() {
  printf "  ${DIM}${BRIGHT_BLACK}→${RESET} %s\n" "$1"
}

# ── Dependency check ──────────────────────────────────────────────────────────
check_dependencies() {
  local missing=0

  for cmd in sqlite3 stat wc awk; do
    if ! command -v "$cmd" &>/dev/null; then
      warn "Missing dependency: ${BOLD}$cmd${RESET}"
      missing=$((missing + 1))
    fi
  done

  if [[ $missing -gt 0 ]]; then
    die "$missing required tool(s) not found. Please install them before continuing."
  fi
}

# ── Formatting helpers ────────────────────────────────────────────────────────
human_bytes() {
  local bytes="$1"
  if   [[ $bytes -ge 1073741824 ]]; then awk "BEGIN{printf \"%.2f GiB\", $bytes/1073741824}"
  elif [[ $bytes -ge 1048576 ]];    then awk "BEGIN{printf \"%.2f MiB\", $bytes/1048576}"
  elif [[ $bytes -ge 1024 ]];       then awk "BEGIN{printf \"%.2f KiB\", $bytes/1024}"
  else echo "${bytes} B"
  fi
}

pad_right() {
  # pad_right <string> <width>
  printf "%-${2}s" "$1"
}

# ── Header banner ─────────────────────────────────────────────────────────────
print_banner() {
  local db_path="$1"
  local db_name
  db_name=$(basename "$db_path")
  local w
  w=$(term_width)

  printf "\n"
  thick_rule

  # Title line
  local title=" ◈  SQLite Inspector"
  local version="v1.1.0 "
  printf "${BG_BLACK}${BOLD}${BRIGHT_CYAN}%-*s${BRIGHT_BLACK}%s${RESET}\n" \
    "$((w - ${#version}))" "$title" "$version"

  thick_rule
  printf "\n"

  # DB identity block
  printf "  ${BOLD}${BRIGHT_WHITE}DATABASE${RESET}    ${YELLOW}%s${RESET}\n" "$db_name"
  printf "  ${BOLD}${BRIGHT_WHITE}PATH    ${RESET}    ${DIM}%s${RESET}\n" "$(realpath "$db_path")"

  # File size
  local raw_size
  raw_size=$(stat -c%s "$db_path" 2>/dev/null || stat -f%z "$db_path" 2>/dev/null || echo 0)
  local human_size
  human_size=$(human_bytes "$raw_size")
  printf "  ${BOLD}${BRIGHT_WHITE}SIZE    ${RESET}    ${BRIGHT_GREEN}%s${RESET}  ${BRIGHT_BLACK}(%s bytes)${RESET}\n" \
    "$human_size" "$raw_size"

  # SQLite library version
  local sqlite_ver
  sqlite_ver=$(sqlite3 --version 2>/dev/null | awk '{print $1}')
  printf "  ${BOLD}${BRIGHT_WHITE}ENGINE  ${RESET}    SQLite ${BRIGHT_MAGENTA}%s${RESET}\n" "$sqlite_ver"

  # Page size & page count
  local page_size page_count
  page_size=$(sqlite3 "$db_path" "PRAGMA page_size;" 2>/dev/null || echo "?")
  page_count=$(sqlite3 "$db_path" "PRAGMA page_count;" 2>/dev/null || echo "?")
  printf "  ${BOLD}${BRIGHT_WHITE}PAGES   ${RESET}    ${page_count} pages × ${page_size} bytes/page\n"

  # Journal mode & WAL status
  local journal_mode
  journal_mode=$(sqlite3 "$db_path" "PRAGMA journal_mode;" 2>/dev/null || echo "?")
  printf "  ${BOLD}${BRIGHT_WHITE}JOURNAL ${RESET}    ${BRIGHT_CYAN}%s${RESET}\n" "$(echo "$journal_mode" | tr '[:lower:]' '[:upper:]')"

  # Encoding
  local encoding
  encoding=$(sqlite3 "$db_path" "PRAGMA encoding;" 2>/dev/null || echo "?")
  printf "  ${BOLD}${BRIGHT_WHITE}ENCODING${RESET}    %s\n" "$encoding"

  # Auto-vacuum
  local autovacuum
  autovacuum=$(sqlite3 "$db_path" "PRAGMA auto_vacuum;" 2>/dev/null || echo "?")
  local av_label
  case "$autovacuum" in
    0) av_label="NONE" ;;
    1) av_label="FULL" ;;
    2) av_label="INCREMENTAL" ;;
    *) av_label="$autovacuum" ;;
  esac
  printf "  ${BOLD}${BRIGHT_WHITE}VACUUM  ${RESET}    %s\n" "$av_label"

  # Foreign keys pragma
  local fk_enabled
  fk_enabled=$(sqlite3 "$db_path" "PRAGMA foreign_keys;" 2>/dev/null || echo "?")
  local fk_label
  [[ "$fk_enabled" == "1" ]] && fk_label="${BRIGHT_GREEN}ON${RESET}" || fk_label="${BRIGHT_RED}OFF${RESET}"
  printf "  ${BOLD}${BRIGHT_WHITE}FK ENFC ${RESET}    ${fk_label}\n"

  printf "\n"
  thin_rule
}

# ── Table list summary ────────────────────────────────────────────────────────
print_table_list() {
  local db_path="$1"
  local -a tables=("${@:2}")
  local count="${#tables[@]}"

  printf "\n"
  printf "  ${BOLD}${BRIGHT_WHITE}TABLES${RESET}  ${BRIGHT_BLACK}(${count} found)${RESET}\n"
  printf "\n"

  local i=1
  for tbl in "${tables[@]}"; do
    local row_count
    row_count=$(sqlite3 "$db_path" "SELECT COUNT(*) FROM \"${tbl}\";" 2>/dev/null || echo "?")
    printf "  ${BRIGHT_BLACK}%3d${RESET}  ${BOLD}${BRIGHT_CYAN}%s${RESET}  ${BRIGHT_BLACK}(%s rows)${RESET}\n" \
      "$i" "$tbl" "$row_count"
    i=$((i + 1))
  done

  printf "\n"
  thin_rule
}

# ── Per-table detail ──────────────────────────────────────────────────────────
type_color() {
  local affinity
  affinity=$(echo "$1" | tr '[:lower:]' '[:upper:]')
  case "$affinity" in
    *INT*)                    echo -n "$BRIGHT_YELLOW" ;;
    *REAL*|*FLOAT*|*DOUBLE*|*NUMERIC*|*DECIMAL*) echo -n "$BRIGHT_MAGENTA" ;;
    *TEXT*|*CHAR*|*CLOB*)     echo -n "$BRIGHT_GREEN" ;;
    *BLOB*)                   echo -n "$BRIGHT_CYAN" ;;
    *BOOL*)                   echo -n "$BRIGHT_BLUE" ;;
    *DATE*|*TIME*)            echo -n "$BRIGHT_RED" ;;
    "")                       echo -n "$DIM" ;;
    *)                        echo -n "$WHITE" ;;
  esac
}

# ── Fill-rate ASCII bar ───────────────────────────────────────────────────────
# fill_bar <pct_integer_0_100> <bar_width>
# Renders a proportional bar with color gradient:
#   0–49  → red    50–79 → yellow    80–99 → cyan    100 → green
fill_bar() {
  local pct="$1"
  local width="${2:-20}"

  local filled
  filled=$(awk "BEGIN{printf \"%d\", ($pct * $width) / 100}")
  local empty=$(( width - filled ))

  # Color by fill level
  local bar_color
  if   [[ $pct -eq 100 ]];  then bar_color="$BRIGHT_GREEN"
  elif [[ $pct -ge 80  ]];  then bar_color="$BRIGHT_CYAN"
  elif [[ $pct -ge 50  ]];  then bar_color="$BRIGHT_YELLOW"
  else                            bar_color="$BRIGHT_RED"
  fi

  local pct_label
  pct_label=$(printf "%3d%%" "$pct")

  printf "${bar_color}"
  [[ $filled -gt 0 ]] && repeat_char "█" "$filled"
  printf "${BRIGHT_BLACK}"
  [[ $empty  -gt 0 ]] && repeat_char "░" "$empty"
  printf "${RESET} ${bar_color}%s${RESET}" "$pct_label"
}

# ── Table statistics (fill-rate truth table) ──────────────────────────────────
# One full table scan per table — single SQL projection of all COUNT(col) calls.
# Complexity: O(rows × cols) time, O(cols) space — one row returned per table.
print_table_stats() {
  local db_path="$1"
  local tbl="$2"

  # Fetch column names
  local col_data
  col_data=$(sqlite3 "$db_path" "PRAGMA table_info(\"${tbl}\");" 2>/dev/null)
  [[ -z "$col_data" ]] && return

  # Build column name array
  local -a col_names=()
  while IFS='|' read -r _cid name _type _nn _dflt _pk; do
    col_names+=("$name")
  done <<< "$col_data"

  local ncols="${#col_names[@]}"
  [[ $ncols -eq 0 ]] && return

  # ── Build single-scan SQL ──────────────────────────────────────────────────
  # SELECT COUNT(*), COUNT("col1"), COUNT("col2"), ... FROM "tbl"
  # COUNT(*) counts all rows; COUNT(col) skips NULLs — ANSI standard.
  local select_parts="COUNT(*)"
  for col in "${col_names[@]}"; do
    select_parts+=", COUNT(\"${col}\")"
  done

  local query="SELECT ${select_parts} FROM \"${tbl}\";"

  local result
  result=$(sqlite3 "$db_path" "$query" 2>/dev/null)
  [[ -z "$result" ]] && return

  # Parse pipe-delimited result into array
  IFS='|' read -r -a counts <<< "$result"

  local total_rows="${counts[0]}"

  printf "  ${BOLD}${UNDERLINE}${BRIGHT_WHITE}FILL RATE${RESET}  "
  printf "${BRIGHT_BLACK}(${total_rows} rows × ${ncols} columns — single scan)${RESET}\n"
  printf "\n"

  # ── Column header ──────────────────────────────────────────────────────────
  local BAR_W=24
  printf "  ${DIM}%-28s  %8s  %8s  %8s  %-${BAR_W}s${RESET}\n" \
    "COLUMN" "TOTAL" "PRESENT" "NULL" "FILL RATE"
  printf "  "
  repeat_char "─" "$(($(term_width) - 4))"
  printf "\n"

  # ── Per-column rows ────────────────────────────────────────────────────────
  local i
  for (( i=0; i<ncols; i++ )); do
    local col="${col_names[$i]}"
    local present="${counts[$((i + 1))]}"   # offset by 1 due to COUNT(*)
    local null_count=$(( total_rows - present ))

    # Fill percentage — guard against zero-row tables
    local pct=0
    if [[ $total_rows -gt 0 ]]; then
      pct=$(awk "BEGIN{printf \"%d\", ($present / $total_rows) * 100}")
    fi

    # Null count color
    local null_color
    [[ $null_count -gt 0 ]] && null_color="$BRIGHT_RED" || null_color="$BRIGHT_BLACK"

    printf "  ${BOLD}${BRIGHT_WHITE}%-28s${RESET}  " "$col"   # column name
    printf "${BRIGHT_BLACK}%8s${RESET}  " "$total_rows"   # total
    printf "${BRIGHT_GREEN}%8s${RESET}  " "$present"       # present
    printf "${null_color}%8s${RESET}  "  "$null_count"     # null count
    fill_bar "$pct" "$BAR_W"
    printf "\n"
  done

  # ── Table-level summary line ───────────────────────────────────────────────
  printf "\n"

  if [[ $total_rows -gt 0 ]]; then
    # Total cells and total present across all columns
    local total_cells=$(( total_rows * ncols ))
    local total_present=0
    for (( i=1; i<=ncols; i++ )); do
      total_present=$(( total_present + counts[i] ))
    done
    local total_null=$(( total_cells - total_present ))
    local overall_pct
    overall_pct=$(awk "BEGIN{printf \"%d\", ($total_present / $total_cells) * 100}")

    printf "  ${DIM}overall  "
    printf "${BRIGHT_BLACK}%8s cells  " "$total_cells"
    printf "${BRIGHT_GREEN}%8s present  " "$total_present"
    printf "${BRIGHT_RED}%8s null${RESET}  " "$total_null"
    fill_bar "$overall_pct" "$BAR_W"
    printf "\n"
  else
    printf "  ${DIM}${BRIGHT_BLACK}(empty table — no fill data)${RESET}\n"
  fi

  printf "\n"
}

print_table_detail() {
  local db_path="$1"
  local tbl="$2"
  local idx="$3"
  local total="$4"

  printf "\n"

  # Table header
  local row_count
  row_count=$(sqlite3 "$db_path" "SELECT COUNT(*) FROM \"${tbl}\";" 2>/dev/null || echo "?")
  local sql_def
  sql_def=$(sqlite3 "$db_path" \
    "SELECT sql FROM sqlite_master WHERE type='table' AND name='${tbl}';" 2>/dev/null || echo "")

  printf "  ${BOLD}${BG_BLACK}${BRIGHT_BLUE} TABLE ${RESET}  ${BOLD}${BRIGHT_WHITE}%s${RESET}  ${BRIGHT_BLACK}[%d/%d]${RESET}  ${BRIGHT_BLACK}%s rows${RESET}\n" \
    "$tbl" "$idx" "$total" "$row_count"

  printf "\n"

  # ── Column info via PRAGMA table_info ──────────────────────────────────────
  printf "  ${BOLD}${UNDERLINE}${BRIGHT_WHITE}COLUMNS${RESET}\n"
  printf "\n"

  # Header row
  printf "  ${DIM}%-4s  %-28s  %-20s  %-8s  %-20s  %-6s${RESET}\n" \
    "CID" "NAME" "TYPE" "NOT NULL" "DEFAULT" "PK"
  printf "  "
  repeat_char "─" "$(($(term_width) - 4))"
  printf "\n"

  local col_data
  col_data=$(sqlite3 "$db_path" "PRAGMA table_info(\"${tbl}\");" 2>/dev/null)

  if [[ -z "$col_data" ]]; then
    printf "  ${DIM}(no columns returned — virtual or shadow table?)${RESET}\n"
  else
    while IFS='|' read -r cid name type notnull dflt_value pk; do
      local tc
      tc=$(type_color "$type")

      # Not-null badge
      local nn_badge
      [[ "$notnull" == "1" ]] \
        && nn_badge="${BRIGHT_RED}NOT NULL${RESET}" \
        || nn_badge="${BRIGHT_BLACK}nullable${RESET}"

      # PK badge
      local pk_badge
      if [[ "$pk" != "0" && -n "$pk" ]]; then
        pk_badge="${BOLD}${BRIGHT_YELLOW}PK${pk}${RESET}"
      else
        pk_badge="${BRIGHT_BLACK} — ${RESET}"
      fi

      # Default value display
      local dflt_display
      if [[ -z "$dflt_value" ]]; then
        dflt_display="${BRIGHT_BLACK}NULL${RESET}"
      else
        dflt_display="${BRIGHT_CYAN}${dflt_value}${RESET}"
      fi

      # Type display (uppercase, colored)
      local type_display
      type_display="${tc}$(echo "$type" | tr '[:lower:]' '[:upper:]')${RESET}"

      printf "  ${BRIGHT_BLACK}%-4s${RESET}  ${BOLD}${BRIGHT_WHITE}%-28s${RESET}  %-20b  %-8b  %-20b  %-6b\n" \
        "$cid" "$name" "$type_display" "$nn_badge" "$dflt_display" "$pk_badge"

    done <<< "$col_data"
  fi

  printf "\n"

  # ── Fill-rate truth table ──────────────────────────────────────────────────
  print_table_stats "$db_path" "$tbl"

  # ── Indices ────────────────────────────────────────────────────────────────
  local index_list
  index_list=$(sqlite3 "$db_path" "PRAGMA index_list(\"${tbl}\");" 2>/dev/null)

  printf "  ${BOLD}${UNDERLINE}${BRIGHT_WHITE}INDICES${RESET}\n"
  printf "\n"

  if [[ -z "$index_list" ]]; then
    printf "  ${DIM}${BRIGHT_BLACK}none${RESET}\n"
  else
    printf "  ${DIM}%-4s  %-36s  %-10s  %-10s  %-8s${RESET}\n" \
      "SEQ" "INDEX NAME" "UNIQUE" "ORIGIN" "PARTIAL"
    printf "  "
    repeat_char "─" "$(($(term_width) - 4))"
    printf "\n"

    while IFS='|' read -r seq idx_name unique origin partial; do
      local uniq_badge
      [[ "$unique" == "1" ]] \
        && uniq_badge="${BRIGHT_GREEN}UNIQUE${RESET}" \
        || uniq_badge="${BRIGHT_BLACK}non-unique${RESET}"

      local origin_label
      case "$origin" in
        c) origin_label="${BRIGHT_CYAN}CREATE${RESET}" ;;
        u) origin_label="${BRIGHT_YELLOW}UNIQUE${RESET}" ;;
        pk) origin_label="${BOLD}${BRIGHT_YELLOW}PK${RESET}" ;;
        *) origin_label="${DIM}${origin}${RESET}" ;;
      esac

      local partial_badge
      [[ "$partial" == "1" ]] \
        && partial_badge="${BRIGHT_MAGENTA}partial${RESET}" \
        || partial_badge="${BRIGHT_BLACK} — ${RESET}"

      printf "  %-4s  ${BRIGHT_WHITE}%-36s${RESET}  %-8b  %-8b  %-6b\n" \
        "$seq" "$idx_name" "$uniq_badge" "$origin_label" "$partial_badge"

      # Show columns in this index
      local idx_cols
      idx_cols=$(sqlite3 "$db_path" "PRAGMA index_info(\"${idx_name}\");" 2>/dev/null)
      if [[ -n "$idx_cols" ]]; then
        local col_names=()
        while IFS='|' read -r _seqno _cid col_name; do
          col_names+=("$col_name")
        done <<< "$idx_cols"
        printf "  ${BRIGHT_BLACK}       ↳ columns: ${BRIGHT_CYAN}%s${RESET}\n" \
          "$(IFS=', '; echo "${col_names[*]}")"
      fi

    done <<< "$index_list"
  fi

  printf "\n"

  # ── Foreign keys ───────────────────────────────────────────────────────────
  local fk_list
  fk_list=$(sqlite3 "$db_path" "PRAGMA foreign_key_list(\"${tbl}\");" 2>/dev/null)

  printf "  ${BOLD}${UNDERLINE}${BRIGHT_WHITE}FOREIGN KEYS${RESET}\n"
  printf "\n"

  if [[ -z "$fk_list" ]]; then
    printf "  ${DIM}${BRIGHT_BLACK}none${RESET}\n"
  else
    printf "  ${DIM}%-4s  %-16s  %-28s  %-20s  %-14s  %-14s${RESET}\n" \
      "ID" "TABLE" "FROM → TO" "ON UPDATE" "ON DELETE" "MATCH"
    printf "  "
    repeat_char "─" "$(($(term_width) - 4))"
    printf "\n"

    while IFS='|' read -r fk_id seq ref_table from_col to_col on_update on_delete match; do
      printf "  %-4s  ${BRIGHT_CYAN}%-16s${RESET}  ${BRIGHT_WHITE}%-14s${RESET} ${BRIGHT_BLACK}→${RESET} ${BRIGHT_GREEN}%-12s${RESET}  ${YELLOW}%-14s${RESET}  ${YELLOW}%-14s${RESET}  %s\n" \
        "$fk_id" "$ref_table" "$from_col" "$to_col" "$on_update" "$on_delete" "$match"
    done <<< "$fk_list"
  fi

  printf "\n"

  # ── Triggers ───────────────────────────────────────────────────────────────
  local trigger_list
  trigger_list=$(sqlite3 "$db_path" \
    "SELECT name, tbl_name, sql FROM sqlite_master WHERE type='trigger' AND tbl_name='${tbl}';" \
    2>/dev/null)

  printf "  ${BOLD}${UNDERLINE}${BRIGHT_WHITE}TRIGGERS${RESET}\n"
  printf "\n"

  if [[ -z "$trigger_list" ]]; then
    printf "  ${DIM}${BRIGHT_BLACK}none${RESET}\n"
  else
    while IFS='|' read -r trg_name _tbl _sql; do
      printf "  ${BRIGHT_MAGENTA}⚡${RESET} ${BOLD}${BRIGHT_WHITE}%s${RESET}\n" "$trg_name"
    done <<< "$trigger_list"
  fi

  printf "\n"

  # ── CREATE TABLE DDL ───────────────────────────────────────────────────────
  if [[ -n "$sql_def" ]]; then
    printf "  ${BOLD}${UNDERLINE}${BRIGHT_WHITE}DDL${RESET}\n"
    printf "\n"
    while IFS= read -r line; do
      printf "  ${DIM}%s${RESET}\n" "$line"
    done <<< "$sql_def"
    printf "\n"
  fi

  thin_rule
}

# ── Views ─────────────────────────────────────────────────────────────────────
print_views() {
  local db_path="$1"

  local view_list
  view_list=$(sqlite3 "$db_path" \
    "SELECT name, sql FROM sqlite_master WHERE type='view' ORDER BY name;" 2>/dev/null)

  [[ -z "$view_list" ]] && return

  printf "\n"
  printf "  ${BOLD}${BRIGHT_WHITE}VIEWS${RESET}\n"
  printf "\n"

  while IFS='|' read -r view_name view_sql; do
    printf "  ${BRIGHT_BLUE}◇${RESET}  ${BOLD}${BRIGHT_WHITE}%s${RESET}\n" "$view_name"
    if [[ -n "$view_sql" ]]; then
      while IFS= read -r line; do
        printf "     ${DIM}%s${RESET}\n" "$line"
      done <<< "$view_sql"
    fi
    printf "\n"
  done <<< "$view_list"

  thin_rule
}

# ── Footer ────────────────────────────────────────────────────────────────────
print_footer() {
  local table_count="$1"
  local elapsed="$2"

  printf "\n"
  thick_rule
  printf "  ${BOLD}${BRIGHT_GREEN}✓ DONE${RESET}  "
  printf "${BRIGHT_WHITE}%d table(s)${RESET} inspected  " "$table_count"
  printf "${BRIGHT_BLACK}in ${elapsed}s${RESET}\n"
  thick_rule
  printf "\n"
}

# ── Main ──────────────────────────────────────────────────────────────────────
main() {
  check_dependencies

  # ── Argument validation ────────────────────────────────────────────────────
  if [[ $# -lt 1 ]]; then
    die "No database path provided."
  fi

  if [[ $# -gt 1 ]]; then
    die "Too many arguments. Expected exactly one: <database-path>."
  fi

  local db_path="$1"

  [[ -e "$db_path" ]]  || die "Path does not exist: ${db_path}"
  [[ -f "$db_path" ]]  || die "Path is not a regular file: ${db_path}"
  [[ -r "$db_path" ]]  || die "File is not readable (check permissions): ${db_path}"

  # Verify it's actually a SQLite file
  local magic
  magic=$(head -c 16 "$db_path" 2>/dev/null | strings 2>/dev/null | head -1 || true)
  if [[ "$magic" != "SQLite format 3" ]]; then
    warn "File header does not match 'SQLite format 3' — proceeding anyway."
  fi

  # ── Timer start ────────────────────────────────────────────────────────────
  local t_start
  t_start=$(date +%s%3N 2>/dev/null || date +%s)

  # ── Banner ─────────────────────────────────────────────────────────────────
  print_banner "$db_path"

  # ── Enumerate tables ───────────────────────────────────────────────────────
  local table_names_raw
  table_names_raw=$(sqlite3 "$db_path" \
    "SELECT name FROM sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%' ORDER BY name;" \
    2>/dev/null)

  if [[ -z "$table_names_raw" ]]; then
    printf "\n  ${DIM}${BRIGHT_BLACK}No user tables found in this database.${RESET}\n\n"
    print_views "$db_path"
    print_footer 0 "0.000"
    exit 0
  fi

  # Read into array
  mapfile -t tables <<< "$table_names_raw"
  local table_count="${#tables[@]}"

  # ── Table summary list ─────────────────────────────────────────────────────
  print_table_list "$db_path" "${tables[@]}"

  # ── Per-table detail ───────────────────────────────────────────────────────
  local i=1
  for tbl in "${tables[@]}"; do
    print_table_detail "$db_path" "$tbl" "$i" "$table_count"
    i=$((i + 1))
  done

  # ── Views ──────────────────────────────────────────────────────────────────
  print_views "$db_path"

  # ── Footer ─────────────────────────────────────────────────────────────────
  local t_end
  t_end=$(date +%s%3N 2>/dev/null || date +%s)
  local elapsed
  # Millisecond precision if available, else whole seconds
  if [[ ${#t_start} -gt 10 ]]; then
    elapsed=$(awk "BEGIN{printf \"%.3f\", ($t_end - $t_start)/1000}")
  else
    elapsed=$((t_end - t_start))
  fi

  print_footer "$table_count" "$elapsed"
}

main "$@"
