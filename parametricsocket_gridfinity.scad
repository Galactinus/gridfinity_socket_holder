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
top_surface = block_height;



    
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
// Helper function to find maximum value in a 2D array
function array_max_2d(arr) = max([for (row = arr) max(row)]);

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
  

        difference()
        { 

        // Create the rows
            translate(origin)
            cube([row_length, row_width_accum[row_count-1] , block_height]);

            
         // Create Socket and Magnet Holes
            // angle = chamfer == 0 ? 90 : 45;
            
           for ( row = [0:row_count-1]) 
               for ( socket = [0:len(socketDiameters[row]) - 1]) {
       
    //              // Create holes for the sockets  
                 posy =  ((0.5 * maxSocketDiameter[row]  ) + row_width_cords_adjusted[row])+ text_size + text_space_offset;
                 posz =  top_surface - well_depths[row][socket];
                  
                 // Skip a zero depth socket - zero length sockets used to create gaps  
                 if ( socketDepths[row][socket] != 0 )
                 {
                    translate( [ socket_coords_adjusted[row][socket] , posy , posz] )   
                    cylinder(d = socketDiameters[row][socket] + add,
                                h = well_depths[row][socket] + 0.01);
                 
                 } 
                 
    //              // Create holes for the magnets 
    //              if ( socketDepths[row][socket] != 0 )
    //              {
    //              magnet_h = MagnetHeight ? MagnetHeight : block_height_accum[row] - socketDepths[row][socket] - 1.5 ;    
    //              translate( [ socket_coords[row][socket], posy + MagnetOffset, -0.01 ] )
    //              cylinder(d = MagnetDiameter , h = magnet_h );
    //              }
                     
                  // Add the Sunken Text
                if (raisedText != 1 && socketLabels[row][socket] != " " ) {
 
                    
                    rowy = row_width_cords_adjusted[row] + text_size - 1;
                    rowz = top_surface - fontExtrude;
                    // echo("x", socket_coords[row][socket]);
                    // echo("y", rowy);
                    // echo("z", rowz);
                    // echo("rotation", angle);
                    
                    translate( [ socket_coords_adjusted[row][socket] ,  rowy, rowz ] )
                    rotate([ 0, 0, 0 ]) color([ 0, 0, 1 ])
                    linear_extrude(height = fontExtrude + 0.1)
                    {
                        text(text = socketLabels[row][socket],
                             font = "Liberation Sans:style=Bold",
                             size =  text_size,
                             halign = "center",
                             valign = "center");
                    }
                    
                }

            }
           
        }
        
    }
    // }
    // if ( is_undef( multi_material ) || multi_material == "all" || multi_material == "text"  ) {
    // // Create the raised text
    //  for ( row = [0:row_count-1]) 
    //            for ( socket = [0:len(socketDiameters[row]) - 1]) {
    //         if ( raisedText == 1 && socketLabels[row][socket] != " " ){       
    //         angle = chamfer == 0 ? 90 : 45;
          
    //         chamferl = sqrt(chamfer * chamfer * 2);
    //         chamferh = chamferl == 0 ? 0 : chamfer * chamfer / chamferl;
                    
    //                 rowy = row_width_cords[row] + chamferh - 1;
    //                 rowz = chamfer == 0 ? top_surface_cords[row] +
    //                                            0.5 * top_surface[row]
    //                                      : top_surface_accum[row] - chamferh;
                                         
    //                  echo( "Text Z: ", rowz );                       
                    
    //                  translate( [ socket_coords[row][socket] ,  rowy, rowz ] )
    //                  rotate([ angle, 0, 0 ]) color([ 0, 0, 1 ])
    //                  linear_extrude(height = fontExtrude)
    //                 {
    //                     text(text = socketLabels[row][socket],
    //                          font = "Liberation Sans:style=Bold",
    //                          size = row1Height * textscale,
    //                          halign = "center",
    //                          valign = "center");
    //                 } 
    //             }    
               
            //    }            
                   
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
            block_height_accum[row_count - 1] + 2
        ]);

        // Add the joiner cutouts
        for (i = [0:row_count - 1]) {
            translate([
                cutposition - joinerdepth,
                row_width_cords[i] + joinerindent,
                block_height_cords[i] + block_height[i] / 3 - joinertolerance / 2
            ])
                color("red")
                cube([
                    joinerdepth + 0.001,
                    row_width_accum[row_count - 1] - joinerindent -
                        row_width_cords[i],
                    block_height[i] / 3 + joinertolerance
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
                block_height_accum[row_count - 1] + 2
            ]);
        }
        
        // Add the Joiner
        for (i = [0:row_count - 1]) {

            translate([
                cutposition - joinerdepth,
                row_width_cords[i] + joinerindent,
                block_height_cords[i] + block_height[i] / 3 + joinertolerance / 2
            ])

                color("red")
                cube([
                    joinerdepth + 0.001,
                    row_width_accum[row_count - 1] - joinerindent - row_width_cords[i],
                    block_height[i] / 3 -  joinertolerance
                ]);
        }
    }
}





