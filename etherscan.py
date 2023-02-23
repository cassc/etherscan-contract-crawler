# Download contract source code using Etherscan HTTP json api

import requests
import json
import argparse

ap = argparse.ArgumentParser()
ap.add_argument("--address", type=str, required=True, help="Contract address")
ap.add_argument("--apikey", type=str, required=True, help="Etherscan api key")
ap.add_argument("--output", type=str, default="source.json", help="Output source code as json, suitable for use as solc input ")

args = ap.parse_args()

address = args.address
api_key = args.apikey
output = args.output

if not api_key:
    print("Please provide --apikey")
    exit(1)

if not address:
    print("Please provide --address")
    exit(1)

url = f'https://api.etherscan.io/api?module=contract&action=getsourcecode&address={address}&apikey={api_key}'

response = requests.get(url)
# with open('response.txt', 'w') as f:
#     f.write(response.text)

data = json.loads(response.text)

if data['status'] == '1':
    contract_name = data['result'][0]['ContractName']
    source_code = data['result'][0]['SourceCode']

    with open(output, 'w') as f:
        t = source_code.replace('{{', '{').replace('}}', '}')
        f.write(t)
else:
    print('Error: Unable to retrieve contract source code')
