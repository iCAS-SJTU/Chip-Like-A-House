# Chip-Like-A-House: Rectilinear Floorplanning Benchmark with Design Constraints for Large-scale Chips

A lightweight benchmark and toolset for generating and modifying DEF files (`.def`), focusing on rectilinear DIEAREA creation and transformation for large-scale chips. It also provides sample scripts to batch-generate benchmarks featuring multiple rectangular notches/holes.

## Repository layout

- `generate_def.py` — generate a minimal, standards‑aware `.def` file from die dimensions. 
- `default_config.json` — example configuration used by `generate_def.py` (defaults for margins, tracks/layers, and other generation options).
- `modify_def.py` — modify an existing `.def` by replacing its `DIEAREA` with rectilinear floorplans. Supports input of either a set of rectangular cutouts or an image of desired floorplan.
- `default_modifier.sh` — convenience script that demonstrates batch modification workflows by invoking `modify_def.py` with different parameters.
- `benchmark/` — collection of sample inputs and helper scripts. Current sample subdirectories include:
    - `sample_ariane133`
    - `sample_ariane136`
    - `sample_black_parrot`
    - `sample_bp_be`
    - `sample_bp_fe`
    - `sample_bp_multi`
    - `sample_bp_quad`
    - `sample_sw`
    - `sample_tr`
    Each sample directory typically contains an input `.def` (when applicable) and a driver script (e.g. `ariane133_modifier.sh`, `bp_quad_modifier.sh`) that demonstrates batch generation of variants.
- `README.md` — this file (overview and usage notes).
- `LICENSE` — contains the project license (if present).

## Getting Started

### Requirements
- Python 3.x (3.8+ recommended)
- A Unix-like environment (Linux/macOS/WSL)
- Optional: Git (for version control), OpenCV (if you later add image-to-contour support)

### Clone
```bash
git clone https://github.com/SurviveAll/Chip-Like-A-House.git
cd Chip-Like-A-House
```


## Usage
### 1. Generate a basic `.def` (generate_def.py)

Given die size in DBU, the script automatically produces:
- Reasonable margins (max of percentage-based and engineering minimums)
- Alternating ROW orientations (N/FS)
- TRACKS for metal1…metal10 (with optional per-layer +1 adjustment)

Usage:
```bash
python generate_def.py -w <width_dbu> -t <height_dbu> -o <output.def> -d <design_name>
```

With a configuration file:
```bash
python generate_def.py -w <width_dbu> -t <height_dbu> -o <output.def> -c <my_config.json>
```

Save the current defaults as a template:
```bash
python generate_def.py --save-config default_config.json
```

The script validates die size to ensure at least one standard cell fits horizontally and at least one ROW fits vertically; otherwise it errors with the required minimum.

### 2. Modify DIEAREA (modify_def.py)

Two main modes are supported:
#### Describe non-rectangular boundaries via rectangular cutouts
```bash
python modify_def.py \
    -i <input.def> -o <output.def> \
    -r <num_rects> -c <x1 y1 x2 y2 ...> [--verbose]
```
- Each rectangle is described by two points:
    - one on the die edge/corner
    - one strictly inside the die
- The script infers which is edge vs internal and emits axis-aligned segments accordingly; multiple non-overlapping cutouts are supported.

#### Provide a full DIEAREA polyline directly
```bash
python modify_def.py \
    -i <input.def> -o <output.def> \
    --diearea-line "DIEAREA ( x0 y0 ) ( x1 y1 ) ... ( xN yN ) ;" [--verbose]
```
- The original DIEAREA line is replaced as-is (no inference).

Validation and errors:
- The tool exits with an error if the DIEAREA line is missing, the coordinate count is invalid, coordinates are negative or exceed the original die width/height, or both points are either internal or both on the boundary.
- Consecutive duplicate vertices are removed to keep the polyline clean (axis-aligned with no consecutive duplicates).

## Batch example scripts (default_modifier.sh)
After editing a few variables at the top of the script, `default_modifier.sh` can be used to produce many rectilinear variants from an input `.def`.

Key variables and their defaults (at top of `default_modifier.sh`):

- `PY_SCRIPT="modify_def.py"` — Python script invoked to rewrite the DIEAREA.
- `INPUT_DEF="input_file.def"` — input DEF filename; change this to the sample `.def` you want to modify (e.g. `input_ariane133.def`).
- `OUT_DIR="out_defs"` — output directory where generated `.def` files and logs are saved.
- `OUTPUT_PREFIX="small_rects"` — prefix used when naming outputs (`$OUT_DIR/$OUTPUT_PREFIX_001.def`, ...).
- `NUM_VARIANTS=${1:-20}` — number of variants (default 20; can be overridden by passing a number as the first script argument).
- `MIN_RECTS`, `MAX_RECTS` — min/max number of rectangular notches per variant (defaults in the script: `1` and `6`).
- `MIN_DEPTH`, `MAX_DEPTH` — depth range used when carving notches (e.g. `100000`..`500000` by default; each depth is capped to at most half the die dimension).
- `MAX_TRIES_PER_RECT` — how many placement attempts per notch (default 80).
- `DEBUG` — set `DEBUG=1` in the environment to enable verbose output.

For each successful variant the script calls:

```bash
python3 "${PY_SCRIPT}" -i "${INPUT_DEF}" -o "${OUT_DIR}/${OUTPUT_PREFIX}_NNN.def" -r <num_rects> -c <x1 y1 x2 y2 ...>
```

and writes an accompanying error log `err_NNN.log` if `modify_def.py` returns a non-zero exit status. Successful runs remove empty error logs.

## License

This repository is released under the MIT License (see LICENSE if present).

## Acknowledgements

Examples are inspired by OpenROAD and MacroPlacement by TILOS-AI-Institute.