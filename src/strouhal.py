import numpy as np
import argparse

from helper import *

def calculate_strouhal(filename: str, ny: int, u_inlet: float) -> float:
	data = np.loadtxt(filename)
	t = data[:, 0]
	uy = data[:, 1]
	
	uy_fft = np.abs(np.fft.fft(uy))
	freqs = np.fft.fftfreq(len(t), d=1)

	idx = np.argmax(uy_fft[1:len(uy)//2]) + 1
	f_lattice = freqs[idx]

	r = ny//10
	u_max = u_inlet * (ny/(ny-2*r))

	return (f_lattice * 2*r / u_max)


if __name__ == '__main__':
	parser = argparse.ArgumentParser(prog='Karman Vortex Street LBM Strouhal',
					 description='Verifies the Strouhal Number for the LBM simulation.')
	parser.add_argument('--config', type=str, help='Path to JSON config file.', default='config.json')
	
	args = parser.parse_args()
	
	config = load_json(args.config)
	
	nx = config['domain']['nx']
	ny = config['domain']['ny']
	tau = config['physics']['tau']
	u_inlet = config['physics']['u_inlet']
	base = config['output']['base_filename']
	
	filename = assemble_data_filename(base, nx, ny, tau, u_inlet, addendum='_PROBE')
	
	print(f'Strouhal Number: {calculate_strouhal(filename, ny, u_inlet):.6f}')


	
