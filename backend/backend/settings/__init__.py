import os
import glob
from pathlib import Path

BASE_DIR = Path(__file__).resolve().parent.parent.parent

current_dir = os.path.dirname(__file__)
py_files = glob.glob(os.path.join(current_dir, '*.py'))

for file in py_files:
    module = os.path.basename(file)
    if module == '__init__.py' or module.startswith('_'):
        continue
    module_name = f'.{module[:-3]}'
    exec(f'from {module_name} import *', globals())
