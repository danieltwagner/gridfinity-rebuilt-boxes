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
// minimum spacing (mm) between bits or to the outside
minimum_spacing = 2;
// gap around bits in width/length
gap = 0.5;
// how wide the thumb slot should be (mm)
thumb_slot_width = 20;
// the thumb slot should be this much lower than the deepest groove (mm)
thumb_slot_step = 2.5;
// amount that the bits should overlap the thumb slot
thumb_slot_overlap = 10;
// how deep should each bit be embedded? 1.0 means slot depth == bit diameter
embed_depth = 1.0;
// text font size
text_size = 5;
// text relief height (mm), 0 to disable.
text_relief_height = 1.0;

/*
// Set of 7 hex drill bits
bit_diameters = [7.25,7.25,7.25,7.25,7.25,7.25,7.25];
bit_lengths = [80,93,98,105,113,113,120];
bit_labels = ["3", "4", "4.5", "5", "5.5", "6", "6.5"];

// Set of 8 wood bits
bit_diameters = [3, 4, 5, 6, 7, 8, 9, 10];
bit_lengths = [61, 76, 86, 93, 108, 119, 127, 133];
bit_labels = ["3", "4", "5", "6", "7", "8", "9", "10"];
*/

/* [Bits] */
bit_diameters = [4,5,6,8,10];
bit_lengths = [70,85,100,120,150];

// labels, will use bit diameter if not specified. set text_relief_height to 0 to disable.
bit_labels = [];

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

num_bits = len(bit_diameters);
// oof, summing over an array?
function cumsum(v) = [for (a = v[0]-v[0], i = 0; i < len(v); a = a+v[i], i = i+1) a+v[i]];

bit_widths_cumulative = cumsum(bit_diameters);
bit_widths_total = bit_widths_cumulative[num_bits-1];

required_width = num_bits * (gap + minimum_spacing) + bit_widths_total + minimum_spacing;

required_length = max(bit_lengths) + thumb_slot_width - thumb_slot_overlap + 2 * minimum_spacing;

thumb_slot_depth = max(bit_diameters) * embed_depth + gap + thumb_slot_step;
required_height = thumb_slot_depth + BASE_HEIGHT;

gridx = ceil(required_width/42);
gridy = ceil(required_length/42);
// bin height. See bin height information and "gridz_define" below.
gridz = max(minimum_height, ceil(required_height/7));

// compute the actual spacing between each bit and the sides
spacing_x = (gridx * 42 - bit_widths_total - (num_bits * gap))/(num_bits + 1);

// There's probably a better way to do the cutouts but for now
// pre-computing all start points is fine.
start_x = [ for (i = [0 : num_bits - 1]) ((i > 0) ? bit_widths_cumulative[i-1] : 0) + (i+1) * spacing_x ];

// ===== IMPLEMENTATION ===== //

color("tomato") {
gridfinityInit(gridx, gridy, height(gridz, 0, style_lip), 0, sl=style_lip) {

    // start at the bottom left corner of the top surface
    translate([-gridx/2 * 42, -gridy/2 * 42, gridz*7]) {
        // thumb cutout
        translate([0, 0, -thumb_slot_depth])
        cube([gridx * 42 - 2, thumb_slot_width, thumb_slot_depth+1], center=false);
        
        // drill cutouts
        for (i = [0 : num_bits - 1]) {
            diameter = bit_diameters[i] + gap;
            length = bit_lengths[i] + gap;
            translate([start_x[i], thumb_slot_width - thumb_slot_overlap, -diameter])
            cube([diameter, length, diameter+1], center=false);
        }
    }
}
gridfinityBase([gridx, gridy], hole_options=bundle_hole_options(refined_hole=true), only_corners=only_corners);

// labels
if (text_relief_height > 0) {
    labels = len(bit_labels) > 0 ? bit_labels : [ for (d = bit_diameters) str(d)];
    translate([-gridx/2 * 42, -gridy/2 * 42, gridz*7]) {
        for (i = [0 : num_bits-1]) {
            
            offset_x = start_x[i] + bit_diameters[i]/2;
            offset_y = thumb_slot_width - thumb_slot_overlap + bit_lengths[i] + gap + 2;
            echo(offset_y, gridy * 42, offset_y + text_size + minimum_spacing)
            
            if (offset_y + text_size + minimum_spacing > gridy * 42) {
            // too tall to fit onto the box, draw next to it
                translate([start_x[i] - 2, thumb_slot_width - thumb_slot_overlap + bit_lengths[i], 0]) {
                    linear_extrude(height = text_relief_height) {
                        text(text=labels[i], font="Liberation Sans", size=text_size, valign = "top", halign = "right");
                    }
                }
            } else {
                translate([offset_x, offset_y, 0]) {
                    linear_extrude(height = text_relief_height) {
                        text(text=labels[i], font="Liberation Sans", size=text_size, halign = "center");
                    }
                }
            }            
        }
    }
}
}
