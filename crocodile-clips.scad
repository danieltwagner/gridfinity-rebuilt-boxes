include <../gridfinity-rebuilt-openscad/src/core/gridfinity-rebuilt-utility.scad>

// ===== INFORMATION ===== //
/*
 IMPORTANT: rendering will be better for analyzing the model if fast-csg is enabled. As of writing, this feature is only available in the development builds and not the official release of OpenSCAD, but it makes rendering only take a couple seconds, even for comically large bins. Enable it in Edit > Preferences > Features > fast-csg
 the magnet holes can have an extra cut in them to make it easier to print without supports
 tabs will automatically be disabled when gridz is less than 3, as the tabs take up too much space
 base functions can be found in "gridfinity-rebuilt-utility.scad"
 examples at end of file

 BIN HEIGHT
 the original gridfinity bins had the overall height defined by 7mm increments
 a bin would be 7*u millimeters tall
 the lip at the top of the bin (3.8mm) added onto this height
 The stock bins have unit heights of 2, 3, and 6:
 Z unit 2 -> 7*2 + 3.8 -> 17.8mm
 Z unit 3 -> 7*3 + 3.8 -> 24.8mm
 Z unit 6 -> 7*6 + 3.8 -> 45.8mm

https://github.com/kennetek/gridfinity-rebuilt-openscad

*/

// ===== PARAMETERS ===== //

/* [Setup Parameters] */
$fa = 8;    // minimum angle for a fragment
$fs = 0.25; // minimum size of a fragment

/* [General Settings] */
min_gap = 1;

// clips take roughly 10x25mm, this means we can fit 3 into a 2-wide bin
num_rows = 4;

// slightly undersized for easy placement
hole_diameter = 9.5;

/* [Customization] */
// minimum height of the bin in units of 7mm increments
minimum_height = 1;
// how should the top lip act
style_lip = 1; //[0: Regular lip, 1:remove lip subtractively, 2: remove lip and retain height]
style_hole = 4; // [0:no holes, 1:magnet holes only, 2: magnet and screw holes - no printable slit, 3: magnet and screw holes - printable slit, 4: Gridfinity Refined hole - no glue needed]
// only cut magnet/screw holes at the corners of the bin to save uneccesary print time
only_corners = true;

// ===== IMPLEMENTATION ===== //
module __Customizer_Limit__ () {}  // Hide following assignments from Customizer.

required_width = num_rows * (hole_diameter + min_gap);

// we'll fix the other two dimensions
gridx = ceil(required_width/42);
gridy = 2;
gridz = 2;

// compute the actual spacing between each bit and the sides
spacing_x = (gridx * 42 - num_rows * hole_diameter)/(num_rows + 1);
hole_depth = gridz * 7 - BASE_HEIGHT;

// ===== IMPLEMENTATION ===== //

color("tomato") {
gridfinityBase([gridx, gridy], hole_options=bundle_hole_options(refined_hole=true), only_corners=only_corners);
difference() {
    gridfinityInit(gridx, gridy, height(gridz, 0, style_lip), 0, sl=style_lip);
    // start at the bottom left corner of the top surface
    translate([-gridx/2 * 42, -gridy/2 * 42, gridz*7]) {

        // holes
        for (i = [0 : num_rows - 1]) {
            for (j = [0 : 2]) {
                start_x = spacing_x * (i+1) + i * hole_diameter + hole_diameter/2;
                start_y = 2 + j * (25 + 2) + hole_diameter/2;
                translate([start_x, start_y, 0])
                cylinder(h = 100, r = hole_diameter/2, center=true);
            }
        }
    }
}
}