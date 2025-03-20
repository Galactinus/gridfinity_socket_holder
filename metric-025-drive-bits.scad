//
// Socket details are a Matrix. Each step is Vector 
//
// If its too big for your printer. Add a socket with no depth or text to create a gap for splitting the model printing 
// 
include <helpers.scad>
// Additional Length add to both ends 
lengthPadding = 1;

// What are the Socket hole diameters?
socketDiameters = [ [  24, 24, 24, 24, 24, 24, 24] , [  26, 28, 30, 32, 34, 38 ]   ];

// What are the Socket hole depths?
socketDepths = [ [ 37, 38, 38, 38, 38, 38, 38] , [ 38, 38, 38, 38, 38, 42.3 ]  ];
 
// What are the Socket hole labels?
socketLabels = [ [ "10", "11", "12", "13" , "14" , "15", "16"  ] , [  "17", "19", "21", "22" , "24", "27"] ] ;

 // 1 = raised text, anything else = sunken text
raisedText = 1;
fontExtrude = .5;
text_size = 4;
text_space_offset = 0;


// Height of each step
grabLength = 18;
bottomThickness = 0;

// Height of Chamfer. 0 for no chamfer
chamfer = 0;

// Magnets
MagnetDiameter = 10 + 1; // 10mm Magnet
MagnetHeight = 0; // 0 - place under socket , else depth from base
MagnetOffset = 0; // Offset the magnet from the centre of the socket

// How much spacing to add for each hole
add = 1;

// How much wider than the widest hole should the step be?
scaling = 1.12;

// Joiners for split model
joinerdepth = 3;
joinerindent = 10;
joinertolerance = 0.25;

// all , text , body 
// multi_material = "all";
// multi_material = "text";
//multi_material = "body";


include <parametricsocket_gridfinity.scad>


// joinlocation = step_length / 2 + 9  ;

CreateSocketHolder(); // Create the socket holder
//CreateBase( 1.5 ); // Create the base
//SplitLeftJoiner( joinlocation ); // Split the model, create the left section
//SplitRightJoiner( joinlocation ); // Split the model, create the right section




