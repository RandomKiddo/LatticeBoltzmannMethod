import numpy as np

data = np.loadtxt('vortex_street_800x200_tau0.6_uinlet0.1_PROBE.dat')
t = data[:, 0]
uy = data[:, 1]

uy_fft = np.abs(np.fft.fft(uy))
freqs = np.fft.fftfreq(len(t), d=1)

idx = np.argmax(uy_fft[1:len(uy)//2]) + 1
f_lattice = freqs[idx]

r = 200//10
u_inlet = 0.1
u_max = u_inlet * (200/(200-2*r))

print(f_lattice * 2*r / u_max)
