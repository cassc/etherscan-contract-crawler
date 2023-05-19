import os
import argparse
from collections import defaultdict

empty_checksum = "d41d8cd98f00b204e9800998ecf8427e"

def find_duplicates(directory):
    checksum_dict = defaultdict(list)
    for foldername in os.listdir(directory):
        contract_path = os.path.join(directory, foldername)
        if os.path.isdir(contract_path):
            checksum_file = os.path.join(contract_path, "naive_checksum.txt")
            if os.path.exists(checksum_file):
                with open(checksum_file, 'r') as file:
                    checksum = file.read()
                if checksum == empty_checksum:
                    continue
                checksum_dict[checksum].append(foldername)

    for checksum, paths in checksum_dict.items():
        if len(paths) > 1:
            print(f"{checksum}:")
            for path in paths:
                print(f"- {path}")

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description='Find duplicate checksums.')
    parser.add_argument('dir', type=str, help='The directory to process')

    args = parser.parse_args()
    find_duplicates(args.dir)
