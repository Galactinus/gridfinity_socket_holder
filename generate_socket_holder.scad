minimum_length=10;
minimum_width=10;
minimum_highth=10;

// Gridfinity Specifications
// Source: https://gridfinity.xyz/specification/

// Base grid dimensions
grid_unit = 42;  // mm - standard grid unit size
grid_height = 7; // mm - standard height unit

// Base plate specifications
base_corner_radius = 4;      // mm - radius of the base plate corners
base_fillet_radius = 0.8;    // mm - radius of the base plate fillets
base_thickness = 5;          // mm - thickness of the base plate
base_lip_height = 2.15;      // mm - height of the lip on the base plate
base_magnet_diameter = 6.5;  // mm - diameter of magnet holes
base_magnet_depth = 2.4;     // mm - depth of magnet holes
base_screw_diameter = 3;     // mm - diameter of screw holes

// Bin specifications
bin_wall_thickness = 1.2;    // mm - standard wall thickness
bin_floor_thickness = 0.8;   // mm - standard floor thickness
bin_corner_radius = 4;       // mm - radius of bin corners
bin_tolerance = 0.25;        // mm - tolerance for fit

// Stacking specifications
stacking_lip_height = 1.8;   // mm - height of the stacking lip
stacking_tolerance = 0.1;    // mm - tolerance for stacking

// Logging configuration
logging_level = "INFO";      // Set default logging level

// Log the loaded specifications
echo("INFO: Loaded Gridfinity specifications from https://gridfinity.xyz/specification/");
echo("INFO: Grid unit size: ", grid_unit, "mm");
echo("INFO: Standard height unit: ", grid_height, "mm");




min_length_cell=minimum_length/41.5;
min_width_cell=minimum_width/41.5;
min_highth_cell=minimum_highth/7;

cells_len=ceil(min_length_cell);
cells_wide=ceil(min_width_cell);
cells_highth=ceil(min_highth_cell);

echo(cells_len,cells_wide,cells_highth);


