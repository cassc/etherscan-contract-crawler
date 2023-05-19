import re
import hashlib
import os
import argparse

def remove_comments_and_whitespaces(code):
    code = re.sub(re.compile("/\*.*?\*/", re.DOTALL), "", code)
    code = re.sub(re.compile("//.*?\n"), "", code)
    code = re.sub('\s+', ' ', code).strip()
    return code

def calculate_md5(code):
    md5_hash = hashlib.md5()
    md5_hash.update(code.encode())
    return md5_hash.hexdigest()

def process_files(directory):
    for foldername in os.listdir(directory):
        contract_path = os.path.join(directory, foldername)
        if os.path.isdir(contract_path):
            all_code = ""
            for filename in os.listdir(contract_path):
                if filename.endswith(".sol"):
                    file_path = os.path.join(contract_path, filename)
                    with open(file_path, 'r') as file:
                        code = file.read()
                    clean_code = remove_comments_and_whitespaces(code)
                    all_code += clean_code

            md5 = calculate_md5(all_code)
            checksum_file = os.path.join(contract_path, "naive_checksum.txt")
            with open(checksum_file, 'w') as file:
                print(f"Writing checksum to {checksum_file}")
                file.write(md5)

if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument('dir', type=str, help='The directory to process')

    args = parser.parse_args()
    process_files(args.dir)
