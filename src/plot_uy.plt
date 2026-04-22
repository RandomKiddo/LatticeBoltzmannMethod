# File: plot_uy.plt
#
# Program that plots the last step of the Karman Vortex Street.
#
# Programmer: Neil Ghugare ghugare.1@osu.edu
#
# Revision History:
#   04/22/2026 Initial version for validation.
#
# Notes:
# Run with "gnuplot" and then "load plot_uy.plt".

# --- 1. Output Settings ---
set terminal pngcairo size 1000,400 enhanced font 'Verdana,12'
set output 'uy.png'
set timestamp

# --- 3. Labels and Legends --- 
set title "Kármán Vortex Street: Velocity Magnitude"
set xlabel "Time t"
set ylabel "uy/rho"
set key outside                   # Ensures legend doesn't overlap data

# --- 5. The Plot Command --- 
splot "vortex_street_4000x1000_tau0.6_uinlet0.1_PROBE.dat" using 1:2 notitle # Update .dat file as needed. 
