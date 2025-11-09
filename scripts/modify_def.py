import argparse
import re
import sys
import cv2
import numpy as np

# --- OpenCV-based Image Processing Functions ---

def merge_close_coords(coords, tolerance):
    """
    Merges close coordinate values into a single average value.
    """
    if not coords:
        return []
        
    coords.sort()
    
    merged_coords = []
    current_group = [coords[0]]
    
    for i in range(1, len(coords)):
        if coords[i] - current_group[-1] < tolerance:
            current_group.append(coords[i])
        else:
            merged_coords.append(int(round(np.mean(current_group))))
            current_group = [coords[i]]
            
    merged_coords.append(int(round(np.mean(current_group))))
    return merged_coords

def simplify_polygon(points):
    """
    Removes redundant collinear points to simplify a polygon.
    """
    if len(points) < 3:
        return points
    
    simplified_points = []
    for i in range(len(points)):
        p_prev = points[(i - 1 + len(points)) % len(points)]
        p_curr = points[i]
        p_next = points[(i + 1) % len(points)]
        
        # Use cross-product to check for collinearity
        vec1_x, vec1_y = p_curr[0] - p_prev[0], p_curr[1] - p_prev[1]
        vec2_x, vec2_y = p_next[0] - p_curr[0], p_next[1] - p_curr[1]
        
        cross_product = vec1_x * vec2_y - vec1_y * vec2_x
        
        # If the cross-product is very close to 0, the three points are collinear.
        # Tolerance can be adjusted as needed.
        if abs(cross_product) > 1:
            simplified_points.append(p_curr)
            
    return simplified_points

def generate_diearea_from_image(image_path, target_width, target_height, origin_at_zero=False):
    """
    Processes an image to generate a DIEAREA line based on its non-red outline.
    """
    img = cv2.imread(image_path, cv2.IMREAD_COLOR)
    if img is None:
        print(f"Error: Could not read image file {image_path}")
        return None
    
    img_height_px, img_width_px = img.shape[:2]
    
    # Pre-processing to find the non-red area
    hsv = cv2.cvtColor(img, cv2.COLOR_BGR2HSV)
    lower_red1 = np.array([0, 100, 100])
    upper_red1 = np.array([10, 255, 255])
    lower_red2 = np.array([160, 100, 100])
    upper_red2 = np.array([180, 255, 255])
    mask1 = cv2.inRange(hsv, lower_red1, upper_red1)
    mask2 = cv2.inRange(hsv, lower_red2, upper_red2)
    mask = cv2.bitwise_or(mask1, mask2)
    die_area_mask = cv2.bitwise_not(mask)
    
    # Morphological operations to clean up the mask
    kernel = np.ones((5, 5), np.uint8)
    die_area_mask = cv2.erode(die_area_mask, kernel, iterations=1)
    die_area_mask = cv2.dilate(die_area_mask, kernel, iterations=1)
    
    # Find contours
    contours, _ = cv2.findContours(die_area_mask, cv2.RETR_EXTERNAL, cv2.CHAIN_APPROX_NONE)
    if not contours:
        print("Error: No contours found in the image.")
        return None
    
    main_contour = max(contours, key=cv2.contourArea)
    
    # Scale physical coordinates
    scale_x = target_width / img_width_px
    scale_y = target_height / img_height_px
    
    physical_points_list = []
    if len(main_contour) > 0:
        p_prev = main_contour[-1][0]
    for i in range(len(main_contour)):
        p_curr = main_contour[i][0]
        p_next = main_contour[(i + 1) % len(main_contour)][0]
        
        # Filter for corner points using cross-product
        vec1_x, vec1_y = p_curr[0] - p_prev[0], p_curr[1] - p_prev[1]
        vec2_x, vec2_y = p_next[0] - p_curr[0], p_next[1] - p_curr[1]
        
        if abs(vec1_x * vec2_y - vec1_y * vec2_x) > 0.001:
            x_phy = p_curr[0] * scale_x
            y_phy = (img_height_px - p_curr[1]) * scale_y
            
            # Avoid adding duplicate points
            if not physical_points_list or (x_phy, y_phy) != physical_points_list[-1]:
                 physical_points_list.append((x_phy, y_phy))
        p_prev = p_curr

    # Snap points to a grid
    if not physical_points_list:
        print("Error: No corner points found.")
        return None
        
    x_coords = [p[0] for p in physical_points_list]
    y_coords = [p[1] for p in physical_points_list]
    
    # Tolerance based on physical scale (e.g., 5 pixels)
    tolerance_x = scale_x * 5
    tolerance_y = scale_y * 5
    
    snap_x = merge_close_coords(x_coords, tolerance_x)
    snap_y = merge_close_coords(y_coords, tolerance_y)
    
    final_points_list = []
    for x_raw, y_raw in physical_points_list:
        closest_x = min(snap_x, key=lambda val: abs(val - x_raw))
        closest_y = min(snap_y, key=lambda val: abs(val - y_raw))
        final_points_list.append((closest_x, closest_y))
    
    # Remove duplicate points while preserving order
    seen_points = set()
    unique_points = []
    for p in final_points_list:
        if p not in seen_points:
            unique_points.append(p)
            seen_points.add(p)
    final_points_list = unique_points

    # Simplify the polygon by removing collinear points
    final_points_list = simplify_polygon(final_points_list)

    # Shift origin to (0,0) if requested
    if origin_at_zero:
        min_x = min(p[0] for p in final_points_list)
        min_y = min(p[1] for p in final_points_list)
        final_points_list = [(p[0] - min_x, p[1] - min_y) for p in final_points_list]

    # Ensure contour is clockwise
    area_sum = 0.0
    for i in range(len(final_points_list)):
        p1 = final_points_list[i]
        p2 = final_points_list[(i + 1) % len(final_points_list)]
        area_sum += (p1[0] * p2[1] - p2[0] * p1[1])
        
    if area_sum > 0:
        final_points_list.reverse()
        
    # Format the final DIEAREA string
    die_area_str = "DIEAREA "
    for p in final_points_list:
        die_area_str += f"( {p[0]} {p[1]} ) "
    
    return die_area_str.strip() + " ;"

# --- DEF File Processing Functions ---

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

    # Create a mutually exclusive group for different modification modes
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
    
    group.add_argument(
        '-g', '--generate-from-image',
        type=str,
        help='Path to the image file to generate the DIEAREA from'
    )
    
    parser.add_argument(
        '-c', '--coordinates',
        type=int,
        nargs='+',
        help='Coordinate pairs in the format x1 y1 x2 y2 ... (4 numbers per pair, number of pairs must match rectangles)'
    )
    
    parser.add_argument(
        '--width',
        type=int,
        help='Physical width of the image in micrometers (required with --generate-from-image)'
    )
    
    parser.add_argument(
        '--height',
        type=int,
        help='Physical height of the image in micrometers (required with --generate-from-image)'
    )

    parser.add_argument(
        '--origin-at-zero',
        action='store_true',
        help='Shift the generated DIEAREA coordinates so the minimum x and y values are 0 (use with --generate-from-image)'
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
    
    # Validate image-based arguments
    if args.generate_from_image:
        if args.width is None or args.height is None:
            parser.error("--width and --height are required when using --generate-from-image")
        if args.coordinates or args.rectangles:
            parser.error("--coordinates and --rectangles cannot be used with --generate-from-image")

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
    return [(int(x), int(y)) for x, y in matches]

def identify_edge_and_internal(original_corners, point1, point2):
    """Determine which point is on the edge (including corners) and which is internal"""
    x0, y0 = original_corners[0]
    w, h = original_corners[1]

    # Check if a point is internal
    def is_internal(point):
        x, y = point
        return x0 < x < w and y0 < y < h

    # Check if a point is on the edge
    def is_edge(point):
        x, y = point
        return (
            (x == x0 and 0 <= y <= h) or
            (x == w and 0 <= y <= h) or
            (y == y0 and 0 <= x <= w) or
            (y == h and 0 <= x <= w)
        )

    if is_internal(point1) and is_edge(point2):
        return point2, point1
    elif is_internal(point2) and is_edge(point1):
        return point1, point2
    else:
        raise ValueError("One point must be inside the rectangle and one on the edge")

def generate_new_diearea(original_corners, top_right_pairs, bottom_right_pairs, top_left_pairs, bottom_left_pairs,
                        left_edge_pairs, top_edge_pairs, right_edge_pairs, bottom_edge_pairs):
    """Generate a new DIEAREA line to form a rectilinear shape"""
    x0, y0 = original_corners[0]
    w, h = original_corners[1]

    all_points = []
    
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
    lines = read_def_file(args.input)

    diearea_index = -1
    for i, line in enumerate(lines):
        if line.strip().startswith("DIEAREA"):
            diearea_index = i
            break

    if diearea_index == -1:
        print("Error: DIEAREA line not found")
        sys.exit(1)

    new_diearea = ""

    # Mode 1: Generate from image
    if args.generate_from_image:
        new_diearea = generate_diearea_from_image(
            args.generate_from_image,
            args.width,
            args.height,
            args.origin_at_zero
        )
        if new_diearea is None:
            sys.exit(1)

    # Mode 2: Direct line replacement
    elif args.diearea_line:
        new_diearea = args.diearea_line.rstrip().rstrip(';').strip() + ' ;'
    
    # Mode 3: Rectangle subtraction
    elif args.rectangles:
        if len(args.coordinates) != args.rectangles * 4:
            print(f"Error: Coordinate count must be {args.rectangles * 4} (4 coordinates per rectangle)")
            sys.exit(1)

        try:
            original_corners = parse_diearea(lines[diearea_index])
        except ValueError:
            print("Error: Invalid DIEAREA line format")
            sys.exit(1)

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

        try:
            new_diearea = generate_new_diearea(
                original_corners, top_right_pairs, bottom_right_pairs, top_left_pairs,
                bottom_left_pairs, left_edge_pairs, top_edge_pairs, right_edge_pairs,
                bottom_edge_pairs
            )
        except ValueError as e:
            print(f"Error: {str(e)}")
            sys.exit(1)

    write_def_file(args.output, lines, new_diearea, diearea_index)
    
    if args.verbose:
        print(f"Successfully processed file {args.input}, generated new file {args.output}")

def main():
    """Main function"""
    args = parse_arguments()
    process_def_file(args)

if __name__ == '__main__':
    main()