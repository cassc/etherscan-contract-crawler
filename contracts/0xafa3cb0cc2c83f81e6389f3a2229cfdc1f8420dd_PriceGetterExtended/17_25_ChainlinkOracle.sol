// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

abstract contract ChainlinkOracle {
    /// @notice Returns the price of the token in decimals of oracle
    function _getChainlinkPriceRaw(address oracleAddress) internal view returns (uint256) {
        AggregatorV3Interface priceFeed = AggregatorV3Interface(oracleAddress);
        (, int256 price, , , ) = priceFeed.latestRoundData();
        return uint256(price);
    }

    /// @notice Returns the price of the token in wei with 18 decimals
    function _getChainlinkPriceNormalized(address oracleAddress) internal view returns (uint256) {
        AggregatorV3Interface priceFeed = AggregatorV3Interface(oracleAddress);
        (, int256 price, , , ) = AggregatorV3Interface(oracleAddress).latestRoundData();
        uint8 decimals = priceFeed.decimals();
        return (uint256(price) * 10 ** 18) / 10 ** decimals;
    }
}