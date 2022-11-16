// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

interface IOkxNFTMarketAggregator {
    enum MarketInfo {
        OKEXCHANGE_MAINNETTOKEN,   
        WYVERN_EXCHANGE,
        LOOKSRARE_ADAPTER,
        OPENSEA_SEAPORT_ADAPTER,
        OKEXCHANGE_ERC20_ADAPTER,
        OK_SEAPORT_ADAPTER
    }
}