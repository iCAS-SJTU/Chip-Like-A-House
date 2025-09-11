import argparse
import re
import sys

def validate_rectangles(value):
    """Validate that the number of rectangles is >= 1"""
    ivalue = int(value)
    if ivalue < 1:
        raise argparse.ArgumentTypeError("Number of rectangles must be >= 1")
    return ivalue

def parse_arguments():
    """Parse command-line arguments"""
    parser = argparse.ArgumentParser(
        description="A tool to process .def files and modify the DIEAREA line",
        formatter_class=argparse.ArgumentDefaultsHelpFormatter
    )
    
    parser.add_argument(
        '-i', '--input',
        type=str,
        required=True,
        help='Input .def file path'
    )
    
    parser.add_argument(
        '-o', '--output',
        type=str,
        required=True,
        help='Output .def file path'
    )

    # Create a mutually exclusive group for rectangle-based input and direct DIEAREA line input
    group = parser.add_mutually_exclusive_group(required=True)
    
    group.add_argument(
        '-r', '--rectangles',
        type=validate_rectangles,
        help='Number of rectangles to remove (must be >= 1)'
    )
    
    group.add_argument(
        '--diearea-line',
        type=str,
        help='Directly specify the new DIEAREA line (e.g., "DIEAREA ( 0 0 ) ( 1000 1000 ) ;")'
    )
    
    parser.add_argument(
        '-c', '--coordinates',
        type=int,
        nargs='+',
        help='Coordinate pairs in the format x1 y1 x2 y2 ... (4 numbers per pair, number of pairs must match rectangles)'
    )
    
    parser.add_argument(
        '--verbose',
        action='store_true',
        help='Enable verbose output mode'
    )

    args = parser.parse_args()

    # Validate that coordinates are provided if rectangles is specified
    if args.rectangles is not None and args.coordinates is None:
        parser.error("--coordinates is required when --rectangles is specified")
    
    # Validate that coordinates are not provided if diearea-line is specified
    if args.diearea_line is not None and args.coordinates is not None:
        parser.error("--coordinates cannot be used with --diearea-line")
    
    return args

def read_def_file(input_file):
    """Read the contents of a .def file"""
    try:
        with open(input_file, 'r', encoding='utf-8') as f:
            return f.readlines()
    except FileNotFoundError:
        print(f"Error: File {input_file} does not exist")
        sys.exit(1)

def parse_diearea(line):
    """Parse coordinates from the DIEAREA line"""
    matches = re.findall(r'\(\s*(\d+)\s+(\d+)\s*\)', line)
    if len(matches) < 2:
        raise ValueError("DIEAREA line must contain at least 2 coordinate pairs")


def identify_edge_and_internal(original_corners, point1, point2):
    """Determine which point is on the edge (including corners) and which is internal"""
    if len(original_corners) < 2:
        raise ValueError("Original corners must contain at least 2 points")
    
    x0, y0 = original_corners[0]  # Usually (0, 0)
    w, h = original_corners[1]    # Width and height of the rectangle
    
    # Validate input points
    if point1 == point2:
        raise ValueError(f"The two points cannot be the same: {point1}")
    
    # Validate coordinate ranges
    for point in [point1, point2]:
        x, y = point
        if x < 0 or y < 0:
            raise ValueError(f"Coordinates cannot be negative: {point}")
        if x > w or y > h:
            raise ValueError(f"Coordinates cannot exceed die area ({w}, {h}): {point}")

    # Check if a point is internal
    def is_internal(point):
        x, y = point
        return x0 < x < w and y0 < y < h

    # Check if a point is on the edge
    def is_edge(point):
        x, y = point
        return (
            (x == x0 and y0 <= y <= h) or  # Left edge (x=0, 0<=y<=h)
            (x == w and y0 <= y <= h) or   # Right edge (x=w, 0<=y<=h)
            (y == y0 and x0 <= x <= w) or  # Bottom edge (y=0, 0<=x<=w)
            (y == h and x0 <= x <= w)      # Top edge (y=h, 0<=x<=w)
        )

    if is_internal(point1) and is_edge(point2):
        return point2, point1  # point2 is edge, point1 is internal
    elif is_internal(point2) and is_edge(point1):
        return point1, point2  # point1 is edge, point2 is internal
    else:
        raise ValueError("One point must be inside the rectangle and one on the edge")

def generate_new_diearea(original_corners, top_right_pairs, bottom_right_pairs, top_left_pairs, bottom_left_pairs,
                        left_edge_pairs, top_edge_pairs, right_edge_pairs, bottom_edge_pairs):
    """Generate a new DIEAREA line to form a rectilinear shape"""
    x0, y0 = original_corners[0]  # Usually (0, 0)
    w, h = original_corners[1]    # Width and height of the rectangle

    # Collect all points
    all_points = [] 

    # Process corner points
    if len(bottom_left_pairs) == 0:
        all_points.append((x0, y0))
    else:
        for corner, internal in bottom_left_pairs:
            x1, y1 = corner
            x2, y2 = internal
            all_points.extend([(x2, y0), (x2, y2), (x0, y2)])

    if len(left_edge_pairs) > 0:
        for edge_point, internal in left_edge_pairs:
            x1, y1 = edge_point
            x2, y2 = internal
            if y1 > y2:
                all_points.extend([(x1, y2), (x2, y2), (x2, y1), (x1, y1)])
            else:
                all_points.extend([(x1, y1), (x2, y1), (x2, y2), (x1, y2)])

    if len(top_left_pairs) == 0:
        all_points.append((x0, h))
    else:
        for corner, internal in top_left_pairs:
            x1, y1 = corner
            x2, y2 = internal
            all_points.extend([(x0, y2), (x2, y2), (x2, h)])

    if len(top_edge_pairs) > 0:
        for edge_point, internal in top_edge_pairs:
            x1, y1 = edge_point
            x2, y2 = internal
            if x1 > x2:
                all_points.extend([(x2, y1), (x2, y2), (x1, y2), (x1, y1)])
            else:
                all_points.extend([(x1, y1), (x1, y2), (x2, y2), (x2, y1)])
    
    if len(top_right_pairs) == 0:
        all_points.append((w, h))
    else:
        for corner, internal in top_right_pairs:
            x1, y1 = corner
            x2, y2 = internal
            all_points.extend([(x2, h), (x2, y2), (w, y2)])

    if len(right_edge_pairs) > 0:
        for edge_point, internal in right_edge_pairs:
            x1, y1 = edge_point
            x2, y2 = internal
            if y1 > y2:
                all_points.extend([(x1, y1), (x2, y1), (x2, y2), (x1, y2)])
            else:
                all_points.extend([(x1, y2), (x2, y2), (x2, y1), (x1, y1)])

    if len(bottom_right_pairs) == 0:
        all_points.append((w, y0))
    else:
        for corner, internal in bottom_right_pairs:
            x1, y1 = corner
            x2, y2 = internal
            all_points.extend([(w, y2), (x2, y2), (x2, y0)])

    if len(bottom_edge_pairs) > 0:
        for edge_point, internal in bottom_edge_pairs:
            x1, y1 = edge_point
            x2, y2 = internal
            if x1 > x2:
                all_points.extend([(x1, y1), (x1, y2), (x2, y2), (x2, y1)])
            else:
                all_points.extend([(x2, y1), (x2, y2), (x1, y2), (x1, y1)])

    # Clean up duplicate points - loop until no more consecutive duplicates
    while True:
        # Step 1: Remove head and tail if they are the same
        if len(all_points) > 1 and all_points[0] == all_points[-1]:
            all_points = all_points[1:]
        
        # Step 2: Remove consecutive duplicate points
        cleaned_points = []
        has_duplicates = False
        
        for i in range(len(all_points)):
            # Add current point if it's not a duplicate of the previous one
            if i == 0 or all_points[i] != all_points[i-1]:
                cleaned_points.append(all_points[i])
            else:
                has_duplicates = True
        
        all_points = cleaned_points
        
        # Exit loop if no duplicates were found
        if not has_duplicates:
            break

    # Format DIEAREA line
    points_str = ' '.join(f'( {x} {y} )' for x, y in all_points)
    return f"DIEAREA {points_str} ;"

def write_def_file(output_file, lines, new_diearea, diearea_index):
    """Write the new .def file"""
    try:
        lines[diearea_index] = new_diearea + '\n'
        with open(output_file, 'w', encoding='utf-8') as f:
            f.writelines(lines)
    except Exception as e:
        print(f"Error: Failed to write to file {output_file}: {str(e)}")
        sys.exit(1)

def process_def_file(args):
    """Main logic for processing the .def file"""
    # Read input file
    lines = read_def_file(args.input)

    # Find DIEAREA line
    diearea_index = -1
    for i, line in enumerate(lines):
        if line.strip().startswith("DIEAREA"):
            diearea_index = i
            break

    if diearea_index == -1:
        print("Error: DIEAREA line not found")
        sys.exit(1)

    # If diearea-line is provided, use it directly, ensuring no extra spaces before semicolon
    if args.diearea_line:
        new_diearea = args.diearea_line.rstrip().rstrip(';').strip() + ' ;'
        write_def_file(args.output, lines, new_diearea, diearea_index)
        if args.verbose:
            print(f"Successfully replaced DIEAREA line in {args.input}, generated new file {args.output}")
        return

    # Original rectangle-based processing
    # Validate coordinate count
    if len(args.coordinates) != args.rectangles * 4:
        print(f"Error: Coordinate count must be {args.rectangles * 4} (4 coordinates per rectangle)")
        sys.exit(1)

    # Parse DIEAREA coordinates
    try:
        original_corners = parse_diearea(lines[diearea_index])
        if len(original_corners) < 2:
            raise ValueError("DIEAREA must contain at least 2 coordinate pairs")
    except (ValueError, IndexError) as e:
        print(f"Error: Invalid DIEAREA line format - {str(e)}")
        sys.exit(1)

    # Process coordinate pairs into eight lists based on edge/corner
    top_right_pairs = []
    bottom_right_pairs = []
    top_left_pairs = []
    bottom_left_pairs = []
    left_edge_pairs = []
    top_edge_pairs = []
    right_edge_pairs = []
    bottom_edge_pairs = []
    try:
        for i in range(0, len(args.coordinates), 4):
            x1, y1, x2, y2 = args.coordinates[i:i+4]
            edge_point, internal = identify_edge_and_internal(original_corners, (x1, y1), (x2, y2))
            x0, y0 = original_corners[0]
            w, h = original_corners[1]
            if edge_point == (w, h):
                top_right_pairs.append((edge_point, internal))
            elif edge_point == (w, y0):
                bottom_right_pairs.append((edge_point, internal))
            elif edge_point == (x0, h):
                top_left_pairs.append((edge_point, internal))
            elif edge_point == (x0, y0):
                bottom_left_pairs.append((edge_point, internal))
            elif edge_point[0] == x0 and 0 < edge_point[1] < h:
                left_edge_pairs.append((edge_point, internal))
            elif edge_point[1] == h and 0 < edge_point[0] < w:
                top_edge_pairs.append((edge_point, internal))
            elif edge_point[0] == w and 0 < edge_point[1] < h:
                right_edge_pairs.append((edge_point, internal))
            elif edge_point[1] == y0 and 0 < edge_point[0] < w:
                bottom_edge_pairs.append((edge_point, internal))
    except ValueError as e:
        print(f"Error: {str(e)}")
        sys.exit(1)

    # Generate new DIEAREA line
    try:
        new_diearea = generate_new_diearea(original_corners, top_right_pairs, bottom_right_pairs, top_left_pairs,
                                          bottom_left_pairs, left_edge_pairs, top_edge_pairs, right_edge_pairs,
                                          bottom_edge_pairs)
    except ValueError as e:
        print(f"Error: {str(e)}")
        sys.exit(1)

    # Write output file
    write_def_file(args.output, lines, new_diearea, diearea_index)
    
    if args.verbose:
        print(f"Successfully processed file {args.input}, generated new file {args.output}, rectangles: {args.rectangles}")

def main():
    """Main function"""
    args = parse_arguments()
    process_def_file(args)

if __name__ == '__main__':
    main()