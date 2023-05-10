// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

/**
 * Network: Ethereum Mainnet
 * Aggregator: ETH / USD
 * Address: 0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419
 */
/**
 * Network: Goerli Testnet
 * Aggregator: ETH / USD
 * Address: 0xD4a33860578De61DBAbDc8BFdb98FD742fA7028e
 */
/**
 * Network: Sepolia Testnet
 * Aggregator: ETH / USD
 * Address: 0x694AA1769357215DE4FAC081bf1f309aDC325306
 */

library PriceConverter {
    /**
     * @dev function to get the Price of ETH / USD.
     * The problem with this we get value with 8 float point while Matic/ETH have 18 float point.
     * Therefore we raise the power of our answer with 10 floating point.
     */
    function getPrice() public view returns (uint256) {
        AggregatorV3Interface priceFeed = AggregatorV3Interface(
            0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419
        );
        (, int256 answer, , , ) = priceFeed.latestRoundData();
        return uint256(answer * 1e10); // 1* 10 ** 10 == 10000000000
    }

    /**
     * @dev function to get eth(matic) in USD.
     * Will get the actual ETH/USD conversion rate, after adjusting the extra 0s.
     */
    function getConversionRate(
        uint256 ethAmount
    ) public view returns (uint256) {
        uint256 ethPrice = getPrice();
        uint256 ethAmountInUsd = (ethPrice * ethAmount) / 1e18; // 1 * 10 ** 18 == 1000000000000000000
        // the actual ETH/USD conversion rate, after adjusting the extra 0s.
        return ethAmountInUsd;
    }

    /**
     * @dev function to get eth(matic) in USD.
     * Will get the actual ETH/USD conversion rate, after adjusting the extra 0s.
     */
    function getEthPrice(uint256 dollarAmount) public view returns (uint256) {
        uint256 ethPrice = getPrice();
        uint256 usdAmountInEth = (1e18 * dollarAmount) / ethPrice;
        return usdAmountInEth;
    }
}