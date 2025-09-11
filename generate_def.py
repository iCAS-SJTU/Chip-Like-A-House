import argparse
import math
import json
import os

class DEFGenerator:
    """
    Improved DEF file generator with configurable parameters
    """
    
    def __init__(self, config_file=None):
        """
        Initialize with default or custom configuration
        
        Args:
            config_file (str): Path to JSON configuration file
        """
        # Default configuration
        self.config = {
            "design": {
                "name": "bp_be",
                "version": "5.8",
                "dbu_per_micron": 2000
            },
            "cell_library": {
                "name": "FreePDK45_38x28_10R_NP_162NW_34O",
                "width": 380,    # Standard cell width in DBU
                "height": 2800   # Standard cell height in DBU
            },
            "margins": {
                # More reasonable percentage-based margins
                # Based on typical I/O + seal ring + power ring requirements
                "left_percent": 0.005,      # ~70um for large chips, scales down for small chips
                "right_percent": 0.005,     # Symmetric left/right
                "bottom_percent": 0.005,    # Slightly less for bottom (fewer constraints)
                "top_percent": 0.005,       # More for top (power/clock distribution)
                
                # Engineering minimums based on physical constraints
                # I/O pads + seal ring + power ring + routing margin
                "min_left": 40280,
                "min_right": 40200,
                "min_bottom": 42000,
                "min_top": 48000
            },
            "tracks": [
                {"layer": "metal1", "direction": "X", "start": 190, "step": 280},
                {"layer": "metal1", "direction": "Y", "start": 140, "step": 280},
                {"layer": "metal2", "direction": "X", "start": 190, "step": 380},
                {"layer": "metal2", "direction": "Y", "start": 140, "step": 380},
                {"layer": "metal3", "direction": "X", "start": 190, "step": 280},
                {"layer": "metal3", "direction": "Y", "start": 140, "step": 280},
                {"layer": "metal4", "direction": "X", "start": 190, "step": 560},
                {"layer": "metal4", "direction": "Y", "start": 140, "step": 560},
                {"layer": "metal5", "direction": "X", "start": 190, "step": 560},
                {"layer": "metal5", "direction": "Y", "start": 140, "step": 560},
                {"layer": "metal6", "direction": "X", "start": 190, "step": 560},
                {"layer": "metal6", "direction": "Y", "start": 140, "step": 560},
                {"layer": "metal7", "direction": "X", "start": 1790, "step": 1600},
                {"layer": "metal7", "direction": "Y", "start": 1740, "step": 1600},
                {"layer": "metal8", "direction": "X", "start": 1790, "step": 1600},
                {"layer": "metal8", "direction": "Y", "start": 1740, "step": 1600},
                {"layer": "metal9", "direction": "X", "start": 3390, "step": 3200},
                {"layer": "metal9", "direction": "Y", "start": 3340, "step": 3200},
                {"layer": "metal10", "direction": "X", "start": 3390, "step": 3200},
                {"layer": "metal10", "direction": "Y", "start": 3340, "step": 3200}
            ],
            "track_adjustments": {
                "add_one_layers": ["metal2", "metal4", "metal5", "metal6", "metal7", "metal8", "metal9", "metal10"]
            }
        }
        
        # Load custom configuration if provided
        if config_file:
            if not os.path.exists(config_file):
                raise FileNotFoundError(f"Configuration file not found: {config_file}")
            self.load_config(config_file)
    
    def load_config(self, config_file):
        """Load configuration from JSON file"""
        try:
            with open(config_file, 'r') as f:
                custom_config = json.load(f)
                self._merge_config(self.config, custom_config)
        except Exception as e:
            print(f"Warning: Could not load config file {config_file}: {e}")
            print("Using default configuration.")
    
    def _merge_config(self, default, custom):
        """Recursively merge custom config into default"""
        for key, value in custom.items():
            if key in default and isinstance(default[key], dict) and isinstance(value, dict):
                self._merge_config(default[key], value)
            else:
                default[key] = value
    
    def save_config_template(self, output_file="def_config_template.json"):
        """Save current configuration as template"""
        with open(output_file, 'w') as f:
            json.dump(self.config, f, indent=2)
        print(f"Configuration template saved to: {output_file}")
    
    def calculate_margins(self, width_dbu, height_dbu):
        """Calculate margins based on die size and configuration"""
        margins = self.config["margins"]
        
        # Calculate percentage-based margins
        left_margin = max(
            int(width_dbu * margins["left_percent"] / 100),
            margins["min_left"]
        )
        right_margin = max(
            int(width_dbu * margins["right_percent"] / 100),
            margins["min_right"]
        )
        bottom_margin = max(
            int(height_dbu * margins["bottom_percent"] / 100),
            margins["min_bottom"]
        )
        top_margin = max(
            int(height_dbu * margins["top_percent"] / 100),
            margins["min_top"]
        )
        
        return left_margin, right_margin, bottom_margin, top_margin
    
    def validate_die_size(self, width_dbu, height_dbu):
        """Validate if die size is sufficient for the design"""
        left_margin, right_margin, bottom_margin, top_margin = self.calculate_margins(width_dbu, height_dbu)
        cell_width = self.config["cell_library"]["width"]
        cell_height = self.config["cell_library"]["height"]
        
        # Check minimum width for at least one cell
        available_width = width_dbu - left_margin - right_margin
        if available_width < cell_width:
            raise ValueError(f"Die width too small. Need at least {left_margin + right_margin + cell_width} DBU, got {width_dbu}")
        
        # Check minimum height for at least one row
        available_height = height_dbu - bottom_margin - top_margin
        if available_height < cell_height:
            raise ValueError(f"Die height too small. Need at least {bottom_margin + top_margin + cell_height} DBU, got {height_dbu}")
        
        return True
    
    def generate_rows(self, width_dbu, height_dbu):
        """Generate ROW section with adaptive parameters"""
        self.validate_die_size(width_dbu, height_dbu)
        
        left_margin, right_margin, bottom_margin, top_margin = self.calculate_margins(width_dbu, height_dbu)
        cell_width = self.config["cell_library"]["width"]
        cell_height = self.config["cell_library"]["height"]
        cell_name = self.config["cell_library"]["name"]
        
        # Calculate number of cells per row
        available_width = width_dbu - left_margin - right_margin
        do_count = math.floor(available_width / cell_width)
        
        # Calculate rows
        available_height = height_dbu - bottom_margin - top_margin
        max_rows = math.floor(available_height / cell_height)
        
        rows = []
        for row_index in range(max_rows):
            current_y = bottom_margin + row_index * cell_height
            orient = "N" if row_index % 2 == 0 else "FS"
            row = f"ROW ROW_{row_index} {cell_name} {left_margin} {current_y} {orient} DO {do_count} BY 1 STEP {cell_width} 0 ;"
            rows.append(row)
        
        if len(rows) == 0:
            raise ValueError("Die size too small to accommodate any rows.")
        
        return rows
    
    def generate_tracks(self, width_dbu, height_dbu):
        """Generate TRACKS section"""
        tracks = []
        
        for track in self.config["tracks"]:
            layer = track["layer"]
            direction = track["direction"]
            start = track["start"]
            step = track["step"]
            
            dimension = width_dbu if direction == "X" else height_dbu
            do = math.floor((dimension - start) / step)
            
            # Apply layer-specific adjustments
            if layer in self.config["track_adjustments"]["add_one_layers"]:
                do += 1
            
            tracks.append(f"TRACKS {direction} {start} DO {do} STEP {step} LAYER {layer} ;")
        
        return tracks
    
    def generate_def_file(self, die_width, die_height, output_file, design_name=None):
        """
        Generate a .def file with adaptive parameters
        
        Args:
            die_width (float): Width of the DIE in database units (DBU)
            die_height (float): Height of the DIE in database units (DBU)
            output_file (str): Output .def file path
            design_name (str): Name of the design (optional)
        """
        width_dbu = int(die_width)
        height_dbu = int(die_height)
        
        if design_name is None:
            design_name = self.config["design"]["name"]
        
        # Generate DIEAREA
        die_area = f"( 0 0 ) ( {width_dbu} {height_dbu} )"
        
        # Generate sections
        rows = self.generate_rows(width_dbu, height_dbu)
        tracks = self.generate_tracks(width_dbu, height_dbu)
        
        row_section = "\n".join(rows)
        tracks_section = "\n".join(tracks)
        
        # DEF file content
        def_content = f"""VERSION {self.config["design"]["version"]} ;
DIVIDERCHAR "/" ;
BUSBITCHARS "[]" ;
DESIGN {design_name} ;
UNITS DISTANCE MICRONS {self.config["design"]["dbu_per_micron"]} ;
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
    parser = argparse.ArgumentParser(description="Generate DEF file with configurable parameters")
    parser.add_argument("-w", "--width", type=float, help="DIE width in database units (DBU)")
    parser.add_argument("-t", "--height", type=float, help="DIE height in database units (DBU)")
    parser.add_argument("-o", "--output", type=str, default="output.def", help="Output DEF file name")
    parser.add_argument("-d", "--design", type=str, help="Design name")
    parser.add_argument("-c", "--config", type=str, help="Configuration file (JSON)")
    parser.add_argument("--save-config", type=str, help="Save configuration template to file")
    
    args = parser.parse_args()
    
    # Create generator
    generator = DEFGenerator(args.config)
    
    # Save configuration template if requested
    if args.save_config:
        generator.save_config_template(args.save_config)
        return
    
    # Check required arguments for DEF generation
    if not args.width or not args.height:
        parser.error("Width (-w) and height (-t) are required for DEF generation")
    
    # Generate DEF file
    generator.generate_def_file(args.width, args.height, args.output, args.design)

if __name__ == "__main__":
    main()
