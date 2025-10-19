#!/usr/bin/env bash
# Generate rectilinear DEF variants with rectangular holes.

PY_SCRIPT="modify_def.py"
INPUT_DEF="input_tr.def"
OUT_DIR="tr_small_rects"
OUTPUT_PREFIX="small_rects"  # Prefix of output files, change here to modify output filenames
NUM_VARIANTS=${1:-20}  # Allow command line override
MIN_RECTS=1
MAX_RECTS=6
# Rectangular cutout size constraints
# Large
# MIN_DEPTH=300000  
# MAX_DEPTH=500000
# Medium
# MIN_DEPTH=200000
# MAX_DEPTH=300000
# Small
MIN_DEPTH=70000
MAX_DEPTH=200000
MAX_TRIES_PER_RECT=80  # Retry count
DEBUG=${DEBUG:-0}      # Set DEBUG=1 to enable debug output
MAX_ASPECT=5           # Maximum allowed aspect ratio

mkdir -p "$OUT_DIR"

# Read DIEAREA bounding box
die_block=$(awk '/DIEAREA/{flag=1} flag{print} /;/{flag=0}' "$INPUT_DEF" | tr -d '\n')
read x0 y0 x1 y1 < <(echo "$die_block" | sed -E 's/.*\(\s*([0-9]+)\s+([0-9]+)\s*\)\s*\(\s*([0-9]+)\s+([0-9]+)\s*\).*/\1 \2 \3 \4/')
orig_width=$(( x1 - x0 ))
orig_height=$(( y1 - y0 ))

success=0; fail=0; fallback_count=0

log_debug() {
  [ "$DEBUG" -eq 1 ] && echo "$@"
}

# Check if two rectangular cutouts would conflict with minimal buffer
cutout_conflict() {
  local ax1=$1 ay1=$2 ax2=$3 ay2=$4
  local bx1=$5 by1=$6 bx2=$7 by2=$8
  local buffer=10000  # Much smaller buffer for tight packing
  
  # Normalize rectangles (ensure x1 <= x2, y1 <= y2)
  [ $ax1 -gt $ax2 ] && { local tmp=$ax1; ax1=$ax2; ax2=$tmp; }
  [ $ay1 -gt $ay2 ] && { local tmp=$ay1; ay1=$ay2; ay2=$tmp; }
  [ $bx1 -gt $bx2 ] && { local tmp=$bx1; bx1=$bx2; bx2=$tmp; }
  [ $by1 -gt $by2 ] && { local tmp=$by1; by1=$by2; by2=$tmp; }
  
  # Add buffer to rectangles
  ax1=$((ax1 - buffer)); ay1=$((ay1 - buffer))
  ax2=$((ax2 + buffer)); ay2=$((ay2 + buffer))
  bx1=$((bx1 - buffer)); by1=$((by1 - buffer))
  bx2=$((bx2 + buffer)); by2=$((by2 + buffer))
  
  # Check for overlap
  if [ $ax2 -gt $bx1 ] && [ $ax1 -lt $bx2 ] && [ $ay2 -gt $by1 ] && [ $ay1 -lt $by2 ]; then
    return 0  # conflict
  fi
  return 1  # no conflict
}

for i in $(seq 1 $NUM_VARIANTS); do
  seed=$((1000+i))
  rects=$(( ((seed*7) % (MAX_RECTS-MIN_RECTS+1)) + MIN_RECTS ))
  coords=()
  log_debug "Variant $i: attempting to place $rects rects"

  for j in $(seq 1 $rects); do
    placed=0; tries=0
    log_debug "Variant $i: trying to place rect $j (already have $((${#coords[@]}/4)) rects)"
    # Try to spread cutouts across different edges by biasing edge selection
    preferred_edge=$(( (j-1) % 4 ))  # 0=left, 1=right, 2=bottom, 3=top
    log_debug "  Preferred edge for rect $j: $preferred_edge"
    
    while [ $tries -lt $MAX_TRIES_PER_RECT ]; do
      tries=$((tries+1))
      s=$((seed+j*37+tries*13))  # Include tries in seed for more variation
      log_debug "  Try $tries for rect $j: seed=$s"
      
      # Bias toward preferred edge for first half of tries, then random
      if [ $tries -le $((MAX_TRIES_PER_RECT / 2)) ]; then
        # First half: prefer the assigned edge
        if [ $((s % 10)) -lt 7 ]; then
          typ=$preferred_edge
          log_debug "    Using preferred edge: $typ"
        else
          typ=$(( (s*31+j*17) % 4 ))
          log_debug "    Using random edge instead of preferred: $typ"
        fi
      else
        # Second half: completely random
        typ=$(( (s*41+j*19) % 4 ))
        log_debug "    Using random edge (second half): $typ"
      fi

      # Depth constraints  
      maxd=$MAX_DEPTH
      [ "$maxd" -gt $((orig_width/2)) ] && maxd=$((orig_width/2))
      [ "$maxd" -gt $((orig_height/2)) ] && maxd=$((orig_height/2))
      if [ "$maxd" -lt "$MIN_DEPTH" ]; then
        depth=$MIN_DEPTH
      else
        depth=$(( MIN_DEPTH + ((s*97+j*53) % (maxd-MIN_DEPTH+1)) ))
      fi
      [ $depth -lt 2 ] && depth=2
      offset=$(( depth/2 ))

      case $typ in
        0) # left edge
           # Use multiple weighted random numbers to create center-biased distribution
           # Generate 4-6 random numbers and take weighted average (strongly favors center)
           num_samples=$(( 4 + ((s*11) % 3) ))  # 4-6 samples
           total=0
           for ((sample=0; sample<num_samples; sample++)); do
             rand_val=$(( (s*73 + j*29 + tries*41 + sample*17) % orig_height ))
             total=$((total + rand_val))
           done
           edge_y=$(( y0 + total / num_samples ))
           
           # Ensure it's within valid range (small buffer to avoid exact corners)
           buffer_y=$(( orig_height / 50 ))  # Much smaller, dynamic buffer
           [ $edge_y -lt $((y0 + buffer_y)) ] && edge_y=$((y0 + buffer_y))
           [ $edge_y -gt $((y1 - buffer_y)) ] && edge_y=$((y1 - buffer_y))
           
           edge_x=$x0
           int_x=$(( edge_x + depth ))
           int_y=$(( edge_y > y0+offset ? edge_y-offset : edge_y+offset ))
           ;;
        1) # right edge  
           num_samples=$(( 4 + ((s*13) % 3) ))
           total=0
           for ((sample=0; sample<num_samples; sample++)); do
             rand_val=$(( (s*89 + j*37 + tries*53 + sample*19) % orig_height ))
             total=$((total + rand_val))
           done
           edge_y=$(( y0 + total / num_samples ))
           
           buffer_y=$(( orig_height / 50 ))
           [ $edge_y -lt $((y0 + buffer_y)) ] && edge_y=$((y0 + buffer_y))
           [ $edge_y -gt $((y1 - buffer_y)) ] && edge_y=$((y1 - buffer_y))
           
           edge_x=$x1
           int_x=$(( edge_x - depth ))
           int_y=$(( edge_y > y0+offset ? edge_y-offset : edge_y+offset ))
           ;;
        2) # bottom edge
           num_samples=$(( 4 + ((s*17) % 3) ))
           total=0
           for ((sample=0; sample<num_samples; sample++)); do
             rand_val=$(( (s*103 + j*47 + tries*67 + sample*23) % orig_width ))
             total=$((total + rand_val))
           done
           edge_x=$(( x0 + total / num_samples ))
           
           buffer_x=$(( orig_width / 50 ))
           [ $edge_x -lt $((x0 + buffer_x)) ] && edge_x=$((x0 + buffer_x))
           [ $edge_x -gt $((x1 - buffer_x)) ] && edge_x=$((x1 - buffer_x))
           
           edge_y=$y0
           int_x=$(( edge_x > x0+offset ? edge_x-offset : edge_x+offset ))
           int_y=$(( edge_y + depth ))
           ;;
        3) # top edge
           num_samples=$(( 4 + ((s*19) % 3) ))
           total=0
           for ((sample=0; sample<num_samples; sample++)); do
             rand_val=$(( (s*113 + j*61 + tries*79 + sample*29) % orig_width ))
             total=$((total + rand_val))
           done
           edge_x=$(( x0 + total / num_samples ))
           
           buffer_x=$(( orig_width / 50 ))
           [ $edge_x -lt $((x0 + buffer_x)) ] && edge_x=$((x0 + buffer_x))
           [ $edge_x -gt $((x1 - buffer_x)) ] && edge_x=$((x1 - buffer_x))
           
           edge_y=$y1
           int_x=$(( edge_x > x0+offset ? edge_x-offset : edge_x+offset ))
           int_y=$(( edge_y - depth ))
           ;;
      esac

      # overlap check with existing cutouts
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

      coords+=( $edge_x $edge_y $int_x $int_y )
      placed=1
      log_debug "  Successfully placed rect $j at edge=($edge_x,$edge_y) internal=($int_x,$int_y)"
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

  outf=$(printf "%s/%s_%03d.def" "$OUT_DIR" "$OUTPUT_PREFIX" "$i")
  err_log="$OUT_DIR/err_${i}.log"
  echo "Generating $outf with $num_rects rect(s)..."

  if python3 "$PY_SCRIPT" -i "$INPUT_DEF" -o "$outf" -r "$num_rects" -c "${coords[@]}" 2>"$err_log"; then
    success=$((success+1))
    # Remove empty error log file if command succeeded
    [ -f "$err_log" ] && rm "$err_log"
  else
    echo "modify_def.py failed for $i (see err_${i}.log)"
    fail=$((fail+1))
  fi
done

echo "=== Done ==="
echo "Success: $success"
echo "Failed : $fail"
echo "Fallbacks: $fallback_count"
echo "DEF files are in $OUT_DIR/"