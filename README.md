# Chip-Like-A-House: Rectilinear Floorplanning Benchmark with Design Constraints for Large-scale Chips

A lightweight benchmark and toolset for generating and modifying DEF files (`.def`), focusing on rectilinear DIEAREA creation and transformation for large-scale chips. It also provides sample scripts to batch-generate benchmarks featuring multiple rectangular notches/holes.

## Repository layout

- `generate_def.py`: Generate a basic `.def` from scratch (VERSION/UNITS/DIEAREA/ROW/TRACKS with placeholder COMPONENTS/NETS).
- `modify_def.py`: Rewrite DIEAREA on an existing `.def` to realize L-/U-shapes or multi-hole rectilinear boundaries, with three methods provided.
- `default_config.json`: Example configuration (for `generate_def.py`).
- `default_modifier.sh`: Generic batch modifier that calls `modify_def.py` to produce multiple variants.
- `benchmark/`: Sample `.def` inputs and batch generators/outputs.
    - `sample_ariane133/`
        - `input_ariane133.def`
        - `ariane133_modifier.sh` (outputs to `ariane133_large_rects_15*10^4-10^6/`, etc.)
    - `sample_ariane136/`
        - `input_ariane136.def`
        - `ariane136_modifier.sh` (outputs to `ariane136_large_rects_5*10^5-15*10^5/`, etc.)
    - `sample_bp_quad/`
        - `input_bp_quad.def`
        - `bp_quad_modifier.sh` (outputs to `bp_quad_*` directories)

Note: Some output directory names contain asterisks (e.g. `5*10^5`). Quote such paths in the shell to avoid glob expansion.

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
python generate_def.py -w <width_dbu> -t <height_dbu> -o <output.def> -c <config.json>
```

Save the current defaults as a template:
```bash
python generate_def.py --save-config my_template.json
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

After some simple edition of parameters, `default_modifier.sh` enables automatic benchmark production of rectilinear floorplans. Under `benchmark/sample_*`, several scripts (`ariane136_modifier.sh`, `ariane133_modifier.sh`, `bp_quad_modifier.sh`) detailedly show how it works:

How they work:
- Parse the original rectangular DIEAREA from the input `.def`
- Randomly place “center‑biased” entry points along left/right/top/bottom edges, pair with an internal point to form a rectangular notch
- Parameters:
    - `NUM_VARIANTS`: number of variants (default 20; can be overridden by the first script argument)
    - `MIN/MAX_RECTS`: number of rectangular notches per variant
    - `MIN/MAX_DEPTH`: notch depth range (capped to at most half of the die dimension)
    - `MAX_TRIES_PER_RECT`: attempts per notch placement
    - `DEBUG`: set to 1 for verbose logging
- A small buffer is used to reduce overlap between cutouts, trading density vs safety
- Outputs are named like `output_001.def`, etc.

Note on quoting paths with asterisks:
```bash
awk '/^DIEAREA/{print FILENAME":"$0}' "benchmark/sample_ariane136/ariane136_large_rects_5*10^5-15*10^5"/*.def
```

## License

This repository is released under the MIT License (see LICENSE if present).

## Acknowledgements

Examples are inspired by OpenROAD and MacroPlacement by TILOS-AI-Institute.