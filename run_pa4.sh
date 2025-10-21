#!/usr/bin/env bash
set -euo pipefail

OUTDIR="out"
LOGDIR="logs"
mkdir -p "$OUTDIR" "$LOGDIR"

log(){ printf '%s\n' "$*" | tee -a "$LOGDIR/last_run.log" >/dev/null; }
err(){ printf 'ERROR: %s\n' "$*" >&2; exit 1; }

RAW_PATH="${1:-}"; [[ -n "${RAW_PATH}" ]] || err "usage: ./run_pa4.sh <file_or_folder>"
[[ -e "$RAW_PATH" ]] || err "input not found: $RAW_PATH"

chmod -R g+rX "$RAW_PATH" 2>/dev/null || true
export LC_ALL=C

req_tools="sed awk sort head tail tee grep"
for t in $req_tools; do command -v "$t" >/dev/null || err "missing required tool: $t"; done

pick_csv() {
  p="$1"
  if [ -d "$p" ]; then
    best=""; score=-1
    set +e
    for f in "$p"/*.csv; do
      [ -f "$f" ] || continue
      hdr="$(head -n1 "$f" || true)"
      s=0
      printf '%s' "$hdr" | grep -Eqi 'zip|zipcode|postal' && s=$((s+2))
      printf '%s' "$hdr" | grep -Eqi 'date|month|year' && s=$((s+2))
      printf '%s' "$hdr" | grep -Eqi 'msa|cbsa|metro|city_full|city|region|market' && s=$((s+1))
      printf '%s' "$hdr" | grep -Eqi 'price|value|index|hpi' && s=$((s+1))
      if [ "$s" -gt "$score" ]; then score="$s"; best="$f"; fi
    done
    set -e
    if [ -z "$best" ]; then
      best="$(ls -S "$p"/*.csv 2>/dev/null | head -n1 || true)"
    fi
    printf '%s\n' "$best"
  else
    printf '%s\n' "$p"
  fi
}

INPUT_CSV="$(pick_csv "$RAW_PATH")"
[ -n "$INPUT_CSV" ] && [ -f "$INPUT_CSV" ] || err "no CSV found at: $RAW_PATH"
[ -r "$INPUT_CSV" ] || err "input not readable: $INPUT_CSV"
log "Input: $INPUT_CSV"

TOPN="${TOPN:-10}"
TOP_COL="${TOP_COL:-}"
FREQ_COLS="${FREQ_COLS:-}"
SKINNY_COLS="${SKINNY_COLS:-}"

TMP1="$OUTDIR/_stage1.csv"
TMP2="$OUTDIR/_stage2.tsv"
NORM_TSV="$OUTDIR/normalized.tsv"

# ============================================================
# SECTION 1: DATA CLEANING & NORMALIZATION (SED + AWK)
# ============================================================

head -n 20 "$INPUT_CSV" > "$OUTDIR/sample_before.txt"

sed -E $'
  s/\r$//;
  1s/^\xEF\xBB\xBF//;
  s/^[[:space:]]+//; s/[[:space:]]+$//;
  s/[“”]/"/g; s/[‘’]/'\''/g;
  s/[][(){}]//g;
' "$INPUT_CSV" > "$TMP1"

awk -v OFS="\t" -F',' '
  BEGIN{ FPAT="([^,]*|(\"([^\"]|\"\")*\"))" }
  NR==1{
    HN=NF
    for(i=1;i<=NF;i++){
      gsub(/^"|"$/,"",$i); gsub(/[[:space:]]+/, " ", $i); gsub(/^[[:space:]]+|[[:space:]]+$/, "", $i)
      hdr[i]=$i
    }
    for(i=1;i<=HN;i++){ printf "%s%s", hdr[i], (i<HN?OFS:"\n") }
    next
  }
  {
    if(NF<HN){ for(i=NF+1;i<=HN;i++) $i="" }
    if(NF>HN){ NF=HN }
    for(i=1;i<=HN;i++){
      gsub(/^"|"$/,"",$i); gsub(/""/,"\"",$i)
      gsub(/[[:space:]]+/, " ", $i); gsub(/^[[:space:]]+|[[:space:]]+$/, "", $i)
      tl=$i; gsub(/[[:space:]]/,"",tl); tl=tolower(tl)
      if(tl=="" || tl=="na" || tl=="n/a" || tl=="null" || tl=="none" || tl=="nan"){ $i="NA" }
      else if($i ~ /^[+-]?([0-9]{1,3}(,[0-9]{3})+)(\.[0-9]+)?$/){ gsub(/,/, "", $i) }
      out[i]=$i
    }
    for(i=1;i<=HN;i++){ printf "%s%s", out[i], (i<HN?OFS:"\n") }
  }
' "$TMP1" > "$TMP2"

head -n 20 "$TMP2" > "$OUTDIR/sample_after.txt"
mv "$TMP2" "$NORM_TSV"
rm -f "$TMP1"
log "Normalized -> $NORM_TSV"

# ============================================================
# SECTION 2: ANALYSIS (EDA + OUTPUT GENERATION)
# ============================================================

col_index() {
  awk -v name="$1" -F'\t' 'NR==1{ for(i=1;i<=NF;i++) if(tolower($i)==tolower(name)){ print i; exit } }' "$NORM_TSV"
}

detect_cols() {
  awk -F'\t' '
    function L(x,i,c,s){for(i=1;i<=length(x);i++){c=substr(x,i,1);s=s ((c>="A"&&c<="Z")?tolower(c):c)};return s}
    NR==1{
      for(i=1;i<=NF;i++){
        h=L($i)
        if(!date && h ~ /(^|_)(date|month|yearmonth|period)($|_)/) date=$i
        if(!zip  && h ~ /(^|_)(zip|zipcode|zip_code|postal)($|_)/) zip=$i
        if(!msa  && h ~ /(msa|cbsa|metro|metropolitan|region|market|city_full|city)/) msa=$i
        if(!price && h ~ /(median.*sale.*price|median.*price|median.*value|home.*value|house.*price|price_index|hpi|value|price)/) price=$i
      }
      printf "%s|%s|%s|%s\n", date, zip, msa, price
    }
  ' "$NORM_TSV"
}

IFS='|' read -r DET_DATE DET_ZIP DET_MSA DET_PRICE <<EOF
$(detect_cols)
EOF

: "${TOP_COL:=${DET_PRICE:-median_sale_price}}"

if [ -z "$FREQ_COLS" ]; then
  if [ -n "${DET_MSA:-}" ] && [ -n "${DET_ZIP:-}" ]; then
    FREQ_COLS="${DET_MSA},${DET_ZIP}"
  else
    FREQ_COLS="$(
      awk -F'\t' '
        function isn(x){ return x ~ /^([+-]?[0-9]+(\.[0-9]+)?|NA)$/ }
        NR==1{ for(i=1;i<=NF;i++) h[i]=$i; next }
        NR<=200{ for(i=1;i<=NF;i++) if(!isn($i)) cat[i]=1 }
        END{ c=0; for(i=1;i<=NF;i++) if(cat[i]){ printf "%s%s",(c++?",":""),h[i]; if(c==2) break } }
      ' "$NORM_TSV"
    )"
  fi
fi

if [ -z "$SKINNY_COLS" ]; then
  skinny=""
  [ -n "${DET_DATE:-}" ] && skinny="${skinny}${DET_DATE},"
  [ -n "${DET_MSA:-}"  ] && skinny="${skinny}${DET_MSA},"
  [ -n "${DET_ZIP:-}"  ] && skinny="${skinny}${DET_ZIP},"
  [ -n "${TOP_COL:-}"  ] && skinny="${skinny}${TOP_COL},"
  skinny="${skinny%,}"
  if [ -z "$skinny" ]; then
    skinny="$(head -n1 "$NORM_TSV" | awk -F'\t' '{for(i=1;i<=NF && i<=5;i++) printf "%s%s",$i,(i<5?",":"") }')"
  fi
  SKINNY_COLS="$skinny"
fi

make_freq() {
  col="$1"; out="$2"
  idx="$(col_index "$col" || true)"
  if [ -z "$idx" ]; then log "WARN: freq column not found: $col"; return 0; fi
  awk -F'\t' -v C="$idx" '
    NR>1 && $C!="NA" && $C!=""{ cnt[$C]++ }
    END{ print "value\tcount"; for(k in cnt) printf "%s\t%d\n", k, cnt[k] }
  ' "$NORM_TSV" | sort -t"$'\t'" -k2,2nr -k1,1 > "$out"
  log "Freq -> $out"
}

IFS=',' read -r F1 F2 REST <<<"$FREQ_COLS"
for COL in $FREQ_COLS; do
  [ -n "$COL" ] || continue
  SAFE="$(printf '%s' "$COL" | sed -E 's#[ /]+#_#g')"
  make_freq "$COL" "$OUTDIR/freq_${SAFE}.tsv"
done

TOP_IDX="$(col_index "$TOP_COL" || true)"
if [ -n "$TOP_IDX" ]; then
  { head -n1 "$NORM_TSV"; tail -n +2 "$NORM_TSV" | sort -t"$'\t'" -k"$TOP_IDX","$TOP_IDX"nr -k1,1; } \
  | head -n $((TOPN+1)) > "$OUTDIR/top_$(printf '%s' "$TOP_COL" | sed -E 's#[[:space:]]+#_#g')_${TOPN}.tsv"
  log "TopN -> $OUTDIR/top_$(printf '%s' "$TOP_COL" | sed -E 's#[[:space:]]+#_#g')_${TOPN}.tsv"
else
  log "WARN: Top-N column not found: $TOP_COL"
fi

PROJ_IDX=""
IFS=',' read -ra WANT <<<"$SKINNY_COLS"
for nm in "${WANT[@]}"; do
  idx="$(col_index "$nm" || true)"
  [ -n "$idx" ] && PROJ_IDX="${PROJ_IDX}${idx},"
done
PROJ_IDX="${PROJ_IDX%,}"

if [ -n "$PROJ_IDX" ]; then
  awk -F'\t' -v list="$PROJ_IDX" '
    BEGIN{ n=split(list, idxs, ",") }
    { out=$idxs[1]; for(j=2;j<=n;j++) out=out "\t" $idxs[j]; print out }
  ' "$NORM_TSV" > "$OUTDIR/skinny.tsv"
else
  cut -f1-5 "$NORM_TSV" > "$OUTDIR/skinny.tsv"
fi
log "Skinny -> $OUTDIR/skinny.tsv"

printf 'Wrote:\n  - %s\n' \
  "$OUTDIR/sample_before.txt" \
  "$OUTDIR/sample_after.txt" \
  "$OUTDIR/normalized.tsv" \
  "$OUTDIR/skinny.tsv" \
  $(printf "%s\n" "$OUTDIR"/freq_*.tsv 2>/dev/null || true) \
  $(printf "%s\n" "$OUTDIR"/top_*.tsv 2>/dev/null || true) \
  | sed '/^$/d'
