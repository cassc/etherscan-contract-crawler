# python contract_crawler.py --web bscscan --session-url https://bscscan.com/address/0x2D530a3b07F2a9Cc3B9043356Af293aEE09ED103#code

import argparse
import os
import fnmatch
import json
from typing import Optional, Dict, List, Any
from typing_extensions import override
from bs4 import BeautifulSoup
import requests
from datetime import datetime
import time
import re

import undetected_chromedriver as uc
from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.support import expected_conditions as EC
from selenium.webdriver.common.by import By

proxies = {}  #{'http': "socks5://127.0.0.1:1080", 'https': "socks5://127.0.0.1:1080"}

REQ_HEADER = {
    'user-agent': 'Mozilla/5.0 (X11; CrOS x86_64 8172.45.0) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/51.0.2704.64 Safari/537.36',
}

VERIFIED_CONTRACT_URL = 'https://etherscan.io/contractsVerified'
CONTRACT_SOURCE_URL   = 'https://etherscan.io/address/{}#code'

INPAGE_META_TEXT = {'Contract Name:': 'contract_name',
                    'Compiler Version': 'version',
                    'Optimization Enabled': 'optimizations',
                    'Other Settings:': 'settings'}

def starts_with_digit(s):
    return bool(re.match(r'^\d', s))

session = {}

class any_of_elements_present:
    def __init__(self, *locators):
        self.locators = locators

    def __call__(self, driver):
        for locator in self.locators:
            try:
                element = EC.presence_of_element_located(locator)(driver)
                if element:
                    return element
            except:
                pass
        return False

def catch_all_exceptions(handler):
    def decorator(func):
        def wrapper(*args, **kwargs):
            try:
                return func(*args, **kwargs)
            except Exception as e:
                return handler(e)
        return wrapper
    return decorator

def exception_silent_handler(e):
    # print(f"Caught an exception: {str(e)}")
    return None


def get_session_from_chromedriver(url):
    options = uc.ChromeOptions()
    options.add_argument('--no-sandbox')
    options.add_argument('--disable-gpu')
    # options.add_argument('--headless=new')

    # options.add_argument('--headless')

    # driver = uc.Chrome(options=options)
    driver = uc.Chrome(options=options, browser_executable_path='/usr/bin/brave', enable_cdp_events=True, version_main=112)

    user_agent = driver.execute_script("return navigator.userAgent;")

    selectors = [
        '#ctl00 > div.d-md-flex.justify-content-between.my-3 > ul',
        '#ContentPlaceHolder1_pageRecords > nav > ul',
        '#searchFilterInvoker',
        '#ContentPlaceHolder1_li_transactions'
    ]

    selectors = [(By.CSS_SELECTOR, s) for s in selectors]

    driver.get(url)
    WebDriverWait(driver, 30).until(any_of_elements_present(*selectors))
    cookies = driver.get_cookies()

    print(cookies)

    session = requests.Session()
    session.headers.update({'User-Agent': user_agent})

    if len(cookies) < 1:
        raise Exception('Should have some cookies here')

    for cookie in cookies:
        session.cookies.set(cookie['name'], cookie['value'])

    print(f'Cookies loaded from {url} {session.cookies}')
    return session

def load_session(url):
    global session
    if not session:
        session = get_session_from_chromedriver(url)
    return session


def address_from_tr(td: Any) -> str:
    a = td.select_one('a.js-clipboard')
    return a.attrs.get('data-clipboard-text') if (a and a.attrs) else None

# Crawl meta info of contracts by page
def parse_page(page: Optional[int]=None, retry=3, retry_delay=5) -> Optional[List[Dict[str, str]]]:
    url = VERIFIED_CONTRACT_URL if page is None else f'{VERIFIED_CONTRACT_URL}/{page}'
    print(f'Crawling {url}')
    resp = session.get(url, allow_redirects=False)
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

def parse_for_balance(soup):
    bsc_selector = '#ContentPlaceHolder1_divSummary > div.row.mb-4 > div.col-md-6.mb-3.mb-md-0 > div > div.card-body > div:nth-child(1) > div.col-md-8'
    eth_selector= '#ContentPlaceHolder1_divSummary > div.row.g-3.mb-4 > div:nth-child(1) > div > div > div:nth-child(2) > div > div'
    found = soup.select_one(eth_selector) or soup.select_one(bsc_selector)
    return found.text.strip() if found else None

def parse_for_num_txs(soup):
    bsc_selector = '#transactions > div.d-md-flex.align-items-center > p'
    eth_selector = '#ContentPlaceHolder1_divTxDataInfo > div > p'

    found = soup.select_one(eth_selector) or soup.select_one(bsc_selector)
    if not found:
        return None

    s = found.text.strip()
    match = re.search(r'a total of ([\d,]+)', s)

    if match:
        num_str = match.group(1)
        num_str = num_str.replace(',', '')
        return int(num_str)
    else:
        return None

# Parse meta data from source code page
def parse_for_inpage_meta(soup):
    rows = [t.text.strip().split('\n', maxsplit=1) for t in soup.select('#ContentPlaceHolder1_contractCodeDiv .row div')]
    # rows = [t.text.strip().split('\n+', maxsplit=1) for t in soup.select('#ContentPlaceHolder1_contractCodeDiv .row div')]
    rows = [[t[0].strip(), t[1].strip()] for t in rows if len(t) == 2]
    rows = [(INPAGE_META_TEXT[t[0]], t[1]) for t in rows if t[0] in INPAGE_META_TEXT]
    balance = parse_for_balance(soup)
    num_txs = parse_for_num_txs(soup)
    data = dict(rows)

    if balance:
        data['balance'] = balance

    if num_txs:
        data['num_txs'] = num_txs

    return data

def parse_for_contract_name(soup):
    meta = parse_for_inpage_meta(soup)
    return meta['contract_name']

def select_file_names(soup) -> list:
    @catch_all_exceptions(exception_silent_handler)
    def parse_for_file_name(text):
        num_text, name_text = text.strip().split(':')
        _, n, _, total = num_text.split()
        num = f'{n:0>2}_{total:0>2}'
        return f'{num}_{name_text.strip()}'

    selectors  =  ['.d-flex > .text-secondary', '.d-flex > .text-muted', '#dividcode > div > span']
    file_spans = []
    files = []
    for selector in selectors:
        file_spans = soup.select(selector)
        files = [parse_for_file_name(name.text) for name in file_spans]
        files = [f for f in files if f]
        if len(files) > 0:
            break
    return files

def select_sources(soup) -> list:
    selectors = ['.js-sourcecopyarea', 'div.ace_scroller > div', 'pre.editor']
    sources = []
    for selector in selectors:
        sources = [e.text for e in soup.select(selector) if e.text and not starts_with_digit(e.text)]
        if len(sources) > 0:
            break
    return sources

def parse_source_soup(soup, address=None, contract_name=None):
    address = address or soup.select('title')[0].text.split(r'|')[1].strip().split()[-1]
    contract_name = contract_name or parse_for_contract_name(soup) or ''

    if not contract_name:
        print(f'ERROR: No contract name found in {address}')

    parent = f'{ROOT_DIR}/{address}_{contract_name}'
    os.makedirs(parent, exist_ok=True)


    def write_source_file(source_file_name, source_code, overwrite=False):
        f = f'{parent}/{source_file_name}'
        if (not overwrite) and os.path.exists(f):
            return
        print(f'Saving {f}')
        with open(f, 'w') as f:
            f.write(source_code)

    files = select_file_names(soup)
    sources = select_sources(soup)


    if len(sources) < 1:
        raise Exception(f'No source code found for {address} {contract_name}')

    inpage_meta = parse_for_inpage_meta(soup)
    write_source_file(f'inpage_meta.json', json.dumps(inpage_meta), True)

    if len(sources) > 1 and len(files) == 0:
        raise Exception(f'Multiple source with no file name? {address} {contract_name}')

    if len(sources) == 1 and len(files) == 0:
        write_source_file(f'{contract_name}.sol', sources[0])
        return

    # if len(sources) != len(files): the extra source appearing in the sources might just be `settings`
    #     raise Exception(f'Number of files does not match number of source text: {address} {contract_name}')

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
    print(f"downloading {url}")
    resp = session.get(url, allow_redirects=False)

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

    session = get_session_from_chromedriver(url)

    resp = session.get(url)
    soup = BeautifulSoup(resp.content, 'lxml')
    parse_source_soup(soup, address)

def download_url(url, retry=3, retry_delay=5, throw_if_fail=False):
    address = url.split('/')[-1].split('#')[0]
    resp = session.get(url, allow_redirects=False)

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
    try:
        parse_source_soup(soup, address)
    except Exception as e:
        with open('.example.html', 'wb') as f:
            f.write(resp.content)
        raise e

def load_addresses_from_csv(csv_path: str, csv_col_index: int = 0):
    import csv
    with open(csv_path, 'r') as f:
        reader = csv.reader(f)
        return [row[csv_col_index] for row in reader]

def build_existing_contracts(root: str):
    return [f.split('_')[0].lower() for f in os.listdir(root) if os.path.isdir(os.path.join(root, f))]

def is_valid_ethereum_address(address):
    pattern = "^0x[a-fA-F0-9]{40}$"
    return bool(re.match(pattern, address))

if __name__ == '__main__':
    ap = argparse.ArgumentParser()
    ap.add_argument("--web", default="etherscan",type=str, help="Choose website, etherscan(default) or bscscan")
    ap.add_argument("--url", type=str, help="URL of contract to download")
    ap.add_argument("--output-dir", type=str, help="URL of contract to download", default="./")
    ap.add_argument("--session-url", type=str, help="URL to load the first session from")
    ap.add_argument("--csv", type=str, help="Load address from csv file")
    ap.add_argument("--csv-col-index", type=int, help="Column index of address in csv file", default=-1)

    args = ap.parse_args()
    OUTPUT_DIR = args.output_dir
    OUTPUT_DIR = OUTPUT_DIR[:-1] if OUTPUT_DIR.endswith('/') else OUTPUT_DIR
    ROOT_DIR = f'{OUTPUT_DIR}/contracts'

    web = args.web

    addresses = []
    if args.csv:
        addresses = load_addresses_from_csv(args.csv, args.csv_col_index)
        print(f'Found {len(addresses)} addresses in {args.csv}')

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

    load_session(args.session_url or VERIFIED_CONTRACT_URL)

    if url:
        fn(url)
    elif args.csv:
        existing = build_existing_contracts(ROOT_DIR)
        processed = set()
        if os.path.exists('.processed.txt'):
            with open('.processed.txt', 'r') as f:
                lines = [line.lower() for line in f.read().split('\n')]
                processed = set(processed)

        ignored = processed.union(existing)
        f_processed = open('.processed.txt', 'w')
        for address in addresses:
            if not is_valid_ethereum_address(address):
                print(f'Invalid address {address}')
                continue

            if address.lower() not in ignored:
                url = CONTRACT_SOURCE_URL.format(address)
                print(f'Processing {url}')
                try:
                    fn(url)
                except KeyError as e:
                    if 'contract_name' in str(e):
                        print(f'Probably no code found for {address}')
                    else:
                        raise e
                finally:
                    f_processed.write(f'{address}\n')
                    f_processed.flush()
            else:
                 print(f'Skipping {address}, already exists')
    else:
        fetch_all()

    print("all jobs done")
