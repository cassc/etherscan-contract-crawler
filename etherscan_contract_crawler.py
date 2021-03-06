import argparse
import os
import json
from typing import Optional, Dict, List
from bs4 import BeautifulSoup
import requests
from datetime import datetime
import time

REQ_HEADER = {
    'user-agent': 'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/102.0.5005.61 Safari/537.36',
}

ETHERSCAN_VERIFIED_CONTRACT_URL = 'https://etherscan.io/contractsVerified'
ETHERSCAN_CONTRACT_SOURCE_URL = 'https://etherscan.io/address/{}#code'

ROOT_DIR = './contracts'
os.makedirs(ROOT_DIR, exist_ok=True)

# Crawl meta info of contracts by page
def parse_page(page: Optional[int]=None) -> Optional[List[Dict[str, str]]]:
    url = ETHERSCAN_VERIFIED_CONTRACT_URL if page is None else f'{ETHERSCAN_VERIFIED_CONTRACT_URL}/{page}'
    print(f'Crawling {url}')
    resp = requests.get(url, headers=REQ_HEADER, allow_redirects=False)
    if resp.status_code != 200:
        print(f'No results found on page: {page}, http status: {resp.status_code}')
        return None
    soup = BeautifulSoup(resp.content, 'lxml')
    trs = soup.select('tr')
    table_headers = [th.text.strip() for th in trs[0].select('th')]
    return [dict(zip(table_headers, [td.text.strip() for td in tr.select('td')])) for tr in trs[1:]]

def parse_source_soup(soup, address=None, contract_name=None):
    address = address or soup.select('title')[0].text.split(r'|')[1].strip().split()[-1]
    contract_name = contract_name or soup.select('title')[0].text.split(r'|')[0].strip()
    parent = f'{ROOT_DIR}/{address}_{contract_name}'
    os.makedirs(parent, exist_ok=True)

    def parse_for_file_name(text):
        num_text, name_text = text.strip().split(':')
        _, n, _, total = num_text.split()
        num = f'{n:0>2}_{total:0>2}'
        return f'{num}_{name_text.strip()}'

    def write_source_file(source_file_name, source_code):
        f = f'{parent}/{source_file_name}'
        if os.path.exists(f):
            print(f'File exists, ignore {f}')
            return
        print(f'Saving {f}')
        with open(f, 'w') as f:
            f.write(source_code)

    files =  [parse_for_file_name(name.text) for name in soup.select('.d-flex > .text-secondary') if '.sol' in name.text.strip()]
    sources = [source.text for source in soup.select('.js-sourcecopyarea')]

    if not files:
        if not sources:
            print(f'No source code found for {address} {contract_name}')
            return
        if len(sources) > 1:
            raise Exception(f'Multiple source with no file name? {address} {contract_name}')
        write_source_file(f'{contract_name}.sol', sources[0])
        return

    for source_file_name, source_code in zip(files, sources):
        write_source_file(source_file_name, source_code)
    

# Get contract source code
def download_source(contract: Dict[str, str], retry=3, retry_delay=5, throw_if_fail=False) -> None:
    address = contract['Address']
    contract_name = contract['Contract Name']
    url = ETHERSCAN_CONTRACT_SOURCE_URL.format(address)
    resp = requests.get(url, headers=REQ_HEADER, allow_redirects=False)

    if resp.status_code != 200:
        if retry > 0:
            time.sleep(retry_delay)
            f'Download source failed for {address} {contract_name}, status {resp.status_code}, retry in {retry_delay} secs'
            return download_source(contract, retry-1, retry_delay)
        else:
            if throw_if_fail:
                raise Exception(f'Download source abort for {address} {contract_name}, status {resp.status_code}')
            return
                
    
    soup = BeautifulSoup(resp.content, 'lxml')
    parse_source_soup(soup, address, contract_name)
    
def fetch_all():
    contracts = [c for p in range(1, 21) for c in parse_page(p)]
    now = f"{datetime.now().strftime('%Y%m%d_%H%M%S')}"

    with open(f'{ROOT_DIR}/contracts_{now}.json', 'w') as f:
        f.write(json.dumps(contracts, indent=2))

    for contract in contracts:
        download_source(contract)

def download_url(url, retry=3, retry_delay=5, throw_if_fail=False):
    address = url.split('/')[-1].split('#')[0]
    resp = requests.get(url, headers=REQ_HEADER, allow_redirects=False)

    if resp.status_code != 200:
        if retry > 0:
            time.sleep(retry_delay)
            f'Download source failed for {url}, status {resp.status_code}, retry in {retry_delay} secs'
            return download_url(url, retry-1, retry_delay)
        else:
            if throw_if_fail:
                raise Exception(f'Download source abort for {url}, status {resp.status_code}')
            return

    soup = BeautifulSoup(resp.content, 'lxml')
    parse_source_soup(soup, address)
        
if __name__ == '__main__':
    ap = argparse.ArgumentParser()
    ap.add_argument("--url", type=str, help="URL of contract to download")
    args = ap.parse_args()
    url = args.url
    if url:
        download_url(url)
    else:
        fetch_all()
    
    
