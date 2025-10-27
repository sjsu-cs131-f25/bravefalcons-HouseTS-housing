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
TAB="$(printf '\t')"   # BSD/macOS-safe tab delimiter for sort -t

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


# =============================
# Sprint 4 — AWK Quality Filters (Jaafar)
# =============================
IN_NORM="out/normalized.tsv"
OUT_VALID="out/clean_valid.tsv"
OUT_INV="out/invalid_counts.tsv"

[ -r "$IN_NORM" ] || err "missing $IN_NORM (run normalization first)"
log "[Sprint4] Filtering invalid rows…"

read HN IDX_DATE IDX_ZIP IDX_MSA IDX_PRICE <<EOF
$(awk -F'\t' '
  function L(x,i,c,s){for(i=1;i<=length(x);i++){c=substr(x,i,1);s=s ((c>="A"&&c<="Z")?tolower(c):c)};return s}
  NR==1{
    hn=NF; date=zip=msa=price=0
    for(i=1;i<=NF;i++){
      h=L($i)
      if(!date && h ~ /(^|_)(date|yearmonth|period|month)($|_)/) date=i
      if(!zip  && h ~ /(^|_)(zip|zipcode|zip_code|postal)($|_)/) zip=i
      if(!msa  && h ~ /(msa|cbsa|metro|metropolitan|region|market|city(_full)?)/) msa=i
      if(!price && h ~ /(median.*(sale)?(_)?price|median.*value|home.*value|house.*price|price_index|^hpi$|(^|_)price($|_)|(^|_)value($|_))/) price=i
    }
    printf "%d %d %d %d %d\n", hn, (date?date:0), (zip?zip:0), (msa?msa:0), (price?price:0)
    exit
  }' "$IN_NORM")
EOF

# Fallback
if [ "$IDX_PRICE" -eq 0 ]; then
  IDX_PRICE="$(awk -F'\t' -v HN="$HN" '
    function isn(x){ return x ~ /^([+-]?[0-9]+(\.[0-9]+)?|NA)$/ }
    NR==1{ next }
    NR<=200{ for(i=1;i<=HN;i++) if($i!="NA" && isn($i)) numc[i]++ }
    END{ best=0;bestc=-1; for(i=1;i<=HN;i++) if(numc[i]>bestc){bestc=numc[i];best=i} print (best?best:0) }
  ' "$IN_NORM")"
fi

tmp_valid="$(mktemp)"; trap 'rm -f "$tmp_valid"' EXIT

awk -v OFS="\t" -v HN="$HN" -v C_DATE="$IDX_DATE" -v C_ZIP="$IDX_ZIP" -v C_MSA="$IDX_MSA" -v C_PRICE="$IDX_PRICE" '
  function isnum(x){ return (x ~ /^-?[0-9]+(\.[0-9]+)?$/) }
  function lower(s,  i,c,t){ for(i=1;i<=length(s);i++){ c=substr(s,i,1); t=t ((c>="A"&&c<="Z")?tolower(c):c) } return t }
  NR==1{ header=$0; print header > "'"$tmp_valid"'"; next }
  {
    bad=0
    if (NF!=HN){ rc["R1_token_count"]++; bad=1 }
    if(!bad){
      # R6
      for(i=1;i<=NF;i++){ t=lower($i); if(t=="test"||t=="dummy"||t=="placeholder"){ rc["R6_anti_test_rows"]++; bad=1; break } }
      # R2
      if(!bad && C_ZIP>0){ z=$C_ZIP; if(z=="NA"||z==""||!(z ~ /^[0-9]{5}(-[0-9]{4})?$/)){ rc["R2_zip_valid"]++; bad=1 } }
      # R3
      if(!bad && C_DATE>0){
        d=$C_DATE
        if(d=="NA"||d==""){ rc["R3_date_format"]++; bad=1 }
        else if(!(d ~ /^[0-9]{4}(-|\/)(0[1-9]|1[0-2])((-|\/)(0[1-9]|[12][0-9]|3[01]))?$/)){ rc["R3_date_format"]++; bad=1 }
        else { split(d,a,/(-|\/)/); yr=a[1]+0; if(yr<1990||yr>2100){ rc["R3_date_format"]++; bad=1 } }
      }
      # R4
      if(!bad && C_PRICE>0){ p=$C_PRICE; if(p=="NA"||p==""||!isnum(p)||p<0){ rc["R4_price_ge0_numeric"]++; bad=1 } }
      # R5
      if(!bad && C_MSA>0){ m=$C_MSA; if(m=="NA"||m==""){ rc["R5_msa_not_NA"]++; bad=1 } }
    }
    if(bad){ invalid_total++; next }
    valid_total++; print $0 > "'"$tmp_valid"'"
  }
  END{
    print "rule","count" > "'"$OUT_INV"'"
    for(k in rc) printf "%s\t%d\n", k, cnt=(k in rc?rc[k]:0) >> "'"$OUT_INV"'"
    printf "%s\t%d\n","TOTAL_invalid_rows", invalid_total >> "'"$OUT_INV"'"
    printf "%s\t%d\n","TOTAL_valid_rows",   valid_total   >> "'"$OUT_INV"'"
  }
' "$IN_NORM"

# Deterministic sorts (no pipes that can SIGPIPE under set -e -o pipefail)
{ head -n 1 "$tmp_valid"; tail -n +2 "$tmp_valid" | sort; } > "$OUT_VALID"
{ head -n 1 "$OUT_INV"; tail -n +2 "$OUT_INV" | sort -t "$TAB" -k1,1 -k2,2nr; } > "$OUT_INV.sorted" && mv "$OUT_INV.sorted" "$OUT_INV"

log "[Sprint4] Wrote $OUT_VALID and $OUT_INV"

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
  ' "$NORM_TSV" | sort -t "$TAB" -k2,2nr -k1,1 > "$out"
  log "Freq -> $out"
}

# Frequency tables for each chosen column
for COL in ${FREQ_COLS//,/ }; do
  [ -n "$COL" ] || continue
  SAFE="$(printf '%s' "$COL" | sed -E 's#[ /]+#_#g')"
  make_freq "$COL" "$OUTDIR/freq_${SAFE}.tsv"
done

# ---- Top-N generation (no SIGPIPE) ----
TOP_IDX="$(col_index "$TOP_COL" || true)"
if [ -n "$TOP_IDX" ]; then
  TOP_SORTED="$OUTDIR/_top_all.tsv"
  { head -n1 "$NORM_TSV"; tail -n +2 "$NORM_TSV" | sort -t "$TAB" -k"$TOP_IDX","$TOP_IDX"nr -k1,1; } > "$TOP_SORTED"
  head -n $((TOPN+1)) "$TOP_SORTED" > "$OUTDIR/top_$(printf '%s' "$TOP_COL" | sed -E 's#[[:space:]]+#_#g')_${TOPN}.tsv"
  rm -f "$TOP_SORTED"
  log "TopN -> $OUTDIR/top_$(printf '%s' "$TOP_COL" | sed -E 's#[[:space:]]+#_#g')_${TOPN}.tsv"
else
  log "WARN: Top-N column not found: $TOP_COL"
fi

# Skinny table
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

# Final “wrote” summary
printf 'Wrote:\n  - %s\n' \
  "$OUTDIR/sample_before.txt" \
  "$OUTDIR/sample_after.txt" \
  "$OUTDIR/normalized.tsv" \
  "$OUTDIR/clean_valid.tsv" \
  "$OUTDIR/invalid_counts.tsv" \
  "$OUTDIR/skinny.tsv" \
  $(printf "%s\n" "$OUTDIR"/freq_*.tsv 2>/dev/null || true) \
  $(printf "%s\n" "$OUTDIR"/top_*.tsv 2>/dev/null || true) \
  | sed '/^$/d'


