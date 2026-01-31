# R-Zoo: Evaluation Subset — Rectilinear Floorplan Benchmarks

This repository provides the evaluation subset of the R-Zoo rectilinear floorplan benchmark, designed for reproducible and geometry-aware physical design research. The subset contains rectilinear DIEAREA definitions with varying notch complexity, as well as examples exhibiting diverse legality issues, with an overall ligeality of 11/14.

To facilitate reproducibility and independent verification, the subset intentionally includes both legal and illegal floorplans. The illegal examples are curated to cover different categories of geometric and syntactic violations (e.g., self-intersection, repeated vertices, and invalid cutout configurations), enabling users to directly evaluate and validate legality checking tools, including LLM-based verifiers, under controlled conditions.

This design allows researchers to reproduce the reported legality assessment results, inspect false positives or false negatives, and benchmark the robustness of alternative verification pipelines using the same input set.

## Subset Overview

| Design | Single-notch | Legality | Multi-notch | Legality |
|:------:|:------------:|:--------:|:-----------:|:--------:|
| Ariane133 | [ariane133_single_notch.def](ariane133_single_notch.def) | Legal | [ariane133_multi_notch.def](ariane133_multi_notch.def) | Legal |
| Ariane136 | [ariane136_single_notch.def](ariane136_single_notch.def) | Legal | [ariane136_multi_notch.def](ariane136_multi_notch.def) | Legal |
| BlackParrot — Back End (BP BE) | [bp_be_single_notch.def](bp_be_single_notch.def) | Illegal | [bp_be_multi_notch.def](bp_be_multi_notch.def) | Legal |
| BlackParrot — Front End (BP FE) | [bp_fe_single_notch.def](bp_fe_single_notch.def) | Legal | [bp_fe_multi_notch.def](bp_fe_multi_notch.def) | Illegal |
| BlackParrot — Multi-core (BP Multi) | [bp_multi_single_notch.def](bp_multi_single_notch.def) | Legal | [bp_multi_multi_notch.def](bp_multi_multi_notch.def) | Illegal |
| SwervWrapper (SW) | [sw_single_notch.def](sw_single_notch.def) | Legal | [sw_multi_notch.def](sw_multi_notch.def) | Legal |
| RocketTile (TR) | [tr_single_notch.def](tr_single_notch.def) | Legal | [tr_multi_notch.def](tr_multi_notch.def) | Legal |

> Notes: All DEFs share the same LEF/tech LEF stacks as in the main dataset for their respective designs (see `dataset/sample_*/input_sources/`). Ensure consistent DBU per micron when mixing with other sources.

## Usage

### Input

A folder of .def files. (eg. a folder of four files: [ariane136_single_notch.def](ariane136_single_notch.def),  [ariane136_multi_notch.def](ariane136_multi_notch.def), [bp_be_single_notch.def](bp_be_single_notch.def), [bp_fe_multi_notch.def](bp_fe_multi_notch.def))

### Prompt Structure (Representative Example)

The LLM is prompted in a deterministic legality-checking role. A representative prompt structure is shown below.

#### Role Definition
```
You are an EDA physical design legality checker.
Your task is to verify whether a given rectilinear .def file is geometrically and syntactically legal.
```

#### Verification Checklist
```
Please verify the following conditions:
1. The contents follow DEF grammar convention.
2. The polygon is closed but not repeated (first point ≠ last point).
3. The polygon is a non-intersecting rectilinear polygon.
4. Cutouts do not overlap.
```

#### Output Constraint
```
Please return the result in the following format:

For each file:
LEGALITY: {LEGAL | ILLEGAL}
REASON: <brief explanation>

At the end:
Conclusively, the legality rate of the input folder is <legality rate>.
```

---

### Example Verification Output

#### Sample output for legal files
```
ariane136_single_notch.def

LEGALITY: LEGAL
REASON: DEF grammar is valid; DIEAREA polygon is rectilinear, closed without repetition, non-self-intersecting, and has no overlapping cutouts.

ariane136_multi_notch.def

LEGALITY: LEGAL
REASON: DEF syntax is correct; DIEAREA polygon is a simple rectilinear polygon; all cutouts are         non-overlapping.
```

#### Sample output for illegal files
```
bp_be_single_notch.def

LEGALITY: ILLEGAL
REASON: DIEAREA polygon is non-simple, exhibiting a self-intersection or self-touching vertex, violating rectilinear polygon constraints.

bp_fe_multi_notch.def

LEGALITY: ILLEGAL
REASON: DIEAREA polygon repeats the first vertex as the last vertex and is also non-simple, violating closure and non-intersection rules.
```

#### Sample Summary
```
Conclusively, the legality rate of the input folder is 50% (2/4).
```

## Reporting

- Identify design (e.g., Ariane136) and notch class (single vs. multi).
- Record key metrics: HPWL, placement density/overflow, congestion proxy (and timing proxy if applicable).
- Specify tool version(s), LEF stack, and DBU/µm.
- Include random seed and runtime environment for reproducibility.

## License

This subset follows the repository’s MIT License.

## Acknowledgements

Tools and flows referenced include DREAMPlace and OpenROAD; see the root README for additional credits.

