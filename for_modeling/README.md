# R-Zoo: Modeling Subset — Learning-Based Floorplan Dataset

A multimodal (DEF + image) collection of rectilinear floorplans for seven open-source SoC / tile designs. Tailored for supervised, semi-/self-supervised learning tasks in physical design (e.g., whitespace prediction, reconstruction, placement optimization).

## Subset Overview

| Design | Gallery (click to open design folder) | Sources (LEF/Verilog) | # DEFs |
|:-----:|:---------------------------------------|:----------------------|:-----:|
| Ariane133 | [![Ariane133](../gallery/gallery_ariane133.jpg)](dataset/sample_ariane133/) | [Nangate45.lef](dataset/sample_ariane133/input_sources/Nangate45.lef)<br>[Nangate45_tech.lef](dataset/sample_ariane133/input_sources/Nangate45_tech.lef)<br>[Ng45_ariane133.v](dataset/sample_ariane133/input_sources/Ng45_ariane133.v)<br>[fake_macros.lef](dataset/sample_ariane133/input_sources/fake_macros.lef)<br>[fakeram45_256x16.lef](dataset/sample_ariane133/input_sources/fakeram45_256x16.lef) | 18 |
| Ariane136 | [![Ariane136](../gallery/gallery_ariane136.jpg)](dataset/sample_ariane136/) | [Nangate45.lef](dataset/sample_ariane136/input_sources/Nangate45.lef)<br>[Nangate45_tech.lef](dataset/sample_ariane136/input_sources/Nangate45_tech.lef)<br>[Ng45_ariane136.v](dataset/sample_ariane136/input_sources/Ng45_ariane136.v)<br>[fake_macros.lef](dataset/sample_ariane136/input_sources/fake_macros.lef)<br>[fakeram45_256x16.lef](dataset/sample_ariane136/input_sources/fakeram45_256x16.lef) | 18 |
| BP BE | [![BP BE](../gallery/gallery_bp_be.jpg)](dataset/sample_bp_be/) | [Nangate45.lef](dataset/sample_bp_be/input_sources/Nangate45.lef)<br>[Nangate45_tech.lef](dataset/sample_bp_be/input_sources/Nangate45_tech.lef)<br>[Ng45_bp_be.v](dataset/sample_bp_be/input_sources/Ng45_bp_be.v)<br>[fake_macros.lef](dataset/sample_bp_be/input_sources/fake_macros.lef)<br>[fakeram45_512x64.lef](dataset/sample_bp_be/input_sources/fakeram45_512x64.lef)<br>[fakeram45_64x15.lef](dataset/sample_bp_be/input_sources/fakeram45_64x15.lef)<br>[fakeram45_64x96.lef](dataset/sample_bp_be/input_sources/fakeram45_64x96.lef) | 18 |
| BP FE | [![BP FE](../gallery/gallery_bp_fe.jpg)](dataset/sample_bp_fe/) | [Nangate45.lef](dataset/sample_bp_fe/input_sources/Nangate45.lef)<br>[Nangate45_tech.lef](dataset/sample_bp_fe/input_sources/Nangate45_tech.lef)<br>[Ng45_bp_fe.v](dataset/sample_bp_fe/input_sources/Ng45_bp_fe.v)<br>[fake_macros.lef](dataset/sample_bp_fe/input_sources/fake_macros.lef)<br>[fakeram45_512x64.lef](dataset/sample_bp_fe/input_sources/fakeram45_512x64.lef)<br>[fakeram45_64x7.lef](dataset/sample_bp_fe/input_sources/fakeram45_64x7.lef)<br>[fakeram45_64x96.lef](dataset/sample_bp_fe/input_sources/fakeram45_64x96.lef) | 16 |
| BP Multi | [![BP Multi](../gallery/gallery_bp_multi.jpg)](dataset/sample_bp_multi/) | [Nangate45.lef](dataset/sample_bp_multi/input_sources/Nangate45.lef)<br>[Nangate45_tech.lef](dataset/sample_bp_multi/input_sources/Nangate45_tech.lef)<br>[Ng45_bp_multi.v](dataset/sample_bp_multi/input_sources/Ng45_bp_multi.v)<br>[fake_macros.lef](dataset/sample_bp_multi/input_sources/fake_macros.lef)<br>[fakeram45_256x96.lef](dataset/sample_bp_multi/input_sources/fakeram45_256x96.lef)<br>[fakeram45_32x64.lef](dataset/sample_bp_multi/input_sources/fakeram45_32x64.lef)<br>[fakeram45_512x64.lef](dataset/sample_bp_multi/input_sources/fakeram45_512x64.lef)<br>[fakeram45_64x15.lef](dataset/sample_bp_multi/input_sources/fakeram45_64x15.lef)<br>[fakeram45_64x7.lef](dataset/sample_bp_multi/input_sources/fakeram45_64x7.lef)<br>[fakeram45_64x96.lef](dataset/sample_bp_multi/input_sources/fakeram45_64x96.lef) | 18 |
| SwervWrapper | [![SW](../gallery/gallery_sw.jpg)](dataset/sample_sw/) | [Nangate45.lef](dataset/sample_sw/input_sources/Nangate45.lef)<br>[Nangate45_tech.lef](dataset/sample_sw/input_sources/Nangate45_tech.lef)<br>[Ng45_sw.v](dataset/sample_sw/input_sources/Ng45_sw.v)<br>[fake_macros.lef](dataset/sample_sw/input_sources/fake_macros.lef)<br>[fakeram45_2048x39.lef](dataset/sample_sw/input_sources/fakeram45_2048x39.lef)<br>[fakeram45_256x34.lef](dataset/sample_sw/input_sources/fakeram45_256x34.lef)<br>[fakeram45_64x21.lef](dataset/sample_sw/input_sources/fakeram45_64x21.lef) | 18 |
| RocketTile | [![TR](../gallery/gallery_tr.jpg)](dataset/sample_tr/) | [Nangate45.lef](dataset/sample_tr/input_sources/Nangate45.lef)<br>[Nangate45_tech.lef](dataset/sample_tr/input_sources/Nangate45_tech.lef)<br>[Ng45_tr.v](dataset/sample_tr/input_sources/Ng45_tr.v)<br>[fake_macros.lef](dataset/sample_tr/input_sources/fake_macros.lef)<br>[fakeram45_1024x32.lef](dataset/sample_tr/input_sources/fakeram45_1024x32.lef)<br>[fakeram45_64x32.lef](dataset/sample_tr/input_sources/fakeram45_64x32.lef) | 15 |

> Image thumbnails link to each design's modeling dataset folder. Inside, `floorplan_plots/` pairs visually with `def_files/` (see per-design README for clickable mapping).

## Motivation

With the growing adoption of data-driven, learning-based EDA methodologies, the availability of structured and validated layout data has become increasingly important. R-Zoo offers both image-based and DEF-based representations of floorplans, making it ideal for supervised and self-supervised learning tasks that combine geometric features. The dataset can be used to train neural networks for tasks such as whitespace prediction, layout reconstruction, or floorplan placement optimization. The synchronized multimodal data enables model developers to exploit physical design cues, while the verified legality of each layout ensures that learned representations remain physically valid. Moreover, the built-in scripts supporting layout modification allow scalable dataset expansion, enabling researchers to easily synthesize new variants for training and ablation studies.

## Repository layout

```
for_modeling/
├── dataset/
│   └── sample_<design>/
│       ├── def_files/            # Canonical rectilinear DEF variants
│       ├── floorplan_plots/      # PNG renderings aligned index-wise to DEFs
│       ├── input_sources/        # LEF + tech LEF + Verilog + macro LEFs
│       ├── input_<design>.def    # Base rectangular starting floorplan
│       ├── <design>_modifier.sh  # Script to batch-produce variants
│       └── README.md             # Per-design gallery (image→DEF mapping)
├── scripts/                      # Generation + modification Python + shell tools
│   ├── generate_def.py
│   ├── modify_def.py
│   ├── default_modifier.sh
│   ├── default_config.json
│   └── rng_helper.py
└── README.md                     # (This file)
```

## Modalities

- Geometry (DEF): Precise DIEAREA polygon, ROW placements, TRACKS, site grid — forms the structural input for graph-based or sequence models.
- Raster (PNG): Floorplan visualizations (macro silhouettes + notch contours) — suitable for CNN/ViT feature extraction and multimodal fusion.

## Usage

### Data loading tips

1. Use file name tokens (`small_rects_###`, `medium_rects_###`, `large_rects_###`) to auto-label notch depth classes.
2. Parse DIEAREA polygon: look for the line beginning with `DIEAREA` and collect `( x y )` coordinate pairs until `;`.
3. Macro extraction: `COMPONENTS` section includes instance names and placed coordinates (`+ PLACED ( x y ) N | FN | S | FS`).
4. Align PNG to DEF: Indices are consistent; e.g. `medium_rects_003.png` ↔ `medium_rects_003.def`.
5. Normalize coordinates by DIEAREA width/height for model-invariant scaling.

### Extending

To synthesize new variants:

```bash
PY_SCRIPT=../../scripts/modify_def.py \
	bash <design>_modifier.sh 25   # Generate 25 new DEF + PNG pairs
```

Or programmatically:

```bash
python3 ../../scripts/modify_def.py -i input_<design>.def -o def_files/custom_001.def \
	-r 2 -c 0 150000 200000 500000  800000 0 600000 350000 --verbose
```

For image-driven shapes (optional OpenCV):

```bash
python3 ../../scripts/modify_def.py -i input_<design>.def -o def_files/img_001.def \
	--generate-from-image path/to/mask.png --width 6000000 --height 4000000 --origin-at-zero
```

### Recommended splits

| Split | Suggested Ratio | Strategy |
|-------|-----------------|----------|
| Train | 70% | Stratified by notch depth + design |
| Val | 15% | Ensure each design + depth present |
| Test | 15% | Hold out unseen indices per design |

Deterministic splits can be seeded via file name hashing (e.g., SHA1 mod 100).

### Quality & legality

All distributed DEFs have validated DIEAREA polygons and non-overlapping macro placements (source verification performed when produced). This reduces label noise and prevents models from learning physically invalid geometry. Always re-check legality if you substantially alter generation parameters.

## License

Distributed under MIT License; see root LICENSE file if present.

## Acknowledgements

Main flow and generation concepts inspired by open-source physical design efforts including OpenROAD and MacroPlacement.

Please cite the main R-Zoo repository if using this modeling subset in publications. Distributed under MIT License; see root LICENSE file if present.

---

Happy modeling! Extend with additional modal encodings (e.g., netlists or timing abstracts) to enrich downstream learning tasks.

