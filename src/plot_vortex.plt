# Gnuplot Visualization for Kármán Vortex Street
# Author: [Your Name]
# Version: 1.0

# 1. Output Settings
set terminal pngcairo size 1000,400 enhanced font 'Verdana,12'
set output 'vortex_street.png'

# 2. Map & Color Settings
set view map
set size ratio -1          # Maintains physical proportions (not stretched)
set object 1 rectangle from screen 0,0 to screen 1,1 fillcolor rgb "white" behind
set palette rgbformulae 33,13,10  # Classic fluid dynamics "Rainbow" or use 22,13,10

# 3. Grading Requirements: Labels and Legends
set title "Kármán Vortex Street: Velocity Magnitude"
set xlabel "Lattice X (Flow Direction)"
set ylabel "Lattice Y"
set cblabel "Velocity Magnitude (u)"
set key outside              # Ensures legend doesn't overlap data

# 4. Range Adjustments
# Adjust these based on your nx and ny
set xrange [0:400]
set yrange [0:100]
set cbrange [0:0.15]         # Limits color scale to highlight swirls

# 5. The Plot Command
# 'pm3d' creates the smooth color map
splot "output.dat" using 1:2:3 with pm3d title "Fluid Wake"