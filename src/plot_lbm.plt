# Gnuplot script for LBM Visualization
# Author: [Your Name]

# Set output to a PNG file
set terminal pngcairo size 800,400 enhanced font 'Verdana,10'
set output 'density_map.png'

# Formatting
set title "LBM Simulation: Fluid Density (rho)"
set xlabel "Lattice X-coordinate"
set ylabel "Lattice Y-coordinate"
set cblabel "Density"

# Color palette (Viridis-like)
set palette rgbformulae 22,13,10

# Plotting the 2D data
set view map
set size ratio -1 # Keep the aspect ratio square-ish
splot "output.dat" using 1:2:3 with pm3d notitle