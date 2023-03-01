// SPDX-License-Identifier: MIT

pragma solidity ^0.8.16;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

contract DataFeeds {

    AggregatorV3Interface internal immutable priceFeed;

    /**
     * Network: BSC - BSC TESTNET 
     * Aggregator: BNB/USD
     * testnet: 0x2514895c72f50D8bd4B4F9b1110F0D6bD2c97526
     * mainnet: 0x0567F2323251f0Aab15c8dFb1967E4e8A7D42aeE
     **/
    constructor() {
        priceFeed = AggregatorV3Interface(0x0567F2323251f0Aab15c8dFb1967E4e8A7D42aeE);
    }

    function _getLatestPrice() internal view returns (int) {
        (
          , // uint80 roundId
          int256 answer,
          , // uint256 startedAt
          , // uint256 updatedAt
            // uint80 answeredInRound
         ) = priceFeed.latestRoundData();
        return answer;
    }
}