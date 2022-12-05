// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../AnteTest.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

// @title Chainlink data feed heartbeat is respected
// @notice Ensure that Chainlink data feeds update according to declared heartbeats
contract AnteChainlinkHeartbeatTest is AnteTest(
    "Top Chainlink price feeds on Ethereum update according to declared heartbeats (2022-12-03)"
) {
    AggregatorV3Interface[6] public priceFeeds;
    uint256[6] public heartbeats;

    // Error margin
    uint256 public constant ERROR_MARGIN = 4 minutes; // to save the world

    constructor() {
        protocolName = "Chainlink";

        // Top 6 price feeds on Ethereum Mainnet and heartbeats as of 2022-12-03
        // as listed on https://data.chain.link/ethereum/mainnet
        priceFeeds = [
            AggregatorV3Interface(0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419), // ETH  / USD
            AggregatorV3Interface(0xF4030086522a5bEEa4988F8cA5B36dbC97BeE88c), // BTC  / USD
            AggregatorV3Interface(0x2c1d072e956AFFC0D435Cb7AC38EF18d24d9127c), // LINK / USD
            AggregatorV3Interface(0x3E7d1eAB13ad0104d2750B8863b489D65364e32D), // USDT / USD
            AggregatorV3Interface(0xAed0c38402a5d19df6E4c03F4E2DceD6e29c1ee9), // DAI  / USD
            AggregatorV3Interface(0x8fFfFfd4AfB6115b954Bd326cbe7B4BA576818f6)  // USDC / USD
        ];
        heartbeats = [
            1 hours, // ETH  / USD
            1 hours, // BTC  / USD
            1 hours, // LINK / USD
            1 days,  // USDT / USD
            1 hours, // DAI  / USD
            1 days   // USDC / USD
        ];
        
        for (uint256 i = 0; i < 6; i++) {
            testedContracts.push(address(priceFeeds[i]));
        }
    }

    function checkTestPasses() external view override returns (bool) {
        for (uint256 i = 0; i < 6; i++) {
            (, , , uint256 updatedAt, ) = priceFeeds[i].latestRoundData();

            // Check if the feed was updated within (heartbeat + error margin)
            if (updatedAt + heartbeats[i] + ERROR_MARGIN < block.timestamp) {
                return false;
            }
        }

        return true;
    }
}