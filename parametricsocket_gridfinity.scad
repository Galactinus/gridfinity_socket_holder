//
// Calculate some internal stuff to position the rows and the sockets
//


// How many rows
row_count =  len( socketDiameters ) ;

// Max socket Diameter for each row - determins row width.
maxSocketDiameter = [for (i = [0:row_count-1 ]) scaling * (max(socketDiameters[i]) + add)];

// Scaled Socket Diameters
socket_diameters_scaled = [ for (i = [0:row_count-1 ] )  [for (j = [0:len(socketDiameters[i]) - 1 ])  scaling *  socketDiameters[i][j] + add  ]   ];

// Calculate total width of each socket set
socket_set_widths = [for (i = [0:row_count-1]) addarray(socket_diameters_scaled[i])];

// Length of the row - take the largest of the socket rows    
row_length =  max( [for (i = [0:row_count-1]) addarray( socket_diameters_scaled[i] ) ] ) + lengthPadding * 2 ;

// Calculate starting offset to center each socket set
socket_set_offsets = [for (i = [0:row_count-1]) (row_length - socket_set_widths[i]) / 2];

// Coordinates of each socket so we know where to place the socket   
socket_coords = [ for ( b = 0, i = [0:row_count-1 ] )  [ for (j = [0:len(socketDiameters[i]) - 1 ]) 
    j == 0 ? 
        socket_set_offsets[i] + socket_diameters_scaled[i][j] / 2 : 
        socket_set_offsets[i] + socket_diameters_scaled[i][j] / 2 + addl(socket_diameters_scaled[i], j - 1) 
] ];

echo("socket_coords", socket_coords[0]);
// Calculate well depths by subtracting grabLength from each socket depth
well_depths = [ for (i = [0:row_count-1]) [for (j = [0:len(socketDepths[i]) - 1]) socketDepths[i][j] - grabLength] ];

// Height of each row
block_height = array_max_2d(well_depths) + bottomThickness;

// Calculate the height needed for stacking
// Find the maximum well depth across all sockets
stacking_clearance = 1; // 1mm clearance above the tallest socket
max_socket_height = array_max_2d(socketDepths);

// Standard gridfinity lip height for stacking
required_lip_height = 4.5; 
echo("required_lip_height", required_lip_height);

// Ensure the top surface is high enough above the tallest socket
// Minimum gridz of 1 (7mm) to ensure proper operation
gridz = max(1, ceil((block_height + grabLength + required_lip_height) / 7));
top_surface = block_height + 7;
echo("Max socket height:", max_socket_height);

// Text label positioning configuration
label_position = "between"; // Options: "bottom", "8oclock", "between"
label_offset_angle = -135; // 8 o'clock position in degrees (0 is right, 90 is up)
label_distance_factor = 1.2; // How far from center (as factor of socket radius) - increased to be outside the circle
// Vertical offset factor for 8oclock-between position (negative moves down)
label_vertical_offset = -0.7; // How far down from center line to place the label
    
// Width of each row - for buiding rows and to center holes
row_width = [for (i = [0:row_count-1]) text_size + text_space_offset + maxSocketDiameter[i]];
echo("row_width", row_width);

// Accumulated row width
row_width_accum =
    [for (a = 0, b = row_width[0]; a < len(row_width);
          a = a + 1, b = b + (row_width[a] == undef ? 0 : row_width[a])) b];
echo("row_width_acc", row_width_accum);
// Coordinates of row width - for creating rows
row_width_cords = concat(0, row_width_accum);
echo("row_width_cords", row_width_cords);


origin = [(0 - row_length / 2), (0 - row_width_accum[row_count-1] / 2), 0];

echo("origin x", origin[0]);
echo("socket_coords", socket_coords[0]);
// Calculate socket coordinates adjusted for origin
socket_coords_adjusted = [ 
    for (i = [0:row_count-1]) 
        [ for (j = [0:len(socket_coords[i]) - 1]) 
            socket_coords[i][j] + origin[0] 
        ] 
];
echo("socket_coords_adjusted", socket_coords_adjusted[0]);

echo ("row_width_cords", row_width_cords);
row_width_cords_adjusted = [
    for (i = [0:row_count])
        row_width_cords[i] + origin[1]
];
echo ("row_width_cords_adjusted", row_width_cords_adjusted);

// Calculate gridfinity grid dimensions based on our object size
gridx = max(1, ceil(row_length / 42));
gridy = max(1, ceil(row_width_accum[row_count-1] / 42));
echo("gridx", gridx, "gridy", gridy);
echo("row_length", row_length, "row_width_accum", row_width_accum[row_count-1]);
echo("block_height", block_height);
// Calculate height in gridfinity units (7mm increments)

// Include gridfinity library
use <src/core/gridfinity-rebuilt-utility.scad>
use <src/core/gridfinity-rebuilt-holes.scad>

// Helper function to find maximum value in a 2D array
function array_max_2d(arr) = max([for (row = arr) max(row)]);

use <src/core/gridfinity-rebuilt-utility.scad>
use <src/core/gridfinity-rebuilt-holes.scad>

// Sum N elements of an array
function addl(list, l , c = 0) = 
 c < l  ? 
 list[c] + addl(list, l , c + 1) 
 :
 list[c];

 // Sum All elments of Array   
function addarray(v) = [for(p=v) 1]*v;
    



//
// Create the Socket Holder
//
module CreateSocketHolder()
{
   
    if ( is_undef( multi_material ) || multi_material == "all" || multi_material == "body" ) {
    union()
    {
        // First create the gridfinity base container
        color("purple") {
            difference() {
                // Use gridfinity functions to create the bin
                union() {
                    echo("gridz", gridz);
                    gridfinityInit(gridx, gridy, height(gridz, 0, 0, false), top_surface - 5, sl=0) {
                        // Make it a solid bin with no divisions
                        // This could be customized with compartments if needed
                    }
                    // Add the base with magnet holes
                    gridfinityBase([gridx, gridy], hole_options=bundle_hole_options(false, false, false, true, true, true));
                }
              
                // Create Socket Holes
                for ( row = [0:row_count-1]) 
                    for ( socket = [0:len(socketDiameters[row]) - 1]) {
            
                        posy = ((0.5 * maxSocketDiameter[row]) + row_width_cords_adjusted[row]) + text_size + text_space_offset;
                        posz = top_surface - well_depths[row][socket];
                        
                        // Skip a zero depth socket - zero length sockets used to create gaps  
                        if ( socketDepths[row][socket] != 0 )
                        {
                            translate([socket_coords_adjusted[row][socket], posy, posz])   
                            cylinder(d = socketDiameters[row][socket] + add,
                                    h = well_depths[row][socket] + 0.1);
                        }
                    }
                // Create text cutouts
                for ( row = [0:row_count-1]) 
                    for ( socket = [0:len(socketDiameters[row]) - 1]) {
                        if (raisedText != 1 && socketLabels[row][socket] != " " ) {
                            // Calculate text position based on configuration
                            if (label_position == "bottom") {
                                // Original position at bottom
                                rowy = row_width_cords_adjusted[row] + text_size - 1;
                                rowz = top_surface - fontExtrude;
                                echo ("rowy", rowy);
                                echo ("rowz", rowz);
                                translate([socket_coords_adjusted[row][socket], rowy, rowz])
                                rotate([0, 0, 0]) color([0, 0, 1])
                                linear_extrude(height = fontExtrude + 100) 
                                {
                                    text(text = socketLabels[row][socket],
                                        font = "Liberation Sans:style=Bold",
                                        size = text_size,
                                        halign = "center",
                                        valign = "center");
                                }
                            } else if (label_position == "8oclock") {
                                // Position at 8 o'clock
                                socket_radius = (socketDiameters[row][socket] + add) / 2;
                                // Use the distance factor to ensure text is outside the socket circumference
                                offset_x = socket_coords_adjusted[row][socket] + socket_radius * label_distance_factor * cos(label_offset_angle);
                                offset_y = ((0.5 * maxSocketDiameter[row]) + row_width_cords_adjusted[row]) + text_size + text_space_offset + socket_radius * label_distance_factor * sin(label_offset_angle);
                                rowz = top_surface - fontExtrude;
                                
                                // Use halign and valign to better position the text based on the angle
                                // At 8 o'clock (-135°), we want text aligned right and top
                                halign = (label_offset_angle >= -90 && label_offset_angle <= 90) ? "left" : "right";
                                valign = (label_offset_angle >= 0 && label_offset_angle <= 180) ? "bottom" : "top";
                                
                                translate([offset_x, offset_y, rowz])
                                rotate([0, 0, 0]) color([0, 0, 1])
                                linear_extrude(height = fontExtrude + 0.1)
                                {
                                    text(text = socketLabels[row][socket],
                                        font = "Liberation Sans:style=Bold",
                                        size = text_size,
                                        halign = halign,
                                        valign = valign);
                                }
                            } else if (label_position == "between") {
                                // Position all labels at 8 o'clock position relative to their socket
                                socket_radius = (socketDiameters[row][socket] + add) / 2;
                                
                                // Calculate common 8 o'clock position for all sockets
                                offset_x = socket_coords_adjusted[row][socket] + socket_radius * label_distance_factor * cos(label_offset_angle);
                                
                                // Use vertical positioning similar to 8 o'clock (below center line)
                                base_y = ((0.5 * maxSocketDiameter[row]) + row_width_cords_adjusted[row]) + text_size + text_space_offset;
                                offset_y = base_y + label_vertical_offset * socket_radius; // Move down by vertical offset factor
                                
                                rowz = top_surface - fontExtrude;
                                
                                // Determine proper text alignment for 8 o'clock position
                                halign = (label_offset_angle >= -90 && label_offset_angle <= 90) ? "left" : "right";
                                valign = (label_offset_angle >= 0 && label_offset_angle <= 180) ? "bottom" : "top";
                                
                                translate([offset_x, offset_y, rowz])
                                rotate([0, 0, 0]) color([0, 0, 1])
                                linear_extrude(height = fontExtrude + 0.1)
                                {
                                    text(text = socketLabels[row][socket],
                                        font = "Liberation Sans:style=Bold",
                                        size = text_size,
                                        halign = halign,
                                        valign = valign);
                                }
                            }
                        }
                    }
            }
        }
        
        // Raised text (if needed)
        if ( is_undef( multi_material ) || multi_material == "all" || multi_material == "text" ) {
            // Create the raised text
            for ( row = [0:row_count-1]) 
                for ( socket = [0:len(socketDiameters[row]) - 1]) {
                    if ( raisedText == 1 && socketLabels[row][socket] != " " ){
                        // Calculate text position based on configuration
                        if (label_position == "bottom") {
                            // Original position at bottom
                            rowy = row_width_cords_adjusted[row] + text_size - 1;
                            rowz = top_surface - fontExtrude;
                                         
                        
                            translate([socket_coords_adjusted[row][socket], rowy, rowz])
                            rotate([0, 0, 0]) color([0, 0, 1])
                            linear_extrude(height = fontExtrude)
                            {
                                text(text = socketLabels[row][socket],
                                    font = "Liberation Sans:style=Bold",
                                    size = text_size,
                                    halign = "center",
                                    valign = "center");
                            }
                        } else if (label_position == "8oclock") {
                            // Position at 8 o'clock
                            socket_radius = (socketDiameters[row][socket] + add) / 2;
                            // Use the distance factor to ensure text is outside the socket circumference
                            offset_x = socket_coords_adjusted[row][socket] + socket_radius * label_distance_factor * cos(label_offset_angle);
                            offset_y = ((0.5 * maxSocketDiameter[row]) + row_width_cords_adjusted[row]) + text_size + text_space_offset + socket_radius * label_distance_factor * sin(label_offset_angle);
                            rowz = top_surface - fontExtrude;
                            
                            // Use halign and valign to better position the text based on the angle
                            // At 8 o'clock (-135°), we want text aligned right and top
                            halign = (label_offset_angle >= -90 && label_offset_angle <= 90) ? "left" : "right";
                            valign = (label_offset_angle >= 0 && label_offset_angle <= 180) ? "bottom" : "top";
                            
                            
                            translate([offset_x, offset_y, rowz])
                            rotate([0, 0, 0]) color([0, 0, 1])
                            linear_extrude(height = fontExtrude)
                            {
                                text(text = socketLabels[row][socket],
                                    font = "Liberation Sans:style=Bold",
                                    size = text_size,
                                    halign = halign,
                                    valign = valign);
                            }
                        } else if (label_position == "between") {
                            // Position all labels at 8 o'clock position relative to their socket
                            socket_radius = (socketDiameters[row][socket] + add) / 2;
                            
                            // Calculate common 8 o'clock position for all sockets
                            offset_x = socket_coords_adjusted[row][socket] + socket_radius * label_distance_factor * cos(label_offset_angle);
                            
                            // Use vertical positioning similar to 8 o'clock (below center line)
                            base_y = ((0.5 * maxSocketDiameter[row]) + row_width_cords_adjusted[row]) + text_size + text_space_offset;
                            offset_y = base_y + label_vertical_offset * socket_radius; // Move down by vertical offset factor
                            
                            rowz = top_surface - fontExtrude;
                            
                            
                            // Determine proper text alignment for 8 o'clock position
                            halign = (label_offset_angle >= -90 && label_offset_angle <= 90) ? "left" : "right";
                            valign = (label_offset_angle >= 0 && label_offset_angle <= 180) ? "bottom" : "top";
                            
                            translate([offset_x, offset_y, rowz])
                            rotate([0, 0, 0]) color([0, 0, 1])
                            linear_extrude(height = fontExtrude)
                            {
                                text(text = socketLabels[row][socket],
                                    font = "Liberation Sans:style=Bold",
                                    size = text_size,
                                    halign = halign,
                                    valign = valign);
                            }
                        }
                    }    
                }            
        }       
    }
    }       
}
//
// Create the Base
//
module CreateBase( cbasethickness )
{

    // Create the Base
    color("red") translate([ 0, row_width_cords[row_count] + 100, 0 ])
        cube([ row_length , row_width_cords[row_count], cbasethickness ]);
}

//
// Split out left side - with joiner
//
module SplitLeftJoiner( cutposition )
{

    difference()
    {

        // Cut off the right half
        CreateSocketHolder();
        translate([ cutposition , -1, -1 ]) cube([
            cutposition * 2,
            row_width_accum[row_count - 1] + 2,
            top_surface + 2
        ]);

        // Add the joiner cutouts
        for (i = [0:row_count - 1]) {
            translate([
                cutposition - joinerdepth,
                row_width_cords[i] + joinerindent,
                top_surface / 3 - joinertolerance / 2
            ])
                color("red")
                cube([
                    joinerdepth + 0.001,
                    row_width_accum[row_count - 1] - joinerindent -
                        row_width_cords[i],
                    top_surface / 3 + joinertolerance
                ]);
        }
    }
}

//
// Split out Right side - with joiner
//
module
SplitRightJoiner( cutposition )
{
    translate( [ - cutposition + joinerdepth , 0 , 0 ] )
    union()
    {
        difference()
        {

            // Cut off the left half
            CreateSocketHolder();
            translate([ -0.1, -0.1, -0.1 ]) 
            cube([
                cutposition,
                row_width_accum[row_count - 1] + 2,
                top_surface + 2
            ]);
        }
        
        // Add the Joiner
        for (i = [0:row_count - 1]) {

            translate([
                cutposition - joinerdepth,
                row_width_cords[i] + joinerindent,
                top_surface / 3 + joinertolerance / 2
            ])

                color("red")
                cube([
                    joinerdepth + 0.001,
                    row_width_accum[row_count - 1] - joinerindent - row_width_cords[i],
                    top_surface / 3 -  joinertolerance
                ]);
        }
    }
}





