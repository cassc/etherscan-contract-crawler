// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "./Error.sol";

library PriceFeed {
    function getLatestPrice(address _priceFeed) internal view returns (uint256) {
        AggregatorV3Interface priceFeed = AggregatorV3Interface(_priceFeed);
        (, int256 price, , , ) = priceFeed.latestRoundData();
        if (price <= 0) revert INVALID_PRICE_FROM_PRICE_FEED();
        return uint256(price);
    }

    function getDecimals(address _priceFeed) internal view returns (uint8) {
        AggregatorV3Interface priceFeed = AggregatorV3Interface(_priceFeed);
        return priceFeed.decimals();
    }

    function convertBUSDToBNB(uint256 _BUSDAmount, address _priceFeed) internal view returns (uint256) {
        uint256 BNBPerBUSD = getLatestPrice(_priceFeed);
        uint8 decimals = getDecimals(_priceFeed);

        return (_BUSDAmount * BNBPerBUSD) / (10**decimals);
    }

    function convertBNBToBUSD(uint256 _BNBAmount, address _priceFeed) internal view returns (uint256) {
        uint256 BNBPerBUSD = getLatestPrice(_priceFeed);
        uint8 decimals = getDecimals(_priceFeed);
        return (_BNBAmount * (10**decimals)) / BNBPerBUSD;
    }
}