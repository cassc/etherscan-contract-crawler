import argparse
import os
import json
from typing import Optional, Dict, List, Any
from bs4 import BeautifulSoup
import requests
from datetime import datetime
import time
try:
    import undetected_chromedriver as uc
except:
    print('undetected_chromedriver not installed, crawling from polygonscan will not work')
    pass

REQ_HEADER = {
    'user-agent': 'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/102.0.5005.61 Safari/537.36',
}

VERIFIED_CONTRACT_URL = 'https://etherscan.io/contractsVerified'
CONTRACT_SOURCE_URL   = 'https://etherscan.io/address/{}#code'

INPAGE_META_TEXT = {'Contract Name:': 'contract_name',
                    'Compiler Version': 'version',
                    'Optimization Enabled': 'optimizations',
                    'Other Settings:': 'settings'}

def address_from_tr(td: Any) -> str:
    a = td.select_one('a.js-clipboard')
    return a.attrs.get('data-clipboard-text') if (a and a.attrs) else None

# Crawl meta info of contracts by page
def parse_page(page: Optional[int]=None, retry=3, retry_delay=5) -> Optional[List[Dict[str, str]]]:
    url = VERIFIED_CONTRACT_URL if page is None else f'{VERIFIED_CONTRACT_URL}/{page}'
    print(f'Crawling {url}')
    resp = requests.get(url, headers=REQ_HEADER, allow_redirects=False)
    if resp.status_code != 200:
        print(f'No results found on page: {page}, http status: {resp.status_code}')
        return None
    try:
        soup = BeautifulSoup(resp.content, 'lxml')
        trs = soup.select('tr')
        table_headers = [th.text.strip() for th in trs[0].select('th')]
        return [dict(zip(table_headers, [address_from_tr(td) or td.text.strip() for td in tr.select('td')])) for tr in trs[1:]]
    except Exception as e:
        print(f'Error {e}')
        if retry > 0:
            time.sleep(retry_delay)
            f'Parse page failed for {url}, status {resp.status_code}, retry in {retry_delay} secs'
            return parse_page(page, retry-1, retry_delay)
        else:
            raise e

# Parse meta data from source code page
def parse_for_inpage_meta(soup):
    rows = [t.text.strip().split('\n', maxsplit=1) for t in soup.select('#ContentPlaceHolder1_contractCodeDiv .row div')]
    # rows = [t.text.strip().split('\n+', maxsplit=1) for t in soup.select('#ContentPlaceHolder1_contractCodeDiv .row div')]
    rows = [[t[0].strip(), t[1].strip()] for t in rows if len(t) == 2]
    rows = [(INPAGE_META_TEXT[t[0]], t[1]) for t in rows if t[0] in INPAGE_META_TEXT]
    return dict(rows)

def parse_for_contract_name(soup):
    meta = parse_for_inpage_meta(soup)
    return meta['contract_name']

def parse_source_soup(soup, address=None, contract_name=None):
    address = address or soup.select('title')[0].text.split(r'|')[1].strip().split()[-1]
    contract_name = contract_name or parse_for_contract_name(soup) or ''

    if not contract_name:
        print(f'ERROR: No contract name found in {address}')

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

    file_spans = [name for name in soup.select('.d-flex > .text-secondary') if '.sol' in name.text] or [name for name in soup.select('.d-flex > .text-muted') if '.sol' in name.text]
    files =  [parse_for_file_name(name.text) for name in file_spans]
    sources = [source.text for source in soup.select('.js-sourcecopyarea')]

    if len(sources) != len(files): # some bscscan contracts have different DOM structure
        sources = [source.text for source in soup.select('pre.editor')]

    inpage_meta = parse_for_inpage_meta(soup)
    write_source_file(f'inpage_meta.json', json.dumps(inpage_meta))

    if not files:
        if not sources:
            raise Exception(f'No source code found for {address} {contract_name}')
        if len(sources) > 1:
            raise Exception(f'Multiple source with no file name? {address} {contract_name}')
        write_source_file(f'{contract_name}.sol', sources[0])
        return

    for source_file_name, source_code in zip(files, sources):
        write_source_file(source_file_name, source_code)

# Save metadata of a contract to a json file
def write_meta_json(contract: Dict[str, str]):
    address = contract['Address']
    contract_name = contract['Contract Name']

    if not (address and contract_name):
        raise Exception(f'Bad meta data in {contract}')

    parent = f'{ROOT_DIR}/{address}_{contract_name}'
    os.makedirs(parent, exist_ok=True)
    f = f'{parent}/meta.json'

    if not os.path.exists(f):
        with open(f, 'w') as f:
            f.write(json.dumps(contract, indent=2))

# Get contract source code
def download_source(contract: Dict[str, str], retry=3, retry_delay=5, throw_if_fail=False) -> None:
    address = contract['Address']
    contract_name = contract['Contract Name']
    url = CONTRACT_SOURCE_URL.format(address)
    resp = requests.get(url, headers=REQ_HEADER, allow_redirects=False)

    def maybe_retry(e=None):
        if retry > 0:
            time.sleep(retry_delay)
            f'Download source failed for {address} {contract_name}, status {resp.status_code}, retry in {retry_delay} secs'
            return download_source(contract, retry-1, retry_delay)
        else:
            if throw_if_fail:
                raise e or Exception(f'Download source abort for {address} {contract_name}, status {resp.status_code}')
            return

    if resp.status_code != 200:
        maybe_retry()

    try:
        soup = BeautifulSoup(resp.content, 'lxml')
        parse_source_soup(soup, address, contract_name)
    except Exception as e:
        maybe_retry(e)

def fetch_all():
    contracts = [c for p in range(1, 21) for c in parse_page(p)]
    now = f"{datetime.now().strftime('%Y%m%d_%H%M%S')}"

    with open(f'{ROOT_DIR}/contracts_{now}.json', 'w') as f:
        f.write(json.dumps(contracts, indent=2))

    for contract in contracts:
        write_meta_json(contract)
        download_source(contract)

def download_url_poly(url, retry=3, retry_delay=5, throw_if_fail=False):
    address = url.split('/')[-1].split('#')[0]
    driver = uc.Chrome()
    driver.get(url)

    # fullscreen_btn = driver.find_elements(By.XPATH, '//a[@class="btn btn-xss btn-secondary togglefullscreen"]')
    # for btn in fullscreen_btn:
    #     btn.click()
    #     time.sleep(0.05)

    cookie = driver.get_cookies()[0]
    for key, value in cookie.items():
        cookie[key] = str(value)

    resp = requests.get(url, headers=REQ_HEADER, allow_redirects=True, cookies=cookie)
    soup = BeautifulSoup(resp.content, 'lxml')
    parse_source_soup(soup, address)

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
    ap.add_argument("--web", default="etherscan",type=str, help="Choose website, etherscan(default) or bscscan")
    ap.add_argument("--url", type=str, help="URL of contract to download")
    ap.add_argument("--output-dir", type=str, help="URL of contract to download", default="./")
    args = ap.parse_args()
    OUTPUT_DIR = args.output_dir
    OUTPUT_DIR = OUTPUT_DIR[:-1] if OUTPUT_DIR.endswith('/') else OUTPUT_DIR
    ROOT_DIR = f'{OUTPUT_DIR}/contracts'

    web = args.web
    if web == 'etherscan':
        VERIFIED_CONTRACT_URL = 'https://etherscan.io/contractsVerified'
        CONTRACT_SOURCE_URL   = 'https://etherscan.io/address/{}#code'
        os.makedirs(ROOT_DIR, exist_ok=True)
        fn = download_url

    elif web == 'bscscan':
        VERIFIED_CONTRACT_URL = 'https://bscscan.com/contractsVerified'
        CONTRACT_SOURCE_URL   = 'https://bscscan.com/address/{}#code'
        ROOT_DIR = f'{OUTPUT_DIR}/bsc_contracts'
        os.makedirs(ROOT_DIR, exist_ok=True)
        fn = download_url

    elif web == "polygon":
        VERIFIED_CONTRACT_URL = 'https://polygonscan.com/contractsVerified'
        CONTRACT_SOURCE_URL   = 'https://polygonscan.com/address/{}#code'
        ROOT_DIR = f'{OUTPUT_DIR}/polygon_contracts'
        os.makedirs(ROOT_DIR, exist_ok=True)
        fn = download_url_poly

    else:
        raise Exception('Invalid website, choose etherscan or bscscan')

    print(VERIFIED_CONTRACT_URL)
    print(CONTRACT_SOURCE_URL)
    print(ROOT_DIR)
    url = args.url
    if url:
        fn(url)
    else:
        fetch_all()

    print("all jobs done")
