# R-Zoo: Evaluation Subset — Rectilinear Floorplan Benchmarks

Benchmarking is fundamental to advancing physical design automation, as it enables quantitative and reproducible comparison of competing algorithms. R-Zoo provides a standardized collection of rectilinear floorplans featuring diverse notch patterns, aspect ratios, and whitespace distributions, allowing researchers to test optimization algorithms under controlled yet realistic conditions. Designs range from single-notch layouts to multi-notch floorplans, ensuring broad coverage across possible scenarios. Each layout is verified for legality and can be directly integrated into open-source flows such as DREAMPlace and OpenROAD, offering a reproducible and extensible environment for evaluating placement quality, whitespace utilization, and congestion metrics. This subset is particularly suitable for assessing rectilinear-aware placement algorithms, whitespace diagnosis frameworks, and topology-driven co-optimization methods.

## Subset Overview

| Design | Single-notch | Multi-notch |
|:------:|:------------:|:-----------:|
| Ariane133 | [ariane133_single_notch.def](ariane133_single_notch.def) | [ariane133_multi_notch.def](ariane133_multi_notch.def) |
| Ariane136 | [ariane136_single_notch.def](ariane136_single_notch.def) | [ariane136_multi_notch.def](ariane136_multi_notch.def) |
| BlackParrot — Back End (BP BE) | [bp_be_single_notch.def](bp_be_single_notch.def) | [bp_be_multi_notch.def](bp_be_multi_notch.def) |
| BlackParrot — Front End (BP FE) | [bp_fe_single_notch.def](bp_fe_single_notch.def) | [bp_fe_multi_notch.def](bp_fe_multi_notch.def) |
| BlackParrot — Multi-core (BP Multi) | [bp_multi_single_notch.def](bp_multi_single_notch.def) | [bp_multi_multi_notch.def](bp_multi_multi_notch.def) |
| SwervWrapper (SW) | [sw_single_notch.def](sw_single_notch.def) | [sw_multi_notch.def](sw_multi_notch.def) |
| RocketTile (TR) | [tr_single_notch.def](tr_single_notch.def) | [tr_multi_notch.def](tr_multi_notch.def) |

> Notes: All DEFs share the same LEF/tech LEF stacks as in the main dataset for their respective designs (see `dataset/sample_*/input_sources/`). Ensure consistent DBU per micron when mixing with other sources.

## Usage

These DEFs are plug-in benchmarks for physical design research:

- Placement evaluation: feed a baseline macro/standard-cell placer and compare final HPWL, overflow, density, and timing-aware proxies.
- Whitespace analysis: quantify utilization vs. notch severity; evaluate legalization robustness.
- Congestion studies: run global routing proxies or congestion estimation and compare hotspots across single vs. multi-notch shapes.

Minimal guidance:

1) Provide the corresponding technology/lib LEFs from the main dataset (e.g., `dataset/sample_*/input_sources/`).
2) Import the chosen DEF into your flow (OpenROAD, DREAMPlace, etc.).
3) Run your standard placement recipe and log metrics (HPWL, density/overflow, congestion score). Fix seeds for reproducibility.

## Reporting

- Identify design (e.g., Ariane136) and notch class (single vs. multi).
- Record key metrics: HPWL, placement density/overflow, congestion proxy (and timing proxy if applicable).
- Specify tool version(s), LEF stack, and DBU/µm.
- Include random seed and runtime environment for reproducibility.

## License

This subset follows the repository’s MIT License (see LICENSE if present).

## Acknowledgements

Tools and flows referenced include DREAMPlace and OpenROAD; see the root README for additional credits.

