import json
import time

from functools import wraps

# * Adapted from pg.31 of High Performance Python by Gorelick & Osvald, 2nd ed.
# Function decorator to time a function.
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
	with open(filename, 'r') as f:
		config = json.load(f)
	
	return dict(config)

def assemble_data_filename(base: str, nx: int, ny: int, tau: float, u_inlet: float, addendum: str = '') -> str:
	return f'{base}_{nx}x{ny}_tau{tau}_uinlet{u_inlet}' + addendum + '.dat'


