#!/usr/bin/env bash

PY_SCRIPT="modify_def.py"
INPUT_DEF="input_tr.def"
OUT_DIR="tr_small_rects"
OUTPUT_PREFIX="small_rects"             # Output file prefix
NUM_VARIANTS=${1:-20}                   # Can override by command line
MIN_RECTS=3
MAX_RECTS=4

# Cutout size constraints used for this benchmark
# Large
# MIN_DEPTH=300000
# MAX_DEPTH=600000
# Medium
# MIN_DEPTH=150000
# MAX_DEPTH=300000
# Small
 MIN_DEPTH=50000
 MAX_DEPTH=200000
MAX_TRIES_PER_RECT=80
DEBUG=${DEBUG:-0}
MAX_ASPECT=5
CORNER_MARGIN_PCT=30

ASPECT_CENTER=${ASPECT_CENTER:-2.5}
ASPECT_MIN=$(awk -v c="$ASPECT_CENTER" 'BEGIN{printf "%.6f", c/2}')
ASPECT_MAX=$(awk -v c="$ASPECT_CENTER" 'BEGIN{printf "%.6f", c*2}')

mkdir -p "$OUT_DIR"

die_block=$(awk '/DIEAREA/{flag=1} flag{print} /;/{flag=0}' "$INPUT_DEF" | tr -d '\n')
read x0 y0 x1 y1 < <(echo "$die_block" | sed -E 's/.*\(\s*([0-9]+)\s+([0-9]+)\s*\)\s*\(\s*([0-9]+)\s+([0-9]+)\s*\).*/\1 \2 \3 \4/')
orig_width=$(( x1 - x0 ))
orig_height=$(( y1 - y0 ))

success=0; fail=0; fallback_count=0

log_debug() { [ "$DEBUG" -eq 1 ] && echo "$@"; }

cutout_conflict() {
  local ax1=$1 ay1=$2 ax2=$3 ay2=$4
  local bx1=$5 by1=$6 bx2=$7 by2=$8
  local buffer=0

  [ $ax1 -gt $ax2 ] && { local t=$ax1; ax1=$ax2; ax2=$t; }
  [ $ay1 -gt $ay2 ] && { local t=$ay1; ay1=$ay2; ay2=$t; }
  [ $bx1 -gt $bx2 ] && { local t=$bx1; bx1=$bx2; bx2=$t; }
  [ $by1 -gt $by2 ] && { local t=$by1; by1=$by2; by2=$t; }

  ax1=$((ax1 - buffer)); ay1=$((ay1 - buffer))
  ax2=$((ax2 + buffer)); ay2=$((ay2 + buffer))
  bx1=$((bx1 - buffer)); by1=$((by1 - buffer))
  bx2=$((bx2 + buffer)); by2=$((by2 + buffer))

  if [ $ax2 -gt $bx1 ] && [ $ax1 -lt $bx2 ] && [ $ay2 -gt $by1 ] && [ $ay1 -lt $by2 ]; then
    return 0
  fi
  return 1
}

for i in $(seq 1 $NUM_VARIANTS); do
  seed=$((1000 + i))
  rects=$(( ((seed * 7) % (MAX_RECTS - MIN_RECTS + 1)) + MIN_RECTS ))
  coords=()
  log_debug "Variant $i: attempting to place $rects rect(s)"

  for j in $(seq 1 $rects); do
    placed=0; tries=0
    log_debug "Variant $i: placing rect $j (already have $((${#coords[@]}/4)) rects)"

    while [ $tries -lt $MAX_TRIES_PER_RECT ]; do
      tries=$((tries + 1))
      s=$((seed + j*37 + tries*13))
      log_debug "  Try $tries for rect $j: seed=$s"

      maxd=$MAX_DEPTH
      [ "$maxd" -gt $((orig_width/2)) ] && maxd=$((orig_width/2))
      [ "$maxd" -gt $((orig_height/2)) ] && maxd=$((orig_height/2))
      if [ "$maxd" -lt "$MIN_DEPTH" ]; then
        depth=$MIN_DEPTH
      else
        depth=$(( MIN_DEPTH + ((s*97 + j*53) % (maxd - MIN_DEPTH + 1)) ))
      fi
      [ $depth -lt 2 ] && depth=2

  typ=$(python3 "$(dirname "$0")/rng_helper.py" --seed "${seed}_${j}_${tries}" --uniform 0 7)
  log_debug "    Selected placement type (from rng_helper): $typ"

      existing_count=$(( ${#coords[@]} / 4 ))
      adj_chance=$(( s % 100 ))
      adj_flag=0
      if [ $existing_count -gt 0 ] && [ $adj_chance -lt 30 ]; then
        adj_flag=1
        idx=$(( (s*3 + j + tries) % existing_count ))
        k=$(( idx * 4 ))
        ex1=${coords[k]}; ey1=${coords[k+1]}; ex2=${coords[k+2]}; ey2=${coords[k+3]}

        ex_min=$(( ex1 < ex2 ? ex1 : ex2 )); ex_max=$(( ex1 < ex2 ? ex2 : ex1 ))
        ey_min=$(( ey1 < ey2 ? ey1 : ey2 )); ey_max=$(( ey1 < ey2 ? ey2 : ey1 ))
        ex_span=$(( ex_max - ex_min )); ey_span=$(( ey_max - ey_min ))
        ex_cx=$(( (ex_min + ex_max) / 2 ))
        ey_cy=$(( (ey_min + ey_max) / 2 ))
        log_debug "    Adjacent-align attempt with existing rect #$((idx+1)), span=($ex_span,$ey_span) center=($ex_cx,$ey_cy)"
      fi

      case $typ in
        0)  # LEFT EDGE: vertical span varies; rectangle grows rightward
            corner_margin=$(( orig_height * CORNER_MARGIN_PCT / 100 ))
            [ $corner_margin -lt 2 ] && corner_margin=2
            max_span=$(( orig_height / 3 ))
            avail=$(( orig_height - 2*corner_margin ))
            [ $avail -lt $max_span ] && max_span=$avail

            min_span=$(( depth / 10 ))
            [ $min_span -lt 2 ] && min_span=2
            [ $max_span -lt $min_span ] && max_span=$min_span

            span_low=$(( (depth + 1) / 2 ))
            span_high=$(( depth * 2 ))
            [ $span_low -lt $min_span ] && span_low=$min_span
            [ $span_high -gt $max_span ] && span_high=$max_span
            if [ $span_low -gt $span_high ]; then span_low=$min_span; span_high=$max_span; fi

            if [ $adj_flag -eq 1 ]; then
              span=$ey_span
              [ $span -lt $span_low ] && span=$span_low
              [ $span -gt $span_high ] && span=$span_high
              center=$ey_cy
              if [ $center -lt $(( y0 + corner_margin + span/2 )) ]; then
                center=$(( y0 + corner_margin + span/2 ))
              fi
              if [ $center -gt $(( y1 - corner_margin - span/2 )) ]; then
                center=$(( y1 - corner_margin - span/2 ))
              fi
            else
              r=$(python3 "$(dirname "$0")/rng_helper.py" --seed "$((s+tries))" --mu "$ASPECT_CENTER" --sigma 0.30 --min "$ASPECT_MIN" --max "$ASPECT_MAX")
              span=$(awk -v d=$depth -v r=$r 'BEGIN{printf("%d", int(r*d + 0.5))}')
              if [ $span -lt $span_low ]; then span=$span_low; fi
              if [ $span -gt $span_high ]; then span=$span_high; fi

              start_min=$(( y0 + corner_margin ))
              start_max=$(( y1 - corner_margin - span ))
              if [ $start_max -lt $start_min ]; then
                start_y=$start_min
              else
                start_y=$(( start_min + ((s*97 + tries*17) % (start_max - start_min + 1)) ))
              fi
              center=$(( start_y + span/2 ))
            fi

            min_ar_span=$(( (depth + 1) / 2 ))
            max_ar_span=$(( depth * 2 ))
            [ $span -lt $min_ar_span ] && span=$min_ar_span
            [ $span -gt $max_ar_span ] && span=$max_ar_span
            min_depth_ar=$(( (span + 1) / 2 ))
            max_depth_ar=$(( span * 2 ))
            if [ $depth -lt $min_depth_ar ]; then depth=$min_depth_ar; fi
            if [ $depth -gt $max_depth_ar ]; then depth=$max_depth_ar; fi

            half=$(( span / 2 ))
            top=$(( center - half ))
            [ $top -lt $y0 ] && top=$y0
            bottom=$(( top + span ))
            [ $bottom -gt $y1 ] && { bottom=$y1; top=$(( bottom - span )); }

            edge_x=$x0
            edge_y=$top
            int_x=$(( edge_x + depth ))
            int_y=$bottom
            ;;

        1)  # RIGHT EDGE: vertical span varies; rectangle grows leftward
            corner_margin=$(( orig_height * CORNER_MARGIN_PCT / 100 ))
            [ $corner_margin -lt 2 ] && corner_margin=2
            max_span=$(( orig_height / 3 ))
            avail=$(( orig_height - 2*corner_margin ))
            [ $avail -lt $max_span ] && max_span=$avail

            min_span=$(( depth / 10 ))
            [ $min_span -lt 2 ] && min_span=2
            [ $max_span -lt $min_span ] && max_span=$min_span

            span_low=$(( (depth + 1) / 2 ))
            span_high=$(( depth * 2 ))
            [ $span_low -lt $min_span ] && span_low=$min_span
            [ $span_high -gt $max_span ] && span_high=$max_span
            if [ $span_low -gt $span_high ]; then span_low=$min_span; span_high=$max_span; fi

            if [ $adj_flag -eq 1 ]; then
              span=$ey_span
              [ $span -lt $span_low ] && span=$span_low
              [ $span -gt $span_high ] && span=$span_high
              center=$ey_cy
              if [ $center -lt $(( y0 + corner_margin + span/2 )) ]; then
                center=$(( y0 + corner_margin + span/2 ))
              fi
              if [ $center -gt $(( y1 - corner_margin - span/2 )) ]; then
                center=$(( y1 - corner_margin - span/2 ))
              fi
            else
              r=$(python3 "$(dirname "$0")/rng_helper.py" --seed "$((s+tries))" --mu "$ASPECT_CENTER" --sigma 0.30 --min "$ASPECT_MIN" --max "$ASPECT_MAX")
              span=$(awk -v d=$depth -v r=$r 'BEGIN{printf("%d", int(r*d + 0.5))}')
              if [ $span -lt $span_low ]; then span=$span_low; fi
              if [ $span -gt $span_high ]; then span=$span_high; fi

              start_min=$(( y0 + corner_margin ))
              start_max=$(( y1 - corner_margin - span ))
              if [ $start_max -lt $start_min ]; then
                start_y=$start_min
              else
                start_y=$(( start_min + ((s*59 + tries*23) % (start_max - start_min + 1)) ))
              fi
              center=$(( start_y + span/2 ))
            fi

            min_ar_span=$(( (depth + 1) / 2 ))
            max_ar_span=$(( depth * 2 ))
            [ $span -lt $min_ar_span ] && span=$min_ar_span
            [ $span -gt $max_ar_span ] && span=$max_ar_span
            min_depth_ar=$(( (span + 1) / 2 ))
            max_depth_ar=$(( span * 2 ))
            if [ $depth -lt $min_depth_ar ]; then depth=$min_depth_ar; fi
            if [ $depth -gt $max_depth_ar ]; then depth=$max_depth_ar; fi

            half=$(( span / 2 ))
            top=$(( center - half ))
            [ $top -lt $y0 ] && top=$y0
            bottom=$(( top + span ))
            [ $bottom -gt $y1 ] && { bottom=$y1; top=$(( bottom - span )); }

            edge_x=$x1
            edge_y=$top
            int_x=$(( edge_x - depth ))
            int_y=$bottom
            ;;

        2)  # BOTTOM EDGE: horizontal span varies; rectangle grows upward
            corner_margin=$(( orig_width * CORNER_MARGIN_PCT / 100 ))
            [ $corner_margin -lt 2 ] && corner_margin=2
            max_span=$(( orig_width / 3 ))
            avail=$(( orig_width - 2*corner_margin ))
            [ $avail -lt $max_span ] && max_span=$avail

            min_span=$(( depth / 10 ))
            [ $min_span -lt 2 ] && min_span=2
            [ $max_span -lt $min_span ] && max_span=$min_span

            span_low=$(( (depth + 1) / 2 ))
            span_high=$(( depth * 2 ))
            [ $span_low -lt $min_span ] && span_low=$min_span
            [ $span_high -gt $max_span ] && span_high=$max_span
            if [ $span_low -gt $span_high ]; then span_low=$min_span; span_high=$max_span; fi

            if [ $adj_flag -eq 1 ]; then
              span=$ex_span
              [ $span -lt $span_low ] && span=$span_low
              [ $span -gt $span_high ] && span=$span_high
              center=$ex_cx
              if [ $center -lt $(( x0 + corner_margin + span/2 )) ]; then
                center=$(( x0 + corner_margin + span/2 ))
              fi
              if [ $center -gt $(( x1 - corner_margin - span/2 )) ]; then
                center=$(( x1 - corner_margin - span/2 ))
              fi
            else
              r=$(python3 "$(dirname "$0")/rng_helper.py" --seed "$((s+tries))" --mu "$ASPECT_CENTER" --sigma 0.30 --min "$ASPECT_MIN" --max "$ASPECT_MAX")
              span=$(awk -v d=$depth -v r=$r 'BEGIN{printf("%d", int(r*d + 0.5))}')
              if [ $span -lt $span_low ]; then span=$span_low; fi
              if [ $span -gt $span_high ]; then span=$span_high; fi

              start_min=$(( x0 + corner_margin ))
              start_max=$(( x1 - corner_margin - span ))
              if [ $start_max -lt $start_min ]; then
                start_x=$start_min
              else
                start_x=$(( start_min + ((s*83 + tries*31) % (start_max - start_min + 1)) ))
              fi
              center=$(( start_x + span/2 ))
            fi

            min_ar_span=$(( (depth + 1) / 2 ))
            max_ar_span=$(( depth * 2 ))
            [ $span -lt $min_ar_span ] && span=$min_ar_span
            [ $span -gt $max_ar_span ] && span=$max_ar_span
            min_depth_ar=$(( (span + 1) / 2 ))
            max_depth_ar=$(( span * 2 ))
            if [ $depth -lt $min_depth_ar ]; then depth=$min_depth_ar; fi
            if [ $depth -gt $max_depth_ar ]; then depth=$max_depth_ar; fi

            half=$(( span / 2 ))
            left=$(( center - half ))
            [ $left -lt $x0 ] && left=$x0
            right=$(( left + span ))
            [ $right -gt $x1 ] && { right=$x1; left=$(( right - span )); }

            edge_y=$y0
            edge_x=$left
            int_x=$right
            int_y=$(( edge_y + depth ))
            ;;

        3)  # TOP EDGE: horizontal span varies; rectangle grows downward
            corner_margin=$(( orig_width * CORNER_MARGIN_PCT / 100 ))
            [ $corner_margin -lt 2 ] && corner_margin=2
            max_span=$(( orig_width / 3 ))
            avail=$(( orig_width - 2*corner_margin ))
            [ $avail -lt $max_span ] && max_span=$avail

            min_span=$(( depth / 10 ))
            [ $min_span -lt 2 ] && min_span=2
            [ $max_span -lt $min_span ] && max_span=$min_span

            span_low=$(( (depth + 1) / 2 ))
            span_high=$(( depth * 2 ))
            [ $span_low -lt $min_span ] && span_low=$min_span
            [ $span_high -gt $max_span ] && span_high=$max_span
            if [ $span_low -gt $span_high ]; then span_low=$min_span; span_high=$max_span; fi

            if [ $adj_flag -eq 1 ]; then
              span=$ex_span
              [ $span -lt $span_low ] && span=$span_low
              [ $span -gt $span_high ] && span=$span_high
              center=$ex_cx
              if [ $center -lt $(( x0 + corner_margin + span/2 )) ]; then
                center=$(( x0 + corner_margin + span/2 ))
              fi
              if [ $center -gt $(( x1 - corner_margin - span/2 )) ]; then
                center=$(( x1 - corner_margin - span/2 ))
              fi
            else
              r=$(python3 "$(dirname "$0")/rng_helper.py" --seed "$((s+tries))" --mu "$ASPECT_CENTER" --sigma 0.30 --min "$ASPECT_MIN" --max "$ASPECT_MAX")
              span=$(awk -v d=$depth -v r=$r 'BEGIN{printf("%d", int(r*d + 0.5))}')
              if [ $span -lt $span_low ]; then span=$span_low; fi
              if [ $span -gt $span_high ]; then span=$span_high; fi

              start_min=$(( x0 + corner_margin ))
              start_max=$(( x1 - corner_margin - span ))
              if [ $start_max -lt $start_min ]; then
                start_x=$start_min
              else
                start_x=$(( start_min + ((s*29 + tries*41) % (start_max - start_min + 1)) ))
              fi
              center=$(( start_x + span/2 ))
            fi

            min_ar_span=$(( (depth + 1) / 2 ))
            max_ar_span=$(( depth * 2 ))
            [ $span -lt $min_ar_span ] && span=$min_ar_span
            [ $span -gt $max_ar_span ] && span=$max_ar_span
            min_depth_ar=$(( (span + 1) / 2 ))
            max_depth_ar=$(( span * 2 ))
            if [ $depth -lt $min_depth_ar ]; then depth=$min_depth_ar; fi
            if [ $depth -gt $max_depth_ar ]; then depth=$max_depth_ar; fi

            # In original code, top-edge final assignment occurs later (intentionally left for parity)
            # Here we keep behavior consistent without redundant assignments in this branch.
            ;;

    4)  # BOTTOM-LEFT CORNER: starts at (x0,y0), extends right/up
      max_allowed_x=$MAX_DEPTH
      [ $max_allowed_x -gt $orig_width ] && max_allowed_x=$orig_width
      [ $max_allowed_x -lt $MIN_DEPTH ] && max_allowed_x=$MIN_DEPTH
      # Sample span_x using depth * aspect ratio (like edge branches)
      r1=$(python3 "$(dirname "$0")/rng_helper.py" --seed "$((s+tries+11))" --mu "$ASPECT_CENTER" --sigma 0.30 --min "$ASPECT_MIN" --max "$ASPECT_MAX")
      span_x=$(awk -v d=$depth -v r=$r1 'BEGIN{printf("%d", int(r*d + 0.5))}')
      [ $span_x -lt $MIN_DEPTH ] && span_x=$MIN_DEPTH
      [ $span_x -gt $max_allowed_x ] && span_x=$max_allowed_x
      [ $span_x -gt $orig_width ] && span_x=$orig_width

      # Sample an aspect ratio like edge branches and compute span_y = r * span_x
      r=$(python3 "$(dirname "$0")/rng_helper.py" --seed "$((s+tries))" --mu "$ASPECT_CENTER" --sigma 0.30 --min "$ASPECT_MIN" --max "$ASPECT_MAX")
      span_y=$(awk -v x=$span_x -v r=$r 'BEGIN{printf("%d", int(r*x + 0.5))}')

      # Clamp span_y to sensible bounds derived from span_x, MIN/ MAX_DEPTH and die size
      min_y=$(( (span_x + 1) / 2 ))
      [ $min_y -lt $MIN_DEPTH ] && min_y=$MIN_DEPTH
      max_y=$(( span_x * 2 ))
      [ $max_y -gt $MAX_DEPTH ] && max_y=$MAX_DEPTH
      [ $max_y -gt $orig_height ] && max_y=$orig_height
      if [ $span_y -lt $min_y ]; then span_y=$min_y; fi
      if [ $span_y -gt $max_y ]; then span_y=$max_y; fi

      edge_x=$x0; edge_y=$y0
      int_x=$(( edge_x + span_x )); int_y=$(( edge_y + span_y ))
            ;;

    5)  # BOTTOM-RIGHT CORNER: starts at (x1,y0), extends left/up
      max_allowed_x=$MAX_DEPTH
      [ $max_allowed_x -gt $orig_width ] && max_allowed_x=$orig_width
      [ $max_allowed_x -lt $MIN_DEPTH ] && max_allowed_x=$MIN_DEPTH
      # Sample span_x from depth * aspect ratio (match edges)
      r1=$(python3 "$(dirname "$0")/rng_helper.py" --seed "$((s+tries+17))" --mu "$ASPECT_CENTER" --sigma 0.30 --min "$ASPECT_MIN" --max "$ASPECT_MAX")
      span_x=$(awk -v d=$depth -v r=$r1 'BEGIN{printf("%d", int(r*d + 0.5))}')
      [ $span_x -lt $MIN_DEPTH ] && span_x=$MIN_DEPTH
      [ $span_x -gt $max_allowed_x ] && span_x=$max_allowed_x
      [ $span_x -gt $orig_width ] && span_x=$orig_width

      r=$(python3 "$(dirname "$0")/rng_helper.py" --seed "$((s+tries))" --mu "$ASPECT_CENTER" --sigma 0.30 --min "$ASPECT_MIN" --max "$ASPECT_MAX")
      span_y=$(awk -v x=$span_x -v r=$r 'BEGIN{printf("%d", int(r*x + 0.5))}')

      min_y=$(( (span_x + 1) / 2 ))
      [ $min_y -lt $MIN_DEPTH ] && min_y=$MIN_DEPTH
      max_y=$(( span_x * 2 ))
      [ $max_y -gt $MAX_DEPTH ] && max_y=$MAX_DEPTH
      [ $max_y -gt $orig_height ] && max_y=$orig_height
      if [ $span_y -lt $min_y ]; then span_y=$min_y; fi
      if [ $span_y -gt $max_y ]; then span_y=$max_y; fi

      edge_x=$x1; edge_y=$y0
      int_x=$(( edge_x - span_x )); int_y=$(( edge_y + span_y ))
            ;;

    6)  # TOP-RIGHT CORNER: starts at (x1,y1), extends left/down
      max_allowed_x=$MAX_DEPTH
      [ $max_allowed_x -gt $orig_width ] && max_allowed_x=$orig_width
      [ $max_allowed_x -lt $MIN_DEPTH ] && max_allowed_x=$MIN_DEPTH
      # Sample span_x from depth * aspect ratio (match edges)
      r1=$(python3 "$(dirname "$0")/rng_helper.py" --seed "$((s+tries+23))" --mu "$ASPECT_CENTER" --sigma 0.30 --min "$ASPECT_MIN" --max "$ASPECT_MAX")
      span_x=$(awk -v d=$depth -v r=$r1 'BEGIN{printf("%d", int(r*d + 0.5))}')
      [ $span_x -lt $MIN_DEPTH ] && span_x=$MIN_DEPTH
      [ $span_x -gt $max_allowed_x ] && span_x=$max_allowed_x
      [ $span_x -gt $orig_width ] && span_x=$orig_width

      r=$(python3 "$(dirname "$0")/rng_helper.py" --seed "$((s+tries))" --mu "$ASPECT_CENTER" --sigma 0.30 --min "$ASPECT_MIN" --max "$ASPECT_MAX")
      span_y=$(awk -v x=$span_x -v r=$r 'BEGIN{printf("%d", int(r*x + 0.5))}')

      min_y=$(( (span_x + 1) / 2 ))
      [ $min_y -lt $MIN_DEPTH ] && min_y=$MIN_DEPTH
      max_y=$(( span_x * 2 ))
      [ $max_y -gt $MAX_DEPTH ] && max_y=$MAX_DEPTH
      [ $max_y -gt $orig_height ] && max_y=$orig_height
      if [ $span_y -lt $min_y ]; then span_y=$min_y; fi
      if [ $span_y -gt $max_y ]; then span_y=$max_y; fi

      edge_x=$x1; edge_y=$y1
      int_x=$(( edge_x - span_x )); int_y=$(( edge_y - span_y ))
            ;;

    7)  # TOP-LEFT CORNER: starts at (x0,y1), extends right/down
      max_allowed_x=$MAX_DEPTH
      [ $max_allowed_x -gt $orig_width ] && max_allowed_x=$orig_width
      [ $max_allowed_x -lt $MIN_DEPTH ] && max_allowed_x=$MIN_DEPTH
      # Sample span_x from depth * aspect ratio (match edges)
      r1=$(python3 "$(dirname "$0")/rng_helper.py" --seed "$((s+tries+31))" --mu "$ASPECT_CENTER" --sigma 0.30 --min "$ASPECT_MIN" --max "$ASPECT_MAX")
      span_x=$(awk -v d=$depth -v r=$r1 'BEGIN{printf("%d", int(r*d + 0.5))}')
      [ $span_x -lt $MIN_DEPTH ] && span_x=$MIN_DEPTH
      [ $span_x -gt $max_allowed_x ] && span_x=$max_allowed_x
      [ $span_x -gt $orig_width ] && span_x=$orig_width

      r=$(python3 "$(dirname "$0")/rng_helper.py" --seed "$((s+tries))" --mu "$ASPECT_CENTER" --sigma 0.30 --min "$ASPECT_MIN" --max "$ASPECT_MAX")
      span_y=$(awk -v x=$span_x -v r=$r 'BEGIN{printf("%d", int(r*x + 0.5))}')

      min_y=$(( (span_x + 1) / 2 ))
      [ $min_y -lt $MIN_DEPTH ] && min_y=$MIN_DEPTH
      max_y=$(( span_x * 2 ))
      [ $max_y -gt $MAX_DEPTH ] && max_y=$MAX_DEPTH
      [ $max_y -gt $orig_height ] && max_y=$orig_height
      if [ $span_y -lt $min_y ]; then span_y=$min_y; fi
      if [ $span_y -gt $max_y ]; then span_y=$max_y; fi

      edge_x=$x0; edge_y=$y1
      int_x=$(( edge_x + span_x )); int_y=$(( edge_y - span_y ))
            ;;
      esac

      overlap=0
      for ((k=0; k<${#coords[@]}; k+=4)); do
        cutout_conflict $edge_x $edge_y $int_x $int_y \
                        ${coords[k]} ${coords[k+1]} ${coords[k+2]} ${coords[k+3]}
        if [ $? -eq 0 ]; then
          overlap=1
          log_debug "  Try $tries: cutout at ($edge_x,$edge_y)-($int_x,$int_y) conflicts with existing cutout $((k/4 + 1)) at (${coords[k]},${coords[k+1]})-(${coords[k+2]},${coords[k+3]})"
          break
        fi
      done
      [ $overlap -eq 1 ] && continue

      if ! ( [ $edge_x -eq $x0 ] || [ $edge_x -eq $x1 ] || [ $edge_y -eq $y0 ] || [ $edge_y -eq $y1 ] ); then
        if [ $int_x -eq $x0 ] || [ $int_x -eq $x1 ] || [ $int_y -eq $y0 ] || [ $int_y -eq $y1 ]; then
          tmpx=$edge_x; tmpy=$edge_y; edge_x=$int_x; edge_y=$int_y; int_x=$tmpx; int_y=$tmpy
        fi
      fi

      if [ $int_x -le $x0 ]; then int_x=$((x0 + 1)); fi
      if [ $int_x -ge $x1 ]; then int_x=$((x1 - 1)); fi
      if [ $int_y -le $y0 ]; then int_y=$((y0 + 1)); fi
      if [ $int_y -ge $y1 ]; then int_y=$((y1 - 1)); fi
      [ $int_x -lt $x0 ] && int_x=$x0
      [ $int_y -lt $y0 ] && int_y=$y0

      if [ $int_x -eq $edge_x ] && [ $int_y -eq $edge_y ]; then
        if   [ $edge_x -eq $x0 ]; then int_x=$(( edge_x + 1 ))
        elif [ $edge_x -eq $x1 ]; then int_x=$(( edge_x - 1 )); fi
        if   [ $edge_y -eq $y0 ]; then int_y=$(( edge_y + 1 ))
        elif [ $edge_y -eq $y1 ]; then int_y=$(( edge_y - 1 )); fi
        if [ $int_x -le $x0 ]; then int_x=$((x0+2)); fi
        if [ $int_x -ge $x1 ]; then int_x=$((x1-2)); fi
        if [ $int_y -le $y0 ]; then int_y=$((y0+2)); fi
        if [ $int_y -ge $y1 ]; then int_y=$((y1-2)); fi
      fi

      edge_on_boundary=0; int_on_boundary=0
      if [ $edge_x -eq $x0 ] || [ $edge_x -eq $x1 ] || [ $edge_y -eq $y0 ] || [ $edge_y -eq $y1 ]; then
        edge_on_boundary=1
      fi
      if [ $int_x -eq $x0 ] || [ $int_x -eq $x1 ] || [ $int_y -eq $y0 ] || [ $int_y -eq $y1 ]; then
        int_on_boundary=1
      fi

      if [ $edge_on_boundary -eq 1 ] && [ $int_on_boundary -eq 1 ]; then
        if [ $edge_x -eq $x0 ]; then int_x=$((x0 + 2)); fi
        if [ $edge_x -eq $x1 ]; then int_x=$((x1 - 2)); fi
        if [ $edge_y -eq $y0 ]; then int_y=$((y0 + 2)); fi
        if [ $edge_y -eq $y1 ]; then int_y=$((y1 - 2)); fi
        [ $int_x -le $x0 ] && int_x=$((x0 + 2))
        [ $int_x -ge $x1 ] && int_x=$((x1 - 2))
        [ $int_y -le $y0 ] && int_y=$((y0 + 2))
        [ $int_y -ge $y1 ] && int_y=$((y1 - 2))
      fi

      if [ $edge_on_boundary -eq 0 ] && [ $int_on_boundary -eq 0 ]; then
        dx_left=$((edge_x - x0)); dx_right=$((x1 - edge_x))
        dy_bottom=$((edge_y - y0)); dy_top=$((y1 - edge_y))
        min_dx=$dx_left; nearest_x=$x0
        [ $dx_right -lt $min_dx ] && { min_dx=$dx_right; nearest_x=$x1; }
        min_dy=$dy_bottom; nearest_y=$y0
        [ $dy_top -lt $min_dy ] && { min_dy=$dy_top; nearest_y=$y1; }
        if [ $min_dx -le $min_dy ]; then edge_x=$nearest_x
        else edge_y=$nearest_y
        fi
      fi

      [ $int_x -le $x0 ] && int_x=$((x0 + 2))
      [ $int_x -ge $x1 ] && int_x=$((x1 - 2))
      [ $int_y -le $y0 ] && int_y=$((y0 + 2))
      [ $int_y -ge $y1 ] && int_y=$((y1 - 2))

      coords+=( $edge_x $edge_y $int_x $int_y )
      placed=1
      log_debug "  Placed rect $j at edge=($edge_x,$edge_y) internal=($int_x,$int_y)"
      break
    done

    if [ $placed -eq 0 ]; then
      log_debug "Variant $i: failed to place rect $j after $MAX_TRIES_PER_RECT tries"
    fi
  done

  num_rects=$(( ${#coords[@]} / 4 ))
  if [ $num_rects -eq 0 ]; then
    coords=( $x0 $y0 $((x0+MIN_DEPTH)) $((y0+MIN_DEPTH)) )
    num_rects=1; fallback_count=$((fallback_count+1))
  fi

  if [ $num_rects -gt 1 ]; then
    thr_x=$(( orig_width / 50 ));  [ $thr_x -lt 1 ] && thr_x=1
    thr_y=$(( orig_height / 50 )); [ $thr_y -lt 1 ] && thr_y=1

    minx=(); miny=(); maxx=(); maxy=()
    for ((ai=0; ai<num_rects; ai++)); do
      x1p=${coords[ai*4]}; y1p=${coords[ai*4+1]}
      x2p=${coords[ai*4+2]}; y2p=${coords[ai*4+3]}
      [ $x1p -le $x2p ] && { mnx=$x1p; mxx=$x2p; } || { mnx=$x2p; mxx=$x1p; }
      [ $y1p -le $y2p ] && { mny=$y1p; mxy=$y2p; } || { mny=$y2p; mxy=$y1p; }
      minx+=( $mnx ); maxx+=( $mxx ); miny+=( $mny ); maxy+=( $mxy )
    done

    edge_idx_of_pair() {
      local px1=$1 py1=$2 px2=$3 py2=$4
      if [ $px1 -eq $x0 ] || [ $px1 -eq $x1 ] || [ $py1 -eq $y0 ] || [ $py1 -eq $y1 ]; then
        echo 0
      else
        echo 1
      fi
    }

    for ((ri=0; ri<num_rects; ri++)); do
      for ((rj=ri+1; rj<num_rects; rj++)); do
        if [ ${maxx[ri]} -lt ${minx[rj]} ]; then
          gap=$(( minx[rj] - maxx[ri] ))
          ov=$(( ( ${maxy[ri]} < ${maxy[rj]} ? ${maxy[ri]} : ${maxy[rj]} ) - ( ${miny[ri]} > ${miny[rj]} ? ${miny[ri]} : ${miny[rj]} ) ))
          [ $ov -lt 0 ] && ov=0
          if [ $gap -gt 0 ] && [ $gap -le $thr_x ] && [ $ov -gt 0 ]; then
            newx=${maxx[ri]}
            jx1=${coords[rj*4]}; jy1=${coords[rj*4+1]}
            jx2=${coords[rj*4+2]}; jy2=${coords[rj*4+3]}
            ej=$(edge_idx_of_pair "$jx1" "$jy1" "$jx2" "$jy2")
            if [ "$ej" -eq 0 ]; then
              [ "$jx1" -le "$jx2" ] && { coords[rj*4]=$newx; minx[rj]=$newx; }
            else
              [ "$jx2" -le "$jx1" ] && { coords[rj*4+2]=$newx; minx[rj]=$newx; }
            fi
          fi

        elif [ ${maxx[rj]} -lt ${minx[ri]} ]; then
          gap=$(( minx[ri] - maxx[rj] ))
          ov=$(( ( ${maxy[ri]} < ${maxy[rj]} ? ${maxy[ri]} : ${maxy[rj]} ) - ( ${miny[ri]} > ${miny[rj]} ? ${miny[ri]} : ${miny[rj]} ) ))
          [ $ov -lt 0 ] && ov=0
          if [ $gap -gt 0 ] && [ $gap -le $thr_x ] && [ $ov -gt 0 ]; then
            newx=${maxx[rj]}
            ix1=${coords[ri*4]}; iy1=${coords[ri*4+1]}
            ix2=${coords[ri*4+2]}; iy2=${coords[ri*4+3]}
            ei=$(edge_idx_of_pair "$ix1" "$iy1" "$ix2" "$iy2")
            if [ "$ei" -eq 0 ]; then
              [ "$ix1" -le "$ix2" ] && { coords[ri*4]=$newx; minx[ri]=$newx; }
            else
              [ "$ix2" -le "$ix1" ] && { coords[ri*4+2]=$newx; minx[ri]=$newx; }
            fi
          fi
        fi

        if [ ${maxy[ri]} -lt ${miny[rj]} ]; then
          gap=$(( miny[rj] - maxy[ri] ))
          ov=$(( ( ${maxx[ri]} < ${maxx[rj]} ? ${maxx[ri]} : ${maxx[rj]} ) - ( ${minx[ri]} > ${minx[rj]} ? ${minx[ri]} : ${minx[rj]} ) ))
          [ $ov -lt 0 ] && ov=0
          if [ $gap -gt 0 ] && [ $gap -le $thr_y ] && [ $ov -gt 0 ]; then
            newy=${maxy[ri]}
            jx1=${coords[rj*4]}; jy1=${coords[rj*4+1]}
            jx2=${coords[rj*4+2]}; jy2=${coords[rj*4+3]}
            ej=$(edge_idx_of_pair "$jx1" "$jy1" "$jx2" "$jy2")
            if [ "$ej" -eq 0 ]; then
              [ "$jy1" -le "$jy2" ] && { coords[rj*4+1]=$newy; miny[rj]=$newy; }
            else
              [ "$jy2" -le "$jy1" ] && { coords[rj*4+3]=$newy; miny[rj]=$newy; }
            fi
          fi

        elif [ ${maxy[rj]} -lt ${miny[ri]} ]; then
          gap=$(( miny[ri] - maxy[rj] ))
          ov=$(( ( ${maxx[ri]} < ${maxx[rj]} ? ${maxx[ri]} : ${maxx[rj]} ) - ( ${minx[ri]} > ${minx[rj]} ? ${minx[ri]} : ${minx[rj]} ) ))
          [ $ov -lt 0 ] && ov=0
          if [ $gap -gt 0 ] && [ $gap -le $thr_y ] && [ $ov -gt 0 ]; then
            newy=${maxy[rj]}
            ix1=${coords[ri*4]}; iy1=${coords[ri*4+1]}
            ix2=${coords[ri*4+2]}; iy2=${coords[ri*4+3]}
            ei=$(edge_idx_of_pair "$ix1" "$iy1" "$ix2" "$iy2")
            if [ "$ei" -eq 0 ]; then
              [ "$iy1" -le "$iy2" ] && { coords[ri*4+1]=$newy; miny[ri]=$newy; }
            else
              [ "$iy2" -le "$iy1" ] && { coords[ri*4+3]=$newy; miny[ri]=$newy; }
            fi
          fi
        fi

      done
    done
  fi

  outf=$(printf "%s/%s_%03d.def" "$OUT_DIR" "$OUTPUT_PREFIX" "$i")
  err_log="$OUT_DIR/err_${i}.log"
  echo "Generating $outf with $num_rects rect(s)..."

  if python3 "$PY_SCRIPT" -i "$INPUT_DEF" -o "$outf" -r "$num_rects" -c "${coords[@]}" 2>"$err_log"; then
    success=$((success+1))
    [ -f "$err_log" ] && rm "$err_log"
  else
    echo "modify_def.py failed for $i (see err_${i}.log)"
    fail=$((fail+1))
  fi
done

echo "=== Done ==="
echo "Success : $success"
echo "Failed  : $fail"
echo "Fallbacks: $fallback_count"
echo "DEF files are in $OUT_DIR/"
