# Fix imports path for all solidity files in current directory
# Use this script to make the source code compilable 

import re
import os

sols =  [f for f in os.listdir('.') if f.endswith('.sol')]

def search_sol_by_filename(name):
    try:
        return next(f for f in sols if f[6:] == name)
    except StopIteration:
        print(f'No candidate contract found for {name}')
        return None

def fix_import_line(line):
    match = re.search(r'".*/(\w+\.sol)";', line)
    if match:
        sol = match.group(1)
        replacement = search_sol_by_filename(sol)
        if replacement:
            nline = f'import "./{replacement}";\n'
            # print(f'{line} -> {nline}')
            return nline
        
    return line
        

def fix_import(source):
    lines = []
    with open(source, 'r') as f:
        lines = list(f.readlines())

    updated_lines = [fix_import_line(line) for line in lines]
    if lines != updated_lines:
        with open(source, 'w') as f:
            f.write(''.join(updated_lines))
        
for f in sols:
    fix_import(f)


