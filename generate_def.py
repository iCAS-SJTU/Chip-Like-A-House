import argparse
import math

def generate_def_file(die_width, die_height, output_file, design_name="bp_be_top"):
    """
    Generate a .def file based on input DIE area with specified format, ROW, and TRACKS sections.
    
    Args:
        die_width (float): Width of the DIE in database units (DBU)
        die_height (float): Height of the DIE in database units (DBU)
        output_file (str): Output .def file path
        design_name (str): Name of the design
    """
    # Use input width and height directly as DBU
    width_dbu = int(die_width)
    height_dbu = int(die_height)
    
    # Generate DIEAREA with two coordinates
    die_area = f"( 0 0 ) ( {width_dbu} {height_dbu} )"
    
    # Calculate ROW DO step count
    start_x = 40280
    step = 380
    margin = 40200  # Unified margin for all cases
    do_count = math.floor((width_dbu - start_x - margin) / step)
    
    # Generate ROW section
    start_y = 42000
    y_increment = 2800
    row_margin = 48000  # Unified margin for rows
    max_y = height_dbu - row_margin
    rows = []
    row_index = 0
    current_y = start_y
    
    while current_y <= max_y:
        orient = "N" if row_index % 2 == 0 else "FS"
        row = f"ROW ROW_{row_index} FreePDK45_38x28_10R_NP_162NW_34O 40280 {current_y} {orient} DO {do_count} BY 1 STEP 380 0 ;"
        rows.append(row)
        current_y += y_increment
        row_index += 1
    
    # Check if enough rows were generated
    if row_index == 0:
        raise ValueError("DIE height too small to accommodate any rows.")
    
    # Generate TRACKS section
    tracks = []
    track_params = [
        ("metal1", "X", 190, 280), ("metal1", "Y", 140, 280),
        ("metal2", "X", 190, 380), ("metal2", "Y", 140, 380),
        ("metal3", "X", 190, 280), ("metal3", "Y", 140, 280),
        ("metal4", "X", 190, 560), ("metal4", "Y", 140, 560),
        ("metal5", "X", 190, 560), ("metal5", "Y", 140, 560),
        ("metal6", "X", 190, 560), ("metal6", "Y", 140, 560),
        ("metal7", "X", 1790, 1600), ("metal7", "Y", 1740, 1600),
        ("metal8", "X", 1790, 1600), ("metal8", "Y", 1740, 1600),
        ("metal9", "X", 3390, 3200), ("metal9", "Y", 3340, 3200),
        ("metal10", "X", 3390, 3200), ("metal10", "Y", 3340, 3200),
    ]
    
    for layer, direction, start, step in track_params:
        dimension = width_dbu if direction == "X" else height_dbu
        do = math.floor((dimension - start) / step)
        if layer in ["metal2", "metal4", "metal5", "metal6", "metal7", "metal8", "metal9", "metal10"]:
            do += 1
        tracks.append(f"TRACKS {direction} {start} DO {do} STEP {step} LAYER {layer} ;")
    
    # Combine sections
    row_section = "\n".join(rows)
    tracks_section = "\n".join(tracks)
    
    # DEF file content
    def_content = f"""VERSION 5.8 ;
DIVIDERCHAR "/" ;
BUSBITCHARS "[]" ;
DESIGN {design_name} ;
UNITS DISTANCE MICRONS 2000 ;
DIEAREA {die_area} ;
{row_section}
{tracks_section}

COMPONENTS 0 ;
END COMPONENTS

NETS 0 ;
END NETS

END DESIGN
"""
    
    # Write to output file
    with open(output_file, 'w') as f:
        f.write(def_content)
    print(f"DEF file generated: {output_file}")

def main():
    # Set up argument parser
    parser = argparse.ArgumentParser(description="Generate DEF file based on DIE area in DBU")
    parser.add_argument("-w", "--width", type=float, required=True, help="DIE width in database units (DBU)")
    parser.add_argument("-t", "--height", type=float, required=True, help="DIE height in database units (DBU)")
    parser.add_argument("-o", "--output", type=str, default="output.def", help="Output DEF file name")
    parser.add_argument("-d", "--design", type=str, default="bp_be_top", help="Design name")
    
    args = parser.parse_args()
    
    # Generate DEF file
    generate_def_file(args.width, args.height, args.output, args.design)

if __name__ == "__main__":
    main()