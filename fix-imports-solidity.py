# Fix imports path for all solidity files in the `--root` directory
# Use this script to make the source code compilable. Assuming all source code are in the root directory.

import re
import os

def search_sol_by_filename(name, sols):
    file_name = lambda p: p.split(os.path.sep)[-1]

    try:
        return next(file_name(f) for f in sols if file_name(f)[6:] == name)
    except StopIteration:
        print(f'No candidate contract found for {name}')
        return None

def fix_import_line(line, sols):
    match = re.search(r'''['"].*/(\w+\.sol)['"];''', line)
    if match:
        sol = match.group(1)
        replacement = search_sol_by_filename(sol, sols)
        if replacement:
            nline = f'import "./{replacement}";\n'
            # print(f'{line} -> {nline}')
            return nline
        
    return line
        

def fix_import(sol, sols):
    lines = []
    with open(sol, 'r') as f:
        lines = list(f.readlines())

    updated_lines = [fix_import_line(line, sols) for line in lines]
    if lines != updated_lines:
        with open(sol, 'w') as f:
            f.write(''.join(updated_lines))
        


if __name__ == '__main__':
    import argparse
    ap = argparse.ArgumentParser()
    ap.add_argument("--root", type=str, help="Root directory of a single solidity project")
    args = ap.parse_args()
    root = args.root
    sols =  [os.path.join(root, f) for f in os.listdir(root) if f.endswith('.sol')]
    for f in sols:
        fix_import(f, sols)

