# Usage

Download contracts from etherscan:

``` bash
python contract_crawler.py --web etherscan  --use-api --api-key $ETHERSCAN_APIKEYS --csv eth-addresses.csv --output-dir ../verified_contracts/
```

Download contracts can be found in https://github.com/cassc/verified_contracts

# Deprecated

Crawl the latest verified contract source code from Etherscan. Usage:

``` bash
python etherscan_contract_crawler.py

python etherscan_contract_crawler.py --url
```

To use a unified crawler for etherscan and bscscan:

``` bash
python contract_crawler.py --web etherscan
python contract_crawler.py --web bscscan
python contract_crawler.py --web etherscan --url URL_HERE
python contract_crawler.py --web bscscan   --url URL_HERE
```

Crawled contracts will be saved in `contracts` folder, each contract
can have multiple source files, and the source files will be placed in
a folder with the format
`{contract_address}_{contract_name}`. Metadata for contracts will be
saved in a JSON file, for example,
`contracts/contracts_20220602_174048.json`.


Some sample outputs:

``` text
contracts
├── contracts/0x00000b7665850F6b1E99447a68dB1e83d8Deafe3_BadgerRegistry
│   ├── contracts/0x00000b7665850F6b1E99447a68dB1e83d8Deafe3_BadgerRegistry/01_02_BadgerRegistry.sol
│   └── contracts/0x00000b7665850F6b1E99447a68dB1e83d8Deafe3_BadgerRegistry/02_02_EnumerableSet.sol
├── contracts/0x00515d3e90950b844D54fB2781afeeda81ADea39_RGB22
│   ├── contracts/0x00515d3e90950b844D54fB2781afeeda81ADea39_RGB22/01_14_RGB22.sol
│   ├── contracts/0x00515d3e90950b844D54fB2781afeeda81ADea39_RGB22/02_14_ERC721A.sol
│   ├── contracts/0x00515d3e90950b844D54fB2781afeeda81ADea39_RGB22/03_14_Ownable.sol
│   ├── contracts/0x00515d3e90950b844D54fB2781afeeda81ADea39_RGB22/04_14_MerkleProof.sol
├── contracts/contracts_20220602_174048.json
...
```
