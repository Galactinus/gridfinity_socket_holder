
// Get maximum value in 1D array
function array_max(v) = max([for(i = v) i]);

// Get maximum value in 2D array
function array_max_2d(v) = max([for(i = v) max([for(j = i) j])]);

// Get maximum value in 3D array
function array_max_3d(v) = max([for(i = v) max([for(j = i) max([for(k = j) k])])]);

// Get maximum value in 4D array
function array_max_4d(v) = max([for(i = v) max([for(j = i) max([for(k = j) max([for(l = k) l])])])]);