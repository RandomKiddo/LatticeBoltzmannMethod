# File: plot_vortex.plt
#
# Program that plots the last step of the Karman Vortex Street.
#
# Programmer: Neil Ghugare ghugare.1@osu.edu
#
# Revision History:
#   04/17/2026 Initial version with comments.
#
# Notes:
# Run with "gnuplot" and then "load plot_vortex.plt".

# --- 1. Output Settings ---
set terminal pngcairo size 1000,400 enhanced font 'Verdana,12'
set output 'vortex_street.png'

# --- 2. Map & Color Settings ---
set view map
set size ratio -1                 # Maintains physical proportions (not stretched).
set object 1 rectangle from screen 0,0 to screen 1,1 fillcolor rgb "white" behind
set palette rgbformulae 33,13,10  

# --- 3. Labels and Legends --- 
set title "Kármán Vortex Street: Velocity Magnitude"
set xlabel "Lattice X (Flow Direction)"
set ylabel "Lattice Y"
set cblabel "Velocity Magnitude (u)"
set key outside                   # Ensures legend doesn't overlap data

# --- 4. Range Adjustments ---
# Adjust these based on nx and ny.
set xrange [0:400]
set yrange [0:100]
set cbrange [0:0.15]              # Limits color scale to highlight swirls.

# --- 5. The Plot Command --- 
# 'pm3d' creates the smooth color map.
splot "vortex_street_1000x250_tau0.6_uinlet0.1_LASTSTEP.dat" using 1:2:3 with pm3d title "Fluid Wake"  # Update .dat file as needed. 