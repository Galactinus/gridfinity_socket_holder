//
// Calculate some internal stuff to position the steps and the sockets
//


// How many steps
steps =  len( socketDiameters ) ;

// Max socket Diameter for each step - determins step width.
maxsocketDiameter = [for (i = [0:steps-1 ]) scaling * (max(socketDiameters[i]) + add)];

// Scaled Socket Diameters
socket_diameters_scaled = [ for (i = [0:steps-1 ] )  [for (j = [0:len(socketDiameters[i]) - 1 ])  scaling *  socketDiameters[i][j] + add  ]   ];

// Calculate total width of each socket set
socket_set_widths = [for (i = [0:steps-1]) addarray(socket_diameters_scaled[i])];

// Calculate starting offset to center each socket set
socket_set_offsets = [for (i = [0:steps-1]) (step_length - socket_set_widths[i]) / 2];

// Cordinates of each socket so we know where to place the socket   
socket_coords = [ for ( b = 0, i = [0:steps-1 ] )  [ for (j = [0:len(socketDiameters[i]) - 1 ]) 
    j == 0 ? 
        socket_set_offsets[i] + socket_diameters_scaled[i][j] / 2 : 
        socket_set_offsets[i] + socket_diameters_scaled[i][j] / 2 + addl(socket_diameters_scaled[i], j - 1) 
] ];

// Height of each step
step_height = [for (i = [1:steps]) i == 1 ? step1Height : stepnheight];

// Accumalted step Height - so we know where to put the socket holes
step_height_accum =
    [for (a = 0, b = step_height[0]; a < len(step_height);
          a = a + 1, b = b + (step_height[a] == undef ? 0 : step_height[a])) b];

// Cordinates of step Height - so we know where to put text
step_height_cords = concat(0, step_height_accum);
    
// Width of each step - for buiding steps and to center holes
step_width = [for (i = [0:steps-1]) chamfer + maxsocketDiameter[i] ];
    

// Accumlated step width
step_width_accum =
    [for (a = 0, b = step_width[0]; a < len(step_width);
          a = a + 1, b = b + (step_width[a] == undef ? 0 : step_width[a])) b];

// Cordinates of step width - for creating steps
step_width_cords = concat(0, step_width_accum);

// Length of the step - take the largest of the socket steps    
step_length =  max( [for (i = [0:steps-1]) addarray( socket_diameters_scaled[i] ) ] ) + lengthPadding * 2 ;
    

// Sum N elements of an array
function addl(list, l , c = 0) = 
 c < l  ? 
 list[c] + addl(list, l , c + 1) 
 :
 list[c];

 // Sum All elments of Array   
function addarray(v) = [for(p=v) 1]*v;

//
// Module to Create the Step and Chamfer
//
module
CreateStep(sizeX, sizeY, sizeZ, chamferHeight)
{
    chamferLength = sqrt(chamferHeight * chamferHeight * 2);

    difference()
    {
        cube([ sizeX, sizeY, sizeZ ]);

        translate([ -0.1, 0, -chamferHeight + sizeZ ]) rotate([ 45, 0, 0 ])
            cube([ sizeX + 0.2, chamferLength, chamferLength ]);
    }
}


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

        // Create the Steps
            for (i = [0:steps-1]) {
                translate([ 0, step_width_cords[i], 0 ])
                    CreateStep(step_length,
                               step_width[i],
                               step_height_accum[i],
                               chamfer);
            }
            
         // Create Socket and Magnet Holes
            angle = chamfer == 0 ? 90 : 45;
            
           for ( step = [0:steps-1]) 
               for ( socket = [0:len(socketDiameters[step]) - 1]) {
       
                 // Create holes for the sockets  
                 posy =  0.5 * (step_width[step] + chamfer) + step_width_cords[step];
                 posz =  step_height_accum[step] - socketDepths[step][socket];
           
                  
                 // Skip a zero depth socket - zero length sockets used to create gaps  
                 if ( socketDepths[step][socket] != 0 )
                 {
                  translate( [ socket_coords[step][socket] , posy , posz] )   
                 cylinder(d = socketDiameters[step][socket] + add,
                                h = socketDepths[step][socket] + 0.01);
                 
                 }
                 
                 // Create holes for the magnets 
                 if ( socketDepths[step][socket] != 0 )
                 {
                 magnet_h = MagnetHeight ? MagnetHeight : step_height_accum[step] - socketDepths[step][socket] - 1.5 ;    
                 translate( [ socket_coords[step][socket], posy + MagnetOffset, -0.01 ] )
                 cylinder(d = MagnetDiameter , h = magnet_h );
                 }
                     
                  // Add the Sunken Text
                if (raisedText != 1 && socketLabels[step][socket] != " " ) {
                    angle = chamfer == 0 ? 90 : 45;
                    chamferl = sqrt(chamfer * chamfer * 2);
                    chamferh = chamferl == 0 ? 0 : chamfer * chamfer / chamferl;
                    
                    stepy = step_width_cords[step] + chamferh - 1;
                    stepz = chamfer == 0 ? step_height_cords[step] +
                                               0.5 * step_height[step]
                                         : step_height_accum[step] - chamferh;
                    
                     translate( [ socket_coords[step][socket] ,  stepy, stepz ] )
                     rotate([ angle, 0, 0 ]) color([ 0, 0, 1 ])
                        linear_extrude(height = fontExtrude)
                    {
                        text(text = socketLabels[step][socket],
                             font = "Liberation Sans:style=Bold",
                             size = step1Height * textscale,
                             halign = "center",
                             valign = "center");
                    }
                    
                }

               }
           
        }
        
    }
    }
    if ( is_undef( multi_material ) || multi_material == "all" || multi_material == "text"  ) {
    // Create the raised text
     for ( step = [0:steps-1]) 
               for ( socket = [0:len(socketDiameters[step]) - 1]) {
            if ( raisedText == 1 && socketLabels[step][socket] != " " ){       
            angle = chamfer == 0 ? 90 : 45;
          
            chamferl = sqrt(chamfer * chamfer * 2);
            chamferh = chamferl == 0 ? 0 : chamfer * chamfer / chamferl;
                    
                    stepy = step_width_cords[step] + chamferh - 1;
                    stepz = chamfer == 0 ? step_height_cords[step] +
                                               0.5 * step_height[step]
                                         : step_height_accum[step] - chamferh;
                                         
                     echo( "Text Z: ", stepz );                       
                    
                     translate( [ socket_coords[step][socket] ,  stepy, stepz ] )
                     rotate([ angle, 0, 0 ]) color([ 0, 0, 1 ])
                     linear_extrude(height = fontExtrude)
                    {
                        text(text = socketLabels[step][socket],
                             font = "Liberation Sans:style=Bold",
                             size = step1Height * textscale,
                             halign = "center",
                             valign = "center");
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
    color("red") translate([ 0, step_width_cords[steps] + 100, 0 ])
        cube([ step_length , step_width_cords[steps], cbasethickness ]);
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
            step_width_accum[steps - 1] + 2,
            step_height_accum[steps - 1] + 2
        ]);

        // Add the joiner cutouts
        for (i = [0:steps - 1]) {
            translate([
                cutposition - joinerdepth,
                step_width_cords[i] + joinerindent,
                step_height_cords[i] + step_height[i] / 3 - joinertolerance / 2
            ])
                color("red")
                cube([
                    joinerdepth + 0.001,
                    step_width_accum[steps - 1] - joinerindent -
                        step_width_cords[i],
                    step_height[i] / 3 + joinertolerance
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
                step_width_accum[steps - 1] + 2,
                step_height_accum[steps - 1] + 2
            ]);
        }
        
        // Add the Joiner
        for (i = [0:steps - 1]) {

            translate([
                cutposition - joinerdepth,
                step_width_cords[i] + joinerindent,
                step_height_cords[i] + step_height[i] / 3 + joinertolerance / 2
            ])

                color("red")
                cube([
                    joinerdepth + 0.001,
                    step_width_accum[steps - 1] - joinerindent - step_width_cords[i],
                    step_height[i] / 3 -  joinertolerance
                ]);
        }
    }
}





