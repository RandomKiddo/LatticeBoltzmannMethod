# File: plot_strouhal.plt
#
# Plots the experimental vs. predicted Strouhal vs. Reynolds from
# a hand-made .dat file.
#
# Programmer: Neil Ghugare ghugare.1@osu.edu
#
# Revision History:
#   04/24/2026 Initial Version.
#
# Notes:
# Run with "gnuplot" and then "load plot_strouhal.plt".

# --- 1. Output Settings ---
set terminal pngcairo size 1000,400 enhanced font 'Verdana,12'
set output 'strouhal_values.png'
set timestamp

# --- 2. Labels and Legends --- 
set title "Strouhal vs. Reynolds Experimental vs. Predicted"
set xlabel "Reynolds Number Re"
set ylabel "Strouhal Number St"
set key bottom right

# --- 3. The Plot Command --- 
# 'smooth unique' is due to the .dat file not being in order.
plot "strouhal_values.dat" using 1:2 title 'Experimental Results' smooth unique with linespoints pt 7 ps 1.5,\
     "strouhal_values.dat" using 1:3 title 'Williamson' smooth unique with linespoints pt 5 ps 1.5
