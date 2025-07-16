#!/bin/bash

# --- Configuration Parameters ---
# Your Python script name
PYTHON_SCRIPT="modify_final.py" 

# Initial DIEAREA dimensions (DBU) - these values are used to calculate cutout and complex shape coordinates
BASE_WIDTH=2200000
BASE_HEIGHT=3000000

# Input DEF file name (all operations will be based on this file)
# Please ensure this file exists in the same directory as the Bash script and is the correct DEF file you wish to modify.
INPUT_DEF_BASE="ariana_origin_with_c.def"

# Output directory for generated files
OUTPUT_DIR="generated_rectilinear_defs"

# --- Script Start ---
echo "--- Preparation Phase: Checking input file and creating output directory ---"

# Create output directory
mkdir -p "$OUTPUT_DIR"

# Check if input file exists
if [ ! -f "${INPUT_DEF_BASE}" ]; then
    echo "Error: Input file ${INPUT_DEF_BASE} does not exist."
    echo "Please ensure you have placed the correct ariana_origin_with_c.def file in the same directory as this Bash script."
    exit 1
fi

echo "--- Starting generation of various rectilinear DIEAREAs ---"

# -----------------------------------------------------------------------------------
# 1. Single Corner Cut-outs (L-shape) - using --rectangles mode
#    An example for each corner, demonstrating how to cut out a corner.
# -----------------------------------------------------------------------------------

echo "Generating Single Corner Cut-outs (L-shape)..."

# 1.1 Bottom-left L-shape cutout
# Cutout area (0,0) to (200000, 200000)
python "$PYTHON_SCRIPT" \
    -i "${INPUT_DEF_BASE}" \
    -o "${OUTPUT_DIR}/corner_bottom_left_L.def" \
    --rectangles 1 \
    --coordinates 0 0 200000 200000 \
    --verbose
echo ""

# 1.2 Bottom-right L-shape cutout
# Cutout area (BASE_WIDTH,0) to (BASE_WIDTH-200000, 200000)
python "$PYTHON_SCRIPT" \
    -i "${INPUT_DEF_BASE}" \
    -o "${OUTPUT_DIR}/corner_bottom_right_L.def" \
    --rectangles 1 \
    --coordinates ${BASE_WIDTH} 0 $((BASE_WIDTH-200000)) 200000 \
    --verbose
echo ""

# 1.3 Top-left L-shape cutout
# Cutout area (0,BASE_HEIGHT) to (200000, BASE_HEIGHT-200000)
python "$PYTHON_SCRIPT" \
    -i "${INPUT_DEF_BASE}" \
    -o "${OUTPUT_DIR}/corner_top_left_L.def" \
    --rectangles 1 \
    --coordinates 0 ${BASE_HEIGHT} 200000 $((BASE_HEIGHT-200000)) \
    --verbose
echo ""

# 1.4 Top-right L-shape cutout
# Cutout area (BASE_WIDTH,BASE_HEIGHT) to (BASE_WIDTH-200000, BASE_HEIGHT-200000)
python "$PYTHON_SCRIPT" \
    -i "${INPUT_DEF_BASE}" \
    -o "${OUTPUT_DIR}/corner_top_right_L.def" \
    --rectangles 1 \
    --coordinates ${BASE_WIDTH} ${BASE_HEIGHT} $((BASE_WIDTH-200000)) $((BASE_HEIGHT-200000)) \
    --verbose
echo ""

# -----------------------------------------------------------------------------------
# 2. Single Edge Cut-outs (U-shape/notch) - using --rectangles mode
#    Ensure edge cutouts do not overlap with corner cutouts.
# -----------------------------------------------------------------------------------

echo "Generating Single Edge Cut-outs (U-shape/notch)..."

# 2.1 Left edge cutout (middle position)
# Cutout rectangle (0, 1000000) to (200000, 2000000)
python "$PYTHON_SCRIPT" \
    -i "${INPUT_DEF_BASE}" \
    -o "${OUTPUT_DIR}/edge_left_notch.def" \
    --rectangles 1 \
    --coordinates 0 1000000 200000 2000000 \
    --verbose
echo ""

# 2.2 Right edge cutout (middle position)
# Cutout rectangle (BASE_WIDTH-200000, 1000000) to (BASE_WIDTH, 2000000)
python "$PYTHON_SCRIPT" \
    -i "${INPUT_DEF_BASE}" \
    -o "${OUTPUT_DIR}/edge_right_notch.def" \
    --rectangles 1 \
    --coordinates $((BASE_WIDTH-200000)) 1000000 ${BASE_WIDTH} 2000000 \
    --verbose
echo ""

# 2.3 Top edge cutout (middle position)
# Cutout rectangle (900000, BASE_HEIGHT-200000) to (1300000, BASE_HEIGHT)
python "$PYTHON_SCRIPT" \
    -i "${INPUT_DEF_BASE}" \
    -o "${OUTPUT_DIR}/edge_top_notch.def" \
    --rectangles 1 \
    --coordinates 900000 $((BASE_HEIGHT-200000)) 1300000 ${BASE_HEIGHT} \
    --verbose
echo ""

# 2.4 Bottom edge cutout (middle position)
# Cutout rectangle (900000, 0) to (1300000, 200000)
python "$PYTHON_SCRIPT" \
    -i "${INPUT_DEF_BASE}" \
    -o "${OUTPUT_DIR}/edge_bottom_notch.def" \
    --rectangles 1 \
    --coordinates 900000 0 1300000 200000 \
    --verbose
echo ""

# -----------------------------------------------------------------------------------
# 3. Multiple Non-Overlapping Cut-outs (3-5 holes) - using --rectangles mode
#    Combine multiple cutouts, but ensure corner and edge cutouts do not overlap.
# -----------------------------------------------------------------------------------

echo "Generating Multiple Non-Overlapping Cut-outs (3-5 holes)..."

# 3.1 Two diagonal cutouts
# Top-left corner + Bottom-right corner
python "$PYTHON_SCRIPT" \
    -i "${INPUT_DEF_BASE}" \
    -o "${OUTPUT_DIR}/multi_cut_diag_corners.def" \
    --rectangles 2 \
    --coordinates \
        0 ${BASE_HEIGHT} 200000 $((BASE_HEIGHT-200000)) \
        ${BASE_WIDTH} 0 $((BASE_WIDTH-200000)) 200000 \
    --verbose
echo ""

# 3.2 Three cutouts: Top-left corner + Bottom-right corner + Bottom edge
python "$PYTHON_SCRIPT" \
    -i "${INPUT_DEF_BASE}" \
    -o "${OUTPUT_DIR}/multi_cut_3_holes.def" \
    --rectangles 3 \
    --coordinates \
        0 ${BASE_HEIGHT} 200000 $((BASE_HEIGHT-200000)) \
        ${BASE_WIDTH} 0 $((BASE_WIDTH-200000)) 200000 \
        900000 0 1300000 200000 \
    --verbose
echo ""

# 3.3 Four corner cutouts
# This will form a shape with a rectangular center and four cut-off corners.
python "$PYTHON_SCRIPT" \
    -i "${INPUT_DEF_BASE}" \
    -o "${OUTPUT_DIR}/multi_cut_4_corners.def" \
    --rectangles 4 \
    --coordinates \
        0 0 200000 200000 \
        ${BASE_WIDTH} 0 $((BASE_WIDTH-200000)) 200000 \
        0 ${BASE_HEIGHT} 200000 $((BASE_HEIGHT-200000)) \
        ${BASE_WIDTH} ${BASE_HEIGHT} $((BASE_WIDTH-200000)) $((BASE_HEIGHT-200000)) \
    --verbose
echo ""

# -----------------------------------------------------------------------------------
# 4. Complex External Contour Approximation (directly generating a complete rectilinear DIEAREA line)
#    This is a rough approximation of the main chip area's external contour from your image.
#    Start from the bottom-left corner (0,0) and list all vertices counter-clockwise.
# -----------------------------------------------------------------------------------

echo "Generating Complex Outer Contour Approximation (using --diearea-line)..."

# Define the coordinates for the approximate external contour (clockwise order)
# These coordinates are estimated visually from the image; you may need to adjust them based on actual requirements.
# They represent the outer boundary of the dark gray main chip area in the image.
COMPLEX_DIEAREA_POINTS="\
( 0 0 ) \
( 0 900000 ) \
( 330000 900000 ) \
( 330000 2100000 ) \
( 0 2100000 ) \
( 0 ${BASE_HEIGHT} ) \
( 660000 ${BASE_HEIGHT} ) \
( 660000 2400000 ) \
( $((BASE_WIDTH - 660000)) 2400000 ) \
( $((BASE_WIDTH - 660000)) ${BASE_HEIGHT} ) \
( ${BASE_WIDTH} ${BASE_HEIGHT} ) \
( ${BASE_WIDTH} 2100000 ) \
( $((BASE_WIDTH - 330000)) 2100000 ) \
( $((BASE_WIDTH - 330000)) 900000 ) \
( ${BASE_WIDTH} 900000 ) \
( ${BASE_WIDTH} 0 ) \
"

# Construct the complete DIEAREA line
COMPLEX_DIEAREA_LINE="DIEAREA ${COMPLEX_DIEAREA_POINTS} ;"

python "$PYTHON_SCRIPT" \
    -i "${INPUT_DEF_BASE}" \
    -o "${OUTPUT_DIR}/complex_outer_contour_from_image.def" \
    --diearea-line "${COMPLEX_DIEAREA_LINE}" \
    --verbose
echo ""