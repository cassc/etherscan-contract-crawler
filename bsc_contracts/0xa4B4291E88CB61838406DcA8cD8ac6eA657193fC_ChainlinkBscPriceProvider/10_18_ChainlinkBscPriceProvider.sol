// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "./ChainlinkPriceProvider.sol";

/**
 * @title Chainlink's price provider for BSC (Binance) network
 */
contract ChainlinkBscPriceProvider is ChainlinkPriceProvider {
    constructor() {
        // Binance's aggregators: https://docs.chain.link/docs/data-feeds/price-feeds/addresses/?network=bnb-chain
        // Note: These are NOT all available aggregators, not adding them all to avoid too expensive deployment cost
        _setAggregator(0x2170Ed0880ac9A755fd29B2688956BD959F933F8, AggregatorV3Interface(0x2A3796273d47c4eD363b361D3AEFb7F7E2A13782)); // BETH
        _setAggregator(0x55d398326f99059fF775485246999027B3197955, AggregatorV3Interface(0xB97Ad0E74fa7d920791E90258A6E2085088b4320)); // USDT
        _setAggregator(0x8AC76a51cc950d9822D68b83fE1Ad97B32Cd580d, AggregatorV3Interface(0x51597f405303C4377E36123cBc172b13269EA163)); // BUSD
        _setAggregator(0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c, AggregatorV3Interface(0x0567F2323251f0Aab15c8dFb1967E4e8A7D42aeE)); // WBNB
        _setAggregator(0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56, AggregatorV3Interface(0xcBb98864Ef56E9042e7d2efef76141f15731B82f)); // BUSD
        _setAggregator(0x1AF3F329e8BE154074D8769D1FFa4eE058B1DBc3, AggregatorV3Interface(0x132d3C0B1D2cEa0BC552588063bdBb210FDeecfA)); // DAI
        _setAggregator(0x7130d2A12B9BCbFAe4f2634d864A1Ee1Ce3Ead9c, AggregatorV3Interface(0x264990fbd0A4796A3E3d8E37C4d5F87a3aCa5Ebf)); // BTCB
       
    }
}