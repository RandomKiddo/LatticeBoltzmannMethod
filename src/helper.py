"""
File: helper.py

Program that includes helper functions for the Python visualization code.

Programmer: Neil Ghugare ghugare.1@osu.edu

Revision History:
	04/10/2026 Created initial version with comments.

Notes:
"""

import json
import time

from functools import wraps

# * Adapted from pg.31 of High Performance Python by Gorelick & Osvald, 2nd ed.
# Function decorator to time a function.
# Used as a decorator @timefn above a function definition. 
def timefn(fn):
	@wraps(fn)
	def measure_time(*args, **kwargs):
		t0 = time.time()
		returns = fn(*args, **kwargs)
		tf = time.time()
		print(f'Fcn *{fn.__name__}* completed in {tf-t0:.3f}s.')
		return returns
	return measure_time

def load_json(filename: str) -> dict:
	"""
	Loads the JSON file that defines simulation parameters.

	Arguments (required)
	1. filename - The JSON file name.
	
	Arguments (optional)
	None

	Returns
	The Python dictionary representing the JSON file.
	"""

	# Open the file.
	with open(filename, 'r') as f:
		config = json.load(f)
	
	# Return the dictionary.
	return dict(config)

def assemble_data_filename(base: str, nx: int, ny: int, tau: float, u_inlet: float, addendum: str = '') -> str:
	"""
	Assembles the .dat filename based on simulation parameters.

	Arguments (required)
	1. base - The string base file name.
	2. nx - The number of x cells.
	3. ny - The number of y cells.
	4. tau - The tau parameter for the simulation.
	5. u_inlet - The inlet velocity parameter.
	
	Arguments (optional)
	1. addendum - The addendum to the file name, like 'PROBE'.

	Returns
	The .dat filename.
	"""
	return f'{base}_{nx}x{ny}_tau{tau}_uinlet{u_inlet}' + addendum + '.dat'


