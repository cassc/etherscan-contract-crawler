# python blockchain-multichain-monitor.py  --endpoint $POLYGON_RPC_ENDPOINT polygon.addresses.csv
# python blockchain-multichain-monitor.py  --endpoint $BSC_RPC_ENDPOINT bsc.addresses.csv

import requests
import csv
import argparse
from web3.middleware import ExtraDataToPOAMiddleware
from web3 import Web3, HTTPProvider
from web3.providers.rpc.utils import (
    REQUEST_RETRY_ALLOWLIST,
    ExceptionRetryConfiguration,
)
import os
from datetime import datetime
import time

# parse command-line arguments
parser = argparse.ArgumentParser()
parser.add_argument('--endpoint', type=str, help='Web3 endpoint', required=True)
parser.add_argument('outfile', type=str, help='CSV file to write created contract addresses')
args = parser.parse_args()

outfile = args.outfile
WEB3_PROVIDER_URI = args.endpoint
CALLS = 5
PERIOD = 1

seen = set()

http_provider_exceptions = (ConnectionError, requests.HTTPError, requests.Timeout)


def make_w3():
    w3 = Web3(HTTPProvider(
        WEB3_PROVIDER_URI,
        exception_retry_configuration=ExceptionRetryConfiguration(
        errors=http_provider_exceptions,

        # number of retries to attempt
        retries=5,

        # initial delay multiplier, doubles with each retry attempt
        backoff_factor=0.125,

        # an in-house default list of retryable methods
        method_allowlist=REQUEST_RETRY_ALLOWLIST,
    ),
    ))


    w3.middleware_onion.inject(ExtraDataToPOAMiddleware, layer=0)
    return w3


if not os.path.exists(outfile):
    print(f"Creating file {outfile}")
    output = open(args.outfile, 'a')
    outfile = csv.writer(output)
    outfile.writerow(['Block', 'Transaction Hash', 'Contract Address'])
else:
    print(f"Appending to file {outfile}")
    with open(outfile, 'r') as f:
        reader = csv.reader(f)
        for row in reader:
            if len(row) > 0:
                seen.add(row[2])
    output = open(args.outfile, 'a')
    outfile = csv.writer(output)


def is_contract(w3, address):
    code = w3.eth.get_code(address)
    return code != b''

def process_transaction(transaction):
    if transaction.get('to') is None:
        receipt = w3.eth.get_transaction_receipt(transaction['hash'])
        contract_address = receipt['contractAddress']
        print(f"Contract created in transaction {transaction['hash'].hex()} at address {contract_address}")
        outfile.writerow([transaction['blockNumber'], transaction['hash'].hex(), contract_address])
    else:
        address = transaction['to']
        if address in seen:
            return
        seen.add(address)
        if is_contract(w3, address):
            print(f"Contract found at address {address}")
            outfile.writerow([transaction['blockNumber'], transaction['hash'].hex(), address])

def handle_block(block_hash):
    block = w3.eth.get_block(block_hash, full_transactions=True)
    for transaction in block.transactions:
        process_transaction(transaction)

w3 = make_w3()
block_filter = w3.eth.filter('latest')
while True:
    try:
        for block_hash in block_filter.get_new_entries():
            print(f'{datetime.now()} new block: {block_hash.hex()}')
            block = w3.eth.get_block(block_hash)
            handle_block(block_hash)
    except KeyboardInterrupt:
        output.flush()
        output.close()
        print("Exiting...")
        break
    except Exception as e:
        print(f"Exception: {e}")
        time.sleep(5)
        if '32000' in str(e) or 'too many' in str(e).lower():
            time.sleep(600)
            print('Restarting...')
            w3 = make_w3()
            block_filter = w3.eth.filter('latest')
        continue
