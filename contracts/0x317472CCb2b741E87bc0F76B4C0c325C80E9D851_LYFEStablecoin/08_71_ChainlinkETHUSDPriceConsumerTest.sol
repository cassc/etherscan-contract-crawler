// SPDX-License-Identifier: MIT
pragma solidity 0.6.11;
pragma experimental ABIEncoderV2;

import "./AggregatorV3Interface.sol";


contract ChainlinkETHUSDPriceConsumerTest {

    AggregatorV3Interface internal priceFeed;

    /**
     * Network: Goerli
     * Aggregator: ETH/USD
     * Address: 0xD4a33860578De61DBAbDc8BFdb98FD742fA7028e
     */
    /**
     * Network: Mainnet
     * Aggregator: ETH/USD
     * Address: 0x5f4ec3df9cbd43714fe2740f5e3616155c5b8419
     */

     
    constructor() public {
        priceFeed = AggregatorV3Interface(0xD4a33860578De61DBAbDc8BFdb98FD742fA7028e);
    }

    /**
     * Returns the latest price
     */
    function getLatestPrice() public returns (int) {
        (
             uint80 roundID, 
             int price,
             uint startedAt,
             uint timeStamp,
             uint80 answeredInRound
         ) = priceFeed.latestRoundData();
        // // If the round is not complete yet, timestamp is 0
        // require(timeStamp > 0, "Round not complete");

        // This will return something like 32063000000
        // Divide this by getDecimals to get the "true" price
        // You can can multiply the "true" price by 1e6 to get the lyfe ecosystem 'price'
        // return price;

        return 59000000000;
    }

    function getDecimals() public returns (uint8) {
        return priceFeed.decimals();
        return 8;
    }
}