# Chip-Like-A-House: Rectilinear Floorplanning Benchmark with Design Constraints for Large-scale Chips

## Project Overview

This repository contains a set of Python scripts and a sample shell script designed to generate and modify `.def` (Design Exchange Format) files, primarily for rectilinear floorplanning with design constraints for large-scale chips. The tools facilitate the creation of basic `.def` outlines and allow for complex rectilinear `DIEAREA` modifications, which are crucial for defining chip boundaries and irregular shapes in integrated circuit layouts.

## Features

* **`generate_def.py`**:
    * Generates a `.def` file based on a specified `DIEAREA` (width and height in Database Units - DBU).
    * Automatically calculates and includes `ROW` sections with alternating orientations.
    * Generates `TRACKS` sections for various metal layers (by default, metal1 to metal10) with configurable start points and steps.
    * Outputs a complete, basic `.def` file structure (with `COMPONENTS` and `NETS` empty).

* **`modify_def.py`**:
    * A versatile tool for modifying the `DIEAREA` section of an existing `.def` file, in order to realize rectilinear floorplanning.
    * Supports two primary modification modes:
        * **Rectangle-based Cutouts (`--rectangles` and `--coordinates`)**: Allows you to define rectangular areas (e.g., L-shaped corners, U-shaped notches) to be "cut out" from the original rectangular `DIEAREA`, resulting in a rectilinear shape.
        * **Direct DIEAREA Line Specification (`--diearea-line`)**: Enables you to directly input a complete rectilinear `DIEAREA` line, providing full control over complex chip boundary definitions.
        * **Image-based Contour Recognition (`--generate-from-image`)**: Enables you to directly input an image with desired rectilinear shape, and the required width and height. After recognizing the contour with OpenCV and rearranging the coordinates, the `DIEAREA` line will be automatically replaced by the rectilinear one.
    * Identifies edge and internal points to correctly form the new rectilinear boundary.

* **`modify_sample.sh`**:
    * A demonstration shell script that showcases various usage examples of `modify_def.py`.
    * Includes examples for:
        * Single corner L-shape cutouts (bottom-left, bottom-right, top-left, top-right).
        * Single edge U-shape/notch cutouts (left, right, top, bottom).
        * Multiple non-overlapping cutouts (two diagonal corners, three holes, four corners).
        * Approximating a complex external contour using direct `DIEAREA` line specification.
    * Creates an `generated_rectilinear_defs` output directory to store modified `.def` files.

## Getting Started

### Prerequisites

* Python 3.x
* Git (for version control and cloning this repository)
* A Unix-like environment (for running `modify_sample.sh`, e.g., Linux, macOS, WSL on Windows)

### Installation

#### 1. Clone the repository:

```bash
git clone https://github.com/SurviveAll/Chip-Like-A-House.git
cd Chip-Like-A-House
```

### Usage

#### 1. Generating a Basic `.def` File (`generate_def.py`)

To generate a new `.def` file:

```bash
python generate_def.py -w <width_dbu> -t <height_dbu> -o <output_file_name.def> -d <design_name>
```

#### 2. Add `COMPONENTS` and `NETS` to the Basic `.def` File (manually)

The `generate_def.py` script creates a `.def` file with empty `COMPONENTS` and `NETS `sections. For a complete and functional `.def` file, you will typically need to populate these sections with your design's components (macros, standard cells) and their interconnections. This step is usually performed by other tools in a standard physical design flow (e.g., placement tools).

#### 3. Modify `DIEAREA` line (`modify_def.py` or `modify_sample.sh`)

As described in the Features section, `modify_def.py` allows you to alter the `DIEAREA` of an existing `.def` file. This is crucial for creating non-rectangular chip boundaries, which can be useful for various purposes like fitting into specific package types or avoiding keep-out zones.

* Directly Specify `DIEAREA` Line

    ```bash
    python modify_def.py -i <input_def_file> -o <output_def_file> --diearea-line "DIEAREA ( x0 y0 ) ( x1 y1 ) ... ( xN yN ) ;" [--verbose]
    ```

* Use Rectangles for Cutouts

    ```bash
    python modify_def.py -i <input_def_file> -o <output_def_file> --rectangles <num_rects> --coordinates <x1 y1 x2 y2 ...> [--verbose]
    ```

* Apply OpenCV to Transform Contour from an Image

    ```bash
    python modify_def.py -i <input_def_file> -o <output_def_file> --generate-from-image --width <desired_width> --height <desired_height> [--origin-at-zero] [--verbose]
    ```

* Batch production using `modify_sample.sh`

    The `modify_sample.sh` script demonstrates various complex DIEAREA modifications using `modify_def.py`. 
    
    Before using this bash, make sure you modify the input file:

    ```bash
    INPUT_DEF_BASE="your_original_def.def"
    ```

    Then execute the script:

    ```bash
    bash modify_sample.sh
    ```
    
    Contents in `modify_sample.sh` can be adjusted for other applications.